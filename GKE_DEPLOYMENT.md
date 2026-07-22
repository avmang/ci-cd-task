# GKE Deployment Guide

This guide covers deploying the Flask application to Google Kubernetes Engine (GKE).

## Architecture

```
GitHub Actions CI/CD
        ↓
   Docker Build
        ↓
  Security Scan (Trivy)
        ↓
  Artifact Registry
        ↓
      GKE Cluster
        ↓
   LoadBalancer Service
        ↓
  Public Application
```

## Prerequisites

- GCP project with billing enabled
- GitHub repository
- Terraform installed
- kubectl installed
- gcloud CLI installed

## Infrastructure Components

### GKE Cluster
- **Name**: mavoyan-flask-app-cluster
- **Type**: Regional cluster in us-central1
- **Node Pool**: 2-5 nodes with e2-medium machines
- **Features**: Workload Identity, auto-scaling, auto-repair

### Kubernetes Resources
- **Deployment**: 3 replicas with rolling updates
- **Service**: LoadBalancer type for external access
- **HPA**: Auto-scales 2-10 pods based on CPU/memory
- **ServiceAccount**: For Workload Identity integration

## Deployment Steps

### 1. Deploy GKE Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file=environments/production.tfvars

# Apply the configuration (this will create GKE cluster)
terraform apply -var-file=environments/production.tfvars
```

**Note**: GKE cluster creation takes 5-10 minutes.

### 2. Get GKE Credentials

```bash
# Get cluster credentials
gcloud container clusters get-credentials mavoyan-flask-app-cluster \
  --region us-central1 \
  --project YOUR_PROJECT_ID

# Verify connection
kubectl cluster-info
kubectl get nodes
```

### 3. Configure GitHub Secrets

Add to GitHub repository → Settings → Secrets:
- `GCP_PROJECT_ID`: Your GCP project ID
- `GCP_WORKLOAD_IDENTITY_PROVIDER`: From terraform output
- `GCP_SERVICE_ACCOUNT`: From terraform output

### 4. Deploy via CI/CD

```bash
# Push to main branch triggers production deployment
git push origin main

# Or push to develop for staging
git push origin develop
```

### 5. Manual Deployment (Optional)

```bash
# Get GKE credentials
gcloud container clusters get-credentials mavoyan-flask-app-cluster \
  --region us-central1

# Update manifests with your project ID
sed -i "s|PROJECT_ID|your-project-id|g" k8s/*.yaml

# Apply Kubernetes manifests
kubectl apply -f k8s/serviceaccount.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml

# Wait for deployment
kubectl rollout status deployment/mavoyan-flask-app

# Get external IP
kubectl get service mavoyan-flask-app
```

## Verification

### Check Deployment Status

```bash
# Check pods
kubectl get pods -l app=mavoyan-flask-app

# Check deployment
kubectl get deployment mavoyan-flask-app

# Check service
kubectl get service mavoyan-flask-app

# Check HPA
kubectl get hpa
```

### View Logs

```bash
# View logs from all pods
kubectl logs -l app=mavoyan-flask-app --tail=100

# Follow logs
kubectl logs -l app=mavoyan-flask-app -f

# View logs from specific pod
kubectl logs POD_NAME
```

### Test Application

```bash
# Get external IP
EXTERNAL_IP=$(kubectl get service mavoyan-flask-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test home endpoint
curl http://$EXTERNAL_IP/

# Test health endpoint
curl http://$EXTERNAL_IP/health
```

## Scaling

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment mavoyan-flask-app --replicas=5

# Scale node pool
gcloud container clusters resize mavoyan-flask-app-cluster \
  --node-pool mavoyan-flask-app-node-pool \
  --num-nodes 3 \
  --region us-central1
```

### Auto-scaling

The HPA automatically scales based on:
- CPU utilization (target: 70%)
- Memory utilization (target: 80%)
- Min replicas: 2
- Max replicas: 10

```bash
# Check HPA status
kubectl get hpa mavoyan-flask-app

# Describe HPA
kubectl describe hpa mavoyan-flask-app
```

## Updates and Rollouts

### Rolling Update

```bash
# Update image
kubectl set image deployment/mavoyan-flask-app \
  flask-app=us-central1-docker.pkg.dev/PROJECT_ID/mavoyan-flask-app-repo/mavoyan-flask-app:NEW_TAG

# Watch rollout
kubectl rollout status deployment/mavoyan-flask-app

# Check rollout history
kubectl rollout history deployment/mavoyan-flask-app
```

### Rollback

```bash
# Rollback to previous version
kubectl rollout undo deployment/mavoyan-flask-app

# Rollback to specific revision
kubectl rollout undo deployment/mavoyan-flask-app --to-revision=2

# Check rollout status
kubectl rollout status deployment/mavoyan-flask-app
```

## Monitoring

### View Metrics

```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods -l app=mavoyan-flask-app

# Resource usage
kubectl describe nodes
```

### GCP Console Monitoring

1. Go to: https://console.cloud.google.com/kubernetes
2. Select your cluster: mavoyan-flask-app-cluster
3. View:
   - Workloads
   - Services & Ingress
   - Storage
   - Configuration
   - Logs

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -l app=mavoyan-flask-app

# Describe pod
kubectl describe pod POD_NAME

# View events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check logs
kubectl logs POD_NAME
```

### LoadBalancer Pending

```bash
# Check service
kubectl describe service mavoyan-flask-app

# Check GCP load balancer
gcloud compute forwarding-rules list

# Check firewall rules
gcloud compute firewall-rules list
```

### Image Pull Errors

```bash
# Check if node can pull from Artifact Registry
kubectl describe pod POD_NAME | grep -A 10 Events

# Verify service account permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:mavoyan-gke-nodes@*"
```

### Health Check Failures

```bash
# Test health endpoint from pod
kubectl exec -it POD_NAME -- curl localhost:8080/health

# Check probe configuration
kubectl describe pod POD_NAME | grep -A 5 Liveness
kubectl describe pod POD_NAME | grep -A 5 Readiness
```

## Resource Management

### Resource Quotas

Current pod resources:
- Requests: 100m CPU, 256Mi memory
- Limits: 500m CPU, 512Mi memory

### Cost Optimization

```bash
# Use preemptible nodes (update gke.tf)
# Set preemptible = true in node_config

# Scale down during off-hours (manual)
kubectl scale deployment mavoyan-flask-app --replicas=1

# Delete cluster when not in use
terraform destroy -var-file=environments/production.tfvars
```

## Security

### Pod Security

- Runs as non-root user (UID 1000)
- Read-only root filesystem
- Security context configured
- Network policies (optional)

### Workload Identity

Kubernetes ServiceAccount is bound to GCP ServiceAccount:
- K8s SA: `mavoyan-flask-app`
- GCP SA: `mavoyan-flask-app-k8s@PROJECT_ID.iam.gserviceaccount.com`

```bash
# Verify binding
kubectl describe serviceaccount mavoyan-flask-app
```

### Network Security

```bash
# Apply network policy (optional)
kubectl apply -f k8s/network-policy.yaml

# Check network policies
kubectl get networkpolicies
```

## Backup and Recovery

### Backup Configuration

```bash
# Export all resources
kubectl get all -o yaml > backup.yaml

# Export specific resources
kubectl get deployment mavoyan-flask-app -o yaml > deployment-backup.yaml
kubectl get service mavoyan-flask-app -o yaml > service-backup.yaml
```

### Disaster Recovery

```bash
# Restore from backup
kubectl apply -f backup.yaml

# Or restore specific resources
kubectl apply -f deployment-backup.yaml
kubectl apply -f service-backup.yaml
```

## Cleanup

### Delete Application

```bash
# Delete Kubernetes resources
kubectl delete -f k8s/

# Or delete individually
kubectl delete deployment mavoyan-flask-app
kubectl delete service mavoyan-flask-app
kubectl delete hpa mavoyan-flask-app-hpa
kubectl delete serviceaccount mavoyan-flask-app
```

### Delete GKE Cluster

```bash
cd terraform
terraform destroy -var-file=environments/production.tfvars
```

## Comparison: GKE vs Cloud Run

| Feature | GKE | Cloud Run |
|---------|-----|-----------|
| Container Orchestration | Full Kubernetes | Managed serverless |
| Scaling | Manual/HPA | Automatic |
| Cost | Always running | Pay per request |
| Flexibility | High | Limited |
| Complexity | Higher | Lower |
| Use Case | Complex apps | Simple services |

## Best Practices

1. **Use Workload Identity** instead of service account keys
2. **Enable auto-scaling** (HPA and cluster autoscaler)
3. **Set resource limits** on all containers
4. **Use health checks** (liveness and readiness probes)
5. **Monitor resources** via GCP Console
6. **Version your images** with specific tags
7. **Test in staging** before production
8. **Enable logging** to Cloud Logging
9. **Use network policies** for pod security
10. **Regular updates** of cluster and node versions

## Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [GKE Best Practices](https://cloud.google.com/architecture/best-practices-for-running-cost-effective-kubernetes-applications-on-gke)

---

**Last Updated**: 2026-07-23  
**Version**: 1.0.0
