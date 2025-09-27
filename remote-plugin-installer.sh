#!/bin/bash

# Remote Jenkins Plugin Installer
# Runs plugin installation directly on the Jenkins server

JENKINS_SERVER="54.166.37.229"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_PASSWORD="${JENKINS_PASSWORD:-}"

# Check if password is set
if [ -z "$JENKINS_PASSWORD" ]; then
    echo "Error: JENKINS_PASSWORD environment variable is not set"
    echo "Please export JENKINS_PASSWORD=<your-password> before running this script"
    exit 1
fi

# List of missing plugins to install
MISSING_PLUGINS=(
    "blueocean"
    "docker-workflow" 
    "pipeline-aws"
    "amazon-ecr"
    "aws-credentials-binding"
    "kubernetes"
    "kubernetes-credentials-provider"
    "slack"
    "maven-plugin"
    "pipeline-maven"
    "jacoco"
    "htmlpublisher"
    "docker-commons"
    "docker-build-step"
    "ansicolor"
    "dependency-check-jenkins-plugin"
    "performance"
)

echo "🚀 Installing missing Jenkins plugins on remote server..."

# Create the installation script on the remote server
ssh ubuntu@$JENKINS_SERVER << 'EOF'
    echo "📥 Downloading Jenkins CLI..."
    cd /tmp
    /usr/bin/curl -s http://localhost:8080/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar
    
    if [ $? -eq 0 ]; then
        echo "✅ Jenkins CLI downloaded successfully"
    else
        echo "❌ Failed to download Jenkins CLI"
        exit 1
    fi
    
    echo "🔌 Installing missing plugins..."
    
    # Install each plugin
    for plugin in blueocean docker-workflow pipeline-aws amazon-ecr aws-credentials-binding kubernetes kubernetes-credentials-provider slack maven-plugin pipeline-maven jacoco htmlpublisher docker-commons docker-build-step ansicolor dependency-check-jenkins-plugin performance; do
        echo "Installing plugin: $plugin"
        /usr/bin/java -jar jenkins-cli.jar -s http://localhost:8080 -auth ${JENKINS_USER}:${JENKINS_PASSWORD} install-plugin $plugin -deploy
        if [ $? -eq 0 ]; then
            echo "✅ $plugin installed successfully"
        else
            echo "❌ Failed to install $plugin"
        fi
    done
    
    echo "🔄 Restarting Jenkins to activate plugins..."
    /usr/bin/java -jar jenkins-cli.jar -s http://localhost:8080 -auth ${JENKINS_USER}:${JENKINS_PASSWORD} restart
    
    echo "✅ Plugin installation completed!"
EOF

echo "⏳ Waiting for Jenkins to restart..."
sleep 30

# Wait for Jenkins to come back online
echo "🔍 Checking Jenkins status..."
for i in {1..30}; do
    if curl -s --connect-timeout 10 http://$JENKINS_SERVER:8080/login > /dev/null; then
        echo "✅ Jenkins is back online!"
        break
    fi
    echo "⏳ Waiting for Jenkins... (attempt $i/30)"
    sleep 10
done

echo "🎉 Plugin installation process completed!"
echo "🌐 Access Jenkins at: http://$JENKINS_SERVER:8080"
