import path from 'path';
import winston from 'winston';
import DailyRotateFile from 'winston-daily-rotate-file';
import { env } from './env';

const logsDir = path.join(__dirname, '..', '..', 'logs');

// Serverless platforms (Vercel, and most others) ship a read-only
// filesystem outside of /tmp, so writing rotated log files would crash the
// process at boot. Vercel sets VERCEL=1 in every function's environment;
// fall back to console-only logging there and rely on the platform's own
// log capture instead.
const isServerless = process.env.VERCEL === '1';

const { combine, timestamp, printf, colorize, errors, json } = winston.format;

const consoleFormat = combine(
  colorize(),
  timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  errors({ stack: true }),
  printf(({ level, message, timestamp: ts, stack, ...meta }) => {
    const metaStr = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
    return `[${ts}] ${level}: ${stack ?? message}${metaStr}`;
  }),
);

const fileFormat = combine(timestamp(), errors({ stack: true }), json());

export const logger = winston.createLogger({
  level: env.LOG_LEVEL,
  defaultMeta: { service: 'taleemplus-backend' },
  transports: [
    new winston.transports.Console({ format: consoleFormat }),
    ...(isServerless
      ? []
      : [
          new DailyRotateFile({
            dirname: logsDir,
            filename: 'app-%DATE%.log',
            datePattern: 'YYYY-MM-DD',
            maxFiles: '14d',
            format: fileFormat,
          }),
          new DailyRotateFile({
            dirname: logsDir,
            filename: 'error-%DATE%.log',
            datePattern: 'YYYY-MM-DD',
            maxFiles: '30d',
            level: 'error',
            format: fileFormat,
          }),
        ]),
  ],
  exceptionHandlers: isServerless
    ? undefined
    : [
        new DailyRotateFile({
          dirname: logsDir,
          filename: 'exceptions-%DATE%.log',
          datePattern: 'YYYY-MM-DD',
          format: fileFormat,
        }),
      ],
  rejectionHandlers: isServerless
    ? undefined
    : [
        new DailyRotateFile({
          dirname: logsDir,
          filename: 'rejections-%DATE%.log',
          datePattern: 'YYYY-MM-DD',
          format: fileFormat,
        }),
      ],
});

/** Stream adapter so `morgan` can pipe HTTP access logs through winston. */
export const httpLogStream = {
  write: (message: string) => logger.http(message.trim()),
};
