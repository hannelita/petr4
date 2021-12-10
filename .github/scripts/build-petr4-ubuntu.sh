#!/bin/bash

# petr4 build script for ubuntu

set -e  # Exit on error.
set -x  # Make command execution verbose


export PETR4_DEPS="m4 \
                   libgmp-dev"

# install deps
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ${PETR4_DEPS}
opam update
opam upgrade
# install p4pp
#opam switch 4.09.1
opam pin add p4pp https://github.com/cornell-netlab/p4pp.git
#install dune
opam install dune
cd ../..
opam external-lib-deps --missing @install

# build petr4
dune build
dune install