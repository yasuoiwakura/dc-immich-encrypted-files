# Docker Compose Stack for encrypted Immich Storage
use a gocryptfs-encrypted directory as storage for Immich (Database is NOT encrypted)

## problem
The Ente Image Server is encrypted but not free, they charge you per GB even if you self-host their server, PLUS their features are very limited compared to Immich.
Immich is by default not encrypted, docker compose CANNOT run host-scripts to unlock encrypted storage you might have set up.

## proposal for solution
A custom build process for the Docker Compose Stack of Immich integrated gocryptfs plus a unlock script. A sidecar container stores the unlock password and can outlive the immich update (if you want).

## limitations
- unlike ENTE, this is NOT end-to-end-encryption E2EE
- not for production use - proof of concept and all your data might get lost - make a backup before setting this up!
- changes at the immich main image (data dir or entrypoint) might break this extension (immich is heaviliy developed)
- if you loose your encryption password, no one can restore your data!
- tested with Immich version 1.136.0 to 2.2.1

## alternative solutions
- Use Ente either as service or self-hosted service, it uses end-to-end encryption, meaning that even your server cannot acces the unencrypted images Images.
- Just encrypt your while data disk using LUKS, ZFS, etc...
- entrust your unencrypted photo collection to google or apple 😓

## How it works internally
1. package has compose.yml (docker compose file), build instructions and some scripts
2. upon building, the Dockerfile will get the regular Immich image and add gocryptfs, hence creating a custom image
3. it will also replace the entrypoint script
4. upon starting, the container is not provided with the reggular /data/ dir but the /encrypted dir
5. The startup script will check
- /encrypted data dir was mounted into the docker volume and is either empty or has gocryptfs system files
- (decrypted) data dir exists and is empty and is NOT yet mounted externally
5. gocryptfs will try unlocking the /encrypted directory and provide unencrypted /usr/src/app/upload (environment variable gocryptfs_decrypt_dir from compose file)
6. loop: decrypt.sh will listen for the password on port 9000 (will continue listening until unlock succeeded)
7. it will try unlocking the encrypted dir
8. send the string "Successfully decrypted" if further connection received
```gocryptfs -allow_other -extpass  "nc" -extpass="-l" -extpass="-p" -extpass "9000" /encrypted $DIR_DECRYPTED```
9. start immich server:
```tini -- /usr/src/app/server/bin/start.sh```

## before first run
you could run the immich_server in interactive mode in order to initialize an gocryptfs directory, but It might be cleaner to do it manually:

This will initialize an *empty* directory into a gocrytpfs encrypted directory.
```
git clone https://github.com/yasuoiwakura/dc-immich-encrypted-files/
cd dc-immich-encrypted-files
mkdir ./encrypted
docker run --rm -it  -v ./encrypted:/encrypted ghcr.io/rfjakob/gocryptfs:latest \
    gocryptfs -init /encrypted
ls ./encrypted
```
the ./encrypted dir should now have some files
```
gocryptfs.conf
gocryptfs.diriv
```
**NOTE YOUR PASSWORD* i.e. Password Manager**

## build and run
prequisites:
- empty encrypted directory has been initialized
- compose.yml and .env have been customized
1. get latest Immich Image
```docker pull ghcr.io/immich-app/immich-server:release```
2. docker compose build
```
# docker compose build
Compose now can delegate build to bake for better performances
Just set COMPOSE_BAKE=true
[+] Building 1.9s (18/18) FINISHED                                       docker:default
 => [immich-server internal] load build definition from Dockerfile                 0.0s
 => => transferring dockerfile: 747B                                               0.0s
 => [immich-server internal] load metadata for ghcr.io/immich-app/immich-server:r  0.0s
 => [immich-server internal] load metadata for docker.io/vmirage/gocryptfs:latest  1.1s
 => [immich-server internal] load .dockerignore                                    0.0s
 => => transferring context: 2B                                                    0.0s
 => [immich-server stage-1 1/9] FROM ghcr.io/immich-app/immich-server:release      0.1s
 => [immich-server gocryptfs_base 1/2] FROM docker.io/vmirage/gocryptfs:latest@sh  0.0s
 => [immich-server internal] load build context                                    0.0s
 => => transferring context: 32B                                                   0.0s
 => CACHED [immich-server gocryptfs_base 2/2] RUN apk add --no-cache bash netcat-  0.0s
 => [immich-server stage-1 2/9] COPY --from=gocryptfs_base /usr/local/bin/gocrypt  0.0s
 => [immich-server stage-1 3/9] COPY --from=gocryptfs_base /bin/fusermount /bin/f  0.0s
 => [immich-server stage-1 4/9] COPY --from=gocryptfs_base /bin/bash /bin/bash     0.0s
 => [immich-server stage-1 5/9] COPY --from=gocryptfs_base /usr/bin/nc /bin/nc     0.0s
 => [immich-server stage-1 6/9] COPY --from=gocryptfs_base /lib /lib               0.0s
 => [immich-server stage-1 7/9] COPY --from=gocryptfs_base /usr/lib /usr/lib       0.1s
 => [immich-server stage-1 8/9] COPY decrypt.sh /decrypt.sh                        0.0s
 => [immich-server stage-1 9/9] RUN chmod +x /decrypt.sh                           0.3s
 => [immich-server] exporting to image                                             0.1s
 => => exporting layers                                                            0.1s
 => => writing image sha256:891b8ed2dbc16d4ac7b3f2b88988c7e1f759c0ed75a1cc43aeb84  0.0s
 => => naming to docker.io/yasuoiwakura/immich-app/immich-server-custom:latest     0.0s
 => [immich-server] resolving provenance for metadata file                         0.0s
[+] Building 1/1
 ✔ immich-server  Built
 ```
2. docker compose up -d
This will start immich, you can check the logs to see the decryption waiting for the password:
3. docker compose logs




## links
- [github link for local reference](https://github.com/yasuoiwakura/dc-immich-encrypted-files/)
- [Immich](https://immich.app/)
- [Immich Github page](https://github.com/immich-app/immich/pkgs/container/immich-server)


## publishing info
- this mod started mid-2025
- refactored and uploaded to github portfolio end-2025
- showcased & trimmed - feel free to ask for help!