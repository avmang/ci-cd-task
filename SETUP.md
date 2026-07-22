# Quick Setup Guide

This is a condensed setup guide. For comprehensive instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Prerequisites Checklist
- [ ] Git installed
- [ ] Docker 20.10+ installed
- [ ] Python 3.11+ installed
- [ ] Terraform 1.5+ installed
- [ ] GCloud CLI installed
- [ ] GCP account with billing enabled
- [ ] GitHub account

## 5-Minute Local Test

```bash
# Clone and setup
git clone <your-repo-url>
cd <your-repo>

# Build and test
docker build -t flask-app:local .
docker run -d -p 8080:8080 --name flask-test flask-app:local

# Verify
curl http://localhost:8080/
curl http://localhost:8080/health

# Cleanup
docker stop flask-test
```

## GCP Deployment (15 minutes)

### 1. Set GCP Project
```bash
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID
```

### 2. Deploy Infrastructure
```bash
cd terraform
cp environments/production.tfvars.example environments/production.tfvars

# Edit production.tfvars with:
# - project_id: Your GCP project ID
# - github_repo: username/repo-name
# - region: us-central1

terraform init
terraform apply -var-file=environments/production.tfvars
```

### 3. Configure GitHub
**Settings → Secrets → Actions:**
- `GCP_PROJECT_ID`: Your project ID
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: From `terraform output`
- `GCP_SERVICE_ACCOUNT`: From `terraform output`

**Settings → Environments:**
- Create: `test`, `staging`, `production`
- Set `production` to require approval

### 4. Deploy
```bash
git add .
git commit -m "Initial commit"
git push origin main
```

Check GitHub Actions for deployment status.

## Project Features

### ✅ CI/CD Pipeline
- Automated testing with pytest
- Docker image building with BuildKit caching
- Trivy security scanning
- Multi-environment deployment (staging/production)
- Pipeline notifications and summaries

### ✅ Security
- Multi-stage Docker builds
- Non-root container user
- Vulnerability scanning with fail thresholds
- Secrets management with Workload Identity
- Security reports in GitHub Security tab

### ✅ Infrastructure
- Infrastructure as Code with Terraform
- GCP Artifact Registry for images
- Cloud Run for serverless deployment
- Auto-scaling and health checks
- Environment-specific configurations

### ✅ Best Practices
- Git repository with proper .gitignore
- Environment variable management
- Comprehensive documentation
- Local development support
- Monitoring and logging

## Verification Checklist

After deployment, verify:

- [ ] Tests pass locally: `pytest test_app.py -v`
- [ ] Docker builds successfully: `docker build -t test .`
- [ ] Container runs locally: `docker run -p 8080:8080 test`
- [ ] Terraform applies without errors
- [ ] GitHub Actions pipeline succeeds
- [ ] Application accessible at Cloud Run URL
- [ ] Health endpoint returns 200
- [ ] Security scan passes (no CRITICAL/HIGH issues)
- [ ] Logs visible in GCP Console

## Architecture Overview

```
Developer Push
      ↓
GitHub Actions (CI/CD)
      ↓
   ┌──────────────────┐
   │  1. Test         │ → Run pytest
   │  2. Build & Scan │ → Docker + Trivy
   │  3. Push         │ → Artifact Registry
   │  4. Deploy       │ → Cloud Run
   │  5. Verify       │ → Health check
   │  6. Notify       │ → Status summary
   └──────────────────┘
      ↓
Production Application
```

## Common Commands

```bash
# View Cloud Run logs
gcloud run services logs read flask-app --region=us-central1 --limit=50

# Get service URL
gcloud run services describe flask-app --region=us-central1 --format='value(status.url)'

# List revisions (for rollback)
gcloud run revisions list --service=flask-app --region=us-central1

# Rollback deployment
gcloud run services update-traffic flask-app --to-revisions=REVISION_NAME=100 --region=us-central1

# View Terraform state
cd terraform && terraform show

# Destroy infrastructure
cd terraform && terraform destroy -var-file=environments/production.tfvars
```

## Troubleshooting Quick Fixes

**Issue**: Docker build fails  
**Fix**: Ensure Docker daemon is running, check Dockerfile syntax

**Issue**: Tests fail  
**Fix**: Activate venv, install requirements, check test file

**Issue**: Terraform apply fails  
**Fix**: Check GCP credentials, verify project ID, enable required APIs

**Issue**: GitHub Actions fails  
**Fix**: Verify secrets are set, check workflow logs, review IAM permissions

**Issue**: Security scan fails  
**Fix**: Update dependencies in requirements.txt, rebuild image

**Issue**: Deployment fails  
**Fix**: Check Cloud Run logs, verify image exists in registry, check quotas

## Next Steps

1. **Review documentation**: Read [DEPLOYMENT.md](DEPLOYMENT.md) and [SECURITY.md](SECURITY.md)
2. **Customize application**: Modify app.py for your use case
3. **Add features**: Extend the application with new endpoints
4. **Configure monitoring**: Set up Cloud Monitoring alerts
5. **Set up domain**: Add custom domain to Cloud Run
6. **Enable notifications**: Configure Slack/email notifications
7. **Review costs**: Monitor GCP billing, set budget alerts

## Support

- **Documentation**: [DEPLOYMENT.md](DEPLOYMENT.md), [SECURITY.md](SECURITY.md)
- **Issues**: GitHub Issues tab
- **GCP Support**: [cloud.google.com/support](https://cloud.google.com/support)

## Key Files

| File | Purpose |
|------|---------|
| `app.py` | Flask application |
| `Dockerfile` | Container image definition |
| `.github/workflows/ci-cd.yml` | CI/CD pipeline |
| `terraform/main.tf` | Infrastructure definition |
| `test_app.py` | Unit tests |
| `.env.example` | Environment variables template |
| `DEPLOYMENT.md` | Complete deployment guide |
| `SECURITY.md` | Security policies |

---

**Status**: Production Ready ✅  
**Estimated Setup Time**: 20-30 minutes  
**Last Updated**: 2026-07-22
