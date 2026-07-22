# CI/CD Pipeline Architecture

## Visual Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          DEVELOPER WORKFLOW                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
            ┌───────────┐   ┌───────────┐   ┌───────────┐
            │  Feature  │   │   Pull    │   │   Push    │
            │  Branch   │   │  Request  │   │  to Main  │
            └───────────┘   └───────────┘   └───────────┘
                    │               │               │
                    └───────────────┼───────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        GITHUB ACTIONS TRIGGER                            │
│                   (on: push, pull_request)                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
        ╔═══════════════════════════════════════════════════╗
        ║            STAGE 1: TEST (Parallel)               ║
        ╚═══════════════════════════════════════════════════╝
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌──────────────┐           ┌──────────────┐          ┌──────────────┐
│   Checkout   │           │  Setup Py    │          │   Install    │
│     Code     │──────────▶│  3.11 with   │─────────▶│ Dependencies │
│              │           │  Pip Cache   │          │              │
└──────────────┘           └──────────────┘          └──────────────┘
        │
        ▼
┌──────────────┐           ┌──────────────┐
│  Run Pytest  │──────────▶│   Upload     │
│  with Cov    │           │  Coverage    │
└──────────────┘           └──────────────┘
        │
        │ [PASS] ✅
        ▼
        ╔═══════════════════════════════════════════════════╗
        ║         STAGE 2: BUILD & SCAN (Sequential)        ║
        ╚═══════════════════════════════════════════════════╝
        │
        ▼
┌──────────────┐           ┌──────────────┐          ┌──────────────┐
│  Setup       │──────────▶│  Build       │─────────▶│  Docker      │
│  BuildKit    │           │  Docker      │          │  Image       │
└──────────────┘           │  w/ Cache    │          │  Ready       │
                           └──────────────┘          └──────────────┘
                                    │
                                    ▼
                           ┌──────────────┐
                           │    Trivy     │
                           │   Security   │
                           │     Scan     │
                           └──────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
            ┌───────────┐   ┌───────────┐   ┌───────────┐
            │  Upload   │   │  Upload   │   │   Fail    │
            │   SARIF   │   │   JSON    │   │   Build   │
            │  GitHub   │   │  Report   │   │    if     │
            │  Security │   │  Artifact │   │ CRITICAL/ │
            │           │   │           │   │   HIGH    │
            └───────────┘   └───────────┘   └───────────┘
                    │
                    │ [PASS] ✅
                    ▼
        ╔═══════════════════════════════════════════════════╗
        ║         STAGE 3: DEPLOY (Conditional)             ║
        ╚═══════════════════════════════════════════════════╝
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌────────────────┐      ┌────────────────┐
│   STAGING      │      │  PRODUCTION    │
│  (develop)     │      │    (main)      │
└────────────────┘      └────────────────┘
        │                       │
        ▼                       ▼
┌────────────────┐      ┌────────────────┐
│ Authenticate   │      │ Authenticate   │
│  to GCP via    │      │  to GCP via    │
│   Workload     │      │   Workload     │
│   Identity     │      │   Identity     │
└────────────────┘      └────────────────┘
        │                       │
        ▼                       ▼
┌────────────────┐      ┌────────────────┐
│  Build Image   │      │  Build Image   │
│   with SHA     │      │   with SHA     │
│   staging-*    │      │   prod-*       │
└────────────────┘      └────────────────┘
        │                       │
        ▼                       ▼
┌────────────────┐      ┌────────────────┐
│  Push to       │      │  Push to       │
│  Artifact      │      │  Artifact      │
│  Registry      │      │  Registry      │
└────────────────┘      └────────────────┘
        │                       │
        ▼                       ▼
┌────────────────┐      ┌────────────────┐
│  Deploy to     │      │  Deploy to     │
│  Cloud Run     │      │  Cloud Run     │
│  (staging)     │      │  (production)  │
│  - 0 min inst  │      │  - 1 min inst  │
│  - 10 max      │      │  - 100 max     │
│  - 1 CPU       │      │  - 2 CPU       │
│  - 512Mi RAM   │      │  - 1Gi RAM     │
└────────────────┘      └────────────────┘
        │                       │
        ▼                       ▼
┌────────────────┐      ┌────────────────┐
│  Wait 10s      │      │  Wait 10s      │
│  Health Check  │      │  Health Check  │
│  /health       │      │  /health       │
└────────────────┘      └────────────────┘
        │                       │
        │ [PASS] ✅             │ [PASS] ✅
        └───────────┬───────────┘
                    │
                    ▼
        ╔═══════════════════════════════════════════════════╗
        ║         STAGE 4: NOTIFY (Always Runs)             ║
        ╚═══════════════════════════════════════════════════╝
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Determine│  │  Create  │  │ Optional │
│  Status  │─▶│   Job    │─▶│  Slack   │
│ Success/ │  │ Summary  │  │  Notify  │
│  Failure │  │          │  │          │
└──────────┘  └──────────┘  └──────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        DEPLOYMENT COMPLETE                               │
│                                                                          │
│  ✅ Tests Passed                                                        │
│  ✅ Security Scan Clean                                                 │
│  ✅ Image in Registry                                                   │
│  ✅ Deployed to Cloud Run                                               │
│  ✅ Health Check Passed                                                 │
└─────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Test Stage
- **Duration**: ~2-3 minutes
- **Caching**: Pip packages cached
- **Output**: Test results, coverage report
- **Failure Action**: Stop pipeline, no deployment

### 2. Build & Scan Stage
- **Duration**: ~3-5 minutes
- **Caching**: Docker layers, BuildKit cache
- **Security Tool**: Trivy
- **Scan Targets**: OS packages, Python dependencies
- **Severity Threshold**: CRITICAL, HIGH
- **Output**: SARIF report (GitHub Security), JSON artifact
- **Failure Action**: Stop pipeline if vulnerabilities found

### 3. Deploy Stage
- **Staging**:
  - Trigger: Push to develop branch
  - Environment: flask-app-staging
  - Scale: 0-10 instances
  - Resources: 1 CPU, 512Mi
  
- **Production**:
  - Trigger: Push to main branch
  - Environment: flask-app
  - Scale: 1-100 instances
  - Resources: 2 CPU, 1Gi
  - Optional: Requires approval

### 4. Notify Stage
- **Always runs**: Even on failure
- **Outputs**: 
  - GitHub Step Summary
  - Job status per stage
  - Optional Slack/Email notification

## Data Flow

```
┌──────────────┐
│  Source Code │
│   (GitHub)   │
└──────┬───────┘
       │
       ▼
┌──────────────┐    ┌─────────────┐
│   Tests +    │───▶│  Coverage   │
│  Build Logs  │    │   Report    │
└──────┬───────┘    └─────────────┘
       │
       ▼
┌──────────────┐    ┌─────────────┐
│    Docker    │───▶│   Trivy     │
│    Image     │    │   Report    │
└──────┬───────┘    └─────────────┘
       │
       ▼
┌──────────────┐    ┌─────────────┐
│   Artifact   │───▶│  Cloud Run  │
│   Registry   │    │  (Running)  │
└──────────────┘    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  Production │
                    │     App     │
                    └─────────────┘
```

## Security Checkpoints

```
┌────────────────────────────────────────────────────────┐
│            Security Gates in Pipeline                   │
├────────────────────────────────────────────────────────┤
│                                                         │
│  1. ✅ Code in Version Control (GitHub)                │
│  2. ✅ Tests Must Pass (pytest)                        │
│  3. ✅ Security Scan Must Pass (Trivy)                 │
│  4. ✅ No CRITICAL/HIGH Vulnerabilities                │
│  5. ✅ Workload Identity Auth (No Keys)                │
│  6. ✅ Health Check Post-Deploy                        │
│  7. ✅ Non-Root Container User                         │
│  8. ✅ Multi-Stage Build (Minimal Surface)             │
│                                                         │
└────────────────────────────────────────────────────────┘
```

## Environment Comparison

```
┌─────────────────┬──────────────────┬──────────────────┐
│   Attribute     │     STAGING      │   PRODUCTION     │
├─────────────────┼──────────────────┼──────────────────┤
│ Branch          │ develop          │ main             │
│ Service Name    │ flask-app-staging│ flask-app        │
│ Min Instances   │ 0                │ 1                │
│ Max Instances   │ 10               │ 100              │
│ CPU             │ 1                │ 2                │
│ Memory          │ 512Mi            │ 1Gi              │
│ Timeout         │ 300s             │ 300s             │
│ Approval        │ No               │ Optional         │
│ Image Tag       │ staging-{sha}    │ {sha}            │
└─────────────────┴──────────────────┴──────────────────┘
```

## Rollback Process

```
┌─────────────────────────────────────────────────────────┐
│              Rollback Procedure                          │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │  Issue Detected  │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │  List Revisions  │
              │  gcloud run      │
              │  revisions list  │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │ Select Previous  │
              │ Known-Good Rev   │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │  Update Traffic  │
              │  100% to Old Rev │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │  Verify Health   │
              │  Check Passes    │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │    Rollback      │
              │    Complete      │
              └──────────────────┘
```

## Monitoring Flow

```
┌─────────────────────────────────────────────────────────┐
│                  Monitoring Stack                        │
└─────────────────────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   GitHub     │ │  Cloud Run   │ │  Security    │
│   Actions    │ │    Logs      │ │   Scanning   │
│   Status     │ │              │ │   Reports    │
└──────────────┘ └──────────────┘ └──────────────┘
        │                │                │
        └────────────────┼────────────────┘
                         │
                         ▼
                ┌──────────────────┐
                │   Alerting       │
                │  (Configurable)  │
                │  - Slack         │
                │  - Email         │
                │  - PagerDuty     │
                └──────────────────┘
```

## Cost Flow

```
┌────────────────────────────────────────────────────┐
│              Resource Costs                         │
├────────────────────────────────────────────────────┤
│                                                     │
│  GitHub Actions:                                   │
│  ✅ Free for public repos                          │
│  💰 Metered for private (included in plan)         │
│                                                     │
│  Cloud Run:                                        │
│  💰 Pay per request + CPU time                     │
│  💰 ~$0.00002400/GB-second (memory)                │
│  💰 ~$0.00002400/vCPU-second (CPU)                 │
│                                                     │
│  Artifact Registry:                                │
│  💰 $0.10/GB storage                               │
│  💰 Free egress to Cloud Run                       │
│                                                     │
│  Networking:                                       │
│  ✅ Free for most operations                       │
│                                                     │
│  Estimated Monthly (low traffic):                  │
│  💰 $5-20/month                                    │
│                                                     │
└────────────────────────────────────────────────────┘
```

## Pipeline Metrics

- **Average Pipeline Duration**: 8-12 minutes
- **Test Stage**: 2-3 minutes
- **Build & Scan**: 3-5 minutes
- **Deploy**: 2-3 minutes
- **Notify**: <1 minute

**Optimization Factors**:
- Pip caching: ~30% faster
- Docker layer caching: ~40% faster
- BuildKit: ~20% faster
- Overall: ~60% faster than without caching

---

**Last Updated**: 2026-07-22  
**Version**: 1.0.0
