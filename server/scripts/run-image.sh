#!/bin/bash
# Use Podman instead of Docker if it is avaiable to run image in production mode

ERROR='\033[0;31m'
NC='\033[0m' # No Color

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

build_and_run() {
  IMAGE_ID=$($1 build . | tail -1)
  $1 run --rm -p 31337:31337 \
    -e DATABASE_URL=memory:// -e ASSETS=1 \
    -it $IMAGE_ID
}

if command_exists podman; then
  build_and_run podman
elif command_exists docker; then
  build_and_run docker
else
  echo -e "${ERROR}Install Podman or Docker${NC}"
  exit 1
fi