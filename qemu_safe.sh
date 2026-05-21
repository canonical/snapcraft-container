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

# force QEMU_CPU=max on riscv on ubuntu 26.04+ else nothing works
if [ "$(uname -m)" = "riscv64" ] && [ -f /etc/os-release ]; then
    . /etc/os-release

    MAJOR_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)

    if [ "${MAJOR_VERSION:-0}" -ge 26 ] 2>/dev/null; then
        # Required RISCV extensions by resolute+ riscv64 buildchain. Failing to
        # define these will make many binaries SIGV/SIGKILL due to missing
        # instructions in the "base" qemu riscv emulation
        gcc -shared -fPIC /force_qemu_cpu_max.c -o /usr/local/lib/force_qemu_cpu_max.so
        echo "/usr/local/lib/force_qemu_cpu_max.so" >> /etc/ld.so.preload
    fi
fi
