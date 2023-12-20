FROM ubuntu:20.04
# TODO(dio): Create a base image with all the dependencies.
RUN apt-get update && apt-get install -y gcc g++ xz-utils python3 libncurses5 curl
COPY ./tools/build.sh /var/local/build.sh
RUN /var/local/build.sh
