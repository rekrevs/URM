# URM - Universal Reasoning Model

> Universal Transformer for ARC-AGI reasoning tasks, achieving SOTA 53.8% pass@1 on ARC-AGI 1.

## Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Login to Wandb (for experiment tracking)
wandb login YOUR_API_KEY

# Prepare data (example for ARC-AGI-1)
python -m data.build_arc_dataset \
  --input-file-prefix kaggle/combined/arc-agi \
  --output-dir data/arc1concept-aug-1000 \
  --subsets training evaluation concept \
  --test-set-name evaluation
```

## Tech Stack

- **Language**: Python 3.x
- **Framework**: PyTorch + Triton (custom CUDA kernels)
- **Experiment Tracking**: Weights & Biases (wandb)
- **Config**: Hydra + OmegaConf
- **Key Libraries**: einops, numba, adam-atan2

## Project Structure

```
URM/
├── models/               # Model architectures
│   ├── urm/              # Universal Reasoning Model
│   ├── hrm/              # Hybrid Reasoning Model
│   ├── trm/              # Transformer baseline
│   ├── layers.py         # Custom layers
│   ├── losses.py         # Loss functions
│   └── muon.py           # Muon optimizer
├── config/               # Hydra config files
│   ├── arch/             # Architecture configs
│   ├── cfg_pretrain.yaml
│   └── cfg_eval.yaml
├── evaluators/           # Evaluation code
│   └── arc.py            # ARC evaluation
├── data/                 # Generated datasets
├── kaggle/               # Raw ARC data
├── scripts/              # Training scripts
├── pretrain.py           # Main training entry
├── evaluate_trained_model.py  # Evaluation entry
└── puzzle_dataset.py     # Data loading
```

## Commands

```bash
# Training
python pretrain.py [hydra overrides]

# Evaluation
python evaluate_trained_model.py [args]

# Reproduce benchmarks
bash scripts/URM_arcagi1.sh   # ARC-AGI 1
bash scripts/URM_arcagi2.sh   # ARC-AGI 2
bash scripts/URM_sudoku.sh    # Sudoku
```

## Configuration

Training uses Hydra. Override configs via command line:
```bash
python pretrain.py arch=urm_base batch_size=32
```

See `config/` for available options.

## Verification

Before committing:
```bash
# Ensure code runs without import errors
python -c "from models.urm.urm import URM; print('OK')"

# Run a quick training sanity check (if data prepared)
python pretrain.py arch=urm max_steps=10
```

## Task Management

```bash
/wotan              # See active tasks
/wotan add "..."    # Create task
/wotan start T-NNNN # Start working
/wotan done T-NNNN  # Complete task
```
