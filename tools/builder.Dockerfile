FROM gcr.io/tetratelabs/boringssl-fips-builder@sha256:d430e7f9f5ab26aae829b9f9d4327e20d2c240d4997aeae629132d4c0f267538
# The image above is a shortcut for:
#  FROM ubuntu:20.04
#  RUN apt-get update && apt-get install -y gcc g++ xz-utils python3 libncurses5 curl
COPY ./tools/build.sh /var/local/build.sh
RUN /var/local/build.sh
