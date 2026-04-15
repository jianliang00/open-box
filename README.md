# OpenBox

OpenBox is a macOS SwiftUI app for managing OCI-backed sandboxes through the
container SDK. It provides a desktop interface for tracking images, creating
sandboxes, running workloads, and opening interactive terminals.

## Features

- Manage local OCI image references and downloaded images.
- Pull public images anonymously or pull private images with per-pull registry credentials.
- Create macOS or Linux sandboxes from downloaded images.
- Start, stop, and remove sandboxes.
- Launch desktop GUI sessions for supported macOS guest sandboxes.
- Run one-off commands or interactive shell workloads.
- View sandbox metadata, networks, workload status, and diagnostic log paths.

## Requirements

- macOS 15.5 or later.
- Xcode 16.4 or later.
- Swift package resolution enabled in Xcode.
- The pinned `container` Swift package checkout available through Xcode DerivedData.

The app embeds its container runtime during the Xcode build using
`Scripts/embed-container-runtime.sh`. For local SDK development, set
`OPENBOX_CONTAINER_PACKAGE_DIR=/path/to/container` before building to use a
specific checkout.

## Getting Started

1. Clone the repository.

   ```sh
   git clone git@github.com:jianliang00/open-box.git
   cd open-box
   ```

2. Open the project in Xcode.

   ```sh
   open OpenBox.xcodeproj
   ```

3. Resolve Swift package dependencies in Xcode.

4. Select the `OpenBox` scheme and run the app.

## Project Structure

- `OpenBox/` contains the SwiftUI app, state model, container SDK service, and embedded terminal view.
- `OpenBoxTests/` contains unit tests.
- `OpenBoxUITests/` contains UI tests.
- `Scripts/embed-container-runtime.sh` builds and embeds the container runtime products into the app bundle.

## Dependencies

- [`container`](https://github.com/jianliang00/container)
- [`SwiftTerm`](https://github.com/migueldeicaza/SwiftTerm)

Dependency versions and revisions are pinned in
`OpenBox.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`.

## License

OpenBox is licensed under the Apache License 2.0. See [LICENSE](LICENSE).
