# TaleemPlus AI/ML Audit

## Scope and count

**Four unique implemented statistical/ML-style algorithms** were found. Two are coefficient based predictors, one is an unsupervised graph-ranking summarizer, and one is an in-quiz TF-IDF similarity scorer. The same TextRank implementation is also reused to rank sentences for AI paper generation; that is a second use, not a fifth model. No locally stored serialized model file or active TFLite model was found.

| Status | Count | Meaning |
|---|---:|---|
| Implemented algorithms | 4 | All run in Dart in the app. |
| Trained on real academy data | 0 | No real-data fit or evaluation evidence is present. |
| Coefficient models with synthetic-training provenance claimed in comments | 2 | Fixed coefficients are embedded in Dart; the referenced trainer is absent in this checkout. |
| Incomplete/planned model pipeline | 1 plan | TFLite conversion is described in historical project notes, but no export script, model asset, or active runtime is present. This is not an additional unique model. |

## Model-wise findings

| Model / purpose | Implementation and application path | Algorithm, inputs → output | Training and data assessment |
|---|---|---|---|
| Fee-delay risk | [fee_risk_model.dart](lib/logic/fee_risk_model.dart), called from [admin_ai_provider.dart](lib/logic/admin_ai_provider.dart) | Logistic-regression equation (dot product + sigmoid); attendance rate, average days late, late payment count → risk probability and boolean at 0.5 threshold | Inference is implemented with fixed hardcoded coefficients. The Dart comments claim sklearn coefficients trained from the local synthetic CSV, but [train_risk_model.py](ml_training/train_risk_model.py) is absent in this checkout, so the fit and metrics cannot be reproduced or verified. No real academy training data is evidenced. Connected to the admin insights flow, which fetches academy challans and attendance. |
| Performance index | [performance_index_model.dart](lib/logic/performance_index_model.dart), called from [admin_ai_provider.dart](lib/logic/admin_ai_provider.dart) | Linear regression equation; quiz average, attendance rate, late payment count → predicted index clamped to 0–100 | Inference uses fixed hardcoded coefficients. Comments claim the same missing sklearn training script and synthetic CSV provenance. It consumes actual academy marks, attendance, and challans when available in the running app, but those records are inference inputs, not evidence that this model was trained on them. |
| Notes summarizer / paper sentence ranking | [text_rank_summarizer.dart](lib/logic/text_rank_summarizer.dart), used by [ai_summarizer_screen.dart](lib/features/student/screens/ai_summarizer_screen.dart) and [create_quiz_screen.dart](lib/features/quiz/screens/create_quiz_screen.dart) | Extractive TextRank: sentence overlap graph + iterative PageRank-style scoring; OCR text → ranked/select sentences | Implemented, unsupervised and untrained. Uses the current user's OCR text at runtime, not a learned model or training corpus. This is a deterministic NLP algorithm. |
| Paper answer grader | [tfidf_grader.dart](lib/logic/tfidf_grader.dart), used by [ai_paper_grader_screen.dart](lib/features/quiz/screens/ai_paper_grader_screen.dart) | TF-IDF weighted cosine similarity; teacher-entered grading keywords, OCR answer text, and other quiz keyword sets → similarity score used to suggest marks | Implemented, no learned model or external corpus. IDF corpus is assembled from the current quiz's grading keywords. This is a deterministic text-similarity scorer, not a trained predictor. |

## Other AI-labeled behavior (not additional ML models)

- Student success risk and weakest-subject insights in [admin_ai_provider.dart](lib/logic/admin_ai_provider.dart) are threshold/aggregation rules (for example, average marks below 50), not model inference.
- Revenue “forecasting” sets projected revenue equal to the current challan total. It is a fixed heuristic, not a trained time-series model.
- Quiz difficulty in [create_quiz_screen.dart](lib/features/quiz/screens/create_quiz_screen.dart) is assigned by word-count/complex-marker thresholds, not a learned classifier.
- AI paper generation uses OCR, TextRank-ranked sentences, and templates/rules. It does not call a generative language model.
- No AI/ML inference API endpoint or OpenAI/Gemini call was found in the app's relevant implementation. No model artifact (`.pkl`, `.joblib`, `.h5`, `.keras`, `.pt`, `.pth`, `.tflite`, or `.onnx`) was found. `assets/ml_models/placeholder.txt` is only a placeholder.

## Training data and readiness

### Local dataset

`ml_training/data/synthetic_dataset.csv` contains **800 rows** and six columns: `attendance_rate`, `days_late_avg`, `late_payment_count`, `quiz_avg`, `fee_delay_risk`, and `performance_index`. The inspected file has no blank values. Its risk label has 239 positive and 561 negative rows. These counts do not make it real training data: [generate_synthetic_data.py](ml_training/generate_synthetic_data.py) constructs all features and targets from seeded random distributions and hand-set formulas with noise. It is explicitly synthetic. There is no separate real academy training dataset in the repository.

The dataset is adequate to execute a basic demonstration fit for the two tabular algorithms, but not to validate generalization to real students. There is no documented real-data sample size, historical observation period, label audit, or leakage/holdout evaluation on real academy records. The trainer referenced in Dart comments is not present, so its reported metrics, exact fit, preprocessing, and relationship to the checked-in coefficients cannot be verified.

### Academy data available in application code

The app has pathways for actual attendance, test marks, and fee challans through [attendance_repository.dart](lib/data/repositories/attendance_repository.dart), [quiz_service.dart](lib/data/remote/quiz_service.dart), and [fee_challan_repository.dart](lib/data/repositories/fee_challan_repository.dart). The backend also defines these record types in [schema.prisma](taleemplus_backend/prisma/schema.prisma) and exposes attendance, quiz/mark, and fee handlers under `taleemplus_backend/src/controllers/`. `AdminAiProvider` combines these for per-academy inference. The codebase shows that the app can store/read these records, but this audit did not connect to a deployed database; it therefore cannot establish whether real records exist, their volume/history, completeness, or label quality. No local database export or seed dataset with real records was found. No student personal records were accessed or included in this report.

### What can be trained now

- The fee-risk logistic regression and performance linear regression are mechanically trainable on the **synthetic CSV only**, if a compatible training script/dependencies are restored. Such a fit would remain synthetic and should not be represented as validated on academy data.
- TextRank and the TF-IDF scorer are algorithmic inference methods; they do not have a model-training step.
- No model can be responsibly claimed as trained/validated on real academy data based on the checked-in files and accessible evidence.

### What needs real data

- Fee-delay risk needs privacy-safe historical attendance and fee events aligned to a clearly defined prediction date and a future delay outcome label. Avoid counting future outcomes in prediction-time inputs.
- Performance prediction needs longitudinal marks and attendance features paired with a later, explicitly defined performance target. Fee payment count should be justified as a predictor and time-aligned.
- Real-data row counts, missingness, class balance, duplicates, label consistency, student/time splits, and held-out performance must be assessed before claiming these models are ready.
- TextRank and keyword similarity do not need training data, but their output quality needs representative textbook OCR and teacher-reviewed grading examples if product accuracy claims are desired.

## Recommended next steps

1. Treat the two Dart coefficient predictors as synthetic-data demonstrations until their training provenance is reproducible and independently evaluated.
2. Confirm whether the deployed academy database contains enough historical attendance, marks, and fee outcomes; export only de-identified/minimized fields for analysis.
3. Define prediction targets, observation windows, and leakage-safe evaluation splits before fitting on real data.
4. Restore or replace the missing training script and record dataset source, preprocessing, split, metrics, and coefficient/artifact version together.
5. If TFLite remains a goal, first decide whether the app should use it: current app code uses Dart formulas, `pubspec.yaml` has no active `tflite_flutter` dependency, and this checkout contains no `export_tflite.py` or generated model asset.
6. Describe the current threshold, revenue, summarization, and grading features accurately as rules/statistical algorithms where appropriate; do not label synthetic-only coefficients as trained on real academy data.

## Final count summary

- **Total unique implemented algorithms/models:** 4.
- **Genuinely trained on real academy data:** 0 evidenced.
- **Untrained algorithms:** 2 (TextRank and TF-IDF similarity; they are designed not to require training).
- **Fixed coefficient predictors with synthetic provenance claimed, but training not reproducible in this checkout:** 2.
- **Models needing real data for real-world training/validation:** 2 (fee-delay risk and performance index).
- **TFLite:** planned/incomplete pipeline only; not a separate model and not connected to the application.
