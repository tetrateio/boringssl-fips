FROM index.docker.io/dio123/boringssl-fips-builder@sha256:d430e7f9f5ab26aae829b9f9d4327e20d2c240d4997aeae629132d4c0f267538
COPY ./tools/build.sh /var/local/build.sh
RUN /var/local/build.sh
