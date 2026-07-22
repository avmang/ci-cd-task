# Security Policy

## Overview
This document outlines the security practices, policies, and procedures for the Flask CI/CD application.

## Security Scanning

### Automated Security Scans
- **Trivy**: Scans Docker images for vulnerabilities in OS packages and application dependencies
- **Frequency**: Every push to main/develop branches
- **Severity Threshold**: CRITICAL and HIGH vulnerabilities block deployment
- **Reports**: Available in GitHub Security tab and as workflow artifacts

### Manual Security Audits
Conduct manual security audits:
- Before major releases
- After significant dependency updates
- Quarterly security reviews

## Vulnerability Management

### Response Times
- **CRITICAL**: Fix within 24 hours
- **HIGH**: Fix within 7 days
- **MEDIUM**: Fix within 30 days
- **LOW**: Fix during regular maintenance

### Process
1. Security scan identifies vulnerability
2. Review CVE details and impact
3. Update affected packages
4. Test the fix
5. Deploy through standard CI/CD pipeline
6. Verify vulnerability is resolved

## Secrets Management

### Prohibited Practices
❌ Never commit secrets to Git
❌ Never hardcode API keys or passwords
❌ Never log sensitive information
❌ Never expose secrets in error messages

### Recommended Practices
✅ Use GitHub Secrets for CI/CD credentials
✅ Use GCP Secret Manager for application secrets
✅ Use environment variables for configuration
✅ Rotate secrets regularly (every 90 days)
✅ Use Workload Identity instead of service account keys
✅ Enable secret scanning in GitHub

### Secret Rotation
```bash
# Rotate GitHub Actions service account
gcloud iam service-accounts keys create new-key.json \
  --iam-account=github-actions@PROJECT_ID.iam.gserviceaccount.com

# Update GitHub Secrets
# Delete old key after verification
gcloud iam service-accounts keys delete KEY_ID \
  --iam-account=github-actions@PROJECT_ID.iam.gserviceaccount.com
```

## Docker Security

### Image Security Best Practices
1. **Base Images**
   - Use official images from trusted sources
   - Use specific version tags, not `latest`
   - Prefer slim/alpine variants when possible

2. **Build Process**
   - Use multi-stage builds to minimize attack surface
   - Remove unnecessary packages and files
   - Don't include development dependencies in production images

3. **Runtime Security**
   - Run containers as non-root user
   - Use read-only root filesystem when possible
   - Minimize capabilities
   - Set resource limits

4. **Image Scanning**
   - Scan all images before deployment
   - Fail builds on critical vulnerabilities
   - Keep base images updated
   - Monitor for new vulnerabilities

### Dockerfile Security Checklist
- ✅ Multi-stage build
- ✅ Non-root user (UID 1000)
- ✅ Specific version tags
- ✅ No secrets in layers
- ✅ Minimal attack surface
- ✅ Health checks configured
- ✅ Resource limits set

## Cloud Run Security

### Service Configuration
```bash
# Deploy with security best practices
gcloud run deploy flask-app \
  --image=IMAGE_URL \
  --region=us-central1 \
  --platform=managed \
  --no-allow-unauthenticated \  # Require authentication
  --service-account=SA_EMAIL \   # Use specific SA
  --cpu=2 \
  --memory=1Gi \
  --max-instances=100 \
  --min-instances=1 \
  --timeout=300 \
  --concurrency=80 \
  --ingress=internal-and-cloud-load-balancing  # Restrict ingress
```

### IAM and Access Control
1. **Principle of Least Privilege**
   - Grant minimum necessary permissions
   - Use specific roles, not primitive roles
   - Review permissions regularly

2. **Service Accounts**
   - Use separate service accounts per service
   - Don't use default Compute Engine service account
   - Rotate service account keys regularly

3. **Workload Identity**
   - Preferred over service account keys
   - Configured in Terraform
   - No key management required

## Network Security

### HTTPS/TLS
- Cloud Run provides HTTPS by default
- Custom domains should use managed SSL certificates
- Enforce HTTPS only (no HTTP)

### CORS Configuration
```python
# In production, specify exact origins
from flask_cors import CORS

CORS(app, resources={
    r"/*": {
        "origins": ["https://yourdomain.com"],
        "methods": ["GET", "POST"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
```

### Rate Limiting
Consider implementing rate limiting:
```python
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)
```

## Application Security

### Input Validation
- Validate all user inputs
- Sanitize data before processing
- Use parameterized queries for databases
- Implement proper error handling

### Security Headers
```python
from flask import Flask
from flask_talisman import Talisman

app = Flask(__name__)
Talisman(app, 
         force_https=True,
         strict_transport_security=True,
         content_security_policy={
             'default-src': "'self'",
             'script-src': "'self'",
             'style-src': "'self'"
         })
```

### Authentication and Authorization
For production applications:
- Implement proper authentication (OAuth 2.0, JWT)
- Use secure session management
- Implement authorization checks
- Log authentication events

### Dependency Management
```bash
# Check for vulnerable dependencies
pip install safety
safety check

# Update dependencies
pip list --outdated
pip install --upgrade PACKAGE_NAME

# Lock dependencies
pip freeze > requirements.txt
```

## Monitoring and Logging

### Security Logging
Log the following events:
- Authentication attempts (success/failure)
- Authorization failures
- Input validation failures
- Rate limiting events
- Errors and exceptions

### Log Security
- Don't log sensitive data (passwords, tokens, PII)
- Use structured logging (JSON format)
- Enable Cloud Logging
- Set up log-based alerting

### Monitoring
```bash
# Set up Cloud Monitoring alerts
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="High Error Rate" \
  --condition-display-name="Error rate > 5%" \
  --condition-threshold-value=5 \
  --condition-threshold-duration=300s
```

## Incident Response

### Security Incident Procedure
1. **Detection**: Identify potential security incident
2. **Containment**: Isolate affected systems
3. **Investigation**: Determine scope and impact
4. **Remediation**: Fix vulnerability and restore service
5. **Review**: Post-incident analysis and improvements

### Incident Response Contacts
- Security Team: security@example.com
- On-call Engineer: oncall@example.com
- GCP Support: [Contact support](https://cloud.google.com/support)

### Emergency Rollback
```bash
# Quick rollback to previous version
gcloud run services update-traffic flask-app \
  --region=us-central1 \
  --to-revisions=PREVIOUS_REVISION=100

# Or deploy specific known-good version
gcloud run deploy flask-app \
  --image=us-central1-docker.pkg.dev/PROJECT/REPO/flask-app:KNOWN_GOOD_SHA \
  --region=us-central1
```

## Compliance

### Data Protection
- Implement data encryption at rest and in transit
- Follow data retention policies
- Implement proper data deletion procedures
- Comply with GDPR/CCPA if applicable

### Audit Logging
```bash
# Enable Cloud Audit Logs
gcloud projects get-iam-policy PROJECT_ID

# View audit logs
gcloud logging read "logName=projects/PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity"
```

## Security Checklist

### Pre-Deployment
- [ ] Security scan passed
- [ ] Dependencies updated
- [ ] Secrets properly managed
- [ ] IAM permissions reviewed
- [ ] Security headers configured
- [ ] Input validation implemented
- [ ] Error handling doesn't expose sensitive info
- [ ] Logging configured properly
- [ ] Monitoring and alerts set up

### Post-Deployment
- [ ] Health checks passing
- [ ] No security alerts triggered
- [ ] Logs reviewed for anomalies
- [ ] Performance within expected range
- [ ] Backup/rollback procedure verified

### Regular Maintenance (Monthly)
- [ ] Review security scan results
- [ ] Update dependencies
- [ ] Review access logs
- [ ] Check for security advisories
- [ ] Review IAM permissions
- [ ] Test backup/restore procedures

### Quarterly Reviews
- [ ] Comprehensive security audit
- [ ] Penetration testing (if applicable)
- [ ] Disaster recovery testing
- [ ] Security training review
- [ ] Update security documentation

## Reporting Security Vulnerabilities

If you discover a security vulnerability:

1. **Do not** create a public GitHub issue
2. **Do not** exploit the vulnerability
3. Email security@example.com with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within 24 hours and work with you to address the issue.

## Security Resources

### Tools
- [Trivy](https://github.com/aquasecurity/trivy) - Container vulnerability scanner
- [Safety](https://github.com/pyupio/safety) - Python dependency checker
- [OWASP ZAP](https://www.zaproxy.org/) - Web application security scanner
- [Bandit](https://github.com/PyCQA/bandit) - Python code security analyzer

### References
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)
- [Cloud Run Security](https://cloud.google.com/run/docs/securing/overview)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)

## Updates
This security policy is reviewed and updated quarterly.
Last updated: 2026-07-22
