#!/usr/bin/env bash
set -e

IMAGE_NAME="listservice:local"
CONTAINER_NAME="listservice-local"

# Stop if already running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
  echo "⚠️  Stopping old container..."
  docker stop $CONTAINER_NAME
  docker rm $CONTAINER_NAME
fi

echo "🚀 Running $IMAGE_NAME on http://localhost:8080"
docker run -d --name $CONTAINER_NAME -p 8080:8080 $IMAGE_NAME
sleep 3

echo "✅ Container started"
