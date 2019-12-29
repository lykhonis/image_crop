## Prepare for Release

Version format is `v{major}.{minor}.{patch}`. e.g. `v0.1.1`.

1. Do `flutter analyze`. Ensure no issues found!
2. Do `flutter format lib/`. Format all dart code.
3. Update `pubsec.yaml` with new version.
4. Update `CHANGELOG.md` with new version and add details describing what's new and/or changed.
5. Do `flutter packages pub publish --dry-run`. Check to ensure there are no warnings!
6. Do `git commit -am "{version}"`.
7. Do `git tag {version}`.
8. Do `flutter packages pub publish` to publish new version.
9. Push changes `git push && git push --tags`
