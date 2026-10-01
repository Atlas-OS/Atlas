# Console presentation

Every AtlasDesktop launcher, Toolbox launcher and nested helper prints through one
vocabulary, `Atlas.Core\Domain\Ui.ps1`, which needs only Windows PowerShell 5.1. This
page is for contributors who write or review that output. A run shows an Atlas
heading, plain sentences, honest progress, one outcome line and one exit pause. Each
line states its meaning in words, so colour is only a hint and a console, transcript
or bug report reads the same.

## The vocabulary

| Function | Prints | Colour | Use |
| --- | --- | --- | --- |
| `Write-AtlasTitle -Text -Explanation` | `AtlasOS - <Text>`, a dashed underline, optional explanation lines, a blank line. Sets the window title. | cyan (underline dark cyan) | Once, at the top of the owning interactive entry point. |
| `Write-AtlasNote` | Text as given. | default | Context the user needs before or after a change. |
| `Write-AtlasStep` | Text as given. | default | Start of noticeably slow work. End with `...`; say how long when known (`This can take a few minutes...`). Never a percentage or spinner. |
| `Write-AtlasWarning` | `Warning: <text>`, continuation lines indented. | yellow | A concrete consequence of the change. |
| `Write-AtlasSuccess` | Text as given. | green | A verified fact the closing line does not already state. |
| `Write-AtlasFailure` | `Error: <text>` | red | Why something did not happen. |
| `Write-AtlasPartial` | `Partly done: <text>`; sets outcome Partial. | yellow | Some work applied; the rest needs the user. |
| `Write-AtlasNextStep` | `Next step: <text>` | cyan | Advice after a completed change (`Open Microsoft Store to confirm it works.`). Outcome stays Applied. |
| `Write-AtlasManualStep` | `To finish: <text>`; sets outcome Manual. | yellow | Atlas opened Settings or another page and the user must finish there. |
| `Write-AtlasRestartNotice -Kind` | `Restart recommended: ...`, `Restart required: ...`, `Sign out required: ...`, `File Explorer was restarted to apply this change.` or `Restart File Explorer, or sign out and back in, to see this change.` | yellow (informational Explorer line: default) | Fixed sentences, so every launcher says the same thing. |
| `Write-AtlasCompletion -Title` | A blank line, then by outcome: `Done: <Title>.` (Applied), `Not finished yet: complete the step above.` (Manual) or `Partly done: <Title>. Review the warnings above.` (Partial) | green (Done), yellow (others) | Once, after all work finished and was recorded. The engine calls it for toggles; hand-written entry points call it themselves. |
| `Write-AtlasNotApplied -Title -Reason [-DetailsPath]` | A blank line, `Not applied: <Title>.`, `Error: <Reason>`, and `Details: <path>` if given. | red (Details line: default) | Failure block of an interactive entry point, before its exit pause. Pass the install log path so the user can find the full diagnostic. |
| `Read-AtlasYesNo -Question [-DefaultYes]` | `<Question> [y/N]` (or `[Y/n]`) | default | Every yes/no decision. Accepts `y`/`yes`/`n`/`no` in any case; Enter takes the default; anything else prints `Please answer y or n.` and re-asks. |
| `Read-AtlasChoice -Question -Option [-CurrentIndex] [-DefaultIndex]` | The question, a `[1] ...` list marking `(current)` and `(default)`, then `Choose 1-N:` | default | Every numbered menu; returns the 1-based index. Enter takes the default, if any. Other input re-asks with `Please type a number from 1 to N.`; the current option with `That is already the current setting. Choose another option.` |
| `Wait-AtlasContinue` | `Press Enter to continue, or Ctrl+C to cancel.` | default | Acknowledgement gate before anything changes. The engine shows it only after a definition's `Warning`; Defender and Mitigations after their own warning or note; the CBS package installer after its heading. |
| `Wait-AtlasExit` | A blank line, then `Press Enter to exit.` | default | Exactly once, by the owning interactive entry point. |

- `Reset-AtlasRunOutcome` and `Get-AtlasRunOutcome` carry the outcome from companions
  to the entry point that prints the closing line. Partial outranks Manual, which
  outranks Applied, so a later report never hides a more serious one.
- Prompts read through the host, so a `-NonInteractive` or windowless process fails
  with a clear error instead of hanging. Silent and replay callers must gate prompts
  on `$Toggle.Silent`.

## Shape of a run

```
AtlasOS - <launcher name>
-------------------------
<optional explanation>

Warning: <consequence>              only when the definition declares Warning
Press Enter to continue, or Ctrl+C to cancel.

<step>...                           only for work that takes time
<question>? [y/N]                   when user input is needed
<facts, warnings, next steps>
Restarting File Explorer...         only when the state declares Reboot = 'RestartExplorer'
File Explorer was restarted to apply this change.

Done: <launcher or menu label>.     or  Not finished yet: ... / Partly done: ...
Restart required: ...               only when the state declares Reboot = 'Prompt'
Restart Windows now? [y/N]          ('Recommend' prints Restart recommended: ... and does not ask)

Press Enter to exit.
```

A failed run ends with the failure block instead of the closing line:

```
Not applied: <launcher name>.
Error: <reason>
Details: <path to atlas-install.log>

Press Enter to exit.
```

## Who prints what

- **Toggle engine:** the heading, warning gate, a `Menu` toggle's numbered state menu,
  closing line, restart or Explorer follow-up and exit pause. Its `Done:` line is the
  only success message. It appears only after every part of the state applied and,
  for machine work, after the state record was written.
- **Companions:** steps for slow work, their existing questions through
  `Read-AtlasYesNo`, and facts the closing line cannot know. Never `Finished`,
  `Completed` or `Changes applied`. A handoff to Settings calls
  `Write-AtlasManualStep`.
- **Nested helpers** (Remove-Edge, Update-Drivers, the CBS package installer, the
  software picker, the nested Network navigation choice): the same vocabulary, never a
  pause. The caller checks the exit code and throws, so a helper that stopped early
  is never reported as done.
- **Elevation:** when an administrator toggle starts without administrator rights,
  the first window prints only the heading and
  `Asking for administrator permission...`; the elevated window prints the rest. A
  state with both administrator and per-user work keeps the run in the original
  window. The administrator window then prints a heading saying so
  (`Administrator step for the change started in the other window.`) and closes on its
  own.

A presentation change must not alter exit codes, state recording, caller identity
checks or deferred completion (a nested choice that leaves the closing line to its
caller). Respect `/silent`, `/justcontext` and `/noaction`.

## Wording

- Sentence case. No exclamation marks, emoji or ASCII art.
- Name the feature the way the launcher does.
- A warning names what stops working, not "may cause issues".
- Explain the consequence before asking. A question asks about one thing and ends with
  a question mark.
- Progress messages describe work the script is actually doing.
- A closing fact says what is true now (`Sleep is now disabled.`), not what the script
  did.
- Distinguish an app relaunch from a Windows restart.
- When work is incomplete, give a useful next step.
- Changing wording must keep prompt defaults and silent/replay behaviour.

## Logging

`Write-AtlasLog` writes every line to `atlas-install.log`, and warnings and errors also
to `warnings-summary.log`, in:

| Process | Log folder |
| --- | --- |
| Elevated | `%WINDIR%\AtlasModules\Logs\install` |
| Not elevated (cannot write the folder above) | `%LOCALAPPDATA%\AtlasOS\Logs\install` |

`Set-AtlasLogConsoleStyle` sets what it echoes to the console:

| Style | Console output | Used by |
| --- | --- | --- |
| `Diagnostic` (default) | The full timestamped line, even with `-NoConsole` | Silent runs, replay, installation and the TrustedInstaller broker, which rely on captured output |
| `Interactive` | Warnings as `Warning: ...`, errors as `Error: ...`; Info lines stay in the file | Interactive entry points |

A log call whose text the presentation already shows passes `-NoConsole`, so the user
never reads the same failure twice.

## Reviewing console changes

The demo shows a simple toggle, a multi-question flow, a failure and a manual Settings
handoff, without changing Windows settings. Add `-NoColor` to see transcript or
monochrome output.

```powershell
powershell -NoProfile -File tools\dev\Show-AtlasConsoleDemo.ps1
```

`tests/Atlas.ConsolePresentation.Tests.ps1` covers headings, prompts, outcome lines,
log console styles and the single exit pause.
