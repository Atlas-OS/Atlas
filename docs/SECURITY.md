# EBOS Security Model

EBOS never sacrifices essential Windows security for theoretical
performance. Where a change has security impact, it is classified,
documented here, and reversible.

## Preserved by default

- **Windows Update** — remains functional; automatic updates can be
  toggled (notifications still arrive)
- **Microsoft Store** — functional; VCLibs re-registered after cleanup
- **Windows Defender / SmartScreen** — enabled by default; removal is an
  explicit, informed installer choice, reversible via
  `Security → Defender` in the EBOS folder
- **Firewall, authentication, recovery** — untouched
- **Sign-in (Microsoft accounts)** — functional

## Opt-in / opt-out security-relevant options

| Option | Default | Risk | Rollback |
|---|---|---|---|
| Defender disable | **enabled (keep Defender)** | HIGH | EBOS folder → Security → Defender, or CAB uninstall |
| CPU mitigations disable | **default mitigations** | MEDIUM | `EBOSModules\Scripts` mitigations toggle |
| Core isolation (VBS/HVCI) disable | checkbox (off) | MEDIUM | registry values back to 1 + reboot |
| UAC secure desktop off | applied (legacy default, documented) | LOW-MEDIUM | delete `PromptOnSecureDesktop` |
| Automatic updates disable | **disabled by default? no — see installer** | LOW | EBOS folder toggle |
| HAGS enable | opt-in | LOW | `HwSchMode=1` + reboot |
| TSX enable | EXPERIMENTAL, off by default | MEDIUM | `DisableTsx=1` + reboot |

## Hardening applied

- Anonymous SAM enumeration restricted
- Remote assistance disabled
- SMB anonymous access/enumeration restricted
- LLMNR disabled configuration shipped (commented, compatibility note)
- Windows RE verified after install (validation check)

## Supply-chain posture

- Playbook is a plain-text, password-protected ZIP — fully auditable
- Binaries are open source with SHA-256 hashes listed in
  `src/playbook/Executables/EBOSModules/README.md`
- No secrets in the repository (CI-enforced secret scan)
- Executed downloads are official/first-party sources only; the legacy
  third-party companion-tool download was **removed** during unification
