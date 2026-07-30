/** Ported directly from the legacy `TestMarkModel.calculateGrade`. */
export function calculateGradeLetter(percentage: number): string {
  if (percentage >= 90) return 'A+';
  if (percentage >= 80) return 'A';
  if (percentage >= 70) return 'B';
  if (percentage >= 60) return 'C';
  if (percentage >= 50) return 'D';
  return 'F';
}

export function calculatePercentage(marksObtained: number, totalMarks: number): number {
  if (totalMarks <= 0) return 0;
  return Math.round((marksObtained / totalMarks) * 10000) / 100;
}

/**
 * The "AI Smart Grader" heuristic (see prompt.md §2), ported verbatim:
 * count how many of a question's teacher-authored grading keywords appear
 * anywhere in the (already OCR'd, lower-cased) answer text, and award a
 * score proportional to the fraction matched. Not semantic understanding —
 * a bag-of-keywords match, by design (see the "Known limitation" note in
 * prompt.md).
 */
export function computeGradeSuggestion(ocrText: string, gradingKeywords: string[], questionMarks: number) {
  const lowerText = ocrText.toLowerCase();
  const matchedKeywords = gradingKeywords.filter((keyword) => lowerText.includes(keyword.toLowerCase()));
  const matches = matchedKeywords.length;
  const keywordCount = gradingKeywords.length;
  const suggestedMarks = keywordCount === 0 ? 0 : Math.round(questionMarks * (matches / keywordCount) * 100) / 100;

  return { matches, keywordCount, matchedKeywords, suggestedMarks };
}
