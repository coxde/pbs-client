#
# Proxmox Backup Client Containerfile.
#

FROM ghcr.io/linuxserver/baseimage-debian:trixie

LABEL maintainer="coxde"

# Install runtime dependencies
RUN apt-get update && apt-get install -y wget cron expect nullmailer bsd-mailx ca-certificates

# Get the Proxmox signing keys and add to trust store
RUN wget https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg \
      -O /usr/share/keyrings/proxmox-archive-keyring.gpg
RUN cat > /etc/apt/sources.list.d/pbs-client.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pbs-client
Suites: trixie
Components: main
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

# Run updates, installs and clean up to minimise image size
RUN apt-get update && \
    apt-get install -y proxmox-backup-client && \
    apt-get autoclean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/apt/archives

# This is the mount point to put your volumes / bind mounts.
RUN mkdir /backups

#COPY ./src/s6-services/env-test /etc/s6-overlay/s6-rc.d/env-test
#RUN touch etc/s6-overlay/s6-rc.d/user/contents.d/env-test

COPY ./src/expect_scripts/client_key /etc/s6-overlay/s6-rc.d/key_setup/client_key
COPY ./src/expect_scripts/client_master_key /etc/s6-overlay/s6-rc.d/key_setup/client_master_key
COPY ./src/s6-services/key_setup /etc/s6-overlay/s6-rc.d/key_setup
COPY ./src/s6-services/key_setup /etc/s6-overlay/s6-rc.d/key_setup
RUN touch etc/s6-overlay/s6-rc.d/user/contents.d/key_setup

COPY ./src/s6-services/setup_check /etc/s6-overlay/s6-rc.d/setup_check
RUN touch etc/s6-overlay/s6-rc.d/user/contents.d/setup_check

COPY ./src/s6-services/backup /etc/s6-overlay/s6-rc.d/backup
RUN touch etc/s6-overlay/s6-rc.d/user/contents.d/backup

COPY ./src/s6-services/cron-backup /etc/s6-overlay/s6-rc.d/cron-backup
RUN touch etc/s6-overlay/s6-rc.d/user/contents.d/cron-backup

COPY ./src/s6-services/nullmailer-configure /etc/s6-overlay/s6-rc.d/nullmailer-configure
RUN touch etc/s6-overlay/s6-rc.d/user/contents.d/nullmailer-configure

COPY ./src/s6-services/nullmailer-service /etc/s6-overlay/s6-rc.d/nullmailer-service
RUN touch etc/s6-overlay/s6-rc.d/user/contents.d/nullmailer-service

COPY ./src/helper_scripts/* /usr/local/sbin/
RUN chmod +x /usr/local/sbin/*

COPY ./src/branding.txt /etc/s6-overlay/s6-rc.d/init-adduser/branding
