import { AccountStatus, UserRole } from '@prisma/client';

export interface AccessTokenPayload {
  sub: string;
  role: UserRole;
  academyId: string | null;
  accountStatus: AccountStatus;
}

export interface AuthenticatedUser {
  id: string;
  role: UserRole;
  academyId: string | null;
  accountStatus: AccountStatus;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}
