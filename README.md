Usage
-----

These containers are meant to be used with the action:
[snapcraft-multiarch-action](https://github.com/canonical/snapcraft-multiarch-action)

These container images have a pre-baked environment for snap building. They
contain snapcraft and all the core bases.

*IMPORTANT* These container images are *NOT* compatible with Docker provided
through the Snap Store due to confinement rules applied to the dockerd
interfering with (preventing) our container's execution.

These container images require you to pass `--privileged`.

Notes
-----
For builds against `core` the version of Systemd included in Ubuntu Xenial,
and thus included in the `core` container images, is not compatible with
cgroups version 2. This causes the `core` container image to fail to finish
starting on newer distros. On systems that use cgroups2 you might _still_ be
able to run the `core` container images by adding `--tmpfs /sys/fs/cgroup` to
the docker or podman command line.

Previous instructions, based on earlier iterations of the container images,
required you to create
and use an AppArmor namespace - this is not necessary any more.  That is, you
no-longer need to create a separate AppArmor namespace directory at
`/sys/kernel/security/apparmor/policy/namespaces/docker-snapcraft` and you can
drop the
`--security-opt apparmor=":docker-snapcraft:unconfined"` parameter from your
`docker` command line.

Running snapcraft
-----------------

Running without specifying a command will run `snapcraft` without any
parameters:

```bash
# Note: You MUST mount your project to /root/project
docker run --rm -it --privileged -v $PWD:/root/project -w /root/project ghcr.io/canonical/snapcraft-container:core26
```

To run with parameters, specify `snapcraft [...params]` when creating the
container:

```bash
docker run --rm -it --privileged -v $PWD:/root/project -w /root/project ghcr.io/canonical/snapcraft-container:core26 snapcraft stage --enable-experimental-package-repositories
```

Drop to a shell with systemd running
------------------------------------

```bash
docker run --rm -it --privileged -v $PWD:/root/project -w /root/project ghcr.io/canonical/snapcraft-container:core26 bash
```
