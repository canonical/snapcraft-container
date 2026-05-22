#!/bin/bash
set -eo pipefail

# collection of workaround to avoid qemu blowing up with a sigv on some
# architectures. All toggled with QEMU_SAFE envvar

# mksquashfs seldomly fails on armhf with a sigv, this is a wrapper that
# disables parallelism
SOURCE_WRAPPER="/mksquashfs"

[ -f "$SOURCE_WRAPPER" ] || exit 1

find /snap -type f -name "mksquashfs" | while read -r target_path; do
    target_dir=$(dirname "$target_path")
    mv "$target_path" "$target_dir/_mksquashfs"
    cp "$SOURCE_WRAPPER" "$target_path"
    chmod +x "$target_path"
done

if [ "$(uname -m)" = "riscv64" ] && [ -f /etc/os-release ]; then
    . /etc/os-release

    MAJOR_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)

    if [ "${MAJOR_VERSION:-0}" -ge 26 ] 2>/dev/null; then
        find /snap -type f -name "site-packages" | while read -r target_path; do
            cp /sitecustomize.py $target_path/sitecustomize.py
        done
    fi
fi
