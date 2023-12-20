#!/usr/bin/env bash

# This is adapted from: https://github.com/envoyproxy/envoy/blob/73dc561f0c227c03ec6535eaf4c30d16766236a0/bazel/external/boringssl_fips.genrule_cmd.

set -e

# Allow to override BoringSSL source. The one that is blessed is the default values.
# The default values are from: https://github.com/envoyproxy/envoy/blob/73dc561f0c227c03ec6535eaf4c30d16766236a0/bazel/repository_locations.bzl#L142.
BORINGSSL_VERSION=${1-"853ca1ea1168dff08011e5d42d94609cc0ca2e27"}
BORINGSSL_SHA256=${2-"a4d069ccef6f3c7bc0c68de82b91414f05cb817494cd1ab483dcf3368883c7c2"}
BORINGSSL_SOURCE=${3-"https://commondatastorage.googleapis.com/chromium-boringssl-fips/boringssl-${BORINGSSL_VERSION}.tar.xz"}

export CXXFLAGS=''
export LDFLAGS=''

# BoringSSL build as described in the Security Policy for BoringCrypto module (2022-05-06):
# https://csrc.nist.gov/CSRC/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp4407.pdf

OS=`uname`
ARCH=`uname -m`
# This works only on Linux-x86_64 and Linux-aarch64.
if [[ "$OS" != "Linux" || ("$ARCH" != "x86_64" && "$ARCH" != "aarch64") ]]; then
  echo "ERROR: BoringSSL FIPS is currently supported only on Linux-x86_64 and Linux-aarch64."
  exit 1
fi

# Clang
VERSION="12.0.0"
if [[ "$ARCH" == "x86_64" ]]; then
  PLATFORM="x86_64-linux-gnu-ubuntu-20.04"
  SHA256=a9ff205eb0b73ca7c86afc6432eed1c2d49133bd0d49e47b15be59bbf0dd292e
else
  PLATFORM="aarch64-linux-gnu"
  SHA256=d05f0b04fb248ce1e7a61fcd2087e6be8bc4b06b2cc348792f383abf414dec48
fi

curl -fsLO https://github.com/llvm/llvm-project/releases/download/llvmorg-"$VERSION"/clang+llvm-"$VERSION"-"$PLATFORM".tar.xz \
  && echo "$SHA256" clang+llvm-"$VERSION"-"$PLATFORM".tar.xz | sha256sum --check
tar -xJf clang+llvm-"$VERSION"-"$PLATFORM".tar.xz

export HOME="$PWD"
printf "set(CMAKE_C_COMPILER \"clang\")\nset(CMAKE_CXX_COMPILER \"clang++\")\n" > ${HOME}/toolchain
export PATH="$PWD/clang+llvm-$VERSION-$PLATFORM/bin:$PATH"

if [[ `clang --version | head -1 | awk '{print $3}'` != "$VERSION" ]]; then
  echo "ERROR: Clang version doesn't match."
  exit 1
fi

# Go
VERSION="1.16.5"
if [[ "$ARCH" == "x86_64" ]]; then
  PLATFORM="linux-amd64"
  SHA256=b12c23023b68de22f74c0524f10b753e7b08b1504cb7e417eccebdd3fae49061
else
  PLATFORM="linux-arm64"
  SHA256=d5446b46ef6f36fdffa852f73dfbbe78c1ddf010b99fa4964944b9ae8b4d6799
fi

curl -fsLO https://dl.google.com/go/go"$VERSION"."$PLATFORM".tar.gz \
  && echo "$SHA256" go"$VERSION"."$PLATFORM".tar.gz | sha256sum --check
tar -xzf go"$VERSION"."$PLATFORM".tar.gz

export GOPATH="$PWD/gopath"
export GOROOT="$PWD/go"
export PATH="$GOPATH/bin:$GOROOT/bin:$PATH"

if [[ `go version | awk '{print $3}'` != "go$VERSION" ]]; then
  echo "ERROR: Go version doesn't match."
  exit 1
fi

# Ninja
VERSION="1.10.2"
SHA256=ce35865411f0490368a8fc383f29071de6690cbadc27704734978221f25e2bed
curl -fsLO https://github.com/ninja-build/ninja/archive/refs/tags/v"$VERSION".tar.gz \
  && echo "$SHA256" v"$VERSION".tar.gz | sha256sum --check
tar -xzf v"$VERSION".tar.gz
cd ninja-"$VERSION"
CC=clang CXX=clang++ python3 ./configure.py --bootstrap

export PATH="$PWD:$PATH"

if [[ `ninja --version` != "$VERSION" ]]; then
  echo "ERROR: Ninja version doesn't match."
  exit 1
fi
cd ..

# CMake
VERSION="3.20.1"
if [[ "$ARCH" == "x86_64" ]]; then
  PLATFORM="linux-x86_64"
  SHA256=b8c141bd7a6d335600ab0a8a35e75af79f95b837f736456b5532f4d717f20a09
else
  PLATFORM="linux-aarch64"
  SHA256=5ad1f8139498a1956df369c401658ec787f63c8cb4e9759f2edaa51626a86512
fi

curl -fsLO https://github.com/Kitware/CMake/releases/download/v"$VERSION"/cmake-"$VERSION"-"$PLATFORM".tar.gz \
  && echo "$SHA256" cmake-"$VERSION"-"$PLATFORM".tar.gz | sha256sum --check
tar -xzf cmake-"$VERSION"-"$PLATFORM".tar.gz

export PATH="$PWD/cmake-$VERSION-$PLATFORM/bin:$PATH"

if [[ `cmake --version | head -n1` != "cmake version $VERSION" ]]; then
  echo "ERROR: CMake version doesn't match."
  exit 1
fi

# Build and test BoringSSL.
VERSION="${BORINGSSL_VERSION}"
SHA256="${BORINGSSL_SHA256}"
curl -fsLO "${BORINGSSL_SOURCE}" \
  && echo "$SHA256" boringssl-"$VERSION".tar.xz | sha256sum --check

tar -xJf boringssl-"$VERSION".tar.xz

cd boringssl
mkdir build && cd build && cmake -GNinja -DCMAKE_TOOLCHAIN_FILE=${HOME}/toolchain -DFIPS=1 -DCMAKE_BUILD_TYPE=Release ..
ninja
ninja run_tests
./crypto/crypto_test

# The result should be in:
#   boringssl/build/crypto/libcrypto.a
#   boringssl/build/ssl/libssl.a

# If you run this script using docker container, you can do:
#   CONTAINER_ID=$(docker create -it your-image-name)
#   docker cp $CONTAINER_ID:/boringssl/build/crypto/libcrypto.a ./libcrypto.a
#   docker cp $CONTAINER_ID:/boringssl/build/ssl/libssl.a ./libssl.a
#   tar -cJf boringssl-fips.tar.xz libcrypto.a libssl.a
