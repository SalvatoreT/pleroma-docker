FROM debian:bullseye-slim

# From Installing on Linux using OTP releases
# https://docs-develop.pleroma.social/backend/installation/otp_en/

# Prepare the system
RUN apt update  \
    && apt full-upgrade -y \
    && apt install -y \
    curl \
    ffmpeg \
    imagemagick \
    libimage-exiftool-perl \
    libmagic-dev \
    libncurses5 \
    libvips \
    locales \
    locales-all \
    postgresql \
    postgresql-contrib \
    unzip \
    vim \
    && rm -rf /var/lib/apt/lists/*

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

# Install PleromaBE
RUN adduser --system --shell /bin/false --home /opt/pleroma pleroma

RUN mkdir -p \
    /mount/uploads \
    /mount/static \
    /mount/config \
    && chown -R pleroma \
    /mount
VOLUME "/mount"

ENV PLEROMA_CONFIG_PATH=/mount/config/config.exs

USER pleroma
WORKDIR /opt/pleroma

# Clone the release build into a temporary directory and unpack it
RUN arch="$(uname -m)";if [ "$arch" = "x86_64" ];then arch="amd64";elif [ "$arch" = "armv7l" ];then arch="arm";elif [ "$arch" = "aarch64" ];then arch="arm64";else echo "Unsupported arch: $arch">&2;fi;if getconf GNU_LIBC_VERSION>/dev/null;then libc_postfix="";elif [ "$(ldd 2>&1|head -c 9)" = "musl libc" ];then libc_postfix="-musl";elif [ "$(find /lib/libc.musl*|wc -l)" ];then libc_postfix="-musl";else echo "Unsupported libc">&2;fi;echo "$arch$libc_postfix" \
    && curl "https://git.pleroma.social/api/v4/projects/2/jobs/artifacts/stable/download?job=$arch" -o /tmp/pleroma.zip \
    && unzip /tmp/pleroma.zip -d /tmp/ \
    && mv /tmp/release/* /opt/pleroma \
    && rmdir /tmp/release \
    && rm /tmp/pleroma.zip

EXPOSE 4000

ENTRYPOINT ["/opt/pleroma/bin/pleroma"]
CMD ["start"]