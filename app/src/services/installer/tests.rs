//! The launch protocol end to end, against stub front doors run by Windows
//! PowerShell, and the front door's progress lines.

use std::os::windows::fs::OpenOptionsExt;
use std::path::Path;

use futures::StreamExt;
use futures::executor::block_on;
use windows::Win32::Storage::FileSystem::FILE_SHARE_DELETE;

use super::*;
use crate::services::test_support::TempDir;

#[test]
fn parses_plan_progress_and_rejects_invalid_or_unrelated_output() {
    let progress = PlanProgress::from_line("[2026-09-06 20:32:19] [-] [INFO] [AtlasProgress] 8/40").unwrap();
    assert_eq!(progress.fraction(), 0.2);
    assert_eq!(PlanProgress::from_line("[AtlasProgress] 40/40").unwrap().fraction(), 1.0);
    for line in [
        "8/40",
        "[AtlasProgress] 1/0",
        "[AtlasProgress] 41/40",
        "[AtlasProgress] -1/40",
        "[AtlasProgress] 3/no",
        "[AtlasProgress] 3/40 extra",
    ] {
        assert!(PlanProgress::from_line(line).is_none(), "{line}");
    }
}

/// The phases come from the front door's own step lines, so rewording one
/// there must fail here rather than freeze the phase shown.
#[test]
fn phases_are_read_from_the_front_doors_own_lines() {
    let script =
        include_str!("../../../../playbook/Executables/AtlasModules/Scripts/Entry/Install-Atlas.ps1");
    let phases: Vec<Phase> = script
        .lines()
        .filter_map(|line| line.trim().strip_prefix("Write-AtlasInstallStep '")?.strip_suffix('\''))
        // PowerShell doubles an apostrophe inside a single-quoted string.
        .filter_map(|step| Phase::from_line(&format!("[Atlas] {}", step.replace("''", "'"))))
        .collect();
    assert_eq!(phases, [Phase::Staging, Phase::Staging, Phase::Applying, Phase::Done]);
    assert_eq!(Phase::from_line("[Atlas] Atlas 0.6.0 from 'C:\\x'."), None);
    assert_eq!(
        Phase::from_line("[Atlas] Staging the payload in a protected directory..."),
        Some(Phase::Staging),
        "earlier 0.6.0 test packages still report their copy step"
    );
}

/// A harmless stand-in for the front door with the real parameter block.
fn stub_playbook(root: &Path, body: &str) -> PathBuf {
    let dir = root.join("Play book 'quoted'").join("0.6.0");
    let script = playbook::front_door(&dir);
    fs::create_dir_all(script.parent().unwrap()).unwrap();
    fs::write(dir.join("playbook.conf"), "<Playbook><Version>0.6.0</Version></Playbook>").unwrap();
    fs::write(
        &script,
        format!(
            "\u{feff}[CmdletBinding()]\r\nparam(\r\n    [Parameter(Mandatory = $true)]\r\n    [ValidatePattern('^[a-z0-9-]+$')]\r\n    [string[]]$Option,\r\n    [switch]$Unattended,\r\n    [switch]$Restart,\r\n    [string]$RestartComment,\r\n    [switch]$KeepStaging\r\n)\r\n{body}\r\n"
        ),
    )
    .unwrap();
    dir
}

fn run(request: InstallRequest, paths: &SessionPaths) -> (SessionRecord, Vec<String>, InstallOutcome) {
    let (record, mut events) = start(request, paths).expect("start the stub installer");
    let mut lines = Vec::new();
    let outcome = block_on(async {
        loop {
            match events.next().await.expect("the reader ends with Finished") {
                InstallEvent::Lines(batch) => lines.extend(batch),
                InstallEvent::OutputProblem(problem) => panic!("output problem: {problem}"),
                InstallEvent::Finished(outcome) => break outcome,
            }
        }
    });
    (record, lines, outcome)
}

/// Also checks that Atlas owns the restart: the request asks for one, and the
/// front door is never asked to restart.
#[test]
fn multiple_options_reach_windows_powershell_as_an_array() {
    let temp = TempDir::new("installer-options");
    let dir = stub_playbook(
        temp.path(),
        "foreach ($o in $Option) { Write-Host \"OPTION=$o\" }\r\nWrite-Host \"COUNT=$($Option.Count)\"\r\nWrite-Host \"UNATTENDED=$Unattended RESTART=$Restart\"\r\nWrite-Host \"CWD=$((Get-Location).Path)\"\r\nexit 0",
    );
    let paths = SessionPaths::under(&temp.path().join("App"));
    let request = InstallRequest {
        playbook_dir: dir.clone(),
        options: vec!["defender-enable".into(), "mitigations-default".into(), "auto-updates-disable".into()],
        restart: true,
    };
    let (record, lines, outcome) = run(request.clone(), &paths);
    assert_eq!(outcome, InstallOutcome::Succeeded, "{lines:?}");
    assert!(lines.contains(&"OPTION=defender-enable".to_owned()), "{lines:?}");
    assert!(lines.contains(&"OPTION=mitigations-default".to_owned()), "{lines:?}");
    assert!(lines.contains(&"OPTION=auto-updates-disable".to_owned()), "{lines:?}");
    assert!(lines.contains(&"COUNT=3".to_owned()), "{lines:?}");
    assert!(lines.contains(&"UNATTENDED=True RESTART=False".to_owned()), "{lines:?}");
    assert!(lines.iter().any(|l| l.starts_with("CWD=") && l.ends_with("0.6.0")), "{lines:?}");
    // The session record points at the log and the exit code was written.
    assert_eq!(record.request, request);
    assert_eq!(record.exit_code(), Some(0));
    assert!(fs::read_to_string(&record.log_path).unwrap().contains("OPTION=defender-enable"));
    assert_eq!(session::load(&paths).unwrap(), Some(record));
}

#[test]
fn exit_codes_and_stderr_come_back_and_output_survives_bad_bytes() {
    let temp = TempDir::new("installer-exit");
    let dir = stub_playbook(
        temp.path(),
        "Write-Host \"[Atlas] Running the install plan as TrustedInstaller. This takes several minutes...\"\r\nWrite-Host \"Grüße ✓\"\r\n$s = [Console]::OpenStandardOutput(); $s.Write([byte[]](0xE9, 0x0A), 0, 2); $s.Flush()\r\nWrite-Host \"AFTER_NON_UTF8\"\r\n[Console]::Error.WriteLine(\"[Atlas] something failed\")\r\nexit 1",
    );
    let paths = SessionPaths::under(&temp.path().join("App"));
    let request =
        InstallRequest { playbook_dir: dir, options: vec!["defender-enable".into()], restart: true };
    let (record, lines, outcome) = run(request, &paths);
    assert_eq!(outcome, InstallOutcome::Failed(1), "{lines:?}");
    assert!(lines.contains(&"Grüße ✓".to_owned()), "{lines:?}");
    assert!(lines.contains(&"\u{FFFD}".to_owned()), "{lines:?}");
    assert!(lines.contains(&"AFTER_NON_UTF8".to_owned()), "{lines:?}");
    assert!(lines.contains(&"[Atlas] something failed".to_owned()), "{lines:?}");
    assert_eq!(record.exit_code(), Some(1));
    assert!(lines.iter().any(|l| Phase::from_line(l) == Some(Phase::Applying)));
}

#[test]
fn a_finished_session_can_be_reattached_from_its_record() {
    let temp = TempDir::new("installer-reattach");
    let dir = stub_playbook(temp.path(), "Write-Host \"first line\"\r\nexit 2");
    let paths = SessionPaths::under(&temp.path().join("App"));
    let request =
        InstallRequest { playbook_dir: dir, options: vec!["defender-enable".into()], restart: false };
    let (record, _, outcome) = run(request, &paths);
    assert_eq!(outcome, InstallOutcome::Failed(2));
    assert!(!record.is_alive());

    let mut events = reattach(&record);
    let (lines, outcome) = block_on(async {
        let mut lines = Vec::new();
        loop {
            match events.next().await.unwrap() {
                InstallEvent::Lines(batch) => lines.extend(batch),
                InstallEvent::OutputProblem(_) => {}
                InstallEvent::Finished(outcome) => break (lines, outcome),
            }
        }
    });
    assert_eq!(lines, vec!["first line".to_owned()]);
    assert_eq!(outcome, InstallOutcome::Failed(2));

    // Without an exit file the ended process is reported as lost, not as a success.
    fs::remove_file(&record.exit_path).unwrap();
    let mut events = reattach(&record);
    let outcome = block_on(async {
        loop {
            if let InstallEvent::Finished(outcome) = events.next().await.unwrap() {
                break outcome;
            }
        }
    });
    assert_eq!(outcome, InstallOutcome::Lost);
}

/// The window died (or Windows restarted) between the record and the
/// go-ahead: the orphaned wrapper gives up, and a reopened app says that
/// nothing was started rather than that the result is unknown.
#[test]
fn a_go_ahead_that_never_comes_is_reported_as_not_started() {
    let temp = TempDir::new("installer-handover-timeout");
    let (request, marker) = marking_stub(temp.path(), "exit 0");
    let logs = temp.path().join("Logs");
    fs::create_dir_all(&logs).unwrap();
    let record = SessionRecord {
        id: "orphan".into(),
        pid: 0,
        process_start: 0,
        started_at: String::new(),
        log_path: logs.join("install-orphan.log"),
        exit_path: logs.join("install-orphan.exit"),
        request,
    };
    fs::write(&record.log_path, "").unwrap();
    let command = wrapper_command(&record.request, &record.exit_path, &record.go_path(), 1).unwrap();
    let status = powershell::command()
        .arg("-Command")
        .arg(&command)
        .current_dir(&record.request.playbook_dir)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .unwrap();
    assert_eq!(status.code(), Some(NOT_STARTED_EXIT_CODE));
    assert!(!marker.exists(), "the front door never ran");
    assert_eq!(record.exit_code(), Some(NOT_STARTED_EXIT_CODE));
    let mut events = reattach(&record);
    let outcome = block_on(async {
        loop {
            if let InstallEvent::Finished(outcome) = events.next().await.unwrap() {
                break outcome;
            }
        }
    });
    assert_eq!(outcome, InstallOutcome::NotStarted);

    // With no exit code, the go-ahead file decides: without it the front
    // door cannot have run; with it, it may have.
    fs::remove_file(&record.exit_path).unwrap();
    assert_eq!(ended_without_a_result(&record), InstallOutcome::NotStarted);
    fs::write(record.go_path(), "go").unwrap();
    assert_eq!(ended_without_a_result(&record), InstallOutcome::Lost);
}

#[test]
fn a_missing_front_door_is_refused_before_anything_starts() {
    let temp = TempDir::new("installer-missing");
    let paths = SessionPaths::under(&temp.path().join("App"));
    let request = InstallRequest {
        playbook_dir: temp.path().join("nowhere"),
        options: vec!["defender-enable".into()],
        restart: false,
    };
    assert!(start(request, &paths).is_err());
    assert!(session::load(&paths).unwrap().is_none());
}

#[test]
fn a_running_install_refuses_a_second_start_and_hands_back_its_record() {
    let temp = TempDir::new("installer-second-start");
    // The stub runs until the test lets it finish (or a minute passes).
    let release = temp.path().join("release");
    let dir = stub_playbook(
        temp.path(),
        &format!(
            "$deadline = (Get-Date).AddMinutes(1)\r\nwhile (-not (Test-Path -LiteralPath '{}') -and (Get-Date) -lt $deadline) {{ Start-Sleep -Milliseconds 50 }}\r\nWrite-Host \"first done\"\r\nexit 0",
            release.display().to_string().replace('\'', "''")
        ),
    );
    let paths = SessionPaths::under(&temp.path().join("App"));
    let request =
        InstallRequest { playbook_dir: dir, options: vec!["defender-enable".into()], restart: false };
    let (first, events) = start(request.clone(), &paths).unwrap();
    assert!(first.is_alive());
    let error = start(request.clone(), &paths).unwrap_err();
    let running = error.downcast::<AlreadyRunning>().expect("a second start reports the running install");
    assert_eq!(running.0.pid, first.pid);
    // Another window releasing its own, older session removes nothing.
    assert!(!session::release(&paths, "an-earlier-session").unwrap());
    assert_eq!(
        session::load(&paths).unwrap().unwrap().pid,
        first.pid,
        "the record still names the first install"
    );
    fs::write(&release, "").unwrap();
    let outcome = block_on(async {
        let mut events = events;
        loop {
            if let InstallEvent::Finished(outcome) = events.next().await.unwrap() {
                break outcome;
            }
        }
    });
    assert_eq!(outcome, InstallOutcome::Succeeded);
    // Once it has ended, a new install may start and gets its own artifacts.
    let (second, _, outcome) = run(request, &paths);
    assert_eq!(outcome, InstallOutcome::Succeeded);
    assert_ne!(second.log_path, first.log_path);
    assert_ne!(second.id, first.id);
}

#[test]
fn a_held_launch_lock_refuses_a_start() {
    let temp = TempDir::new("installer-launch-lock");
    let dir = stub_playbook(temp.path(), "exit 0");
    let paths = SessionPaths::under(&temp.path().join("App"));
    let held = session::LaunchLock::acquire(&paths).unwrap();
    let request =
        InstallRequest { playbook_dir: dir, options: vec!["defender-enable".into()], restart: false };
    let error = launch(session::new_id(), request, &paths, Duration::from_millis(100)).unwrap_err();
    assert!(format!("{error:#}").contains("another Atlas window"), "{error:#}");
    assert!(session::load(&paths).unwrap().is_none());
    drop(held);
    assert!(session::LaunchLock::acquire(&paths).is_ok());
}

#[test]
fn a_completed_session_replays_the_whole_log() {
    let temp = TempDir::new("installer-large-replay");
    let logs = temp.path().join("Logs");
    fs::create_dir_all(&logs).unwrap();
    let log_path = logs.join("install-large.log");
    let exit_path = logs.join("install-large.exit");
    let mut text = String::new();
    let padding = "x".repeat(110);
    for index in 0..80_000 {
        text.push_str(&format!("line {index} {padding}\n"));
    }
    text.push_str("FINAL_SENTINEL\n");
    text.push_str("tail without newline \u{20ac}");
    fs::write(&log_path, text.as_bytes()).unwrap();
    assert!(text.len() > 9 * 1024 * 1024, "the log must span several read chunks");
    fs::write(&exit_path, "1").unwrap();
    let record = SessionRecord {
        id: "large".into(),
        pid: 0,
        process_start: 0,
        started_at: String::new(),
        log_path,
        exit_path,
        request: InstallRequest { playbook_dir: temp.path().into(), options: vec![], restart: false },
    };
    let mut events = reattach(&record);
    let (lines, outcome) = block_on(async {
        let mut lines = Vec::new();
        loop {
            match events.next().await.unwrap() {
                InstallEvent::Lines(batch) => lines.extend(batch),
                InstallEvent::OutputProblem(problem) => panic!("{problem}"),
                InstallEvent::Finished(outcome) => break (lines, outcome),
            }
        }
    });
    assert_eq!(outcome, InstallOutcome::Failed(1));
    assert_eq!(lines.len(), 80_002, "every line reaches the UI");
    assert_eq!(lines[80_000], "FINAL_SENTINEL");
    assert_eq!(lines[80_001], "tail without newline \u{20ac}");
}

/// A stub whose front door records that it ran in a side file, so a test
/// can tell whether the script body was ever entered.
fn marking_stub(root: &Path, body: &str) -> (InstallRequest, PathBuf) {
    let marker = root.join("front-door-ran.txt");
    let dir = stub_playbook(
        root,
        &format!("Set-Content -LiteralPath '{}' -Value 'ran'\r\n{body}", marker.display()),
    );
    (InstallRequest { playbook_dir: dir, options: vec!["defender-enable".into()], restart: false }, marker)
}

#[test]
fn abandoned_and_unreadable_records_do_not_own_anything() {
    let temp = TempDir::new("installer-abandoned");
    let paths = SessionPaths::under(&temp.path().join("App"));
    let pending = SessionRecord {
        id: "pending".into(),
        pid: 0,
        process_start: 0,
        started_at: String::new(),
        log_path: paths.logs.join("x.log"),
        exit_path: paths.logs.join("x.exit"),
        request: InstallRequest { playbook_dir: temp.path().into(), options: vec![], restart: false },
    };
    session::save(&paths, &pending).unwrap();
    assert!(!pending.is_alive());
    {
        let lock = LaunchLock::acquire(&paths).unwrap();
        assert!(matches!(lock.inspect(&paths), Inspection::Abandoned));
    }
    assert!(!session::release(&paths, "pending").unwrap(), "an abandoned record is nobody's to release");
    let dir = stub_playbook(temp.path(), "exit 0");
    let request =
        InstallRequest { playbook_dir: dir, options: vec!["defender-enable".into()], restart: false };

    // Another process holds the record open without read sharing: its owner
    // is unknown for now, so nothing may release it or start beside it.
    let holder =
        fs::OpenOptions::new().read(true).share_mode(FILE_SHARE_DELETE.0).open(&paths.record).unwrap();
    assert!(fs::read_to_string(&paths.record).is_err(), "the record must be unreadable for this test");
    {
        let lock = LaunchLock::acquire(&paths).unwrap();
        assert!(matches!(lock.inspect(&paths), Inspection::Unreadable(_)));
    }
    assert!(session::release(&paths, "pending").is_err());
    LAST_SPAWNED.with(|last| last.set(0));
    let error = start(request.clone(), &paths).unwrap_err();
    assert!(format!("{error:#}").contains("cannot be read"), "{error:#}");
    assert_eq!(LAST_SPAWNED.with(|last| last.get()), 0, "no child may be launched");
    drop(holder);
    assert_eq!(session::load(&paths).unwrap(), Some(pending), "the record survives");

    // Unparseable is unknown ownership too, not abandonment: nothing may touch it.
    fs::write(&paths.record, "{ not json").unwrap();
    let lock = LaunchLock::acquire(&paths).unwrap();
    assert!(matches!(lock.inspect(&paths), Inspection::Unreadable(_)));
    assert!(matches!(lock.inspect(&SessionPaths::under(&temp.path().join("empty"))), Inspection::None));
    drop(lock);
    assert!(session::release(&paths, "pending").is_err(), "an unreadable record cannot be released");
    assert!(paths.record.is_file(), "the record is preserved");
    let error = start(request, &paths).unwrap_err();
    assert!(format!("{error:#}").contains("cannot be read"), "{error:#}");
    assert_eq!(fs::read_to_string(&paths.record).unwrap(), "{ not json", "the record is not replaced");
}

#[test]
fn record_publication_failures_never_reach_the_front_door() {
    for point in [FailPoint::InitialRecord, FailPoint::RecordRewrite, FailPoint::GoAhead] {
        let temp = TempDir::new("installer-fail-point");
        let paths = SessionPaths::under(&temp.path().join("App"));
        let (request, marker) = marking_stub(temp.path(), "exit 0");
        FAIL_AT.with(|fail| fail.set(Some(point)));
        LAST_SPAWNED.with(|last| last.set(0));
        let result = start(request, &paths);
        FAIL_AT.with(|fail| fail.set(None));
        let error = result.err().unwrap_or_else(|| panic!("{point:?} must fail the start"));
        assert!(error.to_string().contains("nothing was started"), "{point:?}: {error:#}");
        let spawned = LAST_SPAWNED.with(|last| last.get());
        if point == FailPoint::InitialRecord {
            assert_eq!(spawned, 0, "nothing is spawned before the record is written");
        } else {
            assert_ne!(spawned, 0);
            assert!(
                !crate::services::system::process_alive(spawned, 0),
                "{point:?}: the waiting child is gone"
            );
        }
        assert!(!marker.exists(), "{point:?}: the front door must not run");
        assert!(session::load(&paths).unwrap().is_none(), "{point:?}: no record remains");
        let artifacts: Vec<String> = fs::read_dir(&paths.logs)
            .map(|d| d.flatten().map(|e| e.file_name().to_string_lossy().into_owned()).collect())
            .unwrap_or_default();
        assert!(artifacts.is_empty(), "{point:?}: no artifacts remain: {artifacts:?}");
    }
}
