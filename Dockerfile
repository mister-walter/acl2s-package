FROM ubuntu:focal

# Based on https://github.com/wshito/roswell-base

# openssl-dev is needed for Quicklisp
# perl is needed for ACL2's certification scripts
# wget is needed for downloading some files while building the docker image
# The rest are needed for Roswell

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        automake \
        autoconf \
        libcurl4-openssl-dev \
        ca-certificates \
        libssl-dev \
        wget \
        perl \
        sbcl \
        zlib1g-dev \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/* # remove cached apt files

RUN mkdir -p /opt/acl2/sbcl \
    mkdir -p /tmp/sbcl \
    && cd /tmp/sbcl \
    && wget "http://prdownloads.sourceforge.net/sbcl/sbcl-2.1.8-source.tar.bz2?download" -O sbcl.tar.bz2 -q \
    && tar -xjf sbcl.tar.bz2 \
    #&& rm sbcl.tar.bz2 \
    && cd sbcl-* \
    && sh make.sh --without-immobile-space --without-immobile-code --without-compact-instance-header --fancy --dynamic-space-size=4Gb --prefix=/opt/acl2/ \
    && apt-get remove -y sbcl \
    && sh install.sh \
    && rm -R /tmp/sbcl

ARG ACL2_COMMIT=master
ENV ACL2_SNAPSHOT_INFO="Git commit hash: ${ACL2_COMMIT}"
RUN wget "https://api.github.com/repos/acl2/acl2/zipball/${ACL2_COMMIT}" -O /tmp/acl2.zip -q \
    && unzip -qq /tmp/acl2.zip -d /opt/acl2_extract \
    && rm /tmp/acl2.zip \
    && mv $(find /opt/acl2_extract/ -mindepth 1 -maxdepth 1 -name "acl2*" -print -quit) /opt/acl2/acl2 \
    && rmdir /opt/acl2_extract

ENV ACL2S_NUM_JOBS=4
ENV ACL2_SYSTEM_BOOKS="/opt/acl2/acl2/books"
ENV ACL2_LISP=/opt/acl2/bin/sbcl
ENV ACL2S_SCRIPTS="/opt/acl2/scripts/"
ENV PATH="/opt/bin:${PATH}"
ENV ACL2_SNAPSHOT_INFO=NONE

RUN mkdir -p /opt/bin \
    && ln -s /opt/acl2/acl2/saved_acl2 /opt/bin/acl2 \
    && ln -s /opt/acl2/acl2/books/build/cert.pl /opt/bin/ \
    && ln -s /opt/acl2/acl2/books/build/clean.pl /opt/bin/ \
    && ln -s /opt/acl2/acl2/books/build/critpath.pl /opt/bin/ \
    && cd /opt/acl2 \
    #&& ./clean-gen-acl2.sh
    && git clone https://gitlab.com/acl2s/external-tool-support/scripts.git \
    && ./scripts/clean-gen-acl2-acl2s.sh

RUN mkdir -p /opt/acl2s/DEBIAN \
    && mkdir /opt/acl2s/opt
COPY DEBIAN_control /opt/acl2s/DEBIAN/control
COPY DEBIAN_postinst /opt/acl2s/DEBIAN/postinst
COPY DEBIAN_postrm /opt/acl2s/DEBIAN/postrm
RUN mv /opt/acl2 /opt/acl2s/opt/ \
    && cd /opt \
    && dpkg-deb --build acl2s
