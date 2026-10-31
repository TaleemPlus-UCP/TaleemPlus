from datetime import date, timedelta

import numpy as np
import pandas as pd
import pytest

from app.models import load_production
from app.training.pipeline import InsufficientData, _time_split, train


def test_chronological_split_never_splits_same_date():
    frame = pd.DataFrame({"target_date": [date(2025, 1, 1)] * 4 + [date(2025, 1, 2)] * 3 + [date(2025, 1, 3)] * 3})
    train_rows, validation_rows = _time_split(frame, "target_date")
    assert max(train_rows.target_date) < min(validation_rows.target_date)


def test_training_refuses_small_datasets(tmp_path):
    with pytest.raises(InsufficientData):
        train("fee-risk", [], tmp_path, "academy-hash", minimum=20)


def test_fee_training_versions_artifact_and_promotes_validated_model(tmp_path):
    rows = []
    origin = date(2024, 1, 1)
    for day in range(80):
        label = day % 2
        rows.append({
            "issue_date": origin + timedelta(days=day), "attendance_pct": 90 - label * 70,
            "late_count": label * 3, "delay_avg": label * 10,
            "consistency": 1 - label, "outstanding": 1000, "label": label,
        })
    meta = train("fee-risk", rows, tmp_path, "academy-hash", minimum=40)
    assert meta["records"] == 80
    assert "roc_auc" in meta["metrics"]["metrics"]
    loaded = load_production(tmp_path, "academy-hash", "fee-risk")
    assert loaded is not None
    model, _metadata = loaded
    probability = model.predict_proba(pd.DataFrame([rows[0]]))[0, 1]
    assert 0 <= probability <= 1
    second = train("fee-risk", rows, tmp_path, "academy-hash", minimum=40)
    assert second["retrained"] is False


def test_failed_candidate_does_not_move_production_pointer(tmp_path):
    rows = []
    origin = date(2024, 1, 1)
    for day in range(80):
        label = day % 2
        rows.append({"issue_date": origin + timedelta(days=day), "attendance_pct": 90 - label * 70,
                     "late_count": label * 3, "delay_avg": label * 10, "consistency": 1 - label,
                     "outstanding": 1000, "label": label})
    first = train("fee-risk", rows, tmp_path, "academy-hash", minimum=40)
    pointer = tmp_path / "academy-hash" / "fee-risk" / "production.json"
    before = pointer.read_text(encoding="utf-8")
    bad_rows = [{**row, "issue_date": row["issue_date"] + timedelta(days=100), "label": 0}
                for row in rows]
    with pytest.raises(InsufficientData):
        train("fee-risk", bad_rows, tmp_path, "academy-hash", minimum=40)
    assert pointer.read_text(encoding="utf-8") == before
    assert first["status"] in {"PRODUCTION", "VALIDATED"}


def test_performance_training_reports_regression_metrics(tmp_path):
    rows = []
    origin = date(2024, 1, 1)
    for day in range(80):
        previous = float(day % 80)
        rows.append({"target_date": origin + timedelta(days=day), "prior_avg": previous,
                     "prior_count": 2, "attendance_pct": 80.0, "target": min(100.0, previous + 2)})
    meta = train("performance", rows, tmp_path, "academy-hash", minimum=40)
    assert {"mae", "rmse", "r2"}.issubset(meta["metrics"]["metrics"])
    assert np.isfinite(meta["metrics"]["metrics"]["rmse"])
