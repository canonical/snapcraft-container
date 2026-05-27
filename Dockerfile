# From: https://github.com/canonical/snapcraft/issues/5079#issuecomment-2414199613
ARG BASE_OS=xenial
ARG SNAPCRAFT_CHANNEL=7.x/stable

# Prepare the filesystem to copy into a blank image
FROM ubuntu:${BASE_OS} AS builder
ENV DEBIAN_FRONTEND=noninteractive
ARG TARGETARCH
ARG SNAPCRAFT_CHANNEL

RUN if [ "$TARGETARCH" = "arm" ]; then \
        echo "armhf" > /tmp/arch; \
    else \
        echo "$TARGETARCH" > /tmp/arch; \
    fi

# Grab dependencies
RUN apt-get update
RUN apt-get dist-upgrade --yes
RUN apt-get install --yes \
      curl \
      jq \
      squashfs-tools

COPY download-snap.sh /usr/local/bin/
# these don't exist on risc64, create the dir to make COPY pass below
RUN if [ "$TARGETARCH" = "riscv64" ]; then \
        mkdir -p /snap/core /snap/core18 /snap/core20; \
    else \
        download-snap.sh core && \
        download-snap.sh core18 && \
        download-snap.sh core20; \
    fi
RUN download-snap.sh core22
RUN download-snap.sh core24
RUN download-snap.sh core26
RUN download-snap.sh snapcraft $SNAPCRAFT_CHANNEL

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
COPY snapcraft /snap/bin/snapcraft


FROM ubuntu:${BASE_OS}
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=builder /snap/core /snap/core
COPY --from=builder /snap/core18 /snap/core18
COPY --from=builder /snap/core20 /snap/core20
COPY --from=builder /snap/core22 /snap/core22
COPY --from=builder /snap/core24 /snap/core24
COPY --from=builder /snap/core26 /snap/core26
COPY --from=builder /snap/snapcraft /snap/snapcraft
COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

# this allows old snapcraft (4.x 5.x) to work because it uses pip to install
# stuff and in this hack-ish environment it assumes it is doing so in /usr/local/bin
# but it is actually writing in the snap local one
RUN case "${SNAPCRAFT_CHANNEL}" in \
      4.*|5.*) rm -rf /usr/local/bin && ln -s /snap/snapcraft/current/usr/local/bin /usr/local/bin ;; \
    esac

# Generate locale and install dependencies.
RUN apt-get update \
  && apt-get dist-upgrade --yes \
  && apt-get install --yes snapd sudo locales git binutils build-essential \
  && locale-gen en_US.UTF-8

RUN mkdir -p /tmp/craft-state
RUN mkdir -p /tmp/snapcraft-state

COPY qemu_safe.sh /qemu_safe.sh
COPY mksquashfs /mksquashfs
RUN ./qemu_safe.sh

# Set the proper environment.
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV PATH="/snap/snapcraft/current/libexec/snapcraft/:/snap/bin:/snap/snapcraft/current/bin:$PATH:/snap/snapcraft/current/usr/bin:/snap/snapcraft/current/usr/local/bin"
ENV SNAPCRAFT_BUILD_ENVIRONMENT=host
ENV CRAFT_BUILD_ENVIRONMENT=host
ENV SNAPCRAFT_MANAGED_MODE=y
ENV CRAFT_MANAGED_MODE=1
ENV SNAPCRAFT_VERBOSITY_LEVEL=verbose
ENV CRAFT_VERBOSITY_LEVEL=verbose
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"

CMD ["/snap/bin/snapcraft"]
