# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-debian:bookworm

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nomandera,nemchik"

# environment settings
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV DEBIAN_FRONTEND=noninteractive

RUN \
  echo "**** install runtime packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    curl \
    fail2ban \
    iptables \
    logrotate \
    msmtp \
    nftables \
    systemd \
    python3-systemd \
    whois && \
  echo "**** copy fail2ban confs to /defaults ****" && \
  mkdir -p \
    /defaults/fail2ban && \
  curl -o \
    /tmp/fail2ban-confs.tar.gz -L \
    "https://github.com/linuxserver/fail2ban-confs/tarball/master" && \
  tar xf \
    /tmp/fail2ban-confs.tar.gz -C \
    /defaults/fail2ban/ --strip-components=1 --exclude=linux*/.editorconfig --exclude=linux*/.gitattributes --exclude=linux*/.github --exclude=linux*/.gitignore --exclude=linux*/LICENSE && \
  echo "**** fix logrotate ****" && \
  sed -i "s#/var/log/messages {}.*# #g" \
    /etc/logrotate.conf && \
  # Debian keeps daily cron scripts in /etc/cron.daily/ instead of Alpine's /etc/periodic/daily/
  if [ -f /etc/cron.daily/logrotate ]; then \
    sed -i 's#/usr/sbin/logrotate /etc/logrotate.conf#/usr/sbin/logrotate /etc/logrotate.conf -s /config/log/logrotate.status#g' \
      /etc/cron.daily/logrotate; \
  fi && \
  printf "Linuxserver.io version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    $HOME/.cache

# add local files
COPY /root/ /

# ports and volumes
VOLUME /config
