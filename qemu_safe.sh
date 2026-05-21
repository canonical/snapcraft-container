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
