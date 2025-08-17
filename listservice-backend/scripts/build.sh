#!/usr/bin/env bash
set -e

IMAGE_NAME="listservice:local"

echo "🛠️  Building Docker image: $IMAGE_NAME"
docker build -t "$IMAGE_NAME" -f Dockerfile .
echo "✅ Build complete"
