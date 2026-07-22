# Deployment Guide

Complete guide for deploying the Flask CI/CD application to Google Cloud Platform.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Infrastructure Setup](#infrastructure-setup)
- [CI/CD Configuration](#cicd-configuration)
- [Security Best Practices](#security-best-practices)
- [Deployment Process](#deployment-process)
- [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)

## Prerequisites

### Required Tools
- Git
- Docker (20.10+)
- Python 3.11+
- Terraform (1.5+)
- GCloud CLI
- GitHub account
- Google Cloud Platform account with billing enabled

### Required GCP APIs
The following APIs will be automatically enabled by Terraform:
- Cloud Run API
- Artifact Registry API
- IAM API
- IAM Credentials API

## Local Development Setup

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
```

### 2. Create Virtual Environment
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 3. Configure Environment Variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

### 4. Run Locally
```bash
# Run directly
python app.py

# Or use Docker
docker build -t flask-app:local .
docker run -p 8080:8080 flask-app:local

# Or use Docker Compose
docker-compose up
```

### 5. Run Tests
```bash
pytest test_app.py -v
```

### 6. Test Application
```bash
curl http://localhost:8080/
curl http://localhost:8080/health
```

## Infrastructure Setup

### 1. GCP Project Setup
```bash
# Set your project ID
export PROJECT_ID="your-gcp-project-id"

# Create a new project (if needed)
gcloud projects create $PROJECT_ID --name="Flask CI/CD Demo"

# Set the project
gcloud config set project $PROJECT_ID

# Enable billing (required)
# Go to: https://console.cloud.google.com/billing
```

### 2. Service Account for Terraform
```bash
# Create service account
gcloud iam service-accounts create terraform \
  --description="Terraform service account" \
  --display-name="Terraform"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

# Create and download key
gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=terraform@${PROJECT_ID}.iam.gserviceaccount.com

# Set credential path
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-key.json"
```

### 3. Create GCS Bucket for Terraform State (Optional but Recommended)
```bash
# Create bucket
gsutil mb -p $PROJECT_ID -l us-central1 gs://${PROJECT_ID}-tfstate

# Enable versioning
gsutil versioning set on gs://${PROJECT_ID}-tfstate

# Copy and configure backend
cp terraform/backend.tf.example terraform/backend.tf
# Edit backend.tf with your bucket name
```

### 4. Configure Terraform Variables
```bash
cd terraform

# For production
cp environments/production.tfvars.example environments/production.tfvars
# Edit with your values:
# - project_id: Your GCP project ID
# - github_repo: your-username/your-repo-name
# - region: us-central1 (or your preferred region)

# For staging (optional)
cp environments/staging.tfvars.example environments/staging.tfvars
```

### 5. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file=environments/production.tfvars

# Apply the configuration
terraform apply -var-file=environments/production.tfvars

# Save the outputs
terraform output -json > outputs.json
```

### 6. Note the Terraform Outputs
```bash
# Get workload identity provider
terraform output workload_identity_provider

# Get service account email
terraform output service_account_email
```

## CI/CD Configuration

### 1. Configure GitHub Repository Secrets
Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:
- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: From terraform output
- `GCP_SERVICE_ACCOUNT`: From terraform output

Optional secrets:
- `SLACK_WEBHOOK_URL`: For Slack notifications (if using)
- `CODECOV_TOKEN`: For code coverage reports (if using)

### 2. Configure GitHub Environments
Go to Settings → Environments

Create three environments:
1. **test**: For running tests (no special configuration needed)
2. **staging**: For staging deployments
   - Add required reviewers (optional)
   - Set deployment branch to `develop`
3. **production**: For production deployments
   - Add required reviewers (recommended)
   - Set deployment branch to `main`

### 3. Branch Protection Rules
Go to Settings → Branches → Add rule

For `main` branch:
- ✅ Require a pull request before merging
- ✅ Require approvals: 1
- ✅ Require status checks to pass before merging
  - Add: `Run Tests`
  - Add: `Build and Security Scan`
- ✅ Require branches to be up to date before merging

## Security Best Practices

### 1. Secrets Management
- **Never commit secrets to the repository**
- Use GitHub Secrets for CI/CD credentials
- Use GCP Secret Manager for application secrets
- Rotate secrets regularly

### 2. Docker Image Security
- Use multi-stage builds to reduce image size
- Run containers as non-root user
- Use specific version tags, not `latest`
- Scan images with Trivy before deployment
- Keep base images updated

### 3. Network Security
- Use Cloud Run with private networking when possible
- Implement proper CORS policies
- Use HTTPS only (Cloud Run provides this by default)
- Consider Cloud Armor for DDoS protection

### 4. IAM and Access Control
- Use Workload Identity for GitHub Actions
- Follow principle of least privilege
- Enable Cloud Audit Logs
- Use service accounts for application access

### 5. Monitoring and Logging
- Enable Cloud Logging for all services
- Set up alerting for errors and anomalies
- Monitor security scan results
- Review Cloud Security Command Center findings

## Deployment Process

### Manual Deployment (for testing)
```bash
# Build image
docker build -t flask-app:test .

# Tag for GCP
docker tag flask-app:test \
  us-central1-docker.pkg.dev/$PROJECT_ID/flask-app-repo/flask-app:test

# Configure Docker auth
gcloud auth configure-docker us-central1-docker.pkg.dev

# Push image
docker push us-central1-docker.pkg.dev/$PROJECT_ID/flask-app-repo/flask-app:test

# Deploy to Cloud Run
gcloud run deploy flask-app \
  --image us-central1-docker.pkg.dev/$PROJECT_ID/flask-app-repo/flask-app:test \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars APP_VERSION=test,ENVIRONMENT=test
```

### Automated Deployment via CI/CD

#### For Staging (develop branch)
```bash
git checkout -b develop
git push origin develop
# Pipeline automatically deploys to staging
```

#### For Production (main branch)
```bash
# Create pull request from develop to main
# Get approval and merge
# Pipeline automatically deploys to production
```

### Rollback Procedure
```bash
# List revisions
gcloud run revisions list --service=flask-app --region=us-central1

# Rollback to previous revision
gcloud run services update-traffic flask-app \
  --region=us-central1 \
  --to-revisions=REVISION_NAME=100
```

## Monitoring and Troubleshooting

### View Logs
```bash
# Cloud Run logs
gcloud run services logs read flask-app --region=us-central1

# Follow logs
gcloud run services logs tail flask-app --region=us-central1
```

### Check Service Status
```bash
# Get service details
gcloud run services describe flask-app --region=us-central1

# Get service URL
gcloud run services describe flask-app \
  --region=us-central1 \
  --format='value(status.url)'
```

### Monitor Metrics
```bash
# View in Cloud Console
https://console.cloud.google.com/run/detail/us-central1/flask-app/metrics
```

### Common Issues

#### Issue: Security scan fails with vulnerabilities
**Solution**: Review the Trivy report, update dependencies, rebuild base image

#### Issue: Deployment fails due to quota limits
**Solution**: Request quota increase in GCP Console

#### Issue: Health check fails
**Solution**: Check logs, verify `/health` endpoint responds with 200

#### Issue: Permission denied errors
**Solution**: Verify IAM roles and Workload Identity configuration

### Health Checks
```bash
# Production
curl https://YOUR-SERVICE-URL/health

# Check response time
curl -w "@curl-format.txt" -o /dev/null -s https://YOUR-SERVICE-URL/

# Create curl-format.txt:
# time_namelookup:  %{time_namelookup}\n
# time_connect:  %{time_connect}\n
# time_appconnect:  %{time_appconnect}\n
# time_pretransfer:  %{time_pretransfer}\n
# time_redirect:  %{time_redirect}\n
# time_starttransfer:  %{time_starttransfer}\n
# ----------\n
# time_total:  %{time_total}\n
```

## Cost Optimization

### Cloud Run Cost Reduction
- Set appropriate min/max instances
- Use Cloud Run's scale-to-zero for staging
- Monitor and adjust CPU/memory allocation
- Use request-based pricing

### Artifact Registry Cost Reduction
- Enable automatic cleanup policies
- Remove old/unused images
- Use lifecycle policies

### Monitoring Costs
```bash
# View current month costs
gcloud billing accounts list
gcloud billing projects describe $PROJECT_ID

# Set budget alerts in Cloud Console
```

## Cleanup

### Destroy Infrastructure
```bash
cd terraform
terraform destroy -var-file=environments/production.tfvars
```

### Delete GCS State Bucket
```bash
gsutil -m rm -r gs://${PROJECT_ID}-tfstate
```

### Delete GCP Project
```bash
gcloud projects delete $PROJECT_ID
```

## Additional Resources
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)

## Support
For issues and questions:
- Check the logs: `gcloud run services logs read flask-app`
- Review GitHub Actions runs
- Check GCP Cloud Console for errors
- Review security scan reports in GitHub Security tab
