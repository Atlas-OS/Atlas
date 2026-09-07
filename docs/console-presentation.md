# Console presentation

Every AtlasDesktop launcher, Toolbox launcher and nested helper prints through one
vocabulary, `Atlas.Core\Domain\Ui.ps1`. The goal is a run that reads the same way
whether it is a one-line registry toggle, a multi-question feature restoration or a
failure: a short Atlas heading, plain sentences, honest progress, one clearly worded
outcome and exactly one exit pause. Colour is a hint only; every line carries its
meaning in words, so a classic console, Windows Terminal, a transcript and a bug report
all read alike. Nothing here needs more than Windows PowerShell 5.1.

## The vocabulary

| Function | Prints | Colour | Use |
| --- | --- | --- | --- |
| `Write-AtlasTitle -Text -Explanation` | `AtlasOS - <Text>` over a dashed underline, then optional explanation lines, then a blank line. Also sets the window title. | cyan | Once, at the top of the owning interactive entry point. |
| `Write-AtlasNote` | The text as given. | default | Context the user needs before or after a change. |
| `Write-AtlasStep` | The text as given; ends with `...`. | default | The start of work that takes noticeable time. Say how long when you know (`This can take a few minutes...`). Never a percentage or a spinner. |
| `Write-AtlasWarning` | `Warning: <text>`, continuation lines indented. | yellow | A concrete consequence the user should know before or after the change. |
| `Write-AtlasSuccess` | The text as given. | green | A verified fact about what changed. The toggle engine prints the standard closing line; companions use this only for extra facts. |
| `Write-AtlasFailure` | `Error: <text>` | red | The reason something did not happen. |
| `Write-AtlasPartial` | `Partly done: <text>` and marks the run outcome Partial. | yellow | Some of the work applied and the rest needs the user. |
| `Write-AtlasNextStep` | `Next step: <text>` | cyan | Advice after a completed change (`Open Microsoft Store to confirm it works.`). The run still counts as applied. |
| `Write-AtlasManualStep` | `To finish: <text>` and marks the run outcome Manual. | yellow | Atlas opened Settings or another page and the user must complete the change there. The closing line then says the change is not finished. |
| `Write-AtlasRestartNotice -Kind` | `Restart recommended: ...`, `Restart required: ...`, `Sign out required: ...`, `File Explorer was restarted to apply this change.`, `Restart File Explorer, or sign out and back in, to see this change.` | yellow (informational Explorer line: default) | Fixed sentences so every launcher says the same thing. |
| `Read-AtlasYesNo -Question [-DefaultYes]` | `<Question> [y/N]` (or `[Y/n]`) | default | Every yes/no decision. `y`/`yes` and `n`/`no` in any case; Enter takes the default; anything else prints `Please answer y or n.` and asks again. |
| `Read-AtlasChoice -Question -Option [-CurrentIndex]` | The question, a `[1] ...` list with `(current)` on the active option, then `Choose 1-N:` | default | Every numbered menu. Out-of-range input re-asks; the current option re-asks with `That is already the current setting.` Returns the 1-based index. |
| `Wait-AtlasContinue` | `Press Enter to continue, or Ctrl+C to cancel.` | default | The acknowledgement gate after a definition `Warning`. Only definitions that already declare a warning get one. |
| `Wait-AtlasExit` | A blank line, then `Press Enter to exit.` | default | Exactly once, by the owning interactive entry point, never by a nested helper. |

`Reset-AtlasRunOutcome` and `Get-AtlasRunOutcome` carry the Applied / Manual / Partial
outcome from companions to the entry point that prints the closing line. Prompt
helpers read through the host, so a `-NonInteractive` or windowless process fails with
a clear error instead of hanging; silent and replay callers must gate prompts on `$Toggle.Silent`.

`Write-AtlasLog` keeps writing every line to `atlas-install.log` (and the warnings
summary). What it echoes to the console depends on
`Set-AtlasLogConsoleStyle`: the default `Diagnostic` style echoes the full timestamped
line, which silent runs, replay, installation and the TrustedInstaller broker rely on
for their captured output; interactive entry points switch to `Interactive`, where
Info lines stay in the file, warnings appear as `Warning: ...` and errors as
`Error: ...`. A log call whose text the presentation already shows passes
`-NoConsole` so the user never reads the same failure twice; silent runs ignore that
switch.

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

Done: <launcher or menu label>.     or  Not finished yet: ... / Partly done: ...
Restart required: ...               only when the state declares Reboot
Restart Windows now? [y/N]

Press Enter to exit.
```

Ownership:

- The toggle engine owns the heading, the warning gate, the numbered state menu of a
  `Menu` toggle, the closing line, the restart or Explorer follow-up and the exit
  pause. Companions never print `Finished`, `Completed` or `Changes applied`; the
  engine's `Done:` line is the one success message, printed only after every part of
  the state applied and, for machine work, after the state record was written.
- A companion prints steps for slow work, asks its existing questions with
  `Read-AtlasYesNo`, and adds facts the closing line cannot know. A companion that
  hands the user over to Settings calls `Write-AtlasManualStep`, so the closing line
  becomes `Not finished yet: complete the step above.` instead of `Done:`.
- A nested helper (Remove-Edge, Update-Drivers, the CBS package installer, the software
  picker, the nested Network navigation choice) prints with the same vocabulary and
  never pauses; its caller checks its exit code and throws, so a helper that stopped
  early can never be reported as done.
- The non-elevated parent of an administrator toggle prints the heading and
  `Asking for administrator permission...`; the elevated window prints everything
  else. The administrator step of a split state prints a heading that says so and
  closes on its own.
- Keep presentation changes separate from exit codes, state recording, caller identity
  and deferred completion. Respect `/silent`, `/justcontext` and `/noaction`.

Wording: sentence case, no exclamation marks, no emoji, no ASCII art. Name the feature
the way the launcher does. A warning names what stops working, not "may cause
issues". A question asks about one thing and ends with a question mark. A closing
fact says what is true now (`Sleep is now disabled.`), not what the script did.

## Reviewing console changes

Run `tools/dev/Show-AtlasConsoleDemo.ps1` under Windows PowerShell 5.1 to see a
simple toggle, a flow with several questions, a failure and a manual Settings
handoff. The demo does not change Windows settings. The behavioural tests in
`tests/Atlas.ConsolePresentation.Tests.ps1` cover headings, prompts, outcome lines
and the single exit pause.

Keep progress messages tied to work the script is doing. Explain the consequence
before asking a question, distinguish an app relaunch from a Windows restart, and
give a useful next step when work is incomplete. Preserve prompt defaults and
silent/replay behaviour when changing wording.
