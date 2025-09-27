# 🔐 Jenkins Credentials Configuration Guide

## Required Credentials for EKS Products Pipeline

### 1. 🔑 **AWS Credentials**
**Purpose**: ECR push, EKS access, S3 operations

1. Go to Jenkins → **Manage Jenkins** → **Manage Credentials**
2. Click on **Global** domain
3. Click **Add Credentials**
4. Select **AWS Credentials**
5. Configure:
   - **ID**: `aws-credentials`
   - **Access Key ID**: `your-aws-access-key`
   - **Secret Access Key**: `your-aws-secret-key`
   - **Description**: `AWS credentials for ECR and EKS`

### 2. 🐙 **GitHub Credentials**
**Purpose**: Repository access, webhook triggers

1. **Add Credentials** → **Username with password**
2. Configure:
   - **ID**: `github-credentials`
   - **Username**: `your-github-username`
   - **Password**: `your-github-personal-access-token`
   - **Description**: `GitHub access for eks-products repo`

### 3. 📊 **SonarQube Token**
**Purpose**: Code quality analysis

1. **Add Credentials** → **Secret text**
2. Configure:
   - **ID**: `sonar-token`
   - **Secret**: `your-sonarqube-token`
   - **Description**: `SonarQube authentication token`

### 4. 🛡️ **Snyk Authentication Token**
**Purpose**: Security vulnerability scanning

1. **Add Credentials** → **Secret text**
2. Configure:
   - **ID**: `snyk-token`
   - **Secret**: `your-snyk-auth-token`
   - **Description**: `Snyk security scanning token`

### 5. 🔔 **Slack Webhook**
**Purpose**: Build notifications

1. **Add Credentials** → **Secret text**
2. Configure:
   - **ID**: `slack-webhook`
   - **Secret**: `your-slack-webhook-url`
   - **Description**: `Slack webhook for notifications`

### 6. ☸️ **Kubernetes Config**
**Purpose**: EKS cluster access

1. **Add Credentials** → **Secret file**
2. Configure:
   - **ID**: `kubeconfig`
   - **File**: Upload your `~/.kube/config` file
   - **Description**: `Kubernetes config for EKS access`

### 7. 🎯 **ArgoCD Token**
**Purpose**: Application deployment via ArgoCD

1. **Add Credentials** → **Secret text**
2. Configure:
   - **ID**: `argocd-auth-token`
   - **Secret**: `your-argocd-auth-token`
   - **Description**: `ArgoCD authentication token`

## 🛠️ How to Get These Credentials

### AWS Credentials
```bash
# From your AWS CLI configuration
aws configure list
# Or create new IAM user with ECR and EKS permissions
```

### GitHub Personal Access Token
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token with `repo`, `workflow`, `admin:repo_hook` scopes

### SonarQube Token
1. SonarQube → My Account → Security → Generate Tokens
2. Or use SonarCloud if you're using the cloud version

### Snyk Token
1. Snyk.io → Account Settings → API Token
2. Copy the authentication token

### Slack Webhook
1. Slack → Apps → Incoming Webhooks
2. Create new webhook for your channel
3. Copy the webhook URL

### ArgoCD Token
```bash
# Login to ArgoCD and get token
argocd login <argocd-server>
argocd account generate-token
```

## ⚠️ Security Best Practices

1. **Never commit credentials** to version control
2. **Use least privilege** for all credentials
3. **Rotate credentials regularly**
4. **Monitor credential usage** in Jenkins logs
5. **Use credential binding** in pipeline scripts

## ✅ Verification

After adding credentials, verify in Jenkins:
1. **Manage Jenkins** → **Manage Credentials**
2. Check that all 7 credential IDs are present:
   - `aws-credentials`
   - `github-credentials`
   - `sonar-token`
   - `snyk-token`
   - `slack-webhook`
   - `kubeconfig`
   - `argocd-auth-token`
