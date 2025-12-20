# URM Training Image
# Base: PyTorch 2.4 with CUDA 12.4 (compatible with flash-attn and adam-atan2)
FROM pytorch/pytorch:2.4.0-cuda12.4-cudnn9-devel

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    wandb \
    einops \
    tqdm \
    hydra-core \
    omegaconf \
    numba \
    triton \
    pydantic \
    argdantic \
    coolname \
    packaging \
    ninja

# Install flash-attn (takes a while to compile)
RUN pip install --no-cache-dir flash-attn --no-build-isolation

# Install adam-atan2
RUN pip install --no-cache-dir adam-atan2

# Create workspace
WORKDIR /workspace

# Verify installations
RUN python -c "import torch; print('PyTorch:', torch.__version__); print('CUDA:', torch.cuda.is_available())"
RUN python -c "from flash_attn import flash_attn_func; print('flash-attn: OK')"
RUN python -c "from adam_atan2 import AdamATan2; print('adam-atan2: OK')"

CMD ["/bin/bash"]
