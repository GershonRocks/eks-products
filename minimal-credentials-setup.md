# 🚀 Minimal Jenkins Credentials Setup

## Required for Basic Pipeline Testing

### 1. AWS Credentials (REQUIRED)
```
Type: AWS Credentials
ID: aws-credentials
Access Key: [Get from AWS IAM]
Secret Key: [Get from AWS IAM]
```

### 2. GitHub Credentials (REQUIRED)
```
Type: Username with password
ID: github-credentials  
Username: [Your GitHub username]
Password: [GitHub Personal Access Token]
```

### 3. Optional Credentials (Can skip for initial testing)
```
- sonar-token (for SonarQube)
- snyk-token (for Snyk scanning)
- slack-webhook (for notifications)
- argocd-auth-token (for ArgoCD deployment)
```

## Quick Setup Steps:
1. Go to Jenkins: http://54.166.37.229:8080
2. Login: admin / <your-jenkins-password>
3. Manage Jenkins → Manage Credentials → Global → Add Credentials
4. Add AWS and GitHub credentials first
5. Create new Pipeline job
6. Set repository: https://github.com/GershonRocks/eks-products
7. Set script path: Jenkinsfile
8. Run pipeline!
