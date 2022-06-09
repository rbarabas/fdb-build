# Build setup
FROM --platform=linux/arm64/v8 ubuntu:latest as build
ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN apt update && apt install -y \
    git \
    vim \
    clang \
    cmake \
    golang \
    libjemalloc2 \
    libjemalloc-dev \
    liblz4-dev \
    libssl-dev \
    mono-devel \
    ninja-build \
    openjdk-11-jdk \
    openssl \
    python3 \
    ruby-dev


# Compiling and packaging
FROM build as compile
ENV SOURCE=https://github.com/rbarabas/foundationdb
ENV VERSION=rb/7.1.7_arm64
RUN git clone ${SOURCE} && \
    cd foundationdb && \
    git checkout ${VERSION} && \
    cd -
RUN mkdir build && cmake -S foundationdb -B build -G Ninja
WORKDIR build
RUN ninja -j3
RUN cpack -G DEB


# Release container
FROM --platform=linux/arm64/v8 ubuntu:latest as foundationdb-server

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl

COPY --from=compile /build/packages/foundationdb-clients*.deb .
COPY --from=compile /build/packages/foundationdb-server*.deb .
RUN mkdir /var/lib/foundationdb
RUN dpkg -i ./foundationdb-clients*.deb
RUN chown foundationdb:foundationdb /var/lib/foundationdb
RUN dpkg -i ./foundationdb-server*.deb
RUN rm -rf *.deb

COPY install_tini.sh .
RUN chmod +x ./install_tini.sh && ./install_tini.sh

RUN bash -c 'mkdir -p /var/lib/foundationdb/{logs,tmp,lib,scripts}'
ADD fdb.bash /var/lib/foundationdb/scripts/
RUN chown foundationdb:foundationdb -R /var/lib/foundationdb

ENV FDB_PORT 4500
ENV FDB_CLUSTER_FILE /var/lib/foundationdb/fdb.cluster
ENV FDB_NETWORKING_MODE container
ENV FDB_COORDINATOR ""
ENV FDB_COORDINATOR_PORT 4500
ENV FDB_CLUSTER_FILE_CONTENTS ""
ENV FDB_PROCESS_CLASS unset

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/var/lib/foundationdb/scripts/fdb.bash"]

