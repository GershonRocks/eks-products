#!/bin/bash

# Jenkins Bootstrap Script for Ubuntu 24.04 LTS
# This script downloads and executes the full installation script

set -euo pipefail

# Variables from Terraform
JENKINS_ADMIN_USER="${jenkins_admin_user}"
JENKINS_ADMIN_PASSWORD="${jenkins_admin_password}"
MAVEN_VERSION="${maven_version}"
NODE_VERSION="${node_version}"
JAVA_VERSION="${java_version}"

# Create log file
LOG_FILE="/var/log/jenkins-installation.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

echo "=== Jenkins Bootstrap Started at $(date) ==="

# Update system first
apt-get update -y

# Install basic tools
apt-get install -y wget curl git unzip vim htop jq

# Create installation script directory
mkdir -p /opt/jenkins-install
cd /opt/jenkins-install

# Create the full installation script inline to avoid external dependencies
cat << 'INSTALL_SCRIPT_EOF' > /opt/jenkins-install/install-jenkins.sh
#!/bin/bash

set -euo pipefail

JENKINS_HOME="/var/lib/jenkins"
JENKINS_USER="jenkins"
LOG_FILE="/var/log/jenkins-installation.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting Jenkins full installation on Ubuntu 24.04 LTS..."

# Install Java
log "Installing Java $JAVA_VERSION..."
apt-get update -y
if [[ "$JAVA_VERSION" == "21" ]]; then
    apt-get install -y openjdk-21-jdk
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
elif [[ "$JAVA_VERSION" == "17" ]]; then
    apt-get install -y openjdk-17-jdk
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
elif [[ "$JAVA_VERSION" == "11" ]]; then
    apt-get install -y openjdk-11-jdk
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
elif [[ "$JAVA_VERSION" == "8" ]]; then
    apt-get install -y openjdk-8-jdk
    export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
else
    # Default to Java 21 if unknown version
    log "Unknown Java version $JAVA_VERSION, defaulting to Java 21 LTS"
    apt-get install -y openjdk-21-jdk
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
fi

echo "export JAVA_HOME=$JAVA_HOME" >> /etc/environment
echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/environment

# Install Jenkins
log "Installing Jenkins..."
wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
apt-get install -y jenkins

# Configure Jenkins data directory on separate EBS volume
log "Configuring Jenkins data directory..."
while [ ! -e /dev/nvme1n1 ]; do
    log "Waiting for EBS volume to be attached..."
    sleep 5
done

# Format and mount the EBS volume
mkfs.ext4 /dev/nvme1n1
mkdir -p /jenkins-data
mount /dev/nvme1n1 /jenkins-data
echo "/dev/nvme1n1 /jenkins-data ext4 defaults,nofail 0 2" >> /etc/fstab

# Set up Jenkins directory
mkdir -p /jenkins-data/jenkins
chown jenkins:jenkins /jenkins-data/jenkins
systemctl stop jenkins || true

# Update Jenkins configuration
sed -i 's|JENKINS_HOME="/var/lib/jenkins"|JENKINS_HOME="/jenkins-data/jenkins"|g' /etc/default/jenkins || true
ln -sf /jenkins-data/jenkins /var/lib/jenkins

# Install Docker
log "Installing Docker..."
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl start docker
systemctl enable docker
usermod -aG docker jenkins

# Install Maven
log "Installing Maven $MAVEN_VERSION..."
cd /opt
wget https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
tar xzf apache-maven-$MAVEN_VERSION-bin.tar.gz
ln -s apache-maven-$MAVEN_VERSION maven
chown -R jenkins:jenkins apache-maven-$MAVEN_VERSION
echo "export M2_HOME=/opt/maven" >> /etc/environment
echo "export PATH=\$PATH:\$M2_HOME/bin" >> /etc/environment

# Install Node.js
log "Installing Node.js $NODE_VERSION..."
curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -
apt-get install -y nodejs
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
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update -y
apt-get install -y terraform

# Install AWS CLI v2
log "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

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
npm install -g snyk

# Configure Jenkins
log "Configuring Jenkins..."
mkdir -p /jenkins-data/jenkins/init.groovy.d

# Basic security configuration
cat << 'GROOVY_EOF' > /jenkins-data/jenkins/init.groovy.d/basic-security.groovy
#!groovy
import jenkins.model.*
import hudson.security.*
import hudson.security.csrf.DefaultCrumbIssuer
import jenkins.security.s2m.AdminWhitelistRule

def instance = Jenkins.getInstance()
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("ADMIN_USER_PLACEHOLDER", "ADMIN_PASSWORD_PLACEHOLDER")
instance.setSecurityRealm(hudsonRealm)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)
instance.setCrumbIssuer(new DefaultCrumbIssuer(true))
instance.getInjector().getInstance(AdminWhitelistRule.class).setMasterKillSwitch(false)
instance.save()
GROOVY_EOF

# Replace placeholders
sed -i "s/ADMIN_USER_PLACEHOLDER/$JENKINS_ADMIN_USER/g" /jenkins-data/jenkins/init.groovy.d/basic-security.groovy
sed -i "s/ADMIN_PASSWORD_PLACEHOLDER/$JENKINS_ADMIN_PASSWORD/g" /jenkins-data/jenkins/init.groovy.d/basic-security.groovy

# Set Jenkins configuration for Ubuntu
cat << JENKINS_CONFIG_EOF > /etc/default/jenkins
JENKINS_HOME="/jenkins-data/jenkins"
JENKINS_JAVA_CMD="$JAVA_HOME/bin/java"
JENKINS_USER="jenkins"
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Xmx2g"
JENKINS_PORT="8080"
JENKINS_LISTEN_ADDRESS="0.0.0.0"
JENKINS_ARGS=""
JENKINS_CONFIG_EOF

# Set ownership
chown -R jenkins:jenkins /jenkins-data/jenkins

# Configure environment for Jenkins user
cat << BASH_CONFIG_EOF > /jenkins-data/jenkins/.bashrc
export JAVA_HOME=$JAVA_HOME
export M2_HOME=/opt/maven
export SONAR_SCANNER_HOME=/opt/sonar-scanner
export PATH=\$PATH:\$JAVA_HOME/bin:\$M2_HOME/bin:\$SONAR_SCANNER_HOME/bin:/usr/local/bin
BASH_CONFIG_EOF
chown jenkins:jenkins /jenkins-data/jenkins/.bashrc

# Start Jenkins
log "Starting Jenkins service..."
systemctl daemon-reload
systemctl start jenkins
systemctl enable jenkins

# Create backup script
cat << 'BACKUP_SCRIPT_EOF' > /usr/local/bin/jenkins-backup.sh
#!/bin/bash
BACKUP_DIR="/jenkins-data/backups"
JENKINS_HOME="/jenkins-data/jenkins"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="jenkins_backup_$TIMESTAMP.tar.gz"
mkdir -p $BACKUP_DIR
systemctl stop jenkins
tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$JENKINS_HOME" . --exclude="workspace" --exclude="temp" --exclude="logs"
systemctl start jenkins
find $BACKUP_DIR -name "jenkins_backup_*.tar.gz" -mtime +7 -delete
echo "Backup completed: $BACKUP_DIR/$BACKUP_NAME"
BACKUP_SCRIPT_EOF
chmod +x /usr/local/bin/jenkins-backup.sh

# Wait for Jenkins to start
log "Waiting for Jenkins to start..."
while ! curl -s http://localhost:8080 > /dev/null; do
    log "Waiting for Jenkins to be ready..."
    sleep 10
done

log "Jenkins installation completed successfully!"
log "Jenkins URL: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
log "Admin User: $JENKINS_ADMIN_USER"

# Create status file
cat << STATUS_EOF > /var/log/jenkins-installation-status.json
{
    "status": "completed",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "jenkins_url": "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080",
    "admin_user": "$JENKINS_ADMIN_USER",
    "os_version": "Ubuntu 24.04 LTS"
}
STATUS_EOF

log "Installation completed at $(date)"
INSTALL_SCRIPT_EOF

# Replace variables in the installation script
sed -i "s/\$JAVA_VERSION/$JAVA_VERSION/g" /opt/jenkins-install/install-jenkins.sh
sed -i "s/\$MAVEN_VERSION/$MAVEN_VERSION/g" /opt/jenkins-install/install-jenkins.sh
sed -i "s/\$NODE_VERSION/$NODE_VERSION/g" /opt/jenkins-install/install-jenkins.sh
sed -i "s/\$JENKINS_ADMIN_USER/$JENKINS_ADMIN_USER/g" /opt/jenkins-install/install-jenkins.sh
sed -i "s/\$JENKINS_ADMIN_PASSWORD/$JENKINS_ADMIN_PASSWORD/g" /opt/jenkins-install/install-jenkins.sh

# Make script executable and run it
chmod +x /opt/jenkins-install/install-jenkins.sh

# Run installation in background and redirect output
nohup /opt/jenkins-install/install-jenkins.sh > /var/log/jenkins-full-install.log 2>&1 &

echo "=== Jenkins Bootstrap Completed at $(date) ==="
echo "Full installation running in background. Check /var/log/jenkins-full-install.log for progress."