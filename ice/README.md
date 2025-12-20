# URM on ICE Datacenter

Tools for running URM training on the ICE GPU cluster at RISE.

## Prerequisites

1. **kubectl configured** for ICE cluster
   ```bash
   # Check connection
   kubectl get nodes
   ```

2. **Namespace access** to `aic`
   ```bash
   kubectl config set-context --current --namespace=aic
   ```

## Quick Start

```bash
# 1. Check available GPUs
./ice/gpus.sh

# 2. Launch training pod
./ice/train.sh arcagi1-exp1 nvidia-gtx-2080ti 2

# 3. Sync code to pod
./ice/sync.sh arcagi1-exp1

# 4. Shell into pod and start training
./ice/shell.sh arcagi1-exp1
# Inside pod:
cd /workspace
python pretrain.py arch=urm

# 5. Check status
./ice/status.sh

# 6. Stop when done (important - stops billing!)
./ice/stop.sh arcagi1-exp1
```

## Available Commands

| Command | Description |
|---------|-------------|
| `./ice/train.sh <name> [gpu_type] [count]` | Launch training pod |
| `./ice/sync.sh <name>` | Sync code to pod |
| `./ice/shell.sh <name>` | Shell into pod |
| `./ice/logs.sh <name>` | View pod logs |
| `./ice/status.sh` | Check all URM pods |
| `./ice/stop.sh <name>` | Stop pod (stop billing!) |
| `./ice/gpus.sh` | List available GPUs |

## GPU Recommendations

| Experiment | GPU Type | Count | Estimated VRAM |
|------------|----------|-------|----------------|
| URM small batch | nvidia-gtx-2080ti | 1 | ~8GB |
| URM standard | nvidia-gtx-2080ti | 2 | ~16GB |
| URM large batch | nvidia-gtx-2080ti | 4 | ~32GB |
| URM XL / multi-node | nvidia-h100 | 2+ | ~180GB+ |

## Billing

**You are billed for running pods!**

- Check status: `./ice/status.sh`
- Stop billing: `./ice/stop.sh <name>`
- Pods with `sleep infinity` still bill - delete when not using!

## Persistent Data

By default, pods use `emptyDir` volumes (deleted with pod). For persistent storage, modify `ice/train.sh` to use PVC.

## Custom Docker Image

To avoid installing dependencies on each pod launch, build a custom image:

```bash
# On a machine with Docker
cd ice/
docker build -t registry.ice.ri.se/aic/urm-training:latest .
docker push registry.ice.ri.se/aic/urm-training:latest

# Then update train.sh to use this image instead of pytorch/pytorch:...
```

The Dockerfile includes:
- PyTorch 2.4 + CUDA 12.4
- flash-attn (pre-compiled)
- adam-atan2
- All other dependencies (wandb, einops, hydra, etc.)

## Troubleshooting

```bash
# Pod won't start
kubectl describe pod urm-<name> -n aic

# Check GPU allocation
kubectl exec urm-<name> -- nvidia-smi

# Check logs
./ice/logs.sh <name>
```
