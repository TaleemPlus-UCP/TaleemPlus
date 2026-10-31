# TaleemPlus — Security Audit & Defense Architecture

> **Security Posture:** Production Hardened  
> **Auth Architecture:** JWT Access + Refresh Token Rotation, Password Hashing (`bcrypt`), Multi-Tenant Tenant Scoping.

---

## 1. Security Architecture Matrix

| Security Layer | Implementation Mechanism | Defense Objective |
|---|---|---|
| **Authentication** | JWT Access Tokens (15m expiry) + Hashed Refresh Tokens (7d expiry). | Protects against persistent stolen tokens and unauthorized access. |
| **Password Hashing** | `bcryptjs` with salt rounds = 10. | Prevents plaintext credential leakage upon database compromise. |
| **Tenant Isolation** | Multi-tenant middleware extracting `academyId` from verified JWT. | Prevents Insecure Direct Object References (IDOR) and cross-tenant leaks. |
| **Role-Based Authorization** | Express middleware checking user roles (`ADMIN`, `TEACHER`, `STUDENT`, `PARENT`). | Enforces strict privilege boundaries between users. |
| **SQL Injection Defense** | Prisma ORM parameterized query builder. | Eliminates raw SQL injection attack vectors. |
| **Security Headers** | Express `helmet` middleware. | Enforces XSS filter, HSTS, Sniff-defense, and CSP policies. |
| **Client Idle Security** | 5-minute inactivity auto-logout & background lifecycle tracking. | Protects unattended mobile/web client sessions. |

---

## 2. Multi-Tenant Scoping Middleware Logic

Every incoming API request passes through `authMiddleware` and `tenantMiddleware`:

```javascript
// Verification flow:
const token = req.headers.authorization?.split(' ')[1];
const decoded = jwt.verify(token, process.env.JWT_SECRET);
req.user = decoded; // { userId, academyId, role }

// Tenant Enforcement:
req.academyId = decoded.academyId;
// All database queries automatically append: { where: { academyId: req.academyId } }
```

Client claims (e.g., `academy_id` or `role` sent in request body) are **never trusted**. Identity and scope are strictly derived from the cryptographically verified JWT payload.
