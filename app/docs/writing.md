# Writing for Atlas

Atlas should help someone make an informed choice without requiring them
to know how Windows works. Use a calm, friendly voice. Be direct about
security, installation failures and restarts.

## Copy conventions

- Address the person as "you" and their computer as "your PC". Use "Atlas"
  for actions the app performs, and "Windows" for actions Windows performs.
- Use sentence case. Give headings and labels no final full stop; write
  explanatory text as complete sentences.
- Keep familiar controls short: Back, Continue, Cancel, Done. Name a
  consequential action explicitly: Remove Microsoft Defender, Install
  Atlas, Restart now. "Relaunch" refers to this app; "restart" refers to
  the PC.
- Introduce technical terms in context. A playbook is an `.apbx` file
  containing setup instructions and files. Processor protections are also
  called security mitigations. Keep actual Windows switch names so people
  can find them in Windows Security.
- Explain both choices before selection. Explain optional changes beside
  their checkboxes, including power, compatibility and security tradeoffs.
  A checked checkbox names the action that will happen, even when that
  action turns a Windows feature off.
- State what the app knows. Four Defender switches being off does not mean
  every Windows security feature is off. No pending updates does not prove
  Windows is fully up to date. An unreadable setting is not an off setting.
- Describe what failed, whether changes may have been made, and what to do
  next. Retain raw diagnostics for troubleshooting. Never promise that a
  partial installation made no changes or that a retry will succeed.
- Explain restart timing and remind people to save their work. Avoid
  unsupported claims about performance gains or how soon setup will finish.
- Preserve product names, file paths, versions, variables and plural rules.
  English UK is the source; English US overrides spelling differences.

## Package compatibility

Edit displayed option labels and descriptions in `i18n/en-GB/atlas.ftl`.
Do not edit `i18n/playbook-source.ftl` just to change interface wording.
That file records the exact package text the app understands. Labels,
page descriptions and option explanations keep their compatibility guards;
unrecognised package wording is shown as supplied, without an app-authored
option explanation that might no longer apply.

When the actual package changes an option, review its implementation and
every affected translation before updating the baseline. Machine option
identifiers, defaults and the installer command are independent of UI copy.

## Translation review

Follow the [locale conventions and open terminology questions](translating.md).
Non-English catalogs remain previews until a native speaker reviews them. Check
long explanations at the minimum 700 × 520 window size and test accessible names
as well as visible labels. See [language checks](i18n.md#review-and-test-hooks).
