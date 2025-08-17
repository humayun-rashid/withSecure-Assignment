#!/usr/bin/env bash
set -e

CONTAINER_NAME="listservice-local"

if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
  echo "🛑 Stopping container $CONTAINER_NAME..."
  docker stop $CONTAINER_NAME
fi

if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  echo "🧹 Removing container $CONTAINER_NAME..."
  docker rm $CONTAINER_NAME
fi

echo "✅ Cleanup complete"
