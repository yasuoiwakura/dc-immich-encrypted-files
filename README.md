# Docker Compose Stack for encrypted Immich Storage
use a gocryptfs-encrypted directory as storage for Immich (Database is NOT encrypted)

## problem
The Ente Image Server is encrypted but not free, they charge you per GB even if you self-host their server, PLUS their features are very limited compared to Immich.
Immich is by default not encrypted, docker compose CANNOT run host-scripts to unlock encrypted storage you might have set up.

## proposal for solution
A custom build process for the Docker Compose Stack of Immich integrated gocryptfs plus a unlock script. A sidecar container stores the unlock password and can outlive the immich update (if you want).


## disclaimer
This solution is a mere Proof of Concept! It has several security flaws and is not meant for production. If you loose your gocryptfs Password no one can restore your precious Pictures!
So make a backup before trying this out!!!

## alternative solutions
- Use Ente either as service or self-hosted service, it uses end-to-end encryption, meaning that even your server cannot acces the unencrypted images Images.
- Just encrypt your while data disk using LUKS, ZFS, etc...
- entrust your unencrypted photo collection to google or apple 😓

## links
- https://immich.app/
- https://github.com/immich-app/immich/pkgs/container/immich-server