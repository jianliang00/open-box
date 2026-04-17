#!/bin/zsh
set -euo pipefail

resolve_container_package_dir() {
  if [[ -n "${OPENBOX_CONTAINER_PACKAGE_DIR:-}" ]]; then
    echo "${OPENBOX_CONTAINER_PACKAGE_DIR}"
    return 0
  fi

  local -a candidates=()
  local derived_data_dir

  if [[ -n "${TARGET_BUILD_DIR:-}" && -d "${TARGET_BUILD_DIR}/../../.." ]]; then
    derived_data_dir="$(cd "${TARGET_BUILD_DIR}/../../.." && pwd)"
    candidates+=("${derived_data_dir}/SourcePackages/checkouts/container")
  fi

  if [[ -n "${PROJECT_TEMP_ROOT:-}" && -d "${PROJECT_TEMP_ROOT}/../.." ]]; then
    derived_data_dir="$(cd "${PROJECT_TEMP_ROOT}/../.." && pwd)"
    candidates+=("${derived_data_dir}/SourcePackages/checkouts/container")
  fi

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "${candidate}/Package.swift" ]]; then
      echo "${candidate}"
      return 0
    fi
  done

  return 1
}

if ! container_package_dir="$(resolve_container_package_dir)"; then
  echo "error: container Swift package checkout was not found." >&2
  echo "error: resolve Xcode packages first, or set OPENBOX_CONTAINER_PACKAGE_DIR=/path/to/container for local SDK development." >&2
  exit 1
fi

if [[ ! -f "${container_package_dir}/Package.swift" ]]; then
  echo "error: container package not found at ${container_package_dir}" >&2
  exit 1
fi

swift_configuration="$(echo "${CONFIGURATION:-Debug}" | tr '[:upper:]' '[:lower:]')"
case "${swift_configuration}" in
  debug|release) ;;
  *) swift_configuration="debug" ;;
esac

embed_root="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/container"
bin_dir="${embed_root}/bin"
libexec_dir="${embed_root}/libexec/container"
scratch_path="${TARGET_TEMP_DIR}/ContainerRuntimeBuild"

clean_swift_env=(env -i "HOME=${HOME}" "PATH=${PATH}" "TMPDIR=${TMPDIR:-/tmp}")
if [[ -n "${DEVELOPER_DIR:-}" ]]; then
  clean_swift_env+=("DEVELOPER_DIR=${DEVELOPER_DIR}")
fi

swiftpm() {
  "${clean_swift_env[@]}" /usr/bin/xcrun swift "$@"
}

products=(
  container-apiserver
  container-runtime-linux
  container-runtime-macos
  container-runtime-macos-sidecar
  container-network-vmnet
  container-core-images
  container-macos-guest-agent
  container-macos-image-prepare
  container-macos-vm-manager
)

echo "Embedding container runtime from ${container_package_dir}"
for product in "${products[@]}"; do
  swiftpm build \
    --package-path "${container_package_dir}" \
    --scratch-path "${scratch_path}" \
    --configuration "${swift_configuration}" \
    --product "${product}"
done

build_bin_dir="$(
  swiftpm build \
    --package-path "${container_package_dir}" \
    --scratch-path "${scratch_path}" \
    --configuration "${swift_configuration}" \
    --show-bin-path
)"

rm -rf "${embed_root}"
install -d "${bin_dir}"
install -d "${libexec_dir}/plugins/container-runtime-linux/bin"
install -d "${libexec_dir}/plugins/container-runtime-macos/bin"
install -d "${libexec_dir}/plugins/container-network-vmnet/bin"
install -d "${libexec_dir}/plugins/container-core-images/bin"
install -d "${libexec_dir}/macos-guest-agent/bin"
install -d "${libexec_dir}/macos-guest-agent/share"
install -d "${libexec_dir}/macos-image-prepare/bin"
install -d "${libexec_dir}/macos-vm-manager/bin"

install -m 0755 "${build_bin_dir}/container-apiserver" "${bin_dir}/container-apiserver"
install -m 0755 "${build_bin_dir}/container-runtime-linux" "${libexec_dir}/plugins/container-runtime-linux/bin/container-runtime-linux"
install -m 0755 "${build_bin_dir}/container-runtime-macos" "${libexec_dir}/plugins/container-runtime-macos/bin/container-runtime-macos"
install -m 0755 "${build_bin_dir}/container-runtime-macos-sidecar" "${libexec_dir}/plugins/container-runtime-macos/bin/container-runtime-macos-sidecar"
install -m 0755 "${build_bin_dir}/container-network-vmnet" "${libexec_dir}/plugins/container-network-vmnet/bin/container-network-vmnet"
install -m 0755 "${build_bin_dir}/container-core-images" "${libexec_dir}/plugins/container-core-images/bin/container-core-images"
install -m 0755 "${build_bin_dir}/container-macos-guest-agent" "${libexec_dir}/macos-guest-agent/bin/container-macos-guest-agent"
install -m 0755 "${build_bin_dir}/container-macos-image-prepare" "${libexec_dir}/macos-image-prepare/bin/container-macos-image-prepare"
install -m 0755 "${build_bin_dir}/container-macos-vm-manager" "${libexec_dir}/macos-vm-manager/bin/container-macos-vm-manager"

install -m 0644 "${container_package_dir}/config/container-runtime-linux-config.json" "${libexec_dir}/plugins/container-runtime-linux/config.json"
install -m 0644 "${container_package_dir}/config/container-runtime-macos-config.json" "${libexec_dir}/plugins/container-runtime-macos/config.json"
install -m 0644 "${container_package_dir}/config/container-network-vmnet-config.json" "${libexec_dir}/plugins/container-network-vmnet/config.json"
install -m 0644 "${container_package_dir}/config/container-core-images-config.json" "${libexec_dir}/plugins/container-core-images/config.json"

install -m 0755 "${container_package_dir}/scripts/macos-guest-agent/install.sh" "${libexec_dir}/macos-guest-agent/share/install.sh"
install -m 0755 "${container_package_dir}/scripts/macos-guest-agent/install-in-guest-from-seed.sh" "${libexec_dir}/macos-guest-agent/share/install-in-guest-from-seed.sh"
install -m 0644 "${container_package_dir}/scripts/macos-guest-agent/container-macos-guest-agent.plist" "${libexec_dir}/macos-guest-agent/share/container-macos-guest-agent.plist"

if [[ "${CODE_SIGNING_ALLOWED:-YES}" != "NO" ]]; then
  sign_identity="${EXPANDED_CODE_SIGN_IDENTITY:-}"
  if [[ -z "${sign_identity}" || "${sign_identity}" == "-" ]]; then
    sign_identity="-"
  fi

  sign_binary() {
    local binary="$1"
    local entitlements="${2:-}"
    local timestamp_args=(--timestamp=none)
    if [[ "${CONFIGURATION:-Debug}" == "Release" && "${sign_identity}" != "-" ]]; then
      timestamp_args=(--timestamp)
    fi

    local args=(--force --sign "${sign_identity}" "${timestamp_args[@]}" --options runtime)
    if [[ -n "${entitlements}" ]]; then
      args+=(--entitlements "${entitlements}")
    fi
    args+=("${binary}")
    /usr/bin/codesign "${args[@]}"
  }

  runtime_entitlements="${container_package_dir}/signing/container-runtime-macos.entitlements"
  linux_entitlements="${container_package_dir}/signing/container-runtime-linux.entitlements"
  network_entitlements="${container_package_dir}/signing/container-network-vmnet.entitlements"

  sign_binary "${bin_dir}/container-apiserver"
  sign_binary "${libexec_dir}/plugins/container-core-images/bin/container-core-images"
  sign_binary "${libexec_dir}/plugins/container-runtime-linux/bin/container-runtime-linux" "${linux_entitlements}"
  sign_binary "${libexec_dir}/plugins/container-runtime-macos/bin/container-runtime-macos" "${runtime_entitlements}"
  sign_binary "${libexec_dir}/plugins/container-runtime-macos/bin/container-runtime-macos-sidecar" "${runtime_entitlements}"
  sign_binary "${libexec_dir}/plugins/container-network-vmnet/bin/container-network-vmnet" "${network_entitlements}"
  sign_binary "${libexec_dir}/macos-guest-agent/bin/container-macos-guest-agent"
  sign_binary "${libexec_dir}/macos-image-prepare/bin/container-macos-image-prepare" "${runtime_entitlements}"
  sign_binary "${libexec_dir}/macos-vm-manager/bin/container-macos-vm-manager" "${runtime_entitlements}"
fi

echo "Embedded container runtime at ${embed_root}"
