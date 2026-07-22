# Kubernetes Deployment

## Environment Management

This project uses **Kubernetes Namespaces** to separate staging and production environments in the same GKE cluster.

### Namespaces

- **staging** - Pre-production testing environment
- **production** - Live production environment

### Deployment Flow

When code is pushed to the `main` branch:

1. Tests run
2. Docker image is built and scanned
3. Deploy to **staging** namespace
4. If staging succeeds → Deploy to **production** namespace

### Accessing Services

Each namespace has its own LoadBalancer with a unique external IP:

```bash
# Get staging URL
kubectl get service mavoyan-flask-app -n staging

# Get production URL
kubectl get service mavoyan-flask-app -n production
```

### Manual Deployment

To manually deploy to a specific environment:

```bash
# Deploy to staging
kubectl apply -f namespace-staging.yaml
kubectl apply -f serviceaccount.yaml -n staging
kubectl apply -f deployment.yaml -n staging
kubectl apply -f service.yaml -n staging
kubectl apply -f hpa.yaml -n staging

# Deploy to production
kubectl apply -f namespace-production.yaml
kubectl apply -f serviceaccount.yaml -n production
kubectl apply -f deployment.yaml -n production
kubectl apply -f service.yaml -n production
kubectl apply -f hpa.yaml -n production
```

### Check Deployment Status

```bash
# Staging
kubectl get pods -n staging
kubectl get svc -n staging
kubectl logs -f deployment/mavoyan-flask-app -n staging

# Production
kubectl get pods -n production
kubectl get svc -n production
kubectl logs -f deployment/mavoyan-flask-app -n production
```
