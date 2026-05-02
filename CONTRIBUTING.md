# Contributing to DankTranslate

## Development setup

Prerequisites: [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) >= 1.4.0, [translate-shell](https://github.com/soimort/translate-shell)

```bash
git clone https://github.com/alcxyz/DankTranslate.git
cd DankTranslate
```

For development, symlink the plugin into the DMS plugins directory:

```bash
ln -s "$(pwd)" ~/.config/DankMaterialShell/plugins/DankTranslate
```

Reload after changes:

```bash
dms ipc call plugins reload dankTranslate
```

## Project structure

- `plugin.json` -- plugin manifest (id, type, trigger, permissions)
- `DankTranslate.qml` -- main launcher component (getItems, executeItem, async translation)
- `DankTranslateSettings.qml` -- settings UI

## Making changes

1. Fork the repo and create a branch from `dev`
2. Make your changes
3. Test by reloading the plugin in DMS
4. Open a pull request against `dev`

## Commit messages

Use conventional-ish prefixes to keep history scannable:

- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation only
- `chore:` maintenance, CI, dependencies
- `refactor:` code changes that don't add features or fix bugs

## Releasing

Releases are automated via GitHub Actions. The `version` field in `plugin.json` is the source of truth for release tags.

Normal development and contributor PRs target `dev` and do not require a version bump. The `main` branch is protected and is used for releases.

To cut a release:

1. Make sure `dev` contains the changes to release.
2. Create a release branch from `dev`, for example `release/v0.2.3`.
3. Bump the `version` field in `plugin.json` on the release branch unless the release is documentation-only.
4. Open a pull request from the release branch to `main`.
5. Merge after review and checks pass. CI creates the git tag and GitHub release from `plugin.json.version`.
6. Sync `main` back into `dev` after the release so both branches agree on released metadata.

### Version numbering

Follow [semver](https://semver.org/):

- **Patch** (`v0.1.x`): bug fixes, minor tweaks
- **Minor** (`v0.x.0`): new features, non-breaking changes
- **Major** (`vx.0.0`): breaking changes

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
