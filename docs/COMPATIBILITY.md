# Compatibility

Last checked: 2026-04-18.

OpenBox's practical compatibility follows Apple's container runtime stack and
the embedded services it uses.

## Current Matrix

| Area | Supported or expected |
| --- | --- |
| Hardware | Apple Silicon Mac |
| Runtime OS | macOS 26 or later |
| Source build | Xcode 26 or later |
| Release build | Built by GitHub Actions on `macos-26` |
| App signing | Release DMGs are signed and notarized by the release workflow |
| Linux sandboxes | OCI images through `container-runtime-linux` |
| macOS guest sandboxes | Images that resolve to `container-runtime-macos` |
| macOS guest desktop GUI | Supported when enabled at sandbox creation time |
| Linux desktop GUI | Future area |
| Interactive terminal | Currently focused on supported macOS guest sandboxes |
| Intel Macs | Apple Silicon is the current target |

## macOS 15.5 Deployment Target Note

The Xcode project currently sets `MACOSX_DEPLOYMENT_TARGET=15.5`. That setting
describes the app target's minimum deployment value. The embedded container
services have a higher practical support floor.

Apple's upstream projects currently document stricter requirements:

- [`apple/container`](https://github.com/apple/container) says `container` is
  supported on macOS 26 and requires Apple Silicon.
- [`apple/containerization`](https://github.com/apple/containerization) says the
  package requires Apple Silicon, macOS 26, and Xcode 26.

Current release validation treats macOS 26 on Apple Silicon as the supported
runtime target.

## Dependency Fork Policy

OpenBox currently pins
[`jianliang00/container`](https://github.com/jianliang00/container), a fork of
[`apple/container`](https://github.com/apple/container), at a fixed revision.
This keeps OpenBox builds reproducible while the app depends on runtime
embedding and launch behavior that is still being stabilized.

The lower-level `Containerization` package comes from Apple's official
[`apple/containerization`](https://github.com/apple/containerization) project
through the pinned container dependency graph.

## Release Validation

The release workflow:

1. Resolves Swift package dependencies.
2. Builds `OpenBox.app` in Release configuration.
3. Embeds the required container runtime products into the app bundle.
4. Packages the app as `OpenBox-<tag>.dmg`.
5. Signs and notarizes the DMG.
6. Uploads the DMG to GitHub Releases.

The workflow is defined in
[`../.github/workflows/release.yml`](../.github/workflows/release.yml).
