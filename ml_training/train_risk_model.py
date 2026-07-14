# Week 6, Day 36-37
# Trains the fee-delay-risk and performance-index models described in the SDS.
# Run this OUTSIDE the Flutter app (plain Python), then export with export_tflite.py.
#
# Usage:
#   pip install -r requirements.txt
#   python train_risk_model.py

import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# TODO: replace with data/synthetic_dataset.csv once you've generated it.
# Expected columns:
#   attendance_rate (0-1), days_late_avg, late_payment_count,
#   quiz_avg (0-100) -> fee_delay_risk (0/1), performance_index (0-100)

def load_data(path: str = "data/synthetic_dataset.csv") -> pd.DataFrame:
    return pd.read_csv(path)


def train_fee_risk_model(df: pd.DataFrame) -> LogisticRegression:
    X = df[["attendance_rate", "days_late_avg", "late_payment_count"]]
    y = df["fee_delay_risk"]
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = LogisticRegression()
    model.fit(X_train, y_train)

    preds = model.predict(X_test)
    print(f"Fee-delay risk model accuracy: {accuracy_score(y_test, preds):.2f}")
    return model


if __name__ == "__main__":
    dataset = load_data()
    risk_model = train_fee_risk_model(dataset)

    # TODO: also train a performance_index regression model the same way.
    # TODO: save both with joblib, then convert to TFLite in export_tflite.py.
    # If the sklearn -> TFLite conversion path gets messy, fall back to the
    # documented heuristic formula (see TaleemPlus_60Day_Plan.md, Week 6 note).
