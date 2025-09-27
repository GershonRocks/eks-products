# 🚀 Simplified Jenkins Setup (Public GitHub Repo)

## Step 1: Essential Credentials (Minimal)

### Required Credentials:
1. **AWS Credentials** (ID: `aws-credentials`)
   - Type: AWS Credentials
   - Access Key ID: [Your AWS access key]
   - Secret Access Key: [Your AWS secret key]

### Optional Credentials (Skip for now):
- ~~GitHub credentials~~ (Not needed for public repo)
- ~~SonarQube token~~ (Pipeline will skip this stage)
- ~~Snyk token~~ (Pipeline will skip this stage)
- ~~Slack webhook~~ (No notifications for now)

## Step 2: Create Pipeline Job

### Pipeline Configuration:
- **Name**: `eks-products-pipeline`
- **Type**: Pipeline
- **Repository URL**: `https://github.com/GershonRocks/eks-products.git`
- **Credentials**: `- none -` (leave empty for public repo)
- **Branch**: `*/main`
- **Script Path**: `Jenkinsfile`

## Step 3: Expected First Run Results

### ✅ Should Work:
- ✅ Checkout from GitHub (public repo)
- ✅ Maven build and test
- ✅ Basic Docker build
- ✅ JaCoCo coverage report

### ⚠️ Will Skip (No credentials):
- ⚠️ SonarQube analysis (no token)
- ⚠️ Snyk security scan (no token)
- ⚠️ Slack notifications (no webhook)

### ❌ May Fail (Needs AWS setup):
- ❌ ECR push (needs AWS permissions)
- ❌ ArgoCD deployment (needs cluster access)

## Benefits of Starting Simple:
1. **Faster setup** - Only need AWS credentials
2. **Quick validation** - Test core pipeline functionality
3. **Incremental approach** - Add more credentials later
4. **Less complexity** - Fewer things to troubleshoot
