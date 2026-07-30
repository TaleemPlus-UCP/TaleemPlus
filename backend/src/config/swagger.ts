import swaggerJsdoc from 'swagger-jsdoc';
import { env } from './env';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.3',
    info: {
      title: 'TaleemPlus API',
      version: '1.0.0',
      description: 'Academy management REST API — Node.js/Express/TypeScript/Prisma/PostgreSQL backend for TaleemPlus.',
    },
    servers: [{ url: `http://localhost:${env.PORT}${env.API_PREFIX}` }],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        RegisterRequest: {
          type: 'object',
          required: ['fullName', 'email', 'password', 'phoneNumber', 'role'],
          properties: {
            fullName: { type: 'string' },
            email: { type: 'string', format: 'email' },
            password: { type: 'string', description: 'Min 8 chars, upper+lower+digit.' },
            phoneNumber: { type: 'string' },
            role: { type: 'string', enum: ['ADMIN', 'TEACHER', 'STUDENT', 'PARENT'] },
            academyName: { type: 'string', description: 'Required when role=ADMIN.' },
            academyAddress: { type: 'string' },
            academyPhone: { type: 'string' },
            academyCode: { type: 'string', description: 'Required when role is not ADMIN.' },
            securityQuestion: { type: 'string' },
            securityAnswer: { type: 'string' },
          },
        },
        LoginRequest: {
          type: 'object',
          required: ['email', 'password'],
          properties: {
            email: { type: 'string', format: 'email' },
            password: { type: 'string' },
          },
        },
        RefreshRequest: {
          type: 'object',
          required: ['refreshToken'],
          properties: {
            refreshToken: { type: 'string' },
          },
        },
      },
    },
    security: [],
  },
  apis: ['./src/routes/*.ts', './dist/routes/*.js'],
};

export const swaggerSpec = swaggerJsdoc(options);
