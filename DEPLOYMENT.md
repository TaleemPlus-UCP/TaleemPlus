iguration
Create a production `.env` file inside `taleemplus_backend/`:
```env
PORT=5000
NODE_ENV=production
DATABASE_URL="postgresql://db_user:secure_password@your-postgres-host:5432/taleemplus_prod?schema=public"
JWT_SECRET="your_strong_production_jwt_secret_key"
JWT_EXPIRES_IN="15m"
REFRESH_TOKEN_SECRET="your_strong_production_refresh_secret"
REFRESH_TOKEN_EXPIRES_IN="7d"
```

---

## 3. Database Migration & Initialization
Run Prisma migrations against the production database:
```bash
cd taleemplus_backend
npx prisma migrate deploy
```

---

## 4. Starting the Production Server
Using PM2 process manager for zero-downtime clustering:
```bash
npm install -g pm2
pm2 start src/server.js --name "taleemplus-api" -i max
pm2 save
pm2 startup
```

---

## 5. Rollback Strategy
If a deployment fails:
1. Revert to previous Git tag/commit.
2. If database schema was updated, run the corresponding Prisma down-migration or restore from automated daily PostgreSQL snapshot backup.
