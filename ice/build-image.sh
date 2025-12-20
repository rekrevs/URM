#!/bin/bash
# Build and push URM training image to ICE registry
# Usage: ./ice/build-image.sh [tag]

set -e

REGISTRY="registry.ice.ri.se"
IMAGE_NAME="aic/urm-training"
TAG="${1:-latest}"

FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "=== Building URM Training Image ==="
echo "Image: ${FULL_IMAGE}"
echo ""

cd "$(dirname "$0")"

# Build the image
echo "Building image..."
docker build -t "${FULL_IMAGE}" -f Dockerfile ..

echo ""
echo "Build complete!"
echo ""

# Push to registry
echo "Pushing to ${REGISTRY}..."
docker push "${FULL_IMAGE}"

echo ""
echo "=== Done ==="
echo "Image available at: ${FULL_IMAGE}"
echo ""
echo "Update ice/train.sh to use this image:"
echo "  image: ${FULL_IMAGE}"
