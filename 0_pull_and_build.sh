#!/bin/bash
echo making sure the newest Immich base image is available for the build
docker pull ghcr.io/immich-app/immich-server:release

echo building dc-immich-encrypt-files Docker Image
docker compose build
