#!/bin/bash
# Download and unsquash a snap from the Snap Store.
# Usage: download-snap.sh <snap-name> [channel]

set -euo pipefail

SNAP_NAME="${1:?Usage: download-snap.sh <snap-name> [channel]}"
CHANNEL="${2:-stable}"
ARCH="$(cat /tmp/arch)"

API_URL="https://api.snapcraft.io/api/v1/snaps/details/${SNAP_NAME}?channel=${CHANNEL}"

DOWNLOAD_URL=$(curl --retry 5 -s -H 'X-Ubuntu-Series: 16' -H "X-Ubuntu-Architecture: ${ARCH}" \
    "$API_URL" | jq '.download_url' -r)

echo "Downloading ${SNAP_NAME} (channel: ${CHANNEL}, arch: ${ARCH})..."
curl --retry 5 -L "$DOWNLOAD_URL" --output /tmp/"${SNAP_NAME}.snap"

mkdir -p "/snap/${SNAP_NAME}"
# proc fails to extract but we don't need it so its fine

unsquashfs -l /tmp/"${SNAP_NAME}.snap" | \
  grep -v '^squashfs-root/proc' | \
  sed 's/^squashfs-root\///' | \
  grep -v '^squashfs-root$' > /tmp/${SNAP_NAME}keep_list.txt
unsquashfs -d "/snap/${SNAP_NAME}/current" -ef /tmp/${SNAP_NAME}keep_list.txt  /tmp/"${SNAP_NAME}.snap"

rm -f "/tmp/${SNAP_NAME}.snap"

echo "Installed ${SNAP_NAME} to /snap/${SNAP_NAME}/current"
