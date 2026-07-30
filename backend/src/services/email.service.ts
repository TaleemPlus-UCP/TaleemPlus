import fs from 'fs';
import path from 'path';
import nodemailer, { Transporter } from 'nodemailer';
import { env } from '../config/env';
import { logger } from '../config/logger';
import { InternalServerError } from '../exceptions/AppError';

const DEV_EMAIL_DIR = path.join(__dirname, '..', '..', 'logs', 'dev-emails');

let smtpTransporter: Transporter | null = null;

function getSmtpTransporter(): Transporter {
  if (smtpTransporter) return smtpTransporter;
  smtpTransporter = nodemailer.createTransport({
    host: env.SMTP_HOST,
    port: env.SMTP_PORT,
    secure: env.SMTP_SECURE,
    auth: env.SMTP_USER ? { user: env.SMTP_USER, pass: env.SMTP_PASSWORD } : undefined,
  });
  return smtpTransporter;
}

interface SendMailOptions {
  to: string;
  subject: string;
  html: string;
}

/**
 * Writes the rendered email to a local .html file instead of sending it.
 * Used when SMTP isn't configured yet (dev/test only) so the full
 * register -> forgot-password -> reset-password flow can be exercised
 * end-to-end without any external dependency or real mailbox. This
 * deliberately avoids depending on a third-party account-provisioning
 * service (e.g. Ethereal's api.nodemailer.com) that may be unreachable in
 * an offline/sandboxed environment.
 */
async function writeDevEmailToDisk(options: SendMailOptions): Promise<string> {
  await fs.promises.mkdir(DEV_EMAIL_DIR, { recursive: true });
  const fileName = `${Date.now()}_${options.to.replace(/[^a-z0-9@.]/gi, '_')}.html`;
  const filePath = path.join(DEV_EMAIL_DIR, fileName);
  const rendered = `<!-- To: ${options.to} | Subject: ${options.subject} -->\n${options.html}`;
  await fs.promises.writeFile(filePath, rendered, 'utf8');
  return filePath;
}

async function sendMail(options: SendMailOptions): Promise<void> {
  if (env.smtpConfigured) {
    await getSmtpTransporter().sendMail({
      from: `"${env.SMTP_FROM_NAME}" <${env.SMTP_FROM_EMAIL}>`,
      to: options.to,
      subject: options.subject,
      html: options.html,
    });
    return;
  }

  if (env.isProduction) {
    throw new InternalServerError('SMTP is not configured. Set SMTP_HOST and related env vars in production.');
  }

  const filePath = await writeDevEmailToDisk(options);
  logger.warn(`SMTP not configured — email written to disk instead of sent: ${filePath}`);
}

export async function sendPasswordResetEmail(to: string, resetLink: string, expiresInMinutes: number): Promise<void> {
  await sendMail({
    to,
    subject: 'Reset your TaleemPlus password',
    html: `
      <p>We received a request to reset your TaleemPlus password.</p>
      <p><a href="${resetLink}">Click here to reset your password</a>. This link expires in ${expiresInMinutes} minutes.</p>
      <p>If you didn't request this, you can safely ignore this email.</p>
    `,
  });
}

export async function sendAccountApprovedEmail(to: string, fullName: string): Promise<void> {
  await sendMail({
    to,
    subject: 'Your TaleemPlus account has been approved',
    html: `<p>Hi ${fullName},</p><p>Your TaleemPlus account has been approved by your academy admin. You can now log in.</p>`,
  });
}

export async function sendAccountRejectedEmail(to: string, fullName: string, academyName?: string | null): Promise<void> {
  await sendMail({
    to,
    subject: 'Your TaleemPlus signup request was not approved',
    html: `<p>Hi ${fullName},</p><p>Your signup request for ${academyName ?? 'this academy'} was not approved by the admin. Contact your academy for details.</p>`,
  });
}
