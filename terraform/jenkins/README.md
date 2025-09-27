# 🚀 Jenkins CI/CD Server Deployment with Terraform

<div align="center">

![Terraform](https://img.shields.io/badge/Terraform-1.0+-623CE4?style=for-the-badge&logo=terraform)
![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?style=for-the-badge&logo=amazon-aws)
![Jenkins](https://img.shields.io/badge/Jenkins-2.x-D33833?style=for-the-badge&logo=jenkins)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

*Complete infrastructure-as-code solution for deploying Jenkins on AWS EC2*

</div>

---

## 📋 Overview

This Terraform configuration deploys a fully-configured Jenkins CI/CD server on AWS EC2 with all essential tools and plugins pre-installed. Perfect for modern DevOps workflows, the deployment includes comprehensive security, monitoring, and backup capabilities.

### 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Internet      │    │   Security      │    │   Jenkins EC2   │
│   Gateway       │───▶│   Group         │───▶│   t3.medium     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                               ┌─────────────────┐
                                               │   EBS Volume    │
                                               │  (Persistent)   │
                                               └─────────────────┘
```

## ✨ Features

### 🔧 **Pre-installed Tools**
- **Jenkins LTS** - Latest stable version with security plugins
- **Java 11/17** - OpenJDK runtime environment
- **Maven 3.9.5** - Build automation tool for Java projects
- **Node.js 18** - JavaScript runtime for frontend builds
- **Docker & Docker Compose** - Container management
- **AWS CLI v2** - AWS service integration
- **kubectl** - Kubernetes cluster management
- **Helm 3** - Kubernetes package manager
- **Terraform** - Infrastructure as code
- **SonarQube Scanner** - Code quality analysis
- **Snyk CLI** - Security vulnerability scanning

### 📦 **Essential Jenkins Plugins**
- **Blue Ocean** - Modern Jenkins UI
- **Pipeline** - Declarative and scripted pipelines
- **Git/GitHub** - Version control integration
- **Docker Pipeline** - Container-based builds
- **Kubernetes** - Deploy to K8s clusters
- **AWS Plugins** - ECR, EKS, S3 integration
- **Security Scanner** - Snyk, OWASP dependency check
- **SonarQube** - Code quality integration
- **Slack/Email** - Notification systems

### 🛡️ **Security & Monitoring**
- **VPC with public subnet** - Isolated network environment
- **Security groups** - Controlled access (SSH, Jenkins, HTTPS)
- **IAM roles** - AWS service permissions
- **EBS encryption** - Data at rest protection
- **CloudWatch monitoring** - Performance metrics and logs
- **Automated backups** - Jenkins data protection

## 🚀 Quick Start

### Prerequisites

Ensure you have the following installed and configured:

| Tool | Version | Purpose |
|------|---------|---------|
| 🏗️ Terraform | 1.0+ | Infrastructure provisioning |
| ☁️ AWS CLI | 2.x | AWS authentication |
| 🔑 SSH Key | - | EC2 instance access |

### 🔧 AWS Configuration

```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### 📋 Deployment Steps

1. **Clone and Navigate**
   ```bash
   cd terraform/jenkins
   ```

2. **Configure Variables**
   ```bash
   # Copy example configuration
   cp terraform.tfvars.example terraform.tfvars
   
   # Edit configuration (see Configuration section below)
   vim terraform.tfvars
   ```

3. **Deploy Infrastructure**
   ```bash
   # Initialize Terraform
   terraform init
   
   # Review deployment plan
   terraform plan
   
   # Deploy infrastructure
   terraform apply
   ```

4. **Access Jenkins**
   ```bash
   # Get Jenkins URL from output
   terraform output jenkins_url
   
   # Get SSH command
   terraform output jenkins_ssh_command
   ```

## ⚙️ Configuration

### 🔐 Required Variables

Edit `terraform.tfvars` with your specific values:

```hcl
# AWS Configuration
aws_region = "us-east-1"
project_name = "your-jenkins-instance"

# SSH Access - REQUIRED
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQAB... your-public-key"

# Jenkins Admin - REQUIRED
jenkins_admin_password = "YourSecurePassword123!"

# Security - IMPORTANT
allowed_cidr_blocks = ["YOUR_IP/32"]  # Replace with your IP
```

### 🔑 SSH Key Generation

If you don't have an SSH key pair:

```bash
# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/jenkins-key

# Copy public key content for terraform.tfvars
cat ~/.ssh/jenkins-key.pub
```

### 🛡️ Security Configuration

**⚠️ IMPORTANT SECURITY SETTINGS:**

1. **Restrict Access**: Change `allowed_cidr_blocks` from `["0.0.0.0/0"]` to your specific IP ranges
2. **Strong Password**: Use a strong admin password
3. **SSH Keys**: Use SSH key authentication instead of passwords

```hcl
# Example secure configuration
allowed_cidr_blocks = [
  "203.0.113.0/24",  # Your office network
  "198.51.100.5/32"  # Your home IP
]
```

## 🔧 Post-Deployment Setup

### 1. Initial Access

```bash
# Get connection information
terraform output -raw jenkins_url
terraform output -raw jenkins_ssh_command

# Access Jenkins web interface
open $(terraform output -raw jenkins_url)
```

### 2. Jenkins Initial Setup

1. **Login with Admin Credentials**
   - Username: `admin` (or your configured username)
   - Password: From your `terraform.tfvars`

2. **Complete Setup Wizard**
   - Install suggested plugins (or skip - already pre-installed)
   - Create additional users as needed
   - Configure Jenkins URL

3. **Verify Plugin Installation**
   - Go to "Manage Jenkins" → "Manage Plugins"
   - Check "Installed" tab for all required plugins

### 3. Configure Build Tools

All tools are pre-installed and configured:

```bash
# SSH to Jenkins server
ssh -i ~/.ssh/jenkins-key ec2-user@<JENKINS_IP>

# Verify installations
java -version
mvn -version
node --version
docker --version
kubectl version --client
helm version
terraform --version
```

### 4. Create Your First Pipeline

1. **Create New Job**
   - Click "New Item"
   - Choose "Pipeline"
   - Enter name and click "OK"

2. **Example Pipeline Script**
   ```groovy
   pipeline {
       agent any
       
       tools {
           maven 'Maven-3.9.5'
           nodejs 'NodeJS-18'
       }
       
       stages {
           stage('Checkout') {
               steps {
                   git 'https://github.com/your-username/your-repo.git'
               }
           }
           
           stage('Build') {
               steps {
                   sh 'mvn clean compile'
               }
           }
           
           stage('Test') {
               steps {
                   sh 'mvn test'
               }
           }
           
           stage('Security Scan') {
               steps {
                   sh 'snyk test'
               }
           }
           
           stage('SonarQube Analysis') {
               steps {
                   withSonarQubeEnv('SonarQube') {
                       sh 'mvn sonar:sonar'
                   }
               }
           }
           
           stage('Docker Build') {
               steps {
                   sh 'docker build -t your-app:${BUILD_NUMBER} .'
               }
           }
       }
       
       post {
           always {
               cleanWs()
           }
       }
   }
   ```

## 📊 Monitoring & Maintenance

### CloudWatch Monitoring

Jenkins automatically sends metrics to CloudWatch:

- **CPU Usage** - Monitor server performance
- **Memory Usage** - Track memory consumption
- **Disk Usage** - Monitor storage utilization
- **Jenkins Logs** - Application and system logs

### Backup & Recovery

**Automated Backup Script:**
```bash
# Run backup manually
sudo /usr/local/bin/jenkins-backup.sh

# Backups are stored in: /jenkins-data/backups/
```

**Manual Backup:**
```bash
# Create backup
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz -C /jenkins-data/jenkins .

# Create EBS snapshot
aws ec2 create-snapshot --volume-id $(terraform output -raw jenkins_data_volume_id) --description "Jenkins backup $(date)"
```

### Health Checks

```bash
# Check Jenkins service status
sudo systemctl status jenkins

# Check application health
curl http://localhost:8080/manage/systemInfo

# View Jenkins logs
sudo journalctl -u jenkins -f

# Check disk space
df -h /jenkins-data
```

## 🔧 Common Tasks

### Restart Jenkins
```bash
sudo systemctl restart jenkins
```

### Update Jenkins
```bash
# Stop Jenkins
sudo systemctl stop jenkins

# Download latest WAR
sudo wget -O /usr/share/jenkins/jenkins.war http://updates.jenkins-ci.org/latest/jenkins.war

# Start Jenkins
sudo systemctl start jenkins
```

### Add Jenkins Tools

Tools can be configured in Jenkins:
1. Go to "Manage Jenkins" → "Global Tool Configuration"
2. Add tool installations (Maven, Node.js, etc.)
3. Specify installation directories:
   - Maven: `/opt/maven`
   - Node.js: `/usr/bin/node`
   - Docker: `/usr/bin/docker`

## 🛠️ Troubleshooting

### Common Issues

<details>
<summary>🔍 Jenkins won't start</summary>

```bash
# Check service status
sudo systemctl status jenkins

# Check logs
sudo journalctl -u jenkins -f

# Verify Java installation
java -version

# Check disk space
df -h /jenkins-data
```

</details>

<details>
<summary>🔍 Can't access Jenkins web interface</summary>

```bash
# Check if Jenkins is running
curl http://localhost:8080

# Verify security group allows port 8080
aws ec2 describe-security-groups --group-ids $(terraform output -raw jenkins_security_group_id)

# Check firewall
sudo firewall-cmd --list-ports
```

</details>

<details>
<summary>🔍 Plugin installation fails</summary>

```bash
# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Verify internet connectivity
curl -I https://updates.jenkins.io

# Restart Jenkins
sudo systemctl restart jenkins
```

</details>

<details>
<summary>🔍 Build tools not found</summary>

```bash
# Verify tool installations
which mvn java node docker kubectl

# Check PATH in Jenkins
# Go to "Manage Jenkins" → "System Information"
# Look for "PATH" environment variable

# Add tools to Jenkins PATH:
# "Manage Jenkins" → "Configure System" → "Global properties"
```

</details>

## 🧹 Cleanup

To destroy the infrastructure:

```bash
# Destroy all resources
terraform destroy

# Confirm destruction
# Type: yes
```

**⚠️ Warning:** This will permanently delete your Jenkins instance and all data!

## 📋 Outputs Reference

After deployment, Terraform provides these useful outputs:

| Output | Description |
|--------|-------------|
| `jenkins_url` | Jenkins web interface URL |
| `jenkins_public_ip` | Public IP address |
| `jenkins_ssh_command` | SSH connection command |
| `jenkins_admin_credentials` | Login information |
| `post_deployment_steps` | Next steps checklist |

## 🔐 Security Best Practices

1. **Network Security**
   - Restrict `allowed_cidr_blocks` to specific IP ranges
   - Use VPN or bastion host for production access
   - Enable VPC flow logs for monitoring

2. **Access Control**
   - Use strong admin passwords
   - Enable two-factor authentication
   - Create role-based user accounts
   - Regularly review user permissions

3. **Data Protection**
   - Enable EBS encryption (done by default)
   - Set up regular backups
   - Store sensitive data in AWS Parameter Store
   - Use Jenkins credential store for secrets

4. **Monitoring**
   - Enable CloudWatch monitoring
   - Set up alerting for failures
   - Monitor security logs
   - Regular security updates

## 🤝 Contributing

Contributions welcome! Please see our [Contributing Guidelines](../../CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.

---

<div align="center">

**⭐ Star this repository if you find it helpful!**

Made with ❤️ for DevOps engineers

</div>
