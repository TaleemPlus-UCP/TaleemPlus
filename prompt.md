# TaleemPlus — "AI" Prompts & Heuristics

## 1. Important framing

TaleemPlus makes no calls to a cloud LLM (no OpenAI/Gemini/Claude/etc. API usage anywhere in `lib/`) and has no locally-loaded trained model (`tflite_flutter` is commented out in `pubspec.yaml`; `assets/ml_models/` is an empty declared asset folder). Every feature marketed as "AI" in the README and in-app UI is one of:

1. **Google ML Kit on-device OCR** (`google_mlkit_text_recognition`) — genuine on-device deep learning, used purely for text extraction from images.
2. **Hand-written heuristic/rule-based Dart logic** — deterministic string/regex/keyword rules that play the role an LLM prompt would play in a cloud-AI version of this app.

This document treats each heuristic as if it were the "prompt" or instruction set driving that feature — i.e. it specifies, in plain language, exactly what each "AI" module does, so it can be read, explained, and defended in an FYP report the same way a prompt library would be for an LLM-backed app. See [phases.md](phases.md) for why a planned TFLite model was replaced by these heuristics.

All four heuristic features share the same two-stage pipeline: **image → ML Kit OCR → heuristic post-processing**.

## 2. AI Smart Grader

**Screen**: `lib/features/quiz/screens/ai_paper_grader_screen.dart`
**Scope**: only questions of type "Short Answer" or "Long Answer" are eligible (MCQs are excluded from AI grading since they're auto-scored by option index, not keyword matching).

**"Prompt" (grading rule), in plain language:**

> Given a student's handwritten answer (photographed and OCR'd) and a question's teacher-authored `gradingKeywords` list, count how many keywords appear anywhere in the lower-cased OCR text (`rawText.contains(keyword)`), then award a score proportional to the fraction of keywords matched.

**Formula:**
```
matches   = count(keyword in gradingKeywords if rawText.toLowerCase().contains(keyword))
suggested = question.marks * (matches / gradingKeywords.length)
```

**Pipeline:**
1. Teacher selects a student + the quiz's short-answer questions.
2. Teacher photographs the answer sheet (camera capture; `SessionProvider.suppressBackgroundLogout()` wraps this so the camera doesn't trigger the auto-logout — see [security.md](security.md)).
3. Fresh `TextRecognizer().processImage()` extracts text; lower-cased.
4. The formula above computes a suggested score per question.
5. Teacher reviews (sees the detected OCR text + suggested score per question) and can adjust before approving.
6. "APPROVE & SAVE MARKS" sums all question scores into a `TestMarkModel`, computes percentage and grade letter, and persists via `QuizProvider.uploadBulkMarks`.

**Grading keywords are teacher-authored**: entered as a comma-separated list per question when creating a quiz (`_AddQuestionSheet` in `create_quiz_screen.dart`) — the teacher is effectively writing the "answer key" the heuristic grades against.

**Known limitation** (worth noting in an FYP report): this is a bag-of-keywords match, not semantic understanding — a student who expresses the right idea in different words scores low, and a student who pads their answer with buzzwords without understanding scores high. There is no partial-credit-for-partial-correctness beyond the keyword-count ratio.

## 3. AI Test Generator

**Screen**: `lib/features/quiz/screens/create_quiz_screen.dart` (invoked as `CreateQuizScreen(isAiGen: true)`)

**"Prompt" (blueprint-analysis rule):**

> Given OCR'd text from a photographed textbook page, estimate an appropriate difficulty level and question-count breakdown, then generate draft questions from sentence-level patterns in the text.

**Step 1 — difficulty & count estimation** (`_analyzeContentAndShowRecommendations`):
```
difficulty:
  wordCount < 100                                        → "Easy"
  contains "law" | "theorem" | "equation" | wordCount>500 → "Hard"
  else                                                     → "Medium"

suggested counts:
  mcqCount   = clamp(wordCount / 40, 3, 15)
  shortCount = clamp(lineCount / 4, 2, 10)
  longCount  = wordCount > 300 ? 2 : 1
```
These suggested counts are shown to the teacher in an "AI Test Blueprint" dialog and can be adjusted before generation.

**Step 2 — question generation** (`_generateQuestionsLocally`): the OCR text is first rejoined into one blob and re-split on sentence terminators (`.`, `?`, `!`) — ML Kit returns one line per *visual* line, not per sentence, so heuristics run on reconstructed sentences instead of raw line breaks. Three heuristics then run in order, each consuming sentences the previous one didn't use, so the same sentence never becomes two questions:

| Question type | Trigger rule | Generated form |
|---|---|---|
| MCQ | sentence contains `" is "` or `" refers to "` | Split on the matched phrase → "What is/refers to `<term>`?" with the term as the correct option plus 3 fixed distractors ("None of the above", "Both A and B", "Incorrect definition"); `correctIndex` is always the first option |
| Long answer (`QuestionType.long`) | remaining sentences ≥ 80 chars, longest first | "Discuss in detail the following concept: `<first 60 chars>`…" (5 marks) |
| Short answer (`QuestionType.short`) | remaining sentences, no `?` | "Briefly explain: `<sentence>`" (2 marks) |

Generated questions are merged into the same manual question builder used for hand-authored questions, so a teacher can freely mix AI-suggested and manually-written questions (including manually adding `gradingKeywords` for the Smart Grader to later use) before saving the quiz. The AI Smart Grader (§2) now accepts both Short and Long Answer questions.

**Known limitation**: the MCQ distractors are generic filler text, not plausible wrong answers derived from the source material — a student with no knowledge of the topic can often eliminate 3 of 4 options by pattern-matching the distractor wording alone.

## 4. AI Notes Summarizer

**Screen**: `lib/features/student/screens/ai_summarizer_screen.dart` (student portal), explicitly labeled in-UI "100% OFFLINE. NO INTERNET REQUIRED."

**"Prompt" (extractive-summary rule), in plain language:**

> Given OCR'd notes text, classify each line as either a "definition" or a "key point" using simple lexical cues, then render the top few of each under fixed headings.

**Rule** (`_generateLocalSummary`):
```
for each line in ocrText.split('\n'):
  if line contains " is " or ":"          → classify as "Definition"
  else if len(line) < 50 and (line.isAllCaps or line.endsWith('.')) → classify as "Key Point"

output:
  "📖 KEY DEFINITIONS" — first 5 definitions found
  "💡 IMPORTANT POINTS" — first 8 key points found
```

This is pure line-classification and truncation — no actual abstraction, paraphrasing, or compression of meaning happens; it is closer to "extract lines matching a pattern" than summarization in the NLP sense. Framing it accurately (extractive heuristic, not generative/abstractive) is important for an FYP report's "limitations" section.

## 5. Admin AI Insights (At-Risk Prediction & Revenue Forecast)

**Screen**: `lib/features/admin/admin_ai_prediction_screen.dart` ("AI Insights & Predictions", "OFFLINE INTELLIGENCE ACTIVE" badge)
**Logic**: `lib/logic/admin_ai_provider.dart`

Unlike the other three features, this one involves **no OCR and no image input** — it's pure aggregation over existing Firestore data (`test_marks`, `fee_challans`).

### At-risk student prediction (`_analyzePerformance`)

**"Prompt" (rule):**

> Given every test-mark record for the academy, compute each student's average percentage across all their marks. Any student averaging below 50% is "at risk." Also report the academy-wide average and the single weakest subject (lowest average percentage across all subjects).

```
per-student average = mean(TestMarkModel.percentage for all marks by that student)
at-risk             = student where per-student average < 50
weakest subject     = subject with lowest average percentage across all marks
```

This was originally planned to be a trained classification model (see [phases.md](phases.md) — the commented-out `tflite_flutter` dependency and the unfinished `ml_training/` pipeline) but ships as a fixed threshold instead.

### Revenue forecast (`_analyzeRevenue`)

**"Prompt" (rule):**

> Given every fee challan for the academy, compute how much of what's owed has actually been collected, and project next month's revenue as roughly similar to the current total owed, discounted by a fixed on-time-payment rate.

```
collectionEfficiency = totalPaid / totalPayable * 100
pendingAmount         = totalPayable - totalPaid
projectedRevenue      = totalPayable                      # "next month expected similar to current setup"
predictedCollection    = projectedRevenue * 0.85            # UI-level heuristic: "85% usually pay on time"
```

No time-series or regression modeling — the forecast is a naive same-as-current-total projection with one fixed discount factor.

## 6. Why this document exists

For an FYP evaluation, it's important to be able to explain precisely what "AI" means in this app: real on-device deep learning (ML Kit OCR) feeding into transparent, explainable, hand-authored rules — not black-box machine learning. This is a defensible design (explainable, deterministic, works fully offline, requires no training data or GPU), and this document is the reference for exactly what each rule does, so it can be presented, defended, or extended (e.g. replacing §5's threshold with a real trained model per the future-work note in [phases.md](phases.md)) with full clarity about the current baseline.
