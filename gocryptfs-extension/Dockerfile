# Stage 1: Build / Tools
# Stage 1: gocryptfs + tools (alpine)
FROM vmirage/gocryptfs AS gocryptfs_base
RUN apk add --no-cache bash netcat-openbsd

# Stage 2: Immich (Debian-basiert)
FROM ghcr.io/immich-app/immich-server:release
#FROM ghcr.io/immich-app/immich-server:latest

COPY --from=gocryptfs_base /usr/local/bin/gocryptfs /usr/bin/gocryptfs
COPY --from=gocryptfs_base /bin/fusermount /bin/fusermount
COPY --from=gocryptfs_base /bin/bash /bin/bash
COPY --from=gocryptfs_base /usr/bin/nc /bin/nc
# Kopiere libs (meist in /lib und /usr/lib)
COPY --from=gocryptfs_base /lib /lib
COPY --from=gocryptfs_base /usr/lib /usr/lib

COPY decrypt.sh /decrypt.sh
RUN chmod +x /decrypt.sh
ENTRYPOINT ["/decrypt.sh"]

