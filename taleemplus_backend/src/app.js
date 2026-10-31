require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const prisma = require('./config/db');
const { errorHandler } = require('./middleware/errorMiddleware');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const classRoutes = require('./routes/classRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');
const feeRoutes = require('./routes/feeRoutes');
const quizRoutes = require('./routes/quizRoutes');
const resourceRoutes = require('./routes/resourceRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const timetableRoutes = require('./routes/timetableRoutes');
const mlRoutes = require('./routes/mlRoutes');

const app = express();

const configuredOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);
const isProduction = process.env.NODE_ENV === 'production';
// Flutter Web debug builds are served from an ephemeral localhost port, so
// development must accept any localhost origin while production stays pinned
// to the explicit CORS_ORIGINS allowlist.
const localhostOriginPattern = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

const corsOptions = {
  origin(origin, callback) {
    // Requests without an Origin header (curl, health checks, native mobile
    // apps) are not browser cross-origin requests and must keep working.
    if (!origin) return callback(null, true);
    if (configuredOrigins.includes(origin)) return callback(null, true);
    if (!isProduction && localhostOriginPattern.test(origin)) {
      return callback(null, true);
    }
    return callback(null, false);
  },
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true,
  optionsSuccessStatus: 204,
  maxAge: 600,
};

app.use(helmet());
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));
app.use(express.json({ limit: '1500kb' }));
app.use(morgan('dev'));

// Versioned API v2 Routes
app.use('/api/v2/auth', authRoutes);
app.use('/api/v2/users', userRoutes);
app.use('/api/v2/classes', classRoutes);
app.use('/api/v2/attendance', attendanceRoutes);
app.use('/api/v2/fees', feeRoutes);
app.use('/api/v2/quizzes', quizRoutes);
app.use('/api/v2/resources', resourceRoutes);
app.use('/api/v2', notificationRoutes);
app.use('/api/v2/timetable', timetableRoutes);
app.use('/api/v2/admin/ml', mlRoutes);

// Backward compatibility v1 Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/classes', classRoutes);
app.use('/api/v1/attendance', attendanceRoutes);
app.use('/api/v1/fees', feeRoutes);
app.use('/api/v1/quizzes', quizRoutes);
app.use('/api/v1/resources', resourceRoutes);
app.use('/api/v1', notificationRoutes);
app.use('/api/v1/timetable', timetableRoutes);

// Health check endpoint. Reports database reachability without exposing
// connection strings or credentials.
app.get('/health', async (req, res) => {
  let database = 'connected';
  try {
    await prisma.$queryRaw`SELECT 1`;
  } catch (err) {
    database = 'unavailable';
    console.error('[Health] Database check failed:', err.message);
  }

  res.json({
    status: 'ok',
    service: 'TaleemPlus Backend Service',
    database,
    timestamp: new Date(),
  });
});

// API v2 Version & Metadata endpoint
app.get('/api/v2/version', (req, res) => {
  res.json({
    success: true,
    data: {
      api_version: '2.0.0',
      service: 'TaleemPlus Enterprise Backend',
      environment: process.env.NODE_ENV || 'development',
      database: 'PostgreSQL + Prisma',
      release_date: '2026-10-30',
      supported_roles: ['ADMIN', 'TEACHER', 'STUDENT', 'PARENT']
    }
  });
});

// Centralized error middleware
app.use(errorHandler);

module.exports = app;
