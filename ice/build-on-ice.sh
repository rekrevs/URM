#!/bin/bash
# Build URM image on ICE using Kaniko
# Usage: ./ice/build-on-ice.sh [tag]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

REGISTRY="registry.ice.ri.se"
IMAGE_NAME="aic/urm-training"
TAG="${1:-latest}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

POD_NAME="urm-build-image"

echo "=== Building URM Image on ICE ==="
echo "Target: ${FULL_IMAGE}"
echo ""

# Check if build pod exists
if kubectl get pod "$POD_NAME" -n "$ICE_NAMESPACE" &>/dev/null; then
    echo "Build pod already exists. Deleting..."
    kubectl delete pod "$POD_NAME" -n "$ICE_NAMESPACE" --wait
fi

# Create build context tarball
echo "Creating build context..."
cd "$SCRIPT_DIR/.."
tar -czf /tmp/urm-build-context.tar.gz \
    --exclude='.git' \
    --exclude='data' \
    --exclude='checkpoints' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    ice/Dockerfile \
    requirements.txt

echo "Starting Kaniko build pod..."
cat <<EOF | kubectl apply -n "$ICE_NAMESPACE" -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args:
    - "--dockerfile=ice/Dockerfile"
    - "--context=tar:///workspace/context.tar.gz"
    - "--destination=${FULL_IMAGE}"
    - "--cache=true"
    volumeMounts:
    - name: build-context
      mountPath: /workspace
    - name: docker-config
      mountPath: /kaniko/.docker
  restartPolicy: Never
  volumes:
  - name: build-context
    emptyDir: {}
  - name: docker-config
    secret:
      secretName: regcred
      optional: true
EOF

echo ""
echo "Copying build context to pod..."
kubectl wait --for=condition=Ready pod/$POD_NAME -n "$ICE_NAMESPACE" --timeout=60s 2>/dev/null || true
kubectl cp /tmp/urm-build-context.tar.gz "$ICE_NAMESPACE/$POD_NAME:/workspace/context.tar.gz"

echo ""
echo "Build started. Monitor with:"
echo "  kubectl logs -f $POD_NAME -n $ICE_NAMESPACE"
echo ""
echo "When complete, update ice/train.sh to use:"
echo "  image: ${FULL_IMAGE}"
