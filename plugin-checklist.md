# 📋 Jenkins Plugin Installation Checklist

## Current Status
- ✅ **Basic plugins installed** (Pipeline, Git, GitHub, SonarQube, Snyk)
- ❌ **Missing essential CI/CD plugins**

## 🚀 Required Plugins for EKS Products Pipeline

### Essential CI/CD
- [ ] **Blue Ocean** - Modern pipeline UI
- [ ] **Docker Pipeline** - Docker build support
- [ ] **Pipeline: AWS Steps** - AWS integration
- [ ] **Amazon ECR** - ECR integration
- [ ] **AWS Credentials Binding** - AWS credentials

### Kubernetes & Containers
- [ ] **Kubernetes** - Kubernetes integration
- [ ] **Kubernetes Credentials Provider** - K8s credentials
- [ ] **Docker Commons** - Docker utilities
- [ ] **Docker Build Step** - Docker build steps

### Build & Quality
- [ ] **Maven Integration** - Maven support
- [ ] **Pipeline Maven Integration** - Maven pipeline
- [ ] **JaCoCo** - Code coverage
- [ ] **HTML Publisher** - Report publishing
- [ ] **AnsiColor** - Colored console output
- [ ] **OWASP Dependency-Check** - Security scanning

### Notifications
- [ ] **Slack Notification** - Slack integration
- [ ] **Performance** - Performance testing

## 📋 Installation Steps

1. **Open Jenkins**: http://54.166.37.229:8080
2. **Login**: admin / <your-jenkins-password>
3. **Navigate**: Manage Jenkins → Manage Plugins → Available
4. **Search and Install** each plugin above
5. **Restart Jenkins** when prompted

## ✅ Verification

After installation, verify plugins are working:
- Check **Manage Jenkins** → **Manage Plugins** → **Installed**
- Create a test pipeline with Docker and AWS steps
- Verify Blue Ocean interface is accessible

## 🔧 Alternative: Use Jenkins Setup Wizard

If manual installation is tedious:
1. Consider using **Install suggested plugins** during setup
2. Add missing plugins afterward
3. Use **Jenkins Configuration as Code** (JCasC) for future deployments
