# boringssl-fips

This builds boringssl (in FIPS mode) using the script based on https://github.com/envoyproxy/envoy/blob/73dc561f0c227c03ec6535eaf4c30d16766236a0/bazel/external/boringssl_fips.genrule_cmd.

This also allows experimentation for patching the referenced boringssl, building and testing it using the tooling prescribed in: https://csrc.nist.gov/CSRC/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp4407.pdf.

## Build

Make sure the installed Docker has `buildx` support, then run: `make`.

## Usage

To use the build from this repository, please head to the "Releases" page.
For `envoy` build, one can patch the `bazel/external/boringssl_fips.genrule_cmd b/bazel/external/boringssl_fips.genrule_cmd` to download and extract the archive from this repository.

Similar to the following:

```bash
curl -fsSLO https://github.com/tetratelab/boringssl-fips/releases/download/fips-20210429/boringssl-fips-"$PLATFORM".tar.xz \
  && echo "$SHA256" boringssl-fips-"$PLATFORM".tar.xz | sha256sum --check
tar -xJf boringssl-fips-"$PLATFORM".tar.xz

# Move compiled libraries to the expected destinations.
popd
mv libcrypto.a $1
mv libssl.a $2
```
