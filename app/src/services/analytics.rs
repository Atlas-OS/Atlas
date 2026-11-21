//! Best-effort analytics for release builds. A single bounded queue preserves the order of screen visits.
use std::sync::{OnceLock, mpsc};
use std::time::Duration;

const ENDPOINT: &str = "https://pla.atlasos.net/api/event";
const DOMAIN: &str = "manager.atlasos.net";

struct Event {
    name: &'static str,
    path: &'static str,
}

impl Event {
    fn body(&self) -> serde_json::Value {
        serde_json::json!({
            "name": self.name,
            "domain": DOMAIN,
            "url": format!("https://{DOMAIN}/{}", self.path),
        })
    }
}

pub fn send(enabled: bool, name: &'static str, path: &'static str) {
    if !enabled || cfg!(any(debug_assertions, test)) {
        return;
    }
    static QUEUE: OnceLock<Option<mpsc::SyncSender<Event>>> = OnceLock::new();
    if let Some(queue) = QUEUE.get_or_init(start_sender) {
        // A slow connection must never hold up the installer or grow a disk backlog.
        let _ = queue.try_send(Event { name, path });
    }
}

fn start_sender() -> Option<mpsc::SyncSender<Event>> {
    let (sender, receiver) = mpsc::sync_channel::<Event>(32);
    std::thread::Builder::new()
        .name("manager-analytics".into())
        .spawn(move || {
            let settings = super::settings::AppPaths::from_process().settings();
            let agent = ureq::Agent::new_with_config(
                ureq::Agent::config_builder()
                    .timeout_global(Some(Duration::from_secs(5)))
                    .max_redirects(0)
                    .user_agent(concat!("AtlasManager/", env!("CARGO_PKG_VERSION"), " (Windows)"))
                    .build(),
            );
            for event in receiver {
                // Another window may have opted out since this event was queued.
                let saved = super::settings::read_from(&settings);
                if saved.problem.is_none() && saved.settings.usage_analytics {
                    let _ = agent.post(ENDPOINT).send_json(event.body());
                }
            }
        })
        .ok()?;
    Some(sender)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_pageview_contains_only_the_site_event_and_screen() {
        let view = Event { name: "pageview", path: "iso/files" };
        assert_eq!(
            view.body(),
            serde_json::json!({
                "domain": "manager.atlasos.net", "name": "pageview", "url": "https://manager.atlasos.net/iso/files"
            })
        );
    }
}
