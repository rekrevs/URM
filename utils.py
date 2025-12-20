"""
Dynamic model loading utilities.

This module provides functions to dynamically load model classes based on
configuration strings in the format "module.path@ClassName".

Examples:
    - "urm.urm@URM" -> loads URM class from models/urm/urm.py
    - "losses@ACTLossHead" -> loads ACTLossHead from models/losses.py
    - "arc@ARC" with prefix "evaluators." -> loads ARC from evaluators/arc.py
"""

import importlib
import os
from typing import Optional


def load_model_class(name: str, prefix: str = "models.") -> type:
    """
    Dynamically load a class based on a configuration string.

    Args:
        name: A string in the format "module.path@ClassName" or just "ClassName".
              The module path uses dots to separate directories.
        prefix: Module prefix to prepend (default: "models.").
                Use "evaluators." for evaluator classes, "" for no prefix.

    Returns:
        The loaded class.

    Examples:
        >>> load_model_class("urm.urm@URM")  # loads models.urm.urm.URM
        >>> load_model_class("losses@ACTLossHead")  # loads models.losses.ACTLossHead
        >>> load_model_class("arc@ARC", prefix="evaluators.")  # loads evaluators.arc.ARC
    """
    if "@" in name:
        module_path, class_name = name.rsplit("@", 1)
    else:
        # If no @, assume the name is both module and class
        # e.g., "ARC" -> module "arc", class "ARC"
        class_name = name
        module_path = name.lower()

    # Build full module path
    full_module_path = f"{prefix}{module_path}" if prefix else module_path

    # Import the module
    try:
        module = importlib.import_module(full_module_path)
    except ModuleNotFoundError as e:
        raise ModuleNotFoundError(
            f"Could not import module '{full_module_path}' for class '{class_name}'. "
            f"Original name: '{name}', prefix: '{prefix}'. Error: {e}"
        ) from e

    # Get the class from the module
    if not hasattr(module, class_name):
        available = [attr for attr in dir(module) if not attr.startswith("_")]
        raise AttributeError(
            f"Module '{full_module_path}' has no class '{class_name}'. "
            f"Available attributes: {available}"
        )

    return getattr(module, class_name)


def get_model_source_path(name: str, prefix: str = "models.") -> Optional[str]:
    """
    Get the file system path to the source file for a model.

    Args:
        name: A string in the format "module.path@ClassName" or just "ClassName".
        prefix: Module prefix (default: "models.").

    Returns:
        The absolute path to the source file, or None if not found.

    Examples:
        >>> get_model_source_path("urm.urm@URM")
        '/path/to/models/urm/urm.py'
    """
    if "@" in name:
        module_path, _ = name.rsplit("@", 1)
    else:
        module_path = name.lower()

    # Build full module path
    full_module_path = f"{prefix}{module_path}" if prefix else module_path

    try:
        module = importlib.import_module(full_module_path)
    except ModuleNotFoundError:
        return None

    # Get the file path from the module
    if hasattr(module, "__file__") and module.__file__:
        return os.path.abspath(module.__file__)

    return None
