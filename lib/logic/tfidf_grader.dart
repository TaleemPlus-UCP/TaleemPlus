import 'dart:math' show log, sqrt;

/// Scores a student's OCR'd answer against a question's grading keywords
/// via TF-IDF weighted cosine similarity, instead of a binary "does the
/// text contain this keyword" ratio. No training data or external corpus
/// needed — the quiz's own question set (each question's keyword list
/// treated as one document) supplies the corpus for IDF weighting, so
/// keywords that are common across many questions in the same quiz count
/// for less than keywords that are distinctive to one question.
class TfIdfGrader {
  /// [corpusKeywordSets]: the gradingKeywords list from every gradable
  /// question in the quiz, used only to compute IDF weights.
  static double score({
    required List<String> keywords,
    required String answerText,
    required List<List<String>> corpusKeywordSets,
  }) {
    final cleanKeywords = keywords.map((k) => k.toLowerCase().trim()).toSet();
    if (cleanKeywords.isEmpty) return 0.0;

    final answerTermFreq = <String, int>{};
    for (final w in _tokenize(answerText)) {
      answerTermFreq[w] = (answerTermFreq[w] ?? 0) + 1;
    }

    final n = corpusKeywordSets.isEmpty ? 1 : corpusKeywordSets.length;

    var dot = 0.0;
    var refMagnitude = 0.0;
    var answerMagnitude = 0.0;

    for (final kw in cleanKeywords) {
      final docFreq = corpusKeywordSets
          .where((doc) => doc.map((k) => k.toLowerCase()).contains(kw))
          .length
          .clamp(1, n);
      // +1 keeps idf strictly positive even when the keyword appears in
      // every document in the corpus (docFreq == n).
      final idf = log(n / docFreq) + 1;

      const refTf = 1.0; // each keyword appears once in its own "document"
      final answerTf = (answerTermFreq[kw] ?? 0).toDouble();

      final refWeight = refTf * idf;
      final answerWeight = answerTf * idf;

      dot += refWeight * answerWeight;
      refMagnitude += refWeight * refWeight;
      answerMagnitude += answerWeight * answerWeight;
    }

    if (refMagnitude == 0 || answerMagnitude == 0) return 0.0;
    final similarity = dot / (sqrt(refMagnitude) * sqrt(answerMagnitude));
    return similarity.clamp(0.0, 1.0);
  }

  static List<String> _tokenize(String text) => text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.isNotEmpty)
      .toList();
}
