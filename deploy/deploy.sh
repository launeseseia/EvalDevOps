#!/usr/bin/env bash
# Deploiement : pull de l'image, lancement, verification de sante, rollback si echec.
set -euo pipefail

: "${IMAGE:?IMAGE non defini}"
: "${NEW_TAG:?NEW_TAG non defini}"

COMPOSE_FILE="deploy/docker-compose.prod.yml"
PROJECT="eval-devops-prod"
STATE_DIR="${HOME}/.eval-devops"
STATE_FILE="${STATE_DIR}/current_tag"
HEALTH_URL="http://localhost:8080/health"

mkdir -p "$STATE_DIR"
PREVIOUS_TAG="$(cat "$STATE_FILE" 2>/dev/null || true)"
echo "Version en production : ${PREVIOUS_TAG:-aucune}"
echo "Version a deployer    : ${NEW_TAG}"

deploy() {
  export APP_IMAGE="${IMAGE}:$1"
  docker pull "$APP_IMAGE"
  docker compose -p "$PROJECT" -f "$COMPOSE_FILE" up -d --remove-orphans
}

healthcheck() {
  curl -fsS --retry 3 --retry-delay 5 --retry-all-errors --max-time 5 "$HEALTH_URL"
}

deploy "$NEW_TAG"
sleep 5

if healthcheck; then
  echo "$NEW_TAG" > "$STATE_FILE"
  echo "Deploiement OK : ${NEW_TAG}"
  exit 0
fi

echo "::error::Healthcheck KO apres deploiement de ${NEW_TAG}"
docker compose -p "$PROJECT" -f "$COMPOSE_FILE" logs --tail=50 app || true

if [ -n "$PREVIOUS_TAG" ]; then
  echo "Rollback vers ${PREVIOUS_TAG}"
  deploy "$PREVIOUS_TAG"
  sleep 5
  if healthcheck; then
    echo "Rollback OK, ${PREVIOUS_TAG} de nouveau en production"
  else
    echo "::error::Rollback KO"
  fi
else
  echo "::warning::Aucune version precedente connue, rollback impossible"
fi
exit 1