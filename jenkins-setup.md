# Jenkins CI/CD Pipeline Setup Guide

This guide provides comprehensive instructions for setting up the Jenkins CI/CD pipeline for the EKS Products application.

## 🚀 Overview

The Jenkins pipeline includes:
- ✅ **Maven Build & Test** - Compile, test, and package the Spring Boot application
- 🔍 **SonarQube Analysis** - Code quality and security analysis
- 🛡️ **Security Scanning** - Snyk dependency and container scanning
- 🐳 **Docker Build** - Multi-architecture container images
- 📦 **ECR Push** - AWS container registry
- 🚀 **ArgoCD Deployment** - GitOps-based deployment to EKS
- 🧪 **Post-Deployment Testing** - Health checks and smoke tests

## 📋 Prerequisites

### 1. Jenkins Server Requirements

- **Java**: OpenJDK 21 or newer
- **Jenkins**: 2.400+ with Blue Ocean plugin
- **Resources**: Minimum 4 CPU cores, 8GB RAM, 50GB storage
- **Network**: Access to GitHub, AWS, SonarQube, and Snyk APIs

### 2. Required Jenkins Plugins

Install these plugins via Jenkins Plugin Manager:

```bash
# Core CI/CD Plugins
- Pipeline (workflow-aggregator)
- Blue Ocean (blueocean)
- Git (git)
- GitHub (github)
- Docker Pipeline (docker-workflow)

# AWS Integration
- AWS Steps (pipeline-aws)
- Amazon ECR (amazon-ecr)
- AWS Credentials (aws-credentials-binding)

# Quality & Security
- SonarQube Scanner (sonar)
- OWASP Dependency Check (dependency-check-jenkins-plugin)
- HTML Publisher (htmlpublisher)

# Notifications
- Slack Notification (slack)
- Email Extension (email-ext)

# Utilities
- Build Timeout (build-timeout)
- Timestamper (timestamper)
- Workspace Cleanup (ws-cleanup)
```

### 3. System Dependencies

Ensure these tools are available on Jenkins agents:

```bash
# Required Tools
- Maven 3.9+
- Docker 24+
- kubectl 1.28+
- Helm 3.19+
- Node.js 18+ (for Snyk CLI)
- curl, git, jq

# Optional but Recommended
- yq (YAML processor)
- argocd CLI
```

## 🔧 Jenkins Configuration

### 1. Global Tool Configuration

Navigate to **Manage Jenkins** → **Global Tool Configuration**:

#### Maven Configuration
```
Name: Maven-3.9
Version: 3.9.5
Install automatically: ✅
Install from Apache: Maven 3.9.5
```

#### JDK Configuration
```
Name: OpenJDK-21
JAVA_HOME: /usr/lib/jvm/java-21-openjdk-amd64
Install automatically: ✅ (if needed)
```

#### Docker Configuration
```
Name: Docker
Install automatically: ✅
Docker version: latest
```

#### Git Configuration
```
Name: Default
Path to Git executable: git
```

### 2. System Configuration

Navigate to **Manage Jenkins** → **Configure System**:

#### SonarQube Servers
```
Name: SonarQube
Server URL: https://your-sonarqube-server.com
Server authentication token: Add via Jenkins credentials
```

#### Global Pipeline Libraries (Optional)
```
Name: shared-libraries
Default version: main
Retrieval method: Modern SCM
Source Code Management: Git
Repository URL: https://github.com/your-org/jenkins-shared-libraries
```

## 🔐 Credentials Setup

Add these credentials in **Manage Jenkins** → **Manage Credentials**:

### 1. AWS Credentials
```
Kind: AWS Credentials
ID: aws-credentials
Description: AWS credentials for ECR and EKS access
Access Key ID: [Your AWS Access Key]
Secret Access Key: [Your AWS Secret Key]
```

### 2. AWS Account ID
```
Kind: Secret text
ID: aws-account-id
Description: AWS Account ID for ECR registry
Secret: 123456789012
```

### 3. SonarQube Token
```
Kind: Secret text
ID: sonar-token
Description: SonarQube authentication token
Secret: [Your SonarQube token]
```

### 4. SonarQube Host URL
```
Kind: Secret text
ID: sonar-host-url
Description: SonarQube server URL
Secret: https://your-sonarqube-server.com
```

### 5. Snyk Token
```
Kind: Secret text
ID: snyk-token
Description: Snyk authentication token
Secret: [Your Snyk API token]
```

### 6. ArgoCD Configuration
```
# ArgoCD Server URL
Kind: Secret text
ID: argocd-server-url
Description: ArgoCD server URL
Secret: argocd.your-domain.com

# ArgoCD Auth Token
Kind: Secret text
ID: argocd-auth-token
Description: ArgoCD authentication token
Secret: [Your ArgoCD token]
```

### 7. Slack Integration (Optional)
```
Kind: Secret text
ID: slack-webhook
Description: Slack webhook URL for notifications
Secret: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

## 📊 Pipeline Configuration

### 1. Create Multi-branch Pipeline

1. **New Item** → **Multibranch Pipeline**
2. **Name**: `eks-products-pipeline`
3. **Branch Sources** → **Add source** → **GitHub**

#### GitHub Configuration:
```
Repository HTTPS URL: https://github.com/GershonRocks/eks-products
Credentials: Add GitHub credentials (username/token)
Behaviors:
  - Discover branches (All branches)
  - Discover pull requests from origin (Merging the pull request with the current target branch revision)
  - Clean before checkout
```

#### Build Configuration:
```
Build Configuration:
  Mode: by Jenkinsfile
  Script Path: Jenkinsfile
```

#### Scan Multibranch Pipeline Triggers:
```
Periodically if not otherwise run: ✅
Interval: 1 hour
```

### 2. Branch Strategy

The pipeline is configured to handle different branch types:

- **`main`**: Production deployments with full security scanning
- **`develop`**: Development deployments with comprehensive testing
- **`release/*`**: Staging deployments with production-like settings
- **`feature/*`**: Feature branch testing (limited deployment)
- **Pull Requests**: Code quality checks and security scanning

## 🔍 Quality Gates Configuration

### SonarQube Quality Gate

Configure in SonarQube dashboard:

```yaml
Conditions:
  - Coverage: > 70%
  - Duplicated Lines: < 3%
  - Maintainability Rating: A
  - Reliability Rating: A
  - Security Rating: A
  - Security Hotspots Reviewed: > 80%
  - New Code Coverage: > 80%
```

### Snyk Security Thresholds

Configured in pipeline environment:

```groovy
SNYK_SEVERITY_THRESHOLD = 'high'  // Fail on high and critical vulnerabilities
```

## 🚀 Deployment Configuration

### ArgoCD Applications

The pipeline manages two ArgoCD applications:

1. **Production** (`eks-products-prod`)
   - Namespace: `production`
   - Source: `main` branch
   - Values: `values-prod.yaml`

2. **Development** (`eks-products-dev`)
   - Namespace: `development`
   - Source: `develop` branch
   - Values: `values-dev.yaml`

### Helm Values Update

The pipeline automatically updates Helm values with:
- New image tags based on build version
- ECR registry URLs
- Environment-specific configurations

## 📈 Monitoring & Notifications

### Pipeline Notifications

Configure Slack notifications for:
- ✅ Successful deployments
- ❌ Failed builds
- ⚠️ Unstable builds (warnings)

### Build Reports

The pipeline generates and publishes:
- Maven test reports
- JaCoCo code coverage reports
- SonarQube analysis results
- OWASP dependency check reports
- Snyk security scan reports

## 🔧 Troubleshooting

### Common Issues

#### 1. Maven Build Failures
```bash
# Check Java version
java -version

# Verify Maven settings
mvn --version

# Clean workspace
mvn clean
```

#### 2. Docker Build Issues
```bash
# Check Docker daemon
docker info

# Verify multi-platform support
docker buildx ls

# Clean Docker cache
docker system prune -f
```

#### 3. SonarQube Connection Issues
```bash
# Test SonarQube connectivity
curl -u [token]: https://your-sonarqube-server.com/api/system/status

# Verify SonarQube token
# Check Jenkins credentials configuration
```

#### 4. ArgoCD Sync Issues
```bash
# Check ArgoCD connectivity
argocd version

# Verify application status
argocd app get eks-products-prod

# Manual sync
argocd app sync eks-products-prod
```

### Pipeline Debugging

Enable debug logging by adding to Jenkinsfile:
```groovy
environment {
    MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository -Xmx2048m -X'  // Maven debug
    DOCKER_BUILDKIT = '1'
    BUILDKIT_PROGRESS = 'plain'  // Docker debug
}
```

## 🔒 Security Best Practices

### 1. Credentials Management
- Use Jenkins credentials store for all secrets
- Rotate tokens regularly
- Use least-privilege IAM roles for AWS access

### 2. Pipeline Security
- Enable build result authentication
- Use agent restrictions
- Implement approval processes for production deployments

### 3. Code Security
- Regular dependency updates
- Security scanning at multiple stages
- Quality gates enforcement

## 📚 Additional Resources

- [Jenkins Pipeline Documentation](https://jenkins.io/doc/book/pipeline/)
- [SonarQube Integration Guide](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-jenkins/)
- [Snyk Jenkins Integration](https://docs.snyk.io/integrations/ci-cd-integrations/jenkins-integration-overview)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [EKS Workshop](https://www.eksworkshop.com/)

---

## 🆘 Support

For pipeline issues or questions:
1. Check Jenkins build logs
2. Review this documentation
3. Contact DevOps team via Slack (#devops-support)
4. Create an issue in the repository
