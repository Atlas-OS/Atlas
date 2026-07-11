# Disposable-VM-only release gates for the Atlas-owned TrustedInstaller v2 protocol.
#
# Every example is intentionally pending in the safe developer-host suite. Run these only
# from a fresh disposable Windows 11 VM matrix where UAC, TrustedInstaller, process death,
# job termination, and reboot-safe cleanup can be exercised without changing a host machine.

Describe 'Atlas TrustedInstaller v2 integration on disposable Windows 11 VMs' -Tag 'VMOnly', 'TrustedInstaller' {
    It 'runs the native amd64 and arm64 bootstrap on every declared supported build, including 26100 and 26200' -Pending {}

    It 'rejects plain SYSTEM and proves an enabled TrustedInstaller SID plus System integrity for the target process' -Pending {}

    It 'preserves exact target exits 0, 5, 259, 0x80000005, and 0xFFFFFFFF through Result and the caller outcome' -Pending {}

    It 'maps accepted and denied split-token UAC consent without treating denial as target completion' -Pending {}

    It 'binds the exact elevated broker process when over-the-shoulder UAC credentials change the security principal' -Pending {}

    It 'distinguishes service, token, protocol, timeout, and cancellation failures from Completed' -Pending {}

    It 'rejects mismatched Request, Ready, and Result bindings, malformed frames, trailing bytes, and premature pipe EOF' -Pending {}

    It 'atomically assigns the broker and TrustedInstaller target to the required outer and inner job hierarchy before resume' -Pending {}

    It 'withholds external Result until the broker exits and both jobs drain with no broker, target, or descendant alive' -Pending {}

    It 'requires the inbound monitor to reach Stopped before exposing Result, then closes the pipe and exits the exact target code without retry' -Pending {}

    It 'kills the suspended broker through the bootstrap-only owner guard when the bootstrap dies before ResumeThread' -Pending {}

    It 'cancels from caller process death before Ready and leaves no privileged survivor' -Pending {}

    It 'cancels from caller process death during internal post-target teardown before Result exposure and leaves no privileged survivor' -Pending {}

    It 'does not accept completion when the caller dies during terminal Result delivery' -Pending {}

    It 'cancels from pipe-only abandonment before Ready while the caller process remains alive' -Pending {}

    It 'cancels from pipe-only abandonment during internal post-target teardown before Result exposure while the caller remains alive' -Pending {}

    It 'does not accept completion after pipe-only abandonment during terminal Result delivery while the caller remains alive' -Pending {}

    It 'contains the complete privileged tree when cross-integrity TerminateProcess access to the elevated broker is unavailable' -Pending {}

    It 'enforces bounded Ready, Result, terminal EOF, broker-exit, and job-drain deadlines without detached I/O' -Pending {}
}
