#!/bin/bash
# URM Training on ICE
# Usage: ./ice/train.sh <experiment_name> [gpu_type] [gpu_count] [extra_args...]
#
# Examples:
#   ./ice/train.sh arcagi1-exp1
#   ./ice/train.sh arcagi1-exp2 nvidia-h100 2
#   ./ice/train.sh arcagi1-exp3 nvidia-gtx-2080ti 4 "arch=urm_large batch_size=16"

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Arguments
EXP_NAME="${1:-urm-training}"
GPU_TYPE="${2:-$ICE_DEFAULT_GPU}"
GPU_COUNT="${3:-$ICE_DEFAULT_GPU_COUNT}"
EXTRA_ARGS="${4:-}"

POD_NAME="${ICE_POD_PREFIX}-${EXP_NAME}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== URM Training on ICE ===${NC}"
echo "Experiment: $EXP_NAME"
echo "GPU: ${GPU_COUNT}x ${GPU_TYPE}"
echo "Pod: $POD_NAME"
echo ""

# Check if pod already exists
if kubectl get pod "$POD_NAME" -n "$ICE_NAMESPACE" &>/dev/null; then
    echo -e "${YELLOW}Pod $POD_NAME already exists.${NC}"
    echo "Options:"
    echo "  1. Attach: ./ice/shell.sh $EXP_NAME"
    echo "  2. Delete: ./ice/stop.sh $EXP_NAME"
    exit 1
fi

# Calculate resources based on GPU count
CPU_REQUEST=$((GPU_COUNT * 4))000m
MEM_REQUEST=$((GPU_COUNT * 16))Gi

echo -e "${YELLOW}Creating pod...${NC}"

cat <<EOF | kubectl apply -n "$ICE_NAMESPACE" -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
  labels:
    app: urm
    experiment: ${EXP_NAME}
spec:
  imagePullSecrets:
  - name: urm-registry-cred
  containers:
  - name: urm
    image: registry.ice.ri.se/aic-misc/urm-training:latest
    command:
    - /bin/bash
    - -c
    - |
      echo "=== URM Training Environment Ready ==="
      echo "To start training:"
      echo "  cd /workspace && python pretrain.py ${EXTRA_ARGS}"
      sleep infinity
    resources:
      requests:
        cpu: "${CPU_REQUEST}"
        memory: "${MEM_REQUEST}"
        nvidia.com/gpu: "${GPU_COUNT}"
      limits:
        memory: "${MEM_REQUEST}"
        nvidia.com/gpu: "${GPU_COUNT}"
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    - name: data
      mountPath: /data
    - name: checkpoints
      mountPath: /checkpoints
    - name: dshm
      mountPath: /dev/shm
    env:
    - name: CUDA_VISIBLE_DEVICES
      value: "$(seq -s, 0 $((GPU_COUNT-1)))"
    - name: WANDB_MODE
      value: "online"
    - name: WANDB_API_KEY
      value: "${WANDB_API_KEY}"
  volumes:
  - name: workspace
    emptyDir: {}
  - name: data
    emptyDir: {}
  - name: checkpoints
    emptyDir: {}
  - name: dshm
    emptyDir:
      medium: Memory
      sizeLimit: 64Gi
  nodeSelector:
    accelerator: ${GPU_TYPE}
  restartPolicy: Never
EOF

echo ""
echo -e "${YELLOW}Waiting for pod to start...${NC}"
kubectl wait --for=condition=Ready pod/$POD_NAME -n "$ICE_NAMESPACE" --timeout=300s

echo ""
echo -e "${GREEN}Pod ready!${NC}"
echo ""
echo "Next steps:"
echo "  1. Sync code:  ./ice/sync.sh $EXP_NAME"
echo "  2. Shell in:   ./ice/shell.sh $EXP_NAME"
echo "  3. View logs:  ./ice/logs.sh $EXP_NAME"
echo "  4. Stop:       ./ice/stop.sh $EXP_NAME"
