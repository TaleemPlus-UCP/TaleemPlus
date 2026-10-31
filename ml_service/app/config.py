import os
from pathlib import Path


DATABASE_URL = os.getenv("DATABASE_URL", "")
INTERNAL_TOKEN = os.getenv("ML_INTERNAL_TOKEN", "")
ARTIFACT_DIR = Path(os.getenv("ML_ARTIFACT_DIR", "./artifacts"))
MIN_FEE_SAMPLES = int(os.getenv("ML_MIN_FEE_SAMPLES", "100"))
MIN_PERFORMANCE_SAMPLES = int(os.getenv("ML_MIN_PERFORMANCE_SAMPLES", "100"))
RETRAIN_INTERVAL_HOURS = int(os.getenv("ML_RETRAIN_INTERVAL_HOURS", "24"))
