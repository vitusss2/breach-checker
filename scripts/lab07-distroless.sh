#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
project="lab07-distroless-${tmp##*.}"
project=${project,,}
base=(docker compose -p "$project" -f docker-compose.yml)
cleanup() {
  "${base[@]}" down --volumes >&2
  rm -f "$tmp/prod.yml"
  rmdir "$tmp"
}
trap cleanup EXIT
cat >"$tmp/prod.yml" <<'YAML'
services:
  backend:
    image: breach-checker-backend:prod
    tmpfs:
      - /tmp
    healthcheck:
      test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=2).read()"]
      interval: 5s
      timeout: 3s
      retries: 10
YAML
docker build --pull -t breach-checker-backend:prod backend
docker build --pull -f backend/Dockerfile.distroless -t breach-checker-backend:distroless backend
for variant in prod distroless; do
  image="breach-checker-backend:$variant"
  echo "=== $image ==="
  docker image inspect --format 'Rozmiar: {{.Size}} B | USER: {{.Config.User}} | ENTRYPOINT: {{json .Config.Entrypoint}}' "$image"
  if [[ $variant == prod ]]; then
    overlay="$tmp/prod.yml"
    python=python
  else
    overlay=docker-compose.distroless.yml
    python=/usr/bin/python3
  fi
  compose=("${base[@]}" -f "$overlay")
  if ! "${compose[@]}" up -d --no-build --wait --wait-timeout 120 backend; then
    "${compose[@]}" logs --tail=40 backend db
    exit 1
  fi
  "${compose[@]}" exec -T backend "$python" -c "import os,sys,urllib.request; print(sys.executable, sys.version.split()[0], 'uid=', os.getuid()); print(urllib.request.urlopen('http://localhost:5000/health').read().decode())"
  for cmd in sh id ls; do
    echo "docker compose exec -T backend $cmd"
    if "${compose[@]}" exec -T backend "$cmd" </dev/null; then
      echo 'kod wyjścia: 0'
    else
      echo "kod wyjścia: $?"
    fi
  done
  docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    -v lab07-trivy-cache:/root/.cache/trivy aquasec/trivy:0.76.0 image \
    --scanners vuln --severity HIGH,CRITICAL "$image"
done
