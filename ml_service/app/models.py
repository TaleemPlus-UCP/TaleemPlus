from pathlib import Path
import json

import joblib


def load_production(root: Path, academy_key: str, model_name: str):
    folder = root / academy_key / model_name
    pointer = folder / "production.json"
    if not pointer.is_file():
        return None
    version = json.loads(pointer.read_text(encoding="utf-8"))["version"]
    directory = folder / version
    metadata = json.loads((directory / "metadata.json").read_text(encoding="utf-8"))
    return joblib.load(directory / "pipeline.joblib"), metadata
