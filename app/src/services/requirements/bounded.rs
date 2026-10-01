//! A time-limited wait on a provider that may never answer: one worker per
//! provider, and a deadline for each caller.

use std::sync::{Arc, Condvar, Mutex};
use std::time::{Duration, Instant};

use anyhow::Result;

/// At most one worker per provider. A caller joins the running job and gets
/// its result, however many later jobs start meanwhile; one whose deadline
/// passes gets [`TimedOut`] while the worker carries on. A finished job is
/// never reused: the next call takes a fresh reading. A blocking COM call
/// cannot be cancelled, so a stalled worker lives until the provider answers
/// or the process ends.
pub(super) struct Bounded<T> {
    name: &'static str,
    current: Mutex<Option<Arc<Job<T>>>>,
}

/// One provider call and its outcome, shared by everyone waiting for it.
struct Job<T> {
    outcome: Mutex<Option<Result<T, String>>>,
    done: Condvar,
}

impl<T> Job<T> {
    fn finished(&self) -> bool {
        self.outcome.lock().unwrap_or_else(|poisoned| poisoned.into_inner()).is_some()
    }
}

/// The provider did not answer within the caller's deadline.
#[derive(Debug)]
struct TimedOut {
    what: &'static str,
    after: Duration,
}

impl std::fmt::Display for TimedOut {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{} did not answer within {} seconds", self.what, self.after.as_secs())
    }
}

impl std::error::Error for TimedOut {}

impl<T: Clone + Send + 'static> Bounded<T> {
    pub(super) const fn new(name: &'static str) -> Self {
        Self { name, current: Mutex::new(None) }
    }

    /// Runs `work` on a worker thread this slot owns (a fresh thread, so the
    /// COM apartment is always the one the work initialises), or joins the
    /// worker already running, and waits at most `timeout` for the answer.
    pub(super) fn run(
        &'static self,
        timeout: Duration,
        work: impl FnOnce() -> Result<T> + Send + 'static,
    ) -> Result<T> {
        let job = {
            let mut current = self.current.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
            match &*current {
                Some(job) if !job.finished() => job.clone(),
                _ => {
                    let job = Arc::new(Job { outcome: Mutex::new(None), done: Condvar::new() });
                    let worker = job.clone();
                    let name = self.name;
                    let spawned =
                        std::thread::Builder::new().name(format!("atlas-{name}")).spawn(move || {
                            let result = work().map_err(|error| format!("{error:#}"));
                            *worker.outcome.lock().unwrap_or_else(|poisoned| poisoned.into_inner()) =
                                Some(result);
                            worker.done.notify_all();
                        });
                    if let Err(error) = spawned {
                        // Nothing is running; the next caller may try again.
                        *current = None;
                        return Err(anyhow::Error::from(error).context(format!("start the {name} worker")));
                    }
                    *current = Some(job.clone());
                    job
                }
            }
        };
        let deadline = Instant::now() + timeout;
        let mut outcome = job.outcome.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
        loop {
            if let Some(result) = &*outcome {
                return result.clone().map_err(|error| anyhow::anyhow!("{error}"));
            }
            let now = Instant::now();
            if now >= deadline {
                return Err(TimedOut { what: self.name, after: timeout }.into());
            }
            let (guard, _) = job
                .done
                .wait_timeout(outcome, deadline - now)
                .unwrap_or_else(|poisoned| poisoned.into_inner());
            outcome = guard;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_slow_provider_has_one_worker_and_a_deadline() {
        use std::sync::atomic::{AtomicUsize, Ordering};
        static SLOW: Bounded<u32> = Bounded::new("a slow provider");
        static STARTED: AtomicUsize = AtomicUsize::new(0);
        let work = || {
            STARTED.fetch_add(1, Ordering::SeqCst);
            std::thread::sleep(Duration::from_millis(400));
            Ok(7)
        };
        // The first caller gives up; the worker carries on alone.
        let error = SLOW.run(Duration::from_millis(50), work).unwrap_err();
        assert!(error.downcast_ref::<TimedOut>().is_some(), "{error:#}");
        // A recheck joins that worker instead of starting a second one.
        assert_eq!(SLOW.run(Duration::from_secs(5), work).unwrap(), 7);
        assert_eq!(STARTED.load(Ordering::SeqCst), 1, "one worker for both callers");
        // Once it has answered, the next check wants a fresh reading.
        assert_eq!(SLOW.run(Duration::from_secs(5), work).unwrap(), 7);
        assert_eq!(STARTED.load(Ordering::SeqCst), 2);
        // Errors are shared the same way.
        static FAILING: Bounded<u32> = Bounded::new("a failing provider");
        let failed = FAILING.run(Duration::from_secs(5), || anyhow::bail!("broken")).unwrap_err();
        assert!(failed.to_string().contains("broken"));
    }

    /// Many simultaneous callers against a fast provider: a caller that
    /// joined a job receives its result even if a later caller starts the
    /// next job before it has woken. A lost result shows up as a timeout, so
    /// the deadline is long enough that a busy machine cannot cause one.
    #[test]
    fn a_later_job_never_steals_the_result_from_earlier_waiters() {
        use std::sync::atomic::{AtomicUsize, Ordering};
        static BUSY: Bounded<u32> = Bounded::new("a busy provider");
        static TIMED_OUT: AtomicUsize = AtomicUsize::new(0);
        static ANSWERED: AtomicUsize = AtomicUsize::new(0);
        let threads: Vec<_> = (0..12)
            .map(|_| {
                std::thread::spawn(|| {
                    for _ in 0..12 {
                        match BUSY.run(Duration::from_secs(5), || {
                            std::thread::sleep(Duration::from_millis(1));
                            Ok(42)
                        }) {
                            Ok(42) => ANSWERED.fetch_add(1, Ordering::SeqCst),
                            Ok(other) => panic!("wrong answer {other}"),
                            Err(error) if error.downcast_ref::<TimedOut>().is_some() => {
                                TIMED_OUT.fetch_add(1, Ordering::SeqCst)
                            }
                            Err(error) => panic!("{error:#}"),
                        };
                    }
                })
            })
            .collect();
        for thread in threads {
            thread.join().unwrap();
        }
        assert_eq!(TIMED_OUT.load(Ordering::SeqCst), 0, "a completed job's result reached every waiter");
        assert_eq!(ANSWERED.load(Ordering::SeqCst), 144);
    }
}
