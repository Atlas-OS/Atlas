# Reviewed timer builds

`Build-TimerTools.ps1 -OutputDirectory <new-folder>` downloads hash-pinned inputs,
applies the small reviewed patch, and compiles x64 candidates with static CRT.
It does not execute either utility, overwrite a previous candidate, install tools,
or replace playbook files. Use PowerShell 7, Git, MSVC 14.44.35207 and Windows SDK
10.0.26100.0. Paths to an existing toolchain can be supplied explicitly.

`inputs.json` pins the original v1.0.0 source commits separately for each utility,
and the header-only args 6.4.6 dependency. TimerResolution is GPL-3.0; args is MIT.
Original license texts are downloaded and hashed alongside the source. The produced
`corresponding-source.zip` contains the exact source, dependency header, licenses,
patch and build recipe. Distribute it with accepted binaries; preserve the generated
build manifest with the release evidence. A stable source download must remain
available when publishing binaries, including binaries committed into the repository.

`MeasureSleep.patch` requires at least three requested samples: the first is
discarded, so two samples would leave a zero denominator for sample variance. It
also rejects negative sleep durations before conversion to Windows' unsigned wait
argument and computes the delta against the requested duration instead of a fixed
one millisecond. `SetTimerResolution.patch` rejects nonpositive resolutions before
the native call. The Atlas scheduled task continues to call
`SetTimerResolution --resolution 5060 --no-console`; positive CLI usage is preserved.

Two independent output directories produced identical executable hashes with this
toolchain during review. This is evidence of reproducibility for those inputs, not
runtime or performance validation. Run timer behavior checks in a disposable test
environment before release. Never run the utilities on the development host merely
to validate provenance: one changes timer resolution and the other raises its own
process priority. Existing upstream measurement/argument behavior beyond the small
patch has not received a complete correctness audit.
