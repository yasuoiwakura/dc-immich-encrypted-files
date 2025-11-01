#!/bin/bash
docker rm $(docker ps -a --filter "name=immich-immich_enterpass-run*" -q)
docker compose run immich_enterpass --remove-orphans

