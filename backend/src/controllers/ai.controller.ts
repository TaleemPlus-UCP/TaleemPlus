import { Request, Response } from 'express';
import { HttpStatus } from '../constants/httpStatus';
import { analyzeTestBlueprint, generateTestQuestions, summarizeNotes } from '../utils/aiHeuristics';
import { sendSuccess } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

export const analyzeTestContent = asyncHandler(async (req: Request, res: Response) => {
  const blueprint = analyzeTestBlueprint(req.body.text);
  sendSuccess(res, HttpStatus.OK, 'Test blueprint analyzed.', blueprint);
});

export const generateQuestions = asyncHandler(async (req: Request, res: Response) => {
  const { text, mcqCount, shortCount, longCount } = req.body;
  const questions = generateTestQuestions(text, { mcqCount, shortCount, longCount });
  sendSuccess(res, HttpStatus.OK, 'Questions generated.', { questions });
});

export const summarizeText = asyncHandler(async (req: Request, res: Response) => {
  const summary = summarizeNotes(req.body.text);
  sendSuccess(res, HttpStatus.OK, 'Notes summarized.', summary);
});
