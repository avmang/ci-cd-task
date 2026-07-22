# Flask CI/CD Pipeline with GCP

[![CI/CD Pipeline](https://github.com/your-username/your-repo/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/your-username/your-repo/actions)
[![Security Rating](https://img.shields.io/badge/security-A-brightgreen)](SECURITY.md)

Production-ready Flask application with comprehensive CI/CD pipeline, automated security scanning, and cloud deployment to Google Cloud Platform.

## 🚀 Features

- **Complete CI/CD Pipeline**: Automated testing, building, security scanning, and deployment
- **Multi-Environment Support**: Separate staging and production environments
- **Security-First**: Docker image scanning, vulnerability detection, and security best practices
- **Cloud-Native**: Deployed on Google Cloud Run with auto-scaling
- **Infrastructure as Code**: Terraform-managed GCP resources
- **Containerized**: Multi-stage Docker builds with security hardening
- **Monitoring**: Health checks, logging, and deployment notifications

## 📋 Requirements Met

✅ **CI/CD System**: GitHub Actions with multi-stage pipeline  
✅ **Cloud Provider**: Google Cloud Platform (Cloud Run, Artifact Registry)  
✅ **Dockerization**: Multi-stage Dockerfile with security best practices  
✅ **Security Scanning**: Trivy vulnerability scanning with fail thresholds  
✅ **Automated Testing**: Pytest with coverage reporting  
✅ **Cloud Registry**: GCP Artifact Registry for Docker images  
✅ **Infrastructure as Code**: Terraform with state management  
✅ **Environment Management**: Separate staging and production configs  
✅ **Secrets Management**: GitHub Secrets and GCP Workload Identity  
✅ **Notifications**: Pipeline status notifications and job summaries  
✅ **Best Practices**: Security, efficiency, and production-ready configuration

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│   GitHub    │────▶│ GitHub       │────▶│ GCP Artifact    │
│ Repository  │     │ Actions      │     │ Registry        │
└─────────────┘     └──────────────┘     └─────────────────┘
                           │                      │
                           │                      │
                           ▼                      ▼
                    ┌──────────────┐     ┌─────────────────┐
                    │   Trivy      │     │  Cloud Run      │
                    │  Security    │     │  (Staging/Prod) │
                    │  Scanner     │     └─────────────────┘
                    └──────────────┘
```

## 📁 Project Structure

```
.
├── app.py                      # Flask application
├── test_app.py                 # Unit tests
├── requirements.txt            # Python dependencies
├── Dockerfile                  # Multi-stage Docker build
├── docker-compose.yml          # Local development setup
├── .dockerignore              # Docker build exclusions
├── .env.example               # Environment variables template
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # CI/CD pipeline configuration
├── terraform/
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Terraform variables
│   ├── outputs.tf             # Terraform outputs
│   ├── backend.tf.example     # State management example
│   └── environments/
│       ├── production.tfvars.example
│       └── staging.tfvars.example
├── DEPLOYMENT.md              # Comprehensive deployment guide
├── SECURITY.md                # Security policies and practices
└── README.md                  # This file
```

## 🚦 Quick Start

### Prerequisites
- Git
- Docker 20.10+
- Python 3.11+
- Terraform 1.5+
- GCloud CLI
- GCP account with billing enabled
- GitHub account

### 1. Local Development

```bash
# Clone the repository
git clone https://github.com/your-username/your-repo.git
cd your-repo

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your configuration

# Run the application
python app.py

# Run tests
pytest test_app.py -v

# Test with Docker
docker build -t flask-app:local .
docker run -p 8080:8080 flask-app:local

# Or use Docker Compose
docker-compose up
```

Visit http://localhost:8080 to see the application.

### 2. Infrastructure Setup

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed setup instructions.

```bash
# Set your GCP project
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Configure Terraform
cd terraform
cp environments/production.tfvars.example environments/production.tfvars
# Edit production.tfvars with your values

# Deploy infrastructure
terraform init
terraform plan -var-file=environments/production.tfvars
terraform apply -var-file=environments/production.tfvars

# Save outputs for GitHub Secrets
terraform output workload_identity_provider
terraform output service_account_email
```

### 3. GitHub Configuration

**Add Repository Secrets** (Settings → Secrets → Actions):
- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: From terraform output
- `GCP_SERVICE_ACCOUNT`: From terraform output

**Configure Environments** (Settings → Environments):
- `test`: For running tests
- `staging`: For staging deployments (branch: develop)
- `production`: For production deployments (branch: main)

### 4. Deploy

```bash
# Deploy to staging
git checkout -b develop
git push origin develop

# Deploy to production
git checkout main
git merge develop
git push origin main
```

## 🔄 CI/CD Pipeline

The pipeline automatically runs on push to `main` or `develop` branches:

### Stage 1: Test
- Checkout code
- Set up Python environment
- Install dependencies (with pip caching)
- Run tests with coverage
- Upload coverage reports

### Stage 2: Build & Security Scan
- Build Docker image with BuildKit caching
- Run Trivy vulnerability scanner
- Fail on CRITICAL/HIGH vulnerabilities
- Upload security reports to GitHub Security
- Generate and archive security report artifacts

### Stage 3: Deploy
- **Staging** (develop branch): Deploy to staging environment
- **Production** (main branch): Deploy to production environment
- Authenticate with GCP using Workload Identity
- Push image to Artifact Registry
- Deploy to Cloud Run with environment-specific configuration
- Run health checks
- Send deployment notifications

### Stage 4: Notify
- Create job summary
- Report pipeline status
- Optional Slack notifications (configurable)

## 🔐 Security

This project follows security best practices:

- **Docker Security**: Multi-stage builds, non-root user, minimal attack surface
- **Vulnerability Scanning**: Trivy scans all images before deployment
- **Secrets Management**: No secrets in code, GitHub Secrets, Workload Identity
- **Network Security**: HTTPS only, private networking options
- **IAM**: Least privilege access, service account per environment
- **Monitoring**: Security alerts, audit logging, health checks

See [SECURITY.md](SECURITY.md) for detailed security policies and procedures.

## 📊 API Endpoints

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/` | GET | Home endpoint | JSON with app info |
| `/health` | GET | Health check | JSON with status |

### Example Requests

```bash
# Home endpoint
curl https://your-service-url.run.app/

# Response
{
  "message": "Flask CI/CD Demo",
  "version": "abc123def456",
  "status": "healthy"
}

# Health check
curl https://your-service-url.run.app/health

# Response
{
  "status": "healthy"
}
```

## 🌍 Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `PORT` | Application port | 8080 | No |
| `APP_VERSION` | Application version | 1.0.0 | No |
| `ENVIRONMENT` | Environment name | development | No |
| `LOG_LEVEL` | Logging level | INFO | No |

See [.env.example](.env.example) for complete configuration.

## 🧪 Testing

```bash
# Run all tests
pytest test_app.py -v

# Run with coverage
pytest test_app.py --cov=app --cov-report=html

# Run specific test
pytest test_app.py::test_home -v

# View coverage report
open htmlcov/index.html
```

## 📦 Deployment

### Automated Deployment
Push to `main` or `develop` branch triggers automatic deployment.

### Manual Deployment
```bash
# Build and push
docker build -t us-central1-docker.pkg.dev/$PROJECT_ID/flask-app-repo/flask-app:manual .
docker push us-central1-docker.pkg.dev/$PROJECT_ID/flask-app-repo/flask-app:manual

# Deploy to Cloud Run
gcloud run deploy flask-app \
  --image us-central1-docker.pkg.dev/$PROJECT_ID/flask-app-repo/flask-app:manual \
  --region us-central1 \
  --platform managed
```

### Rollback
```bash
# List revisions
gcloud run revisions list --service=flask-app --region=us-central1

# Rollback
gcloud run services update-traffic flask-app \
  --region=us-central1 \
  --to-revisions=REVISION_NAME=100
```

## 📈 Monitoring

### View Logs
```bash
# Cloud Run logs
gcloud run services logs read flask-app --region=us-central1 --limit=50

# Follow logs
gcloud run services logs tail flask-app --region=us-central1
```

### Metrics
- View metrics in [GCP Console](https://console.cloud.google.com/run)
- Monitor request count, latency, error rate
- Set up alerting for anomalies

### Health Checks
```bash
# Check service health
curl https://your-service-url.run.app/health

# Check with response time
time curl https://your-service-url.run.app/
```

## 🛠️ Development

### Adding New Features

1. Create feature branch
```bash
git checkout -b feature/new-feature
```

2. Make changes and test locally
```bash
pytest test_app.py -v
docker build -t flask-app:test .
docker run -p 8080:8080 flask-app:test
```

3. Commit and push
```bash
git add .
git commit -m "Add new feature"
git push origin feature/new-feature
```

4. Create pull request to `develop`
5. After approval, merge to `develop` (deploys to staging)
6. Create pull request from `develop` to `main`
7. After approval, merge to `main` (deploys to production)

### Adding Tests

Add tests to `test_app.py`:

```python
def test_new_endpoint(client):
    response = client.get('/new-endpoint')
    assert response.status_code == 200
    data = json.loads(response.data)
    assert data['key'] == 'expected_value'
```

## 📖 Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Comprehensive deployment guide
- [SECURITY.md](SECURITY.md) - Security policies and best practices
- [.env.example](.env.example) - Environment configuration template

## 🐛 Troubleshooting

### Common Issues

**Problem**: Security scan fails  
**Solution**: Update dependencies, review Trivy report, rebuild with latest base image

**Problem**: Deployment fails  
**Solution**: Check Cloud Run logs, verify IAM permissions, check quotas

**Problem**: Tests fail locally  
**Solution**: Ensure virtual environment is activated, dependencies installed

**Problem**: Docker build fails  
**Solution**: Check Docker daemon is running, verify Dockerfile syntax

See [DEPLOYMENT.md](DEPLOYMENT.md#monitoring-and-troubleshooting) for more troubleshooting guides.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Ensure all tests pass
6. Submit a pull request

## 📝 License

This project is open source and available under the MIT License.

## 👥 Authors

- Your Name - Initial work

## 🙏 Acknowledgments

- Flask framework
- Google Cloud Platform
- GitHub Actions
- Trivy Security Scanner
- Terraform

## 📞 Support

For issues and questions:
- Check the [documentation](DEPLOYMENT.md)
- Review [security policies](SECURITY.md)
- Check GitHub Issues
- Contact: your-email@example.com

## 🔗 Links

- [Live Application](https://your-service-url.run.app)
- [GCP Console](https://console.cloud.google.com)
- [GitHub Repository](https://github.com/your-username/your-repo)
- [CI/CD Dashboard](https://github.com/your-username/your-repo/actions)

---

**Status**: Production Ready ✅  
**Last Updated**: 2026-07-22  
**Version**: 1.0.0
