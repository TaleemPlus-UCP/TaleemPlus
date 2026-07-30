/**
 * Offline heuristic "AI" features, ported verbatim from the legacy Flutter
 * app's hand-written Dart rules (see prompt.md §3–4 for the reference
 * "prompt"/specification of each). All three operate on plain text already
 * extracted by on-device OCR (Google ML Kit) in the Flutter client — OCR
 * itself is not, and will not be, reimplemented server-side.
 */

export type QuizDifficultyGuess = 'EASY' | 'MEDIUM' | 'HARD';

export interface TestBlueprint {
  difficulty: QuizDifficultyGuess;
  mcqCount: number;
  shortCount: number;
  longCount: number;
  preview: string;
}

function clampInt(value: number, min: number, max: number): number {
  return Math.trunc(Math.min(Math.max(value, min), max));
}

/**
 * Step 1 of the AI Test Generator (prompt.md §3): estimate difficulty and a
 * question-count breakdown from OCR'd source text. The "law"/"theorem"/
 * "equation" check is intentionally case-sensitive, matching the legacy
 * Dart code (`text.contains('law')`, no case-folding) — not a bug we're
 * fixing here, since this is a faithful port of a documented heuristic.
 */
export function analyzeTestBlueprint(text: string): TestBlueprint {
  const lines = text.split('\n').filter((l) => l.trim().length > 10);
  const wordCount = text.split(' ').length;

  let difficulty: QuizDifficultyGuess = 'MEDIUM';
  if (wordCount < 100) difficulty = 'EASY';
  if (text.includes('law') || text.includes('theorem') || text.includes('equation') || wordCount > 500) {
    difficulty = 'HARD';
  }

  const mcqCount = clampInt(wordCount / 40, 3, 15);
  const shortCount = clampInt(lines.length / 4, 2, 10);
  const longCount = wordCount > 300 ? 2 : 1;

  return { difficulty, mcqCount, shortCount, longCount, preview: text.slice(0, 100) };
}

export interface GeneratedQuestion {
  text: string;
  type: 'MCQ' | 'SHORT' | 'LONG';
  options?: string[];
  correctIndex?: number;
  marks: number;
  gradingKeywords: string[];
}

interface GenerateCounts {
  mcqCount: number;
  shortCount: number;
  longCount: number;
}

/**
 * Step 2 of the AI Test Generator (prompt.md §3). ML Kit returns one line
 * per *visual* line, not per sentence, so the source text is rejoined into
 * one blob and re-split on sentence terminators before the three
 * heuristics run — each consumes sentences the previous one didn't use, so
 * the same sentence never becomes two questions.
 */
export function generateTestQuestions(text: string, counts: GenerateCounts): GeneratedQuestion[] {
  const normalized = text.replace(/\s+/g, ' ').trim();
  const sentences = normalized
    .split(/[.?!]+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 15);

  const generated: GeneratedQuestion[] = [];
  const used = new Set<string>();

  // Heuristic 1: MCQs from "X is/refers to Y" definitions.
  let mGenerated = 0;
  for (const sentence of sentences) {
    if (mGenerated >= counts.mcqCount) break;
    if (used.has(sentence)) continue;
    if (sentence.includes(' is ') || sentence.includes(' refers to ')) {
      const parts = sentence.split(/ is | refers to /);
      if (parts.length === 2 && parts[0].trim() && parts[1].trim()) {
        generated.push({
          text: `What ${sentence.includes(' refers to ') ? 'refers to' : 'is'} ${parts[1].trim()}?`,
          type: 'MCQ',
          options: [parts[0].trim(), 'None of the above', 'Both A and B', 'Incorrect definition'],
          correctIndex: 0,
          marks: 1,
          gradingKeywords: [],
        });
        used.add(sentence);
        mGenerated += 1;
      }
    }
  }

  // Remaining sentences, longest first, so the longest become Long Questions.
  const remaining = sentences.filter((s) => !used.has(s)).sort((a, b) => b.length - a.length);

  // Heuristic 2: Long Questions from the longest remaining sentences.
  let lGenerated = 0;
  for (const sentence of remaining) {
    if (lGenerated >= counts.longCount) break;
    if (used.has(sentence)) continue;
    if (sentence.length < 80) continue;
    const preview = sentence.length > 60 ? `${sentence.slice(0, 60)}...` : sentence;
    generated.push({
      text: `Discuss in detail the following concept: ${preview}`,
      type: 'LONG',
      marks: 5,
      gradingKeywords: [],
    });
    used.add(sentence);
    lGenerated += 1;
  }

  // Heuristic 3: Short Questions from whatever's left.
  let sGenerated = 0;
  for (const sentence of remaining) {
    if (sGenerated >= counts.shortCount) break;
    if (used.has(sentence)) continue;
    if (sentence.includes('?')) continue;
    generated.push({
      text: `Briefly explain: ${sentence}`,
      type: 'SHORT',
      marks: 2,
      gradingKeywords: [],
    });
    used.add(sentence);
    sGenerated += 1;
  }

  return generated;
}

export interface NotesSummary {
  definitions: string[];
  keyPoints: string[];
  isTooShort: boolean;
}

/**
 * AI Notes Summarizer (prompt.md §4) — a pure extractive line-classifier,
 * not abstraction/paraphrasing. Returns structured data rather than the
 * legacy app's pre-formatted emoji-headed string, so the client can render
 * it however it likes; the underlying classification rule is unchanged.
 */
export function summarizeNotes(text: string): NotesSummary {
  const lines = text
    .split('\n')
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  const definitions: string[] = [];
  const keyPoints: string[] = [];

  for (const line of lines) {
    if (line.includes(' is ') || line.includes(':')) {
      definitions.push(line);
    } else if (line.length < 50 && (line.toUpperCase() === line || line.endsWith('.'))) {
      keyPoints.push(line);
    }
  }

  return {
    definitions: definitions.slice(0, 5),
    keyPoints: keyPoints.slice(0, 8),
    isTooShort: definitions.length === 0 && keyPoints.length === 0,
  };
}
