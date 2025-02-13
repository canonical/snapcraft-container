ARG BASE_OS=xenial

# Prepare the filesystem to copy into a blank image
FROM ubuntu:${BASE_OS} AS base

ENV DEBIAN_FRONTEND=noninteractive

# Run apt-get commands together to always ensure apt-get update is run
# before using apt-get install to avoid issues with stale apt caches.
RUN apt-get update -qq && \
	apt-get dist-upgrade --yes && \
	apt-get install --yes -qq --no-install-recommends \
		build-essential \
		fuse \
		gnupg \
		python3 \
		snapd \
		sudo \
		systemd

# Clean apt lists because we'll be copying the entire filesystem to a blank image
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists

# Ensure snapd's system-key file exists
RUN touch /var/lib/snapd/system-key

# stop udevadm from working
RUN dpkg-divert --local --rename --add /sbin/udevadm
RUN ln -s /bin/true /sbin/udevadm

# remove systemd 'wants' triggers
RUN rm -f \
		/etc/systemd/system/*.wants/* \
		/lib/systemd/system/local-fs.target.wants/* \
		/lib/systemd/system/multi-user.target.wants/* \
		/lib/systemd/system/sockets.target.wants/*initctl*

# remove everything except tmpfiles setup in sysinit target
RUN find \
		/lib/systemd/system/sysinit.target.wants \
		\( -type f -or -type l \) -and -not -name '*systemd-tmpfiles-setup*' \
		-delete

# remove UTMP updater service
RUN rm -f /lib/systemd/system/systemd-update-utmp-runlevel.service

# disable /tmp mount
RUN rm -vf /usr/share/systemd/tmp.mount

# disable most systemd console output
RUN echo ShowStatus=no >> /etc/systemd/system.conf

# disable ondemand.service
RUN systemctl disable ondemand.service || true

# set basic.target as default
RUN systemctl set-default basic.target

# enable the services we care about
RUN systemctl enable snapd.service
RUN systemctl enable snapd.socket


# The actual snapcraft image
FROM scratch

# Set the proper environment.
ENV container=docker \
	init=/lib/systemd/systemd

# Copy the entire filesystem from the base image
COPY --from=base / /

# Add our entrypoint
ADD entrypoint.sh /bin/
ADD systemd-detect-virt /usr/bin/

# Ensure docker sends the shutdown signal that systemd expects
STOPSIGNAL SIGRTMIN+3

# Set our entrypoint
ENTRYPOINT ["/bin/entrypoint.sh"]

# Set our default command
CMD ["snapcraft"]
