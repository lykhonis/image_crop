## Prepare for Release

Version format is `v{major}.{minor}.{patch}`. e.g. `v0.1.1`.

1. Do `flutter analyze`. Ensure no issues found!
2. Update `pubsec.yaml` with new version.
3. Update `CHANGELOG.md` with new version and add details describing what's new and/or changed.
4. Do `git commit -am "{version}"`.
5. Do `git tag {version}`.
6. Do `flutter packages pub publish --dry-run`. Check to ensure there are no warnings!
7. Do `flutter packages pub publish` to publish new version.
8. Push changes `git push && git push --tags`
