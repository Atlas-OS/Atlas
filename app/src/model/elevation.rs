//! Relaunching as administrator, with the draft saved first so the elevated
//! copy resumes the flow.

use gpui::{AsyncApp, Context, WeakEntity};

use super::AppModel;
use super::drafts::DraftWrite;

/// Why the last "Restart as administrator" did not happen.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum ElevationProblem {
    /// The user refused the prompt that begins the flow; the flow is abandoned.
    Declined,
    /// The user refused the prompt to relaunch from inside the flow; the flow
    /// and its saved draft stay.
    DeclinedContinue,
    /// Another window began a flow of its own and now owns the draft.
    TakenOver,
    /// The draft could not be saved, so the elevated copy was not started.
    DraftNotSaved { error: String },
}

impl AppModel {
    /// Whether "Relaunch as administrator" may run: nothing is locked; no
    /// package is still being prepared, since the draft names only a package
    /// that is ready and the elevated copy would fetch another in its place;
    /// and no other window has taken the setup over, which a relaunch would
    /// only report again (Start over takes it back).
    pub fn may_relaunch_elevated(&self) -> bool {
        !self.locked()
            && !self.acquisition.is_busy()
            && self.elevation_error != Some(ElevationProblem::TakenOver)
    }

    /// Relaunches elevated from inside the flow (only reachable when the app
    /// was started on the Install page without elevation). The draft is
    /// written first (awaited, off the window's thread) so the elevated copy
    /// resumes here.
    pub fn relaunch_elevated(&mut self, cx: &mut Context<Self>) {
        if self.elevating || !self.may_relaunch_elevated() {
            return;
        }
        let Some(draft) = self.current_draft() else { return };
        // Each attempt shows only its own result.
        self.elevation_error = None;
        self.settings.draft = Some(draft.clone());
        let saved = self.write_owned_draft(draft);
        self.elevating = true;
        cx.notify();
        cx.spawn(async move |this, cx| {
            let saved = saved.await;
            let ready = this
                .update(cx, |this, cx| {
                    if !this.may_relaunch_elevated() {
                        this.elevating = false;
                        cx.notify();
                        return false;
                    }
                    let problem = match saved {
                        DraftWrite::Written => return true,
                        DraftWrite::TakenOver => ElevationProblem::TakenOver,
                        DraftWrite::Failed(error) => ElevationProblem::DraftNotSaved { error },
                    };
                    this.elevating = false;
                    this.elevation_error = Some(problem);
                    cx.notify();
                    false
                })
                .unwrap_or(false);
            if ready {
                Self::relaunch_as_administrator(this, cx, |this, _| {
                    this.elevation_error = Some(ElevationProblem::DeclinedContinue);
                })
                .await;
            }
        })
        .detach();
    }

    /// Starts the elevated copy, whose draft the caller has saved, and quits
    /// once Windows has started it; a refusal is handed to `declined`.
    ///
    /// Runs off the window's thread: ShellExecute "runas" pumps a nested
    /// message loop during the UAC prompt, which on the window's thread
    /// re-enters the app state.
    pub(super) async fn relaunch_as_administrator(
        this: WeakEntity<Self>,
        cx: &mut AsyncApp,
        declined: impl FnOnce(&mut Self, &mut Context<Self>),
    ) {
        let Ok(relaunch) = this.read_with(cx, |this, _| this.env.adapters.relaunch_elevated.clone()) else {
            return;
        };
        let launched = cx.background_executor().spawn(async move { relaunch() }).await;
        this.update(cx, |this, cx| match launched {
            // The elevated copy is starting; quit once this handler has
            // returned, since quitting mid-update would re-enter the app
            // state. Nothing may start meanwhile, so `elevating` stays set.
            Ok(()) => cx.defer(|cx| cx.quit()),
            Err(error) => {
                log::warn!("elevation declined: {error:#}");
                this.elevating = false;
                declined(this, cx);
                cx.notify();
            }
        })
        .ok();
    }
}
