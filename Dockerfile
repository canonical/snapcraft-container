# From: https://github.com/canonical/snapcraft/issues/5079#issuecomment-2414199613
ARG BASE_OS=xenial
ARG SNAPCRAFT_CHANNEL=7.x/stable

# Prepare the filesystem to copy into a blank image
FROM ubuntu:${BASE_OS} AS builder
ENV DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH
ARG SNAPCRAFT_CHANNEL
RUN echo "$TARGETARCH" > /tmp/arch
ENV ARCH_FILE=/tmp/arch

# Grab dependencies
RUN apt-get update
RUN apt-get dist-upgrade --yes
RUN apt-get install --yes \
      curl \
      jq \
      squashfs-tools

# download and extract core22 (required for snapcraft to run)

RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' -H "X-Ubuntu-Architecture: $(cat /tmp/arch)" \
    'https://api.snapcraft.io/api/v1/snaps/details/core22' | jq '.download_url' -r) --output core22.snap
RUN mkdir -p /snap/core22
# err 2 is mostly failing to create bougus dev files in /snap/core22/current
RUN unsquashfs -no-xattrs -d /snap/core22/current core22.snap || [ $? -eq 2 ]

# download and extract snapcraft
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' -H "X-Ubuntu-Architecture: $(cat /tmp/arch)" \
    "https://api.snapcraft.io/api/v1/snaps/details/snapcraft?channel=${SNAPCRAFT_CHANNEL}" | jq '.download_url' -r) --output snapcraft.snap
RUN mkdir -p /snap/snapcraft
RUN unsquashfs -d /snap/snapcraft/current snapcraft.snap

# Fix Python3 installation: Make sure we use the interpreter from
# the snapcraft snap:
RUN unlink /snap/snapcraft/current/usr/bin/python3 || true
RUN unlink /snap/snapcraft/current/bin/python3 || true
RUN PYTHON3=$(find /snap/snapcraft/current/ -name 'python3.*' -type f | head -1) \
    && ln -s "$PYTHON3" /snap/snapcraft/current/usr/bin/python3
RUN PYTHON3=$(find /snap/snapcraft/current/ -name 'python3.*' -type f | head -1) \
    && ln -s "$PYTHON3" /snap/snapcraft/current/bin/python3
RUN PYVER=$(find /snap/snapcraft/current/lib/ -name 'python3.*' -type d | head -1) \
    && echo "$PYVER/site-packages" >> /snap/snapcraft/current/usr/lib/python3/dist-packages/site-packages.pth

# Create a snapcraft runner
RUN mkdir -p /snap/bin
RUN echo "#!/bin/sh" > /snap/bin/snapcraft
RUN snap_version="$(awk '/^version:/{print $2}' /snap/snapcraft/current/meta/snap.yaml | tr -d \')" && echo "export SNAP_VERSION=\"$snap_version\"" >> /snap/bin/snapcraft
RUN echo 'exec "/snap/snapcraft/current/bin/python3" -m snapcraft "$@"' >> /snap/bin/snapcraft
RUN chmod +x /snap/bin/snapcraft

# download and extract core24
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' -H "X-Ubuntu-Architecture: $(cat /tmp/arch)" \
    'https://api.snapcraft.io/api/v1/snaps/details/core24' | jq '.download_url' -r) --output core24.snap
RUN mkdir -p /snap/core24
RUN unsquashfs -d /snap/core24/current core24.snap || [ $? -eq 2 ]

FROM ubuntu:${BASE_OS}
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=builder /snap/core22 /snap/core22
COPY --from=builder /snap/core24 /snap/core24
COPY --from=builder /snap/snapcraft /snap/snapcraft
COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

# Generate locale and install dependencies.
RUN apt-get update && apt-get dist-upgrade --yes && apt-get install --yes snapd sudo locales git binutils && locale-gen en_US.UTF-8
RUN mkdir /snap/snapcraft/current/usr/share/snapcraft/keyrings \
    /snap/snapcraft/current/usr/share/snapcraft/extensions \
    /snap/snapcraft/current/usr/share/snapcraft/plugins \
    /snap/snapcraft/current/usr/share/snapcraft/schema -p
# Set the proper environment.
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV PATH="/snap/snapcraft/current/libexec/snapcraft/:/snap/bin:$PATH"
ENV SNAPCRAFT_BUILD_ENVIRONMENT=host
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"

CMD ["/snap/bin/snapcraft"]
