# Week 6, Day 38
# Converts the trained scikit-learn model to TensorFlow Lite for on-device
# inference via tflite_flutter. sklearn models don't convert directly, so
# the usual path is: re-implement the trained model's logic (weights) as a
# tiny tf.keras model, or train an equivalent model directly in tf.keras.
#
# If this step stalls, fall back to the documented heuristic formula instead
# (see TaleemPlus_60Day_Plan.md, Week 6 fallback note) rather than losing
# days here — it's a legitimate, documentable design decision.

import tensorflow as tf

# TODO: build a tf.keras.Sequential model matching the trained sklearn
# logistic regression's input shape (3 features) and copy over the learned
# weights, OR retrain directly in tf.keras on the same dataset.

# Example skeleton:
# model = tf.keras.Sequential([
#     tf.keras.layers.Dense(8, activation="relu", input_shape=(3,)),
#     tf.keras.layers.Dense(1, activation="sigmoid"),
# ])
# model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
# model.fit(X_train, y_train, epochs=20)

# converter = tf.lite.TFLiteConverter.from_keras_model(model)
# tflite_model = converter.convert()
# with open("../assets/ml_models/risk_model.tflite", "wb") as f:
#     f.write(tflite_model)

print("Fill in the TODOs above once train_risk_model.py produces a working model.")
