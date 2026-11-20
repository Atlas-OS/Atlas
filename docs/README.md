# Atlas documentation

This index lists the documentation kept in this repository, grouped by who it's for.
User guides live on the [Atlas documentation site](https://atlasos.net/docs/), and Atlas Manager has its own documentation in [the Atlas Manager README](../app/README.md).

## Using Atlas

- [Updating Atlas](upgrading.md): how Atlas Manager updates an installed Atlas and what the update keeps.
- [Moving Windows to a newer release](windows-transition.md): how Atlas Manager moves Windows to a newer release before it installs or updates Atlas.
- [Reporting problems](diagnostics.md): how to send a report or export diagnostics, and what the export contains.
- [Windows release policy](windows-release-policy.md): which Windows releases Atlas installs on, and how it checks them.

## How Atlas works

- [Architecture](architecture.md): how the Atlas package, its scripts and Atlas Manager fit together.
- [The front door](front-door.md): how Atlas Manager starts an install through `Install-Atlas.ps1`, and the install modes.
- [Install state](install-state.md): what Atlas records about an install and how an interrupted install resumes.
- [Preparation](preparation.md): how Atlas Manager brings Windows and Microsoft Store apps up to date before Atlas changes anything.
- [Files kept for compatibility](compatibility.md): files Atlas keeps only because older installs or other programs address them by path.
- [Power-saving policy](power-saving-policy.md): what the **Turn off power saving** choice changes and what it leaves alone.
- [Service and driver startup policy](services-startup-policy.md): why Atlas leaves service startup values at Windows defaults, and the exceptions.
- [Console presentation](console-presentation.md): how Atlas launchers and helpers word and format what they print.

## Contributing

- [Writing style](style.md): the house style for documentation, comments and commit messages.
- [Building](building.md): how to build and verify the Atlas package and cross-build Atlas Manager.
- [Testing](testing.md): the automated checks, the lab VM run and the checks to repeat for a release.
- [AtlasDesktop toggles](catalog/toggles.md): the generated reference of every toggle and its launchers.
- [Install tweaks](catalog/tweaks.md): the generated reference of every tweak the install runs.

## Releasing

- [Releasing Atlas](releasing.md): the steps from a version bump to a published release.
- [Publication contents](publication.md): what belongs in Git, what stays local, and what to review before a release.
- [Release verification matrix](release-verification-matrix.md): the evidence every release needs before it's published.
