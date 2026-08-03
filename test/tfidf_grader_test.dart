import 'package:flutter_test/flutter_test.dart';
import 'package:taleemplus_app/logic/tfidf_grader.dart';

void main() {
  group('TfIdfGrader', () {
    test('empty keywords score 0', () {
      final score = TfIdfGrader.score(
        keywords: [],
        answerText: 'force mass acceleration',
        corpusKeywordSets: [],
      );
      expect(score, 0.0);
    });

    test('answer containing every keyword scores near 1', () {
      final score = TfIdfGrader.score(
        keywords: ['force', 'mass', 'acceleration'],
        answerText: 'Force equals mass times acceleration, per Newton.',
        corpusKeywordSets: [
          ['force', 'mass', 'acceleration'],
        ],
      );
      expect(score, closeTo(1.0, 0.01));
    });

    test('answer missing all keywords scores 0', () {
      final score = TfIdfGrader.score(
        keywords: ['force', 'mass', 'acceleration'],
        answerText: 'The weather today is sunny and warm.',
        corpusKeywordSets: [
          ['force', 'mass', 'acceleration'],
        ],
      );
      expect(score, 0.0);
    });

    test('partial keyword overlap scores between 0 and 1', () {
      final score = TfIdfGrader.score(
        keywords: ['force', 'mass', 'acceleration'],
        answerText: 'Force is a push or pull on an object.',
        corpusKeywordSets: [
          ['force', 'mass', 'acceleration'],
        ],
      );
      expect(score, greaterThan(0.0));
      expect(score, lessThan(1.0));
    });

    test(
        'a keyword shared across many corpus questions weighs less than '
        'one unique to this question', () {
      // "energy" appears in every question's keyword list (low IDF);
      // "gravity" appears only in this one (high IDF).
      final corpus = [
        ['energy', 'gravity'],
        ['energy', 'momentum'],
        ['energy', 'friction'],
      ];

      final scoreCommonOnly = TfIdfGrader.score(
        keywords: ['energy', 'gravity'],
        answerText: 'energy',
        corpusKeywordSets: corpus,
      );
      final scoreDistinctiveOnly = TfIdfGrader.score(
        keywords: ['energy', 'gravity'],
        answerText: 'gravity',
        corpusKeywordSets: corpus,
      );

      expect(scoreDistinctiveOnly, greaterThan(scoreCommonOnly));
    });
  });
}
