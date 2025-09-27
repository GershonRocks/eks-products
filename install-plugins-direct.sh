#!/bin/bash

# Direct Jenkins Plugin Installation
# Downloads and installs plugins directly to Jenkins plugins directory

set -e

JENKINS_SERVER="54.166.37.229"
JENKINS_PLUGINS_DIR="/var/lib/jenkins/plugins"
JENKINS_UPDATE_CENTER="https://updates.jenkins.io"

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

# Plugin list with their dependencies
PLUGINS=(
    # Core CI/CD plugins
    "blueocean"
    "docker-workflow"
    "pipeline-aws"
    "amazon-ecr"
    "aws-credentials-binding"
    
    # Kubernetes plugins
    "kubernetes"
    "kubernetes-credentials-provider"
    
    # Docker plugins
    "docker-commons"
    "docker-build-step"
    
    # Build tools
    "maven-plugin"
    "pipeline-maven"
    
    # Quality & Testing
    "jacoco"
    "htmlpublisher"
    "dependency-check-jenkins-plugin"
    
    # Utilities
    "ansicolor"
    "copyartifact"
    "build-name-setter"
    "config-file-provider"
    
    # Notifications
    "slack"
    "performance"
    
    # Security & Monitoring
    "role-strategy"
    "monitoring"
    "metrics"
    "prometheus"
)

# Function to download and install plugins on remote server
install_plugins_remote() {
    print_status "Installing plugins directly on Jenkins server..."
    
    # Create the installation script
    local install_script=$(cat << 'EOF'
#!/bin/bash

PLUGINS_DIR="/var/lib/jenkins/plugins"
UPDATE_CENTER_URL="https://updates.jenkins.io"

# Function to download plugin
download_plugin() {
    local plugin_name=$1
    local plugin_url="${UPDATE_CENTER_URL}/latest/${plugin_name}.hpi"
    
    echo "📥 Downloading plugin: $plugin_name"
    
    # Download to temporary location first
    if /usr/bin/curl -L -s -f -o "/tmp/${plugin_name}.hpi" "$plugin_url"; then
        echo "✅ Downloaded $plugin_name successfully"
        
        # Move to plugins directory and set ownership
        /usr/bin/sudo /bin/mv "/tmp/${plugin_name}.hpi" "${PLUGINS_DIR}/${plugin_name}.jpi"
        /usr/bin/sudo /bin/chown jenkins:jenkins "${PLUGINS_DIR}/${plugin_name}.jpi"
        /usr/bin/sudo /bin/chmod 644 "${PLUGINS_DIR}/${plugin_name}.jpi"
        
        return 0
    else
        echo "❌ Failed to download $plugin_name"
        return 1
    fi
}

# Install each plugin
PLUGINS=("blueocean" "docker-workflow" "pipeline-aws" "amazon-ecr" "aws-credentials-binding" "kubernetes" "kubernetes-credentials-provider" "docker-commons" "docker-build-step" "maven-plugin" "pipeline-maven" "jacoco" "htmlpublisher" "dependency-check-jenkins-plugin" "ansicolor" "copyartifact" "build-name-setter" "config-file-provider" "slack" "performance" "role-strategy" "monitoring" "metrics" "prometheus")

successful=0
failed=0

echo "🚀 Starting plugin installation..."
echo "📂 Installing to: $PLUGINS_DIR"

for plugin in "${PLUGINS[@]}"; do
    # Check if plugin already exists
    if [ -f "${PLUGINS_DIR}/${plugin}.jpi" ] || [ -d "${PLUGINS_DIR}/${plugin}" ]; then
        echo "⏭️  Plugin $plugin already exists, skipping"
        ((successful++))
        continue
    fi
    
    if download_plugin "$plugin"; then
        ((successful++))
    else
        ((failed++))
    fi
    
    # Small delay to avoid overwhelming the server
    sleep 1
done

echo
echo "📊 Installation Summary:"
echo "✅ Successful: $successful"
echo "❌ Failed: $failed"
echo "📁 Total plugins in directory: $(ls -1 $PLUGINS_DIR | wc -l)"

echo
echo "🔄 Restarting Jenkins to load new plugins..."
/usr/bin/sudo /bin/systemctl restart jenkins

echo "✅ Plugin installation completed!"
EOF
)

    # Execute the installation script on the remote server
    ssh ubuntu@$JENKINS_SERVER "$install_script"
}

# Function to wait for Jenkins to restart
wait_for_jenkins() {
    print_status "Waiting for Jenkins to restart and come back online..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "http://$JENKINS_SERVER:8080/login" > /dev/null 2>&1; then
            print_success "Jenkins is back online!"
            return 0
        fi
        
        print_status "Waiting for Jenkins... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    print_error "Jenkins did not come back online within expected time"
    return 1
}

# Function to verify plugin installation
verify_plugins() {
    print_status "Verifying plugin installation..."
    
    ssh ubuntu@$JENKINS_SERVER << 'EOF'
echo "📋 Checking installed plugins..."
echo "Total .jpi files: $(ls -1 /var/lib/jenkins/plugins/*.jpi 2>/dev/null | wc -l)"
echo "Total plugin directories: $(ls -1d /var/lib/jenkins/plugins/*/ 2>/dev/null | wc -l)"

echo
echo "🔍 Recently installed plugins:"
find /var/lib/jenkins/plugins -name "*.jpi" -newer /var/lib/jenkins/plugins/git.jpi 2>/dev/null | head -10

echo
echo "📊 Plugin status summary:"
REQUIRED_PLUGINS=("blueocean" "docker-workflow" "pipeline-aws" "amazon-ecr" "aws-credentials-binding" "kubernetes" "maven-plugin" "jacoco" "slack")

for plugin in "${REQUIRED_PLUGINS[@]}"; do
    if [ -f "/var/lib/jenkins/plugins/${plugin}.jpi" ] || [ -d "/var/lib/jenkins/plugins/${plugin}" ]; then
        echo "✅ $plugin"
    else
        echo "❌ $plugin"
    fi
done
EOF
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} Jenkins Direct Plugin Installer${NC}"
    echo -e "${BLUE} EKS Products CI/CD Pipeline${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    print_status "Installing ${#PLUGINS[@]} plugins directly on Jenkins server..."
    
    if install_plugins_remote; then
        if wait_for_jenkins; then
            verify_plugins
            
            echo
            print_success "🎉 Plugin installation completed successfully!"
            print_status "🌐 Access Jenkins at: http://$JENKINS_SERVER:8080"
            print_status "🔑 Login with: admin / <your-jenkins-password>"
        else
            print_error "Jenkins restart verification failed"
        fi
    else
        print_error "Plugin installation failed"
        exit 1
    fi
}

# Execute main function
main "$@"
