import 'dart:math' show log;

/// Offline, unsupervised extractive summarization (TextRank — Mihalcea &
/// Tarau, 2004). No training data or external corpus needed: sentences are
/// scored by how much they overlap with every other sentence in the same
/// document, then ranked via the same iterative algorithm PageRank uses for
/// web pages, treating "shared vocabulary" as a link between two sentences.
///
/// Replaces the previous heuristic (pick lines that are short/ALL-CAPS/end
/// with a period) which also suffered from splitting OCR text on raw '\n'
/// — ML Kit breaks lines on visual layout, not sentence boundaries, so that
/// heuristic often chopped sentences mid-thought. This operates on real
/// sentences instead.
class TextRankSummarizer {
  static const _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'but', 'is', 'are', 'was', 'were', 'be',
    'been', 'being', 'to', 'of', 'in', 'on', 'at', 'by', 'for', 'with',
    'about', 'as', 'into', 'through', 'this', 'that', 'these', 'those', 'it',
    'its', 'their', 'his', 'her', 'they', 'them', 'which', 'who', 'whom',
    'also', 'can', 'may', 'not', 'from', 'such', 'than', 'then', 'so', 'if',
    'when', 'while', 'has', 'have', 'had', 'will', 'we', 'you', 'your', //
    'یہ', 'وہ', 'ایک', 'ہے', 'ہیں', 'کا', 'کی', 'کے', 'سے', 'کو', 'اور',
  };

  static List<String> _splitSentences(String text) {
    // Join OCR hyphenation, treat visual line breaks as spaces, and collapse
    // repeated whitespace before sentence segmentation.
    final normalized = text
        .replaceAllMapped(RegExp(r'([A-Za-z])-\s*\n\s*([A-Za-z])'),
            (match) => '${match[1]}${match[2]}')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final seen = <String>{};
    return normalized
        .split(RegExp(r'(?<=[.?!\u06d4\u061f])\s+'))
        .map((s) => s.trim())
        .where((s) {
      if (s.length < 15 || _wordSet(s).length < 3) return false;
      final canonical = _canonical(s);
      return canonical.isNotEmpty && seen.add(canonical);
    }).toList();
  }

  /// Returns the top [maxSentences] sentences from [text], in their
  /// original order (so the summary still reads coherently).
  static List<String> summarize(String text, {int maxSentences = 5}) {
    if (maxSentences <= 0) return const [];
    final sentences = _splitSentences(text);
    if (sentences.length <= maxSentences) return sentences;

    final order = _rankByImportance(sentences);
    final topIndices = order.take(maxSentences).toList()..sort();
    return topIndices.map((i) => sentences[i]).toList();
  }

  /// Every sentence in [text], sorted by TextRank importance (most central
  /// to the document first) — exposed directly so callers that need a full
  /// importance ordering (e.g. the AI Paper Generator deciding which
  /// sentences become questions) can reuse the same graph-based ranking
  /// instead of picking by arbitrary length or position.
  static List<String> rankSentences(String text) {
    final sentences = _splitSentences(text);
    if (sentences.length <= 1) return sentences;
    return _rankByImportance(sentences).map((i) => sentences[i]).toList();
  }

  /// Sentence indices into [sentences], sorted by TextRank importance
  /// (descending). Index-based so duplicate-content sentences don't
  /// collide the way a string-`Set` match would.
  static List<int> _rankByImportance(List<String> sentences) {
    final wordSets = sentences.map(_wordSet).toList();
    final n = sentences.length;

    // Similarity matrix: normalized shared-vocabulary overlap between every
    // pair of sentences (the original TextRank similarity function).
    final similarity = List.generate(n, (_) => List.filled(n, 0.0));
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final shared = wordSets[i].intersection(wordSets[j]).length;
        if (shared == 0) continue;
        final denom = _log(wordSets[i].length) + _log(wordSets[j].length);
        final sim = denom == 0 ? 0.0 : shared / denom;
        similarity[i][j] = sim;
        similarity[j][i] = sim;
      }
    }

    final outWeights =
        List.generate(n, (i) => similarity[i].fold<double>(0, (a, b) => a + b));

    // Weighted PageRank iteration.
    const damping = 0.85;
    var scores = List.filled(n, 1.0);
    for (var iter = 0; iter < 30; iter++) {
      final next = List.filled(n, 1 - damping);
      for (var i = 0; i < n; i++) {
        var sum = 0.0;
        for (var j = 0; j < n; j++) {
          if (j == i || outWeights[j] == 0) continue;
          sum += (similarity[j][i] / outWeights[j]) * scores[j];
        }
        next[i] = (1 - damping) + damping * sum;
      }
      scores = next;
    }

    return List<int>.generate(n, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));
  }

  static Set<String> _wordSet(String sentence) => _normalizeArabic(sentence)
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9\u0600-\u06ff]+'))
      .where((w) => w.length > 1 && !_stopWords.contains(w))
      .toSet();

  static String _canonical(String sentence) => _normalizeArabic(sentence)
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), ' ')
      .trim();

  static String _normalizeArabic(String text) => text
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('ة', 'ه');

  static double _log(int x) => x <= 1 ? 0 : log(x);
}
