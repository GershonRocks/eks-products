#!/bin/bash

# Jenkins Installation and Configuration Script
# This script installs Jenkins with all necessary tools and plugins

set -euo pipefail

# Variables
JENKINS_HOME="/var/lib/jenkins"
JENKINS_USER="jenkins"
LOG_FILE="/var/log/jenkins-installation.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting Jenkins installation and configuration..."

# Update system
log "Updating system packages..."
yum update -y

# Install essential packages
log "Installing essential packages..."
yum install -y \
    wget \
    curl \
    git \
    unzip \
    vim \
    htop \
    jq \
    tree \
    awscli \
    yum-utils \
    device-mapper-persistent-data \
    lvm2

# Install Java ${java_version}
log "Installing Java ${java_version}..."
if [[ "${java_version}" == "11" ]]; then
    yum install -y java-11-amazon-corretto-headless
    export JAVA_HOME="/usr/lib/jvm/java-11-amazon-corretto"
elif [[ "${java_version}" == "17" ]]; then
    yum install -y java-17-amazon-corretto-headless
    export JAVA_HOME="/usr/lib/jvm/java-17-amazon-corretto"
else
    yum install -y java-11-amazon-corretto-headless
    export JAVA_HOME="/usr/lib/jvm/java-11-amazon-corretto"
fi

echo "export JAVA_HOME=$JAVA_HOME" >> /etc/environment
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/environment

# Install Jenkins
log "Installing Jenkins..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins

# Configure Jenkins data directory on separate EBS volume
log "Configuring Jenkins data directory..."
# Wait for EBS volume to be attached
while [ ! -e /dev/xvdf ]; do
    log "Waiting for EBS volume to be attached..."
    sleep 5
done

# Format and mount the EBS volume
mkfs.ext4 /dev/xvdf
mkdir -p /jenkins-data
mount /dev/xvdf /jenkins-data

# Add to fstab for persistent mounting
echo "/dev/xvdf /jenkins-data ext4 defaults,nofail 0 2" >> /etc/fstab

# Set up Jenkins directory structure
mkdir -p /jenkins-data/jenkins
chown jenkins:jenkins /jenkins-data/jenkins

# Configure Jenkins to use the mounted volume
sed -i 's|JENKINS_HOME="/var/lib/jenkins"|JENKINS_HOME="/jenkins-data/jenkins"|g' /etc/sysconfig/jenkins

# Create symlink for backward compatibility
ln -sf /jenkins-data/jenkins /var/lib/jenkins

# Install Docker
log "Installing Docker..."
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add jenkins user to docker group
usermod -aG docker jenkins

# Install Docker Compose
log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Maven ${maven_version}
log "Installing Maven ${maven_version}..."
cd /opt
wget https://archive.apache.org/dist/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz
tar xzf apache-maven-${maven_version}-bin.tar.gz
ln -s apache-maven-${maven_version} maven
chown -R jenkins:jenkins apache-maven-${maven_version}

echo "export M2_HOME=/opt/maven" >> /etc/environment
echo "export PATH=\$PATH:\$M2_HOME/bin" >> /etc/environment

# Install Node.js ${node_version}
log "Installing Node.js ${node_version}..."
curl -fsSL https://rpm.nodesource.com/setup_${node_version}.x | bash -
yum install -y nodejs

# Install Yarn
npm install -g yarn

# Install kubectl
log "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Helm
log "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install Terraform
log "Installing Terraform..."
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y terraform

# Install AWS CLI v2
log "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install additional development tools
log "Installing additional development tools..."

# Install Gradle
wget https://services.gradle.org/distributions/gradle-8.4-bin.zip -P /tmp
unzip -d /opt /tmp/gradle-8.4-bin.zip
ln -s /opt/gradle-8.4 /opt/gradle
chown -R jenkins:jenkins /opt/gradle-8.4

echo "export GRADLE_HOME=/opt/gradle" >> /etc/environment
echo "export PATH=\$PATH:\$GRADLE_HOME/bin" >> /etc/environment

# Install SonarQube Scanner
log "Installing SonarQube Scanner..."
cd /opt
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
unzip sonar-scanner-cli-5.0.1.3006-linux.zip
ln -s sonar-scanner-5.0.1.3006-linux sonar-scanner
chown -R jenkins:jenkins sonar-scanner-5.0.1.3006-linux

echo "export SONAR_SCANNER_HOME=/opt/sonar-scanner" >> /etc/environment
echo "export PATH=\$PATH:\$SONAR_SCANNER_HOME/bin" >> /etc/environment

# Install Snyk CLI
log "Installing Snyk CLI..."
npm install -g snyk

# Configure Jenkins
log "Configuring Jenkins..."

# Set Jenkins admin user and password
mkdir -p /jenkins-data/jenkins/init.groovy.d

cat << 'EOF' > /jenkins-data/jenkins/init.groovy.d/basic-security.groovy
#!groovy

import jenkins.model.*
import hudson.security.*
import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("${jenkins_admin_user}", "${jenkins_admin_password}")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Enable CSRF protection
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))

// Disable slave-to-master security for now (you may want to enable this in production)
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)

instance.save()
EOF

# Create Jenkins plugin installation script
cat << 'EOF' > /jenkins-data/jenkins/init.groovy.d/install-plugins.groovy
#!groovy

import jenkins.model.*
import hudson.model.*
import jenkins.install.*

def instance = Jenkins.getInstance()

// Install plugins
def plugins = [
    "blueocean",
    "workflow-aggregator", 
    "pipeline-stage-view",
    "pipeline-maven",
    "maven-plugin",
    "gradle",
    "nodejs",
    "git",
    "github",
    "github-branch-source",
    "docker-plugin",
    "docker-workflow",
    "kubernetes",
    "kubernetes-cli",
    "sonar",
    "snyk-security-scanner",
    "owasp-dependency-check",
    "ec2",
    "aws-credentials",
    "aws-parameter-store",
    "amazon-ecr",
    "slack",
    "email-ext",
    "timestamper",
    "ws-cleanup",
    "build-timeout",
    "credentials-binding",
    "ssh-agent",
    "junit",
    "jacoco",
    "html-publisher",
    "cobertura",
    "parameterized-trigger",
    "build-pipeline-plugin",
    "delivery-pipeline-plugin",
    "workflow-multibranch",
    "terraform",
    "ansible"
]

def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

plugins.each { plugin ->
    if (!pm.getPlugin(plugin)) {
        def deployment = uc.getPlugin(plugin).deploy()
        deployment.get()
    }
}

instance.save()
EOF

# Set Jenkins configuration
cat << EOF > /etc/sysconfig/jenkins
JENKINS_HOME="/jenkins-data/jenkins"
JENKINS_JAVA_CMD="$JAVA_HOME/bin/java"
JENKINS_USER="jenkins"
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Xmx2g -XX:MaxPermSize=512m"
JENKINS_PORT="8080"
JENKINS_LISTEN_ADDRESS="0.0.0.0"
JENKINS_HTTPS_PORT=""
JENKINS_HTTPS_KEYSTORE=""
JENKINS_HTTPS_KEYSTORE_PASSWORD=""
JENKINS_HTTPS_LISTEN_ADDRESS=""
JENKINS_DEBUG_LEVEL="5"
JENKINS_ENABLE_ACCESS_LOG="no"
JENKINS_HANDLER_MAX="100"
JENKINS_HANDLER_IDLE="20"
JENKINS_EXTRA_LIB_FOLDER=""
JENKINS_ARGS=""
EOF

# Set ownership
chown -R jenkins:jenkins /jenkins-data/jenkins

# Configure environment variables for Jenkins user
cat << EOF > /jenkins-data/jenkins/.bashrc
export JAVA_HOME=$JAVA_HOME
export M2_HOME=/opt/maven
export GRADLE_HOME=/opt/gradle  
export SONAR_SCANNER_HOME=/opt/sonar-scanner
export PATH=\$PATH:\$JAVA_HOME/bin:\$M2_HOME/bin:\$GRADLE_HOME/bin:\$SONAR_SCANNER_HOME/bin:/usr/local/bin
EOF

chown jenkins:jenkins /jenkins-data/jenkins/.bashrc

# Start and enable Jenkins
log "Starting Jenkins service..."
systemctl daemon-reload
systemctl start jenkins
systemctl enable jenkins

# Configure firewall (if enabled)
if systemctl is-active --quiet firewalld; then
    log "Configuring firewall..."
    firewall-cmd --permanent --zone=public --add-port=8080/tcp
    firewall-cmd --permanent --zone=public --add-port=22/tcp
    firewall-cmd --reload
fi

# Create Jenkins backup script
log "Creating backup script..."
cat << 'EOF' > /usr/local/bin/jenkins-backup.sh
#!/bin/bash

BACKUP_DIR="/jenkins-data/backups"
JENKINS_HOME="/jenkins-data/jenkins"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="jenkins_backup_$TIMESTAMP.tar.gz"

mkdir -p $BACKUP_DIR

# Stop Jenkins service
systemctl stop jenkins

# Create backup
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$JENKINS_HOME" . --exclude="workspace" --exclude="temp" --exclude="logs"

# Start Jenkins service
systemctl start jenkins

# Remove backups older than 7 days
find $BACKUP_DIR -name "jenkins_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/$BACKUP_NAME"
EOF

chmod +x /usr/local/bin/jenkins-backup.sh

# Set up log rotation for Jenkins
cat << 'EOF' > /etc/logrotate.d/jenkins
/var/log/jenkins/jenkins.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 jenkins jenkins
    postrotate
        systemctl reload jenkins > /dev/null 2>&1 || true
    endscript
}
EOF

# Install CloudWatch agent for monitoring
log "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure CloudWatch agent
cat << 'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "metrics": {
        "namespace": "AWS/EC2/Jenkins",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "diskio": {
                "measurement": ["io_time"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": ["tcp_established", "tcp_time_wait"],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": ["swap_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/jenkins/jenkins.log",
                        "log_group_name": "/aws/ec2/jenkins",
                        "log_stream_name": "{instance_id}/jenkins.log"
                    },
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/jenkins",
                        "log_stream_name": "{instance_id}/messages"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Wait for Jenkins to start
log "Waiting for Jenkins to start..."
while ! curl -s http://localhost:8080 > /dev/null; do
    log "Waiting for Jenkins to be ready..."
    sleep 10
done

# Display installation summary
log "Jenkins installation completed successfully!"
log "=========================================="
log "Jenkins URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
log "Admin User: ${jenkins_admin_user}"
log "Admin Password: ${jenkins_admin_password}"
log "Jenkins Home: /jenkins-data/jenkins"
log "Initial Admin Password: $(cat /jenkins-data/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'Not available yet')"
log "=========================================="
log "Installed Tools:"
log "- Java: $(java -version 2>&1 | head -n 1)"
log "- Maven: $(mvn -version 2>/dev/null | head -n 1 || echo 'Maven ${maven_version}')"
log "- Node.js: $(node --version 2>/dev/null || echo 'Node.js ${node_version}')"
log "- Docker: $(docker --version 2>/dev/null || echo 'Docker installed')"
log "- kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl installed')"
log "- Helm: $(helm version --short 2>/dev/null || echo 'Helm installed')"
log "- Terraform: $(terraform --version 2>/dev/null | head -n 1 || echo 'Terraform installed')"
log "- AWS CLI: $(aws --version 2>/dev/null || echo 'AWS CLI v2 installed')"
log "=========================================="

# Create a status file
cat << EOF > /var/log/jenkins-installation-status.json
{
    "status": "completed",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "jenkins_url": "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080",
    "admin_user": "${jenkins_admin_user}",
    "tools_installed": {
        "java": "$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)",
        "maven": "${maven_version}",
        "nodejs": "${node_version}",
        "docker": "installed",
        "kubectl": "installed",
        "helm": "installed",
        "terraform": "installed",
        "aws_cli": "v2"
    }
}
EOF

log "Installation completed at $(date)"
