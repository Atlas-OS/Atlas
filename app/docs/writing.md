# Writing for Atlas

This guide sets the voice and conventions for the text in Atlas Manager's interface: labels, messages, explanations and accessible names.
It's for anyone who writes or reviews that text in the English source catalog, `i18n/en-GB/atlas.ftl`.
Documentation, READMEs and code comments follow the [writing style](../../docs/style.md), which shares the terms below.

Atlas should help someone make an informed choice without requiring them to know how Windows works.
Use a calm, friendly voice.
Be direct about security, installation failures and restarts.

## Copy conventions

- Address the person as "you" and their computer as "your PC".
  Use "Atlas" for actions the app performs, and "Windows" for actions Windows performs.
- Use sentence case.
  Give headings and labels no final full stop, and write explanatory text as complete sentences.
- Keep familiar controls short: Back, Continue, Cancel, Done.
  Name a consequential action explicitly: Remove Microsoft Defender, Install Atlas, Restart now.
- "Relaunch" refers to this app, and "restart" refers to the PC.
- Introduce technical terms in context.
  The Atlas package is the `.apbx` file that holds Atlas's setup instructions and files.
  Processor protections are also called security mitigations.
  Keep Windows' own switch names, so people can find them in Windows Security.
- Explain both answers before the person chooses.
  Explain optional changes beside their check boxes, including power, compatibility and security trade-offs.
  A selected check box names the action that will happen, even when that action turns a Windows feature off.
- State only what the app knows.
  The protection switches being off doesn't mean every Windows security feature is off.
  No pending updates doesn't prove Windows is fully up to date.
  An unreadable setting isn't an off setting.
- Describe what failed, whether changes may have been made, and what to do next.
  Keep raw diagnostics for troubleshooting.
  Never promise that a partial installation made no changes, or that a retry will succeed.
- Explain when a restart happens, and remind people to save their work.
  Don't claim performance gains or say how soon setup will finish.
- Preserve product names, file paths, versions, variables and plural rules.
  English (United Kingdom) is the source, and English (United States) overrides only spelling differences.
- Use contractions (can't, isn't, couldn't) and straight apostrophes in English copy.

## Names

Use one name for one thing.

- In running text, the selections made in the **Your choices** step are "choices", the ISO modes included.
  Summary cards list them in an "Options" row, and the ISO review in an "Atlas choices" row, kept apart from the step name on purpose.
- "Settings" is the app's own page.
- The `.apbx` file is "the Atlas package", or "the package" once that's clear.
  Interface text never calls it a playbook.
- The install steps are **Get ready**, **Your choices**, **Windows Security** and **Install**.
  The ISO steps are **Files**, **Windows setup**, **Your choices** and **Review**.
  "Windows setup" otherwise means Windows' own installer.
- When text tells people to choose a control, use its exact label.
- On first mention, the four switches Atlas asks people to turn off are "the four Windows Security protection switches"; after that, "the protection switches".
  They're turned off and turned back on, never paused or disabled.
  Name each one as Windows Security does.
- Name the help actions as the app labels them.
  **Export diagnostics** saves a ZIP, **Open log folder** shows the raw logs of an update, ISO or USB job, and **Send a report** goes privately to the Atlas team.
  **Report a problem** on Home opens **Send a report**.
- Privacy text never claims more than the export removes: the user name, PC name, email addresses and known passwords or keys.

## Translations

[Languages](i18n.md) covers how package text stays recognisable and how translations are reviewed.
[Translation guidance](translating.md) records each language's terms.
