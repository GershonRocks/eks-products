#!/bin/bash

# Quick Setup Script for Jenkins Pipeline
# This script helps you configure the minimal requirements to test the pipeline

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE} EKS Products Pipeline Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo

print_status "Setting up Jenkins pipeline for EKS Products..."

# Check prerequisites
print_status "Checking prerequisites..."

# Check AWS CLI
if aws sts get-caller-identity > /dev/null 2>&1; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    print_success "AWS CLI configured (Account: $AWS_ACCOUNT)"
else
    print_error "AWS CLI not configured. Please run 'aws configure'"
    exit 1
fi

# Check kubectl
if kubectl cluster-info > /dev/null 2>&1; then
    print_success "Kubernetes cluster accessible"
else
    print_error "Kubernetes cluster not accessible. Please configure kubectl"
    exit 1
fi

# Check ECR repository
ECR_URI=$(aws ecr describe-repositories --repository-names eks-products --query 'repositories[0].repositoryUri' --output text 2>/dev/null || echo "")
if [[ -n "$ECR_URI" ]]; then
    print_success "ECR repository found: $ECR_URI"
else
    print_warning "ECR repository not found. Creating..."
    aws ecr create-repository --repository-name eks-products
    ECR_URI=$(aws ecr describe-repositories --repository-names eks-products --query 'repositories[0].repositoryUri' --output text)
    print_success "ECR repository created: $ECR_URI"
fi

# Get ArgoCD server
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
if [[ -n "$ARGOCD_SERVER" ]]; then
    print_success "ArgoCD server found: $ARGOCD_SERVER"
else
    print_warning "ArgoCD server not found. Please ensure ArgoCD is installed"
fi

echo
print_status "Generating pipeline configuration..."

# Create Jenkins environment file
cat > jenkins-env-vars.txt << EOF
# Copy these environment variables to Jenkins Pipeline configuration
# Go to Jenkins → Pipeline → Environment

AWS_DEFAULT_REGION=us-east-1
AWS_ACCOUNT_ID=$AWS_ACCOUNT
ECR_REGISTRY=$ECR_URI
ECR_REPOSITORY=eks-products
DOCKER_BUILDKIT=1
MAVEN_OPTS=-Xmx2048m -XX:MaxPermSize=512m
ARGOCD_SERVER=$ARGOCD_SERVER
K8S_CLUSTER_NAME=eks-products-cluster
APP_NAME=eks-products
HELM_CHART_PATH=helm/eks-products
EOF

print_success "Environment variables saved to jenkins-env-vars.txt"

echo
print_status "Creating minimal credentials guide..."

cat > minimal-credentials-setup.md << 'EOF'
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
EOF

print_success "Minimal setup guide created: minimal-credentials-setup.md"

echo
print_status "Creating kubeconfig for Jenkins..."

# Copy kubeconfig to Jenkins-friendly location
mkdir -p ~/.jenkins
cp ~/.kube/config ~/.jenkins/kubeconfig 2>/dev/null || print_warning "Could not copy kubeconfig"

echo
print_success "🎉 Pipeline setup completed!"
print_status "Next steps:"
echo "  1. Open Jenkins: http://54.166.37.229:8080"
echo "  2. Follow minimal-credentials-setup.md to add credentials"
echo "  3. Create new Pipeline job with your GitHub repository"
echo "  4. Use jenkins-env-vars.txt for environment configuration"
echo "  5. Run your first pipeline build!"

echo
print_status "Ready to create Jenkins pipeline? (Y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]] || [[ -z "$response" ]]; then
    print_status "Opening Jenkins in browser..."
    if command -v open > /dev/null; then
        open "http://54.166.37.229:8080"
    elif command -v xdg-open > /dev/null; then
        xdg-open "http://54.166.37.229:8080"
    else
        print_status "Please open: http://54.166.37.229:8080"
    fi
fi

echo
print_success "Setup script completed!"
EOF
