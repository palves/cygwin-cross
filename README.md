# Cygwin cross toolchain environment

Cygwin cross compiling toolchain in a Docker image.

This is a Docker container that provides a Cygwin toolchain cross
environment.  It is custom tailored for building Cygwin GDB, but it
can also be a base for developing other projects.  (You may need to
tweak the Dockerfile to install more packages in that case.)

For the cross-toolchain itself, this uses yselkowitz's Fedora copr,
found at: https://copr.fedorainfracloud.org/coprs/yselkowitz/cygwin/

## Features

- Pre-built and configured toolchain for cross compiling Cygwin
  programs, based on the yselkowitz/cygwin Fedora copr.
- Transparent usage:
  - Commands in the container are run with the same user/group id as
    the user running the container, so that any created files have the
    expected ownership, and the build commands can access source files
    as expected.
  - The user's home is mounted inside the container.
  - The user's /net is mounted inside the container.
  - The container's workdir is the calling user's current directory.
- The hostname inside the container is tweaked to "$HOSTNAME-cygwin",
  to make it easy to tell when inside the container in shell prompts.
- Can be run without arguments, which launches a shell ready for
  invoking commands (e.g., make) interactively, or,
- Can be run with arguments, which are passed as commands to the
  non-interative shell inside the container.


## Installation

This image is not meant to be run directly.  Instead, there is a
**cygwin-cross** helper script you use to enter the container
environment and/or execute build commands on build directories that
exist on the local host filesystem.

To install the helper script, simply copy or symlink it to some
directory found in your \$PATH.  E.g., you can download it directly
from github, like so:

```bash
wget https://raw.githubusercontent.com/palves/cygwin-cross/refs/heads/main/cygwin-cross
chmod u+x cygwin-cross
```

Or if you have a local repo checkout:

```bash
ln -s /path/to/cygwin-cross-git/cygwin-cross ~/bin/
```

## Examples

1. `cygwin-cross`: Run an interactive shell inside the container,
   preserving current directory.
2. `cygwin-cross make`: Invoke make with the *Makefile* found in the
   current directory.

## Usage

The packaged Cygwin toolchain uses the "x86_64-pc-cygwin"
prefix/triplet, so e.g., the compiler is "x86_64-pc-cygwin-gcc".

For example, here\'s how to compile GDB for Cygwin:

```bash
cd /path/to/gdb/build/
cygwin-cross
# You're now inside the container.
/path/to/gdb/src/configure \
    --disable-ld \
    --disable-binutils \
    --disable-gas \
    --disable-gold \
    --disable-nls \
    --with-gmp=/path/to/gmp/install-cygwin \
    --with-mpfr=/path/to/mpfr/install-cygwin \
    --with-expat=yes \
    --with-libexpat-prefix=/path/to/expat/install-cygwin \
    --host=x86_64-pc-cygwin \
    --target=x86_64-pc-cygwin
 make -j8
```

(You'll actually need to build gmp/mpfr/libexpat beforehand, in a
similar fashion.  But you get the point.)

Alternatively, you can invoke any toolchain command (make, gcc, etc.)
inside the container by prepending the **cygwin-cross** script on the
commandline.  Assuming **cygwin-cross** can be found in your PATH, you
can run:

```bash
$ cygwin-cross [command] [args...]
```

For example:

```bash
$ cygwin-cross make -j8
```

Note that if you prefer the prepending alternative above, it is not
recommended to wrap every compilation invocation in **cygwin-cross**,
like e.g., with ```CC="cygwin-cross x86_64-pc-cygwin-gcc" make```, as
that would result in a very significant slowdown caused by
entering/leaving the container many times.  It is much faster to wrap
the "make" invocation instead, and let make inside the container spawn
the compiler as many times as needed.


## Rebuilding the image

This isn't normally needed, because the image is available on [docker
hub](https://hub.docker.com/r/palves79/cygwin-cross), but if you want
to, you can rebuild it with:

```bash
git clone https://github.com/cygwin-cross/cygwin-cross.git
cd cygwin-cross
./build-docker
```
