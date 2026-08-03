# Week 6, Day 36-37
# Trains the fee-delay-risk and performance-index models described in the SDS.
# Run OUTSIDE the Flutter app (plain Python), then paste the printed
# coefficients into lib/logic/fee_risk_model.dart and
# lib/logic/performance_index_model.dart — see those files for why a plain
# Dart port replaced the original TFLite plan.
#
# Usage:
#   pip install -r requirements.txt
#   python generate_synthetic_data.py   # only needed to regenerate the CSV
#   python train_risk_model.py
#
# Expected data/synthetic_dataset.csv columns:
#   attendance_rate (0-1), days_late_avg, late_payment_count,
#   quiz_avg (0-100) -> fee_delay_risk (0/1), performance_index (0-100)

import pandas as pd
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, mean_absolute_error


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


def train_performance_index_model(df: pd.DataFrame) -> LinearRegression:
    X = df[["quiz_avg", "attendance_rate", "late_payment_count"]]
    y = df["performance_index"]
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    model = LinearRegression()
    model.fit(X_train, y_train)

    preds = model.predict(X_test)
    print(f"Performance-index model MAE: {mean_absolute_error(y_test, preds):.2f}")
    return model


def print_dart_coefficients(model, feature_names: list[str], label: str) -> None:
    print(f"\n--- Dart port ({label}) ---")
    coef = model.coef_[0] if model.coef_.ndim > 1 else model.coef_
    intercept = model.intercept_[0] if hasattr(model.intercept_, "__len__") else model.intercept_
    for name, w in zip(feature_names, coef):
        print(f"  {name}: {w:.6f}")
    print(f"  intercept: {intercept:.6f}")


if __name__ == "__main__":
    dataset = load_data()

    risk_model = train_fee_risk_model(dataset)
    print_dart_coefficients(
        risk_model,
        ["attendance_rate", "days_late_avg", "late_payment_count"],
        "lib/logic/fee_risk_model.dart",
    )

    performance_model = train_performance_index_model(dataset)
    print_dart_coefficients(
        performance_model,
        ["quiz_avg", "attendance_rate", "late_payment_count"],
        "lib/logic/performance_index_model.dart",
    )
