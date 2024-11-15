# SPDX-License-Identifier: GPL-3.0-or-later
# Author  : Pedro Alves (pedro@palves.net)
#
# Dockerfile that sets up a development environment for cross building
# Cygwin GDB.
#
# This is meant to be run with the host's $HOME mounted inside the
# container.

# Use a multi-stage approach, squashing all the layers at the end.
# This lets us write multiple RUN invocations below without caring
# about the fact that that creates layers with stuff that is removed
# later.  This helps with keeping readability, and helps with
# development at the same time (compared to moving every step to a
# single RUN invocation), as with this approach, adding an extra RUN
# command to test installing some extra package or something of the
# sort still lets docker reuse the previously cached layers.

FROM registry.fedoraproject.org/fedora:41 AS fedora

FROM fedora AS stage0
LABEL maintainer="Pedro Alves <pedro@palves.net>"

RUN dnf -y update

# Need this for "copr".
RUN dnf -y install dnf-plugins-core

# Enable the copr with the Cygwin cross toolchain.
RUN dnf -y copr enable yselkowitz/cygwin

# Uncomment to easily see the set of Cygwin packages in the repo.
# RUN dnf -y search cygwin64

# The Cygwin cross toolchain.
RUN dnf -y install \
    cygwin64-gcc \
    cygwin64-gcc-c++ \
    cygwin64-gcc-gfortran \
    cygwin64-libiconv \
    cygwin64-ncurses

# Not strictly needed, but useful.
RUN dnf -y install ccache

# Basic GDB build dependency packages.
RUN dnf -y install make flex bison texinfo

# Binutils needs to build "chew" for the build machine, so we need the
# build compiler.
RUN dnf -y install gcc

# Also needed to build binutils.
RUN dnf -y install diffutils

# Some conveniences inside the container.  Not too much, if you need
# to edit the files in the build dir, do it outside the container.
RUN dnf -y install hstr less which procps

# So we can easily upload binaries to the target Windows machine.
RUN dnf -y install rsync openssh-clients

# Neither su-exec or gosu are available in the Fedora distro.
# Download it straight from github, and build it locally.

# Github lets you download a tarball of any commit hash.  This is the
# latest at the time of writing.
ARG SU_EXEC_GITHASH=4c3bb42b093f14da70d8ab924b487ccfbb1397af

RUN dnf -y install wget && \
    wget -qO- https://github.com/ncopa/su-exec/archive/$SU_EXEC_GITHASH.tar.gz | tar xvz && \
    cd su-exec-* && make && mv su-exec /usr/local/bin && cd .. && rm -rf su-exec-* && \
    dnf -y remove wget

# Stay lean.
RUN dnf -y autoremove && dnf clean all

COPY entrypoint.sh /entrypoint.sh

FROM fedora AS squashed
COPY --from=stage0 / /

ENTRYPOINT ["/entrypoint.sh"]
