FROM debian:bullseye

# Update apt repository
RUN apt-get update

# Install Go and add binary to path
RUN apt-get -y install curl && \
    curl -O https://dl.google.com/go/go1.19.13.linux-amd64.tar.gz && \
    tar xvf go1.19.13.linux-amd64.tar.gz && \
    chown -R root:root ./go && \
    mv go /usr/local
ENV PATH="$PATH:/usr/local/go/bin"

# Install dependencies
RUN apt-get -y install \
        build-essential \
        software-properties-common \
        libtest-harness-perl \
        apache2-dev \
        gcc \
        rsync \
        gdb \
        strace \
        inotify-tools

RUN apt-get -y install git

# Copy Apache plugin source
COPY buildtools buildtools
COPY cmd cmd
COPY src src
COPY apxs.sh .
COPY go.mod .
COPY go.sum .
COPY Makefile .

RUN make
