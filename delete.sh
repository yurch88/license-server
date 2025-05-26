#!/bin/bash
set -e

echo -e "\033[1;31m[DELETE] ОСТОРОЖНО! Полная очистка всего Docker — все контейнеры, образы, volume, сети!\033[0m"

docker ps -aq | xargs -r docker stop || true
docker ps -aq | xargs -r docker rm -f || true

docker images -aq | xargs -r docker rmi -f || true

docker volume ls -q | xargs -r docker volume rm -f || true

docker network ls | grep -v 'bridge\|host\|none' | awk '{print $1}' | xargs -r docker network rm || true

docker builder prune -af || true

docker compose down -v --remove-orphans || true

echo -e "\033[1;33m[DELETE] Очищаю папки и файлы проекта...\033[0m"
rm -rf backend frontend migrations docker-compose.yml .env

echo -e "\033[1;32m[DELETE] Полная очистка завершена. Docker как с нуля!\033[0m"
