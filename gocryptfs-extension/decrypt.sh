#!/bin/bash
set -e

if [ -n "$gocryptfs_decrypt_dir" ]; then
  # Wenn sie gesetzt ist, verwende ihren Wert
  DIR_DECRYPTED="$gocryptfs_decrypt_dir"
else
  DIR_DECRYPTED=/usr/src/app/upload # DIR_DECRYPTED=/decrypted
fi
echo "[gocryptfs] DIR_DECRYPTED=$DIR_DECRYPTED"


if [ ! -d $DIR_DECRYPTED ]; then
  echo "[gocryptfs] $DIR_DECRYPTED not found (fresh build?) - creating..."
  mkdir -p "$DIR_DECRYPTED"
  echo "[gocryptfs] created."
  echo "[gocryptfs] ls"
  find $DIR_DECRYPTED
  # exit 1
else
  echo "[gocryptfs] $DIR_DECRYPTED exists - trying to decrypt..."
fi

if [ "$(ls -A $DIR_DECRYPTED)" ]; then
    echo "[gocryptfs] ERROR: TARGET $DIR_DECRYPTED is not empty! Aborting to avoid unencrypted writes. DO NOT PROCEED UNLESS YOU KNOW WHAT YOU DO."
    exit 1
fi
echo "[gocryptfs] Target directory empty, continue..."

if ! mountpoint -q /encrypted; then
    echo "[gocryptfs] ERROR: /encrypted is no mounted Volume! It MUST be either an empty directory or an encrypted gocryptfs directory!"
    exit 1
fi

if [ ! -f /encrypted/gocryptfs.conf ]; then
  echo "[gocryptfs] MISSING /encrypted/gocryptfs.conf - volume not mounted or not initialized!!!"
  echo "[gocryptfs] Trying to Init..."
  if [ ! -t 0 ]; then # TODO remove
    echo "!!! need interactive shell for init\ndocker compose run crypt -T\n(only for setup - wenn NOT data access for stack!)"
    exit 1
  else
    echo "gocryptfs --init /encrypted "
    gocryptfs --init /encrypted       
    wait 1
    echo "[gocryptfs] INIT success"
  fi
fi

if [ ! -f /encrypted/gocryptfs.conf ]; then
  echo "[gocryptfs] DATA DIRECTORY NOT INITIALIZED - ABORTING DECRYPTION..."
  exit 1
fi

# echo grep "$DIR_DECRYPTED" /proc/mounts
# grep "$DIR_DECRYPTED" /proc/mounts
echo "[gocryptfs] Checking if no docker volume was accidently mounted into the data dir..."
if grep -qs "$DIR_DECRYPTED" /proc/mounts; then
    echo "[gocryptfs] Already mounted - fatal error - do NOT mount encrypted Data into $DIR_DECRYPTED!!!"
    exit 1
else
    echo "[gocryptfs] Not mounted yet - we can safely mount the decrypted dir there..."
fi


#if mountpoint -q /usr/src/app/upload; then
#  echo "Unmounting existing mount at /usr/src/app/upload"
#  umount /usr/src/app/upload || echo "Unmount failed, maybe not mounted"
#fi

echo "[gocryptfs] Starting decryption..."
while ! grep -qs "^.* $DIR_DECRYPTED fuse.gocryptfs " /proc/mounts; do #if ! mountpoint -q /decrypted; then
#while ! mountpoint -q $DIR_DECRYPTED; do 
  echo "[gocryptfs] Not yet mounted - Mount..."
  if [ -t 0 ]; then
    echo ":-) INTERACTIVE PASSWORD POSSIBLE - but mounts will NOT reach the Stack"
    gocryptfs /encrypted $DIR_DECRYPTED -allow_other
  else
    echo "NO interactive shell!!! :-("
    echo "------------------------------------"
    echo "Waiting for your input,"
    echo "Please transmit password via network:"
    echo ""
    echo "nc immich-server 9000 (from within stack)"
    echo "nc localhost 9000 (from docker host)"
    echo "Enter password, then press ENTER and Ctrl-D to end connection"
    echo "------------------------------------"
    #gocryptfs /encrypted $DIR_DECRYPTED -allow_other -extpass "nc" -extpass="-l" -extpass="-p" -extpass "9000"
    echo gocryptfs -allow_other -extpass  "nc" -extpass="-l" -extpass="-p" -extpass "9000" /encrypted $DIR_DECRYPTED
    gocryptfs -allow_other -extpass  "nc" -extpass="-l" -extpass="-p" -extpass "9000" /encrypted $DIR_DECRYPTED
    sleep 2
  fi
done
echo "Successfully decrypted" | nc -l -p 9000 -q 5
echo "[gocryptfs] Mount successful, ending loop."

#else
#  echo "[gocryptfs] /decrypted was already mounted!"
#fi
df -h|grep -e Filesystem -e encrypted -e decrypted
echo ""
echo ls /encrypted
ls /encrypted
echo ""
echo ls $DIR_DECRYPTED
ls $DIR_DECRYPTED
echo ""
echo "[gocryptfs] Mount abgeschlossen. Starte Debugshell"
#tail -f /dev/null

echo "[entrypoint] Starte immich..."
#echo exec /usr/src/app/start-server.sh "$@"
echo "(TODO) start server"
#exec tini -- "$@"
echo exec tini -- /usr/src/app/start.sh 
#exec tini -- /usr/src/app/start.sh before 2025-07-26
exec tini -- /usr/src/app/server/bin/start.sh
