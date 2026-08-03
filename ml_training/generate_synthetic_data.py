# Week 6 — generates ml_training/data/synthetic_dataset.csv so
# train_risk_model.py has something to train on. The original dataset
# ships empty (header only); this fills it with a plausible academy
# population, tying fee_delay_risk and performance_index to the feature
# columns (with noise) so the trained model reflects a real relationship
# rather than random labels.
#
# Usage:
#   python generate_synthetic_data.py

import numpy as np
import pandas as pd

RNG = np.random.default_rng(42)
N = 800


def generate() -> pd.DataFrame:
    attendance_rate = np.clip(RNG.beta(a=6, b=2, size=N), 0.3, 1.0)
    days_late_avg = np.clip(RNG.gamma(shape=1.5, scale=2.0, size=N), 0, 30)
    late_payment_count = np.clip(
        RNG.poisson(lam=1.2, size=N) + (days_late_avg > 10).astype(int), 0, 12
    )
    quiz_avg = np.clip(
        55 + 30 * attendance_rate - 1.5 * late_payment_count
        + RNG.normal(0, 8, size=N),
        0, 100,
    )

    risk_score = (
        -1.5
        - 4.0 * (attendance_rate - 0.7)
        + 0.18 * days_late_avg
        + 0.55 * late_payment_count
        + RNG.normal(0, 0.6, size=N)
    )
    fee_delay_risk = (risk_score > 0).astype(int)

    performance_index = np.clip(
        0.6 * quiz_avg + 40 * attendance_rate - 3 * late_payment_count
        + RNG.normal(0, 5, size=N),
        0, 100,
    )

    return pd.DataFrame({
        "attendance_rate": attendance_rate.round(3),
        "days_late_avg": days_late_avg.round(2),
        "late_payment_count": late_payment_count.astype(int),
        "quiz_avg": quiz_avg.round(1),
        "fee_delay_risk": fee_delay_risk,
        "performance_index": performance_index.round(1),
    })


if __name__ == "__main__":
    df = generate()
    df.to_csv("data/synthetic_dataset.csv", index=False)
    print(f"Wrote {len(df)} rows to data/synthetic_dataset.csv")
    print(f"fee_delay_risk positive rate: {df['fee_delay_risk'].mean():.2%}")
