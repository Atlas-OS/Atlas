# Atlas elevation bootstrap

`AtlasElevationBootstrap-amd64.exe` and `AtlasElevationBootstrap-arm64.exe` are the
small native, `requireAdministrator` transport boundary between Atlas's
medium-integrity caller and the fixed Windows PowerShell TrustedInstaller broker.

The caller owns the one local, first-instance
`\\.\pipe\AtlasOS.TrustedInstaller.<32-lowercase-hex>` rendezvous. The elevated
bootstrap connects as a client with constrained SQOS, binds the server to kernel
PID/process-generation/SID/session evidence, validates one bounded `ATLASTI2` request
frame, and relays the payload opaquely over dedicated inherited handles. It accepts
only `Request`, `Ready`, and `Result` frame kinds and never parses the request body.

The bootstrap validates its elevated high-integrity token and fixed protected self,
Windows PowerShell, and broker paths; retains non-write/non-delete file leases;
constructs a clean Unicode environment; uses a protected per-request temporary
directory; and launches the fixed broker with an inherited-handle allowlist and an
atomic outer/owner-guard job chain. After the one Request, a permanent one-byte
overlapped read treats caller-pipe closure or additional inbound data as cancellation.
The bootstrap retains the broker Result until the broker has exited and the outer job
has drained, commits the inbound monitor, then publishes exactly one Result and closes
the pipe. No fallible lifecycle phase occurs after that terminal publication, so every
32-bit target exit pattern remains unambiguous. It does not perform UAC elevation,
accept executable paths or command text, invoke a command shell, or parse JSON.
Because Windows jobs are session-bound, the broker stays in the requester-session
outer/owner-guard jobs while the TrustedInstaller-session target is atomically assigned
only to a broker-owned kill-on-close inner job.

Build both payloads directly with PowerShell 7:

```powershell
& .\tools\build\Build-AtlasElevationBootstrap.ps1 `
    -Architecture all `
    -RunContractHarness
```

The build requires LLVM 22.1.8, MSVC tools 14.51.36231, and Windows SDK
10.0.26100.0; `-LlvmRoot` (or `ATLAS_LLVM_ROOT`) selects the one LLVM root used for
both `clang-cl` and `lld-link`. It snapshots the complete source input set, clears
ambient compiler/linker variables, records exact tool, Clang builtin-header, consumed
MSVC/Windows SDK include-tree, and per-architecture library evidence, and restores the
caller's environment on every exit. One no-CRT source and the same hardened flags produce
amd64 and ARM64 outputs twice in independent roots. Objects, resources, harnesses, and
executables must compare byte-for-byte.

Before publication, the build runs the host-compatible same-translation-unit,
no-manifest harness with a 30-second bound, writes the closed schema-3 provenance
manifest, and verifies the complete candidate set. Publication uses final filesystem
identity checks, same-directory atomic replacements, destination re-hashing, reverse
rollback, and the manifest as the last commit record. The harness exercises process
exits, job-owner death, caller liveness, duplex named-pipe monitoring, and cancellation
ownership.

Only harness architectures runnable by the current Windows host are executed locally.
Cross-compiling the ARM64 payload is not ARM64 runtime evidence; native ARM64 execution
remains a disposable-VM/release-runner gate.

Verify the committed binaries, closed provenance schema, complete raw-backed PE layout,
exact import symbols/IAT, canonical relocations, architecture-specific
GuardCF/GuardXFG/CastGuard load configuration, CFG/CET evidence, and exact embedded
manifest with either Windows PowerShell 5.1 or PowerShell 7:

```powershell
& .\tools\build\Test-AtlasElevationBootstrap.ps1
```

The native build and static verification do not replace the disposable-VM release
gate. End-to-end acceptance still requires the matching caller/broker handle protocol,
wrong-peer and abandonment tests, job-tree drain tests, UAC accept/cancel coverage,
and native ARM64 execution on supported Windows builds.
