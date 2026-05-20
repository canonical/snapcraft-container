#!/bin/bash
# Download and unsquash a snap from the Snap Store.
# Usage: download-snap.sh <snap-name> [channel]

set -euo pipefail

SNAP_NAME="${1:?Usage: download-snap.sh <snap-name> [channel]}"
CHANNEL="${2:-stable}"
ARCH="$(cat /tmp/arch)"

API_URL="https://api.snapcraft.io/api/v1/snaps/details/${SNAP_NAME}?channel=${CHANNEL}"

DOWNLOAD_URL=$(curl -s -H 'X-Ubuntu-Series: 16' -H "X-Ubuntu-Architecture: ${ARCH}" \
    "$API_URL" | jq '.download_url' -r)

echo "Downloading ${SNAP_NAME} (channel: ${CHANNEL}, arch: ${ARCH})..."
curl -L "$DOWNLOAD_URL" --output "${SNAP_NAME}.snap"

mkdir -p "/snap/${SNAP_NAME}"
# Exit code 2 from unsquashfs is typically from failing to create device files, which is harmless
unsquashfs -d "/snap/${SNAP_NAME}/current" "${SNAP_NAME}.snap" || [ $? -eq 2 ]

rm -f "${SNAP_NAME}.snap"

echo "Installed ${SNAP_NAME} to /snap/${SNAP_NAME}/current"
