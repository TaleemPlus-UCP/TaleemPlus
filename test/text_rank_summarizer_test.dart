import 'package:flutter_test/flutter_test.dart';
import 'package:taleemplus_app/logic/text_rank_summarizer.dart';

void main() {
  group('TextRankSummarizer', () {
    test('returns all sentences when fewer than maxSentences', () {
      const text = 'Force is a push or pull. Mass measures inertia.';
      final result = TextRankSummarizer.summarize(text, maxSentences: 5);
      expect(result.length, 2);
    });

    test('caps output at maxSentences for a longer document', () {
      const text = 'Newton described force as a push or pull on an object. '
          'Mass is a measure of the inertia of an object. '
          'Acceleration is the rate of change of velocity over time. '
          'Energy can neither be created nor destroyed, only transformed. '
          'Momentum is the product of mass and velocity of an object. '
          'Gravity is a force that attracts two bodies toward each other. '
          'Friction opposes the relative motion between two surfaces.';
      final result = TextRankSummarizer.summarize(text, maxSentences: 3);
      expect(result.length, 3);
    });

    test('keeps selected sentences in original document order', () {
      const text = 'Alpha discusses force and motion in classical mechanics. '
          'Beta is an unrelated sentence about cooking recipes today. '
          'Gamma also discusses force and motion in classical systems. '
          'Delta is another unrelated line about weather patterns here. '
          'Epsilon returns to force and motion as the central theme.';
      final result = TextRankSummarizer.summarize(text, maxSentences: 3);
      final indices = result.map((s) => text.indexOf(s)).toList();
      final sorted = [...indices]..sort();
      expect(indices, sorted);
    });

    test('empty text yields no sentences', () {
      expect(TextRankSummarizer.summarize('', maxSentences: 5), isEmpty);
    });

    test('rankSentences returns every sentence exactly once, none dropped', () {
      const text =
          'Force and motion are central to this entire mechanics chapter. '
          'A short unrelated note about cooking recipes appears here today. '
          'This mechanics chapter often returns to force and motion again.';
      final ranked = TextRankSummarizer.rankSentences(text);
      expect(ranked.length, 3);
      expect(ranked.toSet(), {
        'Force and motion are central to this entire mechanics chapter.',
        'A short unrelated note about cooking recipes appears here today.',
        'This mechanics chapter often returns to force and motion again.',
      });
    });

    test('rankSentences does not simply favor the longest sentence', () {
      const text =
          'Energy is central and energy recurs across this entire passage. '
          'Energy transformations are discussed again in relation to energy. '
          'This unrelated sentence about a totally different topic happens to run on for quite a long stretch of unrelated words just to be long.';
      final ranked = TextRankSummarizer.rankSentences(text);
      // The longest sentence (the unrelated one) should not be ranked first
      // purely for its length — the two sentences sharing "energy" should
      // dominate the ranking.
      expect(ranked.first, isNot(contains('unrelated sentence')));
    });
  });
}
