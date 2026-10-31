const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
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

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
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

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'TaleemPlus Backend Service', timestamp: new Date() });
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
