## Summary

<!-- 1–3 sentences: what changes, and why. -->

## Related issue

<!-- e.g. "Fixes #12" / "Refs #45" / "N/A" -->

## Affected packages

- [ ] `showfase` (runtime)
- [ ] `showfase_generator` (build_runner)
- [ ] `showfase_annotation`
- [ ] `showfase_test` (golden testing)
- [ ] `packages/showfase/example`
- [ ] repo tooling / docs (melos, workspace, `.github/`, README)

## Screenshots or clips

<!-- Required when the PR changes rendered widgets. Delete this
section otherwise. Before → after, or a short screen recording. -->

## Breaking change

- [ ] Yes — this PR changes public API in a source-incompatible way.
- [ ] No.

<!-- If Yes, add a short migration note here. -->

## How was this tested?

<!-- Required. CI runs format/analyze/tests/codegen checks, but
platform-specific behavior still needs local verification. Describe
what you actually ran:

- Commands executed beyond CI (e.g. `flutter run` on a device,
  `dart run build_runner build`).
- Platforms tried for UI changes (Chrome, macOS, iOS Simulator, …).
- Anything skipped and why.

PRs that leave this section empty may be closed. -->

## Checklist

- [ ] PR title follows [Conventional Commits](https://www.conventionalcommits.org/).
- [ ] `dart format .` has been run.
- [ ] `dart analyze` (or `melos run analyze`) passes locally.
- [ ] `dart test` / `flutter test` passes locally in every affected package.
- [ ] Public API additions/changes carry `///` doc comments.
- [ ] Generator changes: I re-ran `dart run build_runner build` in
      `packages/showfase/example` and committed the updated
      `showfase.g.dart` alongside the source change.
- [ ] `CHANGELOG.md` in every affected package updated under an
      `## Unreleased` heading.
