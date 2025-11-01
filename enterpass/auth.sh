#!/bin/bash

echo "\$FORGET_PASS=$FORGET_PASS"

read -s -p "Passwort: " password
echo -e "\nStarte Schleife..."

while true; do
  echo "Versuche Verbindung zu immich_server:9000..."
  output=$(echo "$password" | nc -q 1 immich_server 9000)
  echo "Serverantwort: $output"

  if [[ "$output" == *"Successfully decrypted"* ]] ; then
    clear
    echo "Verbindung erfolgreich! Decryption bestätigt."
    if [ "$FORGET_PASS" -eq 1 ]; then
      password=""
      echo "Verbindung erfolgreich! Decryption bestätigt. Passwort vergessen."
      break
    else
      echo "Warte auf weitere Verbindungen..."
    fi
  else
    echo "Error while connecting/decrypting. Wiederhole in 1 Sekunde..."
    sleep 1
  fi
done
exit 0
