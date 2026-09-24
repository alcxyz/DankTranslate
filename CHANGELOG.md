# Changelog

All notable changes to this plugin are documented here. The format follows
Keep a Changelog, and the release workflow publishes each version's section
as its GitHub release notes.

## [Unreleased]

## [0.1.4] - 2026-09-20

- Added a packaged build-identity workflow: development installs (Nix or the `scripts/package.py` helper) now stamp their `plugin.json` with a `X.Y.Z-dev.<commit>` version (with a `.dirty` suffix for uncommitted changes) instead of silently reusing the release version. Release packages still require a clean checkout at the exact `vX.Y.Z` tag, and the README documents how to stage an identifiable dev build with `python3 scripts/package.py --output dist/dev`.

## [0.1.3] - 2026-05-09

- Fixed translation failures not being reported clearly: the plugin now distinguishes between `translate-shell` (`trans`) not being installed, the command producing no output, and other command failures, and shows a specific error message for each case instead of a generic failure.
- Added a 15-second timeout so a hung or unresponsive `trans` process no longer leaves the launcher stuck showing "Translating..." forever.
- Updated the README screenshot.
- Simplified versioning by dropping the separate `VERSION` file; the plugin version is now read from `plugin.json` everywhere (CI, Nix packaging, and the test script), removing a value that was easy to forget to bump.
- Added an automated test suite (`test.sh`) covering manifest validation, plugin ID consistency, language-code detection, command construction, multi-line result parsing, and clipboard safety, now run in CI.
- Fixed a Nix installation instruction in the README (released as the intermediate v0.1.2 build, folded into this release).

## [0.1.1] - 2026-04-22

- Fixed translations appearing to spin forever: the plugin now tells the DMS launcher to refresh results via `requestLauncherUpdate` once a translation completes, instead of relying on a signal the launcher never listened for.
- Fixed language-prefixed queries (e.g. `ru hi`) being silently dropped from results: plugin items are now marked `_preScored` so DMS's launcher scorer no longer filters them out for lacking a literal text match against the query.
- Hardened translation handling by stopping any stale `trans` process before starting a new one and by surfacing translation errors in the launcher instead of failing silently.

## [0.1.0] - 2026-04-22

- Initial release: a DankMaterialShell launcher plugin that translates text using `translate-shell` (`trans`), activated with the `>` trigger by default.
- Supports a configurable default target language plus an optional per-query language-code prefix (e.g. `pt hello`) to override it for a single translation.
- Copies the translated result to the clipboard via `wl-copy` and includes a settings panel for configuring the default language.
