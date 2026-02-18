# Necto – Deployment Plan (Backend First)

This guide covers deploying the **backend first** (Go API + PostgreSQL), then the Flutter web frontend. Two options:

**Backend-only quick order (do in this sequence):**

1. Create managed PostgreSQL (RDS on AWS or Cloud SQL on GCP).
2. Run migrations (`001_init.sql`, `002_shift_requests_notifications.sql`) against that DB.
3. Build API Docker image and push to a container registry (ECR / Artifact Registry).
4. Deploy the container as a service (ECS Fargate, App Runner, or Cloud Run) with env vars pointing to the DB and a strong `JWT_SECRET`.
5. Verify `GET /health` and auth endpoints; then deploy the frontend with the API base URL set at build time.

- **Option A: AWS** – API on ECS Fargate or App Runner, database on RDS PostgreSQL.
- **Option B: Firebase + Google Cloud** – API on Cloud Run, database on Cloud SQL; Flutter web on **Firebase Hosting**.

Firebase does **not** run your Go backend; it hosts the Flutter app and can provide auth/firestore if you adopt them later. So “Firebase” here means: **Firebase Hosting for the app** and **Google Cloud Run + Cloud SQL** for the API and DB.

---

## Table of contents

1. [Pre-deployment checklist](#1-pre-deployment-checklist)
2. [Option A: Backend on AWS (step-by-step)](#2-option-a-backend-on-aws-step-by-step)
3. [Option B: Backend on Google Cloud (step-by-step)](#3-option-b-backend-on-google-cloud-step-by-step)
4. [Frontend deployment (after backend)](#4-frontend-deployment-after-backend)
5. [Post-deployment: env and CORS](#5-post-deployment-env-and-cors)

---

## 1. Pre-deployment checklist

Before deploying the backend:

- [ ] **Code**
  - Backend builds: `cd backend && go build ./cmd/api`
  - Docker builds: `cd backend && docker compose build`
- [ ] **Secrets**
  - Strong `JWT_SECRET` (e.g. 32+ random characters).
  - DB password different from local/dev.
- [ ] **Database**
  - Production DB uses **SSL** (e.g. `DB_SSLMODE=require` for RDS/Cloud SQL).
- [ ] **Migrations**
  - All SQL under `backend/migrations/` (e.g. `001_init.sql`, `002_...sql`) applied to the production DB (see steps below).

---

## 2. Option A: Backend on AWS (step-by-step)

High level: **RDS (PostgreSQL)** → run migrations → **ECR (Docker image)** → **ECS Fargate** or **App Runner** running the API container.

### Step 1: Create RDS PostgreSQL

1. In **AWS Console** go to **RDS** → **Create database**.
2. Choose **PostgreSQL 16** (or 15), **Standard create**.
3. **Template**: Dev/Test (or Production if you need Multi-AZ).
4. **DB instance identifier**: e.g. `necto-db`.
5. **Master username**: e.g. `necto_admin` (or `necto`).
6. **Master password**: set a strong password and store it securely (e.g. Secrets Manager).
7. **Instance type**: e.g. `db.t3.micro` (or larger for production).
8. **Storage**: 20 GiB GP3 (or as needed).
9. **Connectivity**:  
   - **VPC**: default or your app VPC.  
   - **Public access**: **Yes** only if you need to run migrations from your laptop; otherwise **No** and run migrations from a bastion or the same VPC as the API.  
   - **VPC security group**: create new or use existing; ensure **inbound** allows PostgreSQL (5432) from the API (e.g. ECS security group) or your IP for migrations.
10. **Database name**: `necto_db`.
11. Create the database. Note the **Endpoint** (e.g. `necto-db.xxxxx.us-east-1.rds.amazonaws.com`).

### Step 2: Run migrations on RDS

From your machine (or a host that can reach RDS on 5432):

```bash
cd backend
export PGHOST="<RDS_ENDPOINT>"
export PGPORT=5432
export PGDATABASE=necto_db
export PGUSER=necto_admin
export PGPASSWORD="<YOUR_DB_PASSWORD>"

# Run all migrations in order
psql -f migrations/001_init.sql
psql -f migrations/002_shift_requests_notifications.sql
```

If RDS is not publicly accessible, run the same commands from an EC2 instance or ECS task in the same VPC.

### Step 3: Push API Docker image to ECR

1. **ECR** → **Create repository** → name e.g. `necto-api` → Create.
2. **View push commands** (or use CLI):

```bash
# Auth Docker to ECR (replace REGION and ACCOUNT_ID)
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com

# Build and tag (from repo root; backend is in backend/)
cd backend
docker build -t necto-api .
docker tag necto-api:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/necto-api:latest

# Push
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/necto-api:latest
```

### Step 4a: Run API with Amazon ECS Fargate

1. **ECS** → **Clusters** → **Create cluster** (e.g. `necto-cluster`), Fargate → Create.
2. **Task definitions** → **Create new**:
   - **Task definition name**: `necto-api-task`.
   - **Container**:
     - **Image**: `<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/necto-api:latest`.
     - **Port**: 8080.
     - **Environment variables** (or use Secrets Manager for secrets):
       - `PORT` = `8080`
       - `DB_HOST` = `<RDS_ENDPOINT>`
       - `DB_PORT` = `5432`
       - `DB_USER` = `necto_admin`
       - `DB_NAME` = `necto_db`
       - `DB_SSLMODE` = `require`
     - **Secrets** (recommended): add `DB_PASSWORD` and `JWT_SECRET` from Secrets Manager.
   - **CPU/Memory**: e.g. 0.25 vCPU, 0.5 GB.
3. **Create service** in the cluster:
   - **Task definition**: `necto-api-task`.
   - **Load balancer**: Application Load Balancer (ALB), target group on port 8080, path `/health` for health checks.
   - **Public IP**: enabled if no NAT; ensure security group allows 80/443 from internet and 8080 from ALB.
4. Note the **ALB DNS name** (e.g. `necto-alb-xxxx.us-east-1.elb.amazonaws.com`). API base URL: `http://<ALB_DNS>` (or use HTTPS with ACM certificate on the ALB).

### Step 4b: Alternative – AWS App Runner

1. **App Runner** → **Create service** → **Container registry** → ECR → select `necto-api:latest`.
2. **Service name**: e.g. `necto-api`.
3. **CPU/Memory**: 0.25 vCPU, 0.5 GB.
4. **Environment variables**: same as above (`PORT`, `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_NAME`, `DB_SSLMODE`; use **Secrets** for `DB_PASSWORD`, `JWT_SECRET`).
5. **VPC**: attach to the same VPC as RDS and configure **ingress** so the service can reach RDS on 5432.
6. Deploy. Use the App Runner URL (e.g. `https://xxxx.us-east-1.awsapprunner.com`) as the API base URL.

### Step 5: Verify backend

```bash
curl https://<YOUR_API_BASE_URL>/health
# Expect: {"status":"ok"}
```

Then test login (or register) with Postman/curl against `/api/auth/login`. Once this works, proceed to frontend deployment.

---

## 3. Option B: Backend on Google Cloud (step-by-step)

High level: **Cloud SQL (PostgreSQL)** → run migrations → **Artifact Registry (Docker image)** → **Cloud Run** for the API. Frontend can go to **Firebase Hosting** later.

### Step 1: Create Cloud SQL (PostgreSQL)

1. **Google Cloud Console** → **SQL** → **Create instance** → **PostgreSQL**.
2. **Instance ID**: e.g. `necto-db`.
3. **Password**: set for user `postgres` (or create a dedicated user later); store securely.
4. **Region**: same as where you will run Cloud Run (e.g. `us-central1`).
5. **Machine type**: e.g. shared-core 1 vCPU.
6. **Storage**: 10 GB (or more).
7. **Connections**:  
   - **Public IP** (for simplicity) or **Private IP** if using VPC with Cloud Run.  
   - If Public: enable **Authorized networks** and add your IP (and later Cloud Run’s if needed) for migrations and admin.
8. Create the instance. Note the **Public IP** (or Private IP).

### Step 2: Create database and user

1. **Cloud SQL** → your instance → **Databases** → **Create database** → name: `necto_db`.
2. **Users** → **Add user** (or use `postgres`): e.g. user `necto`, password `<STRONG_PASSWORD>`.

Connect (Cloud SQL Auth Proxy or direct if public):

```bash
# Optional: Cloud SQL Auth Proxy
cloud_sql_proxy -instances=<PROJECT>:<REGION>:necto-db=tcp:5432

# Then from another terminal (or use Public IP with authorized network)
psql -h 127.0.0.1 -p 5432 -U necto -d necto_db -f backend/migrations/001_init.sql
psql -h 127.0.0.1 -p 5432 -U necto -d necto_db -f backend/migrations/002_shift_requests_notifications.sql
```

If using Public IP:

```bash
psql -h <CLOUD_SQL_PUBLIC_IP> -p 5432 -U necto -d necto_db -f backend/migrations/001_init.sql
psql -h <CLOUD_SQL_PUBLIC_IP> -p 5432 -U necto -d necto_db -f backend/migrations/002_shift_requests_notifications.sql
```

### Step 3: Push API image to Artifact Registry

1. **Artifact Registry** → **Create repository** → name `necto`, format **Docker**, region e.g. `us-central1`.
2. Build and push:

```bash
# Auth
gcloud auth configure-docker <REGION>-docker.pkg.dev

# Build and push (from backend directory)
cd backend
docker build -t <REGION>-docker.pkg.dev/<PROJECT_ID>/necto/necto-api:latest .
docker push <REGION>-docker.pkg.dev/<PROJECT_ID>/necto/necto-api:latest
```

### Step 4: Deploy API to Cloud Run

1. **Cloud Run** → **Create service**.
2. **Container image**: select the image you pushed (e.g. `<REGION>-docker.pkg.dev/<PROJECT_ID>/necto/necto-api:latest`).
3. **Service name**: e.g. `necto-api`.
4. **Region**: same as Cloud SQL.
5. **Authentication**: **Allow unauthenticated invocations** (so the Flutter app can call the API; secure with JWT in the app).
6. **Connections**:  
   - If Cloud SQL has **Private IP**: set **VPC connector** and **Private IP** so Cloud Run can reach the instance.  
   - If Cloud SQL has **Public IP**: you can use **Direct VPC egress** or allow Cloud Run’s egress to reach the DB (and add Cloud SQL IP to authorized networks if required).
7. **Variables and secrets** (Environment variables):
   - `PORT` = `8080`
   - `DB_HOST` = `<CLOUD_SQL_PRIVATE_OR_PUBLIC_IP>` (use Private IP if using VPC)
   - `DB_PORT` = `5432`
   - `DB_USER` = `necto`
   - `DB_NAME` = `necto_db`
   - `DB_SSLMODE` = `require` (or `disable` only for dev over proxy)
   - `DB_PASSWORD` = (use Secret Manager reference or paste for dev)
   - `JWT_SECRET` = (use Secret Manager or strong random string)
8. **CPU/Memory**: 0.5 vCPU, 512 MiB (or 256 MiB minimum).
9. Deploy. Note the **Cloud Run URL** (e.g. `https://necto-api-xxxxx-uc.a.run.app`). This is your **API base URL**.

### Step 5: Verify backend

```bash
curl https://<CLOUD_RUN_URL>/health
# Expect: {"status":"ok"}
```

Test `/api/auth/login` (and optionally register). Then proceed to frontend.

---

## 4. Frontend deployment (after backend)

### Option A: Flutter web on Firebase Hosting

1. **Firebase Console** → **Add project** (or use existing) → **Hosting**.
2. Install Firebase CLI: `npm install -g firebase-tools` → `firebase login`.
3. In the repo root:
   ```bash
   firebase init hosting
   ```
   - **Public directory**: `build/web` (Flutter web output).
   - **Single-page app**: Yes.
   - **Overwrite index.html**: No (Flutter generates it).
4. Build Flutter web with your **production API base URL**:
   ```bash
   cd necto_frontend_flutter
   flutter build web --dart-define=API_BASE_URL=https://<YOUR_API_BASE_URL>
   ```
   (Ensure `api_config.dart` uses `String.fromEnvironment('API_BASE_URL', ...)` so this works.)
5. Copy build output to Firebase’s expected folder (if different) or configure `firebase.json` so `public` points to `necto_frontend_flutter/build/web`.
   - Example `firebase.json`:
   ```json
   {
     "hosting": {
       "public": "necto_frontend_flutter/build/web",
       "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]
     }
   }
   ```
6. Deploy:
   ```bash
   firebase deploy
   ```
7. Your app will be at `https://<project>.web.app` or the custom domain you attach.

### Option B: Flutter web on AWS (S3 + CloudFront)

1. **S3** → Create bucket (e.g. `necto-app`), block public access off only if you use CloudFront OAI; enable **Static website hosting** (index: `index.html`, error: `index.html` for SPA).
2. Build Flutter web with API URL:
   ```bash
   cd necto_frontend_flutter
   flutter build web --dart-define=API_BASE_URL=https://<YOUR_API_BASE_URL>
   ```
3. Upload contents of `build/web` to the S3 bucket.
4. **CloudFront** → Create distribution:
   - **Origin**: S3 bucket (or S3 website endpoint).
   - **Default root object**: `index.html`.
   - **Error pages**: 403 and 404 → respond with `index.html` (200) for SPA routing.
5. Use the CloudFront URL (or custom domain) as the app URL.

---

## 5. Post-deployment: env and CORS

### Backend

- **CORS**: The backend already has CORS middleware. For production, you can restrict `Access-Control-Allow-Origin` to your frontend origin(s) (e.g. `https://<project>.web.app`, `https://yourdomain.com`) instead of `*` or dynamic `Origin`.
- **Environment**: Ensure production uses:
  - `DB_SSLMODE=require` (RDS / Cloud SQL).
  - Strong, unique `JWT_SECRET`.
  - Strong DB password (prefer secrets manager).

### Flutter

- **API base URL**: Set at build time via `--dart-define=API_BASE_URL=https://...` so the built app points to your deployed API (see `api_config.dart`).
- **HTTPS**: Use HTTPS for the API in production so the browser allows requests from your hosted app.

---

## Quick reference

| Component   | AWS                          | Firebase / GCP                    |
|------------|------------------------------|-----------------------------------|
| Backend API| ECS Fargate or App Runner    | Cloud Run                         |
| Database   | RDS PostgreSQL               | Cloud SQL PostgreSQL              |
| Frontend   | S3 + CloudFront              | Firebase Hosting                  |
| Secrets    | AWS Secrets Manager          | Google Secret Manager             |

**Order of operations (backend first):**

1. Create and configure database (RDS or Cloud SQL).
2. Run all migrations.
3. Build and push API Docker image (ECR or Artifact Registry).
4. Deploy API (ECS/App Runner or Cloud Run) with correct env and DB connectivity.
5. Verify `/health` and auth endpoints.
6. Build Flutter web with production API URL and deploy to Firebase Hosting or S3+CloudFront.
7. Tighten CORS and secrets as needed.
