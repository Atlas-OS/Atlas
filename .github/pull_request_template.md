## Summary

<!-- What does this pull request change, and why? -->

## Related issue

<!-- For example: Fixes #123. Write "None" if there isn't one. -->

## How you tested

- [ ] Windows PowerShell tests, in Windows PowerShell 5.1
- [ ] Build tests, in PowerShell 7
- [ ] Atlas Manager tests (`cargo test --locked` in `app/`)
- [ ] Built the Atlas package and verified it with `tools/build/Test-Apbx.ps1`
- [ ] Installed Atlas on a VM (needed for changes to what Atlas does to a PC)

<!-- Add anything else you checked, such as the steps you followed on the VM. -->

## Checklist

- [ ] After changing tweak or toggle definitions, I ran the generators, then ran them with `-Validate`
- [ ] I updated the documentation for any behaviour I changed
- [ ] Scripts under `playbook/` use Windows PowerShell 5.1 syntax
- [ ] My changes follow the [writing style guide](https://github.com/Atlas-OS/Atlas/blob/main/docs/style.md)

See [Contributing](https://atlasos.net/docs/contributing/) in the Atlas documentation and the [contributing guide](https://github.com/Atlas-OS/Atlas/blob/main/.github/CONTRIBUTING.md) for details.
