#!/bin/bash

# Jenkins Plugin Installer Script
# Automatically installs required plugins for EKS Products CI/CD Pipeline

set -e

# Configuration
JENKINS_URL="http://54.166.37.229:8080"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_PASSWORD="${JENKINS_PASSWORD:-}"  # Set JENKINS_PASSWORD environment variable

# Check if password is set
if [ -z "$JENKINS_PASSWORD" ]; then
    echo "Error: JENKINS_PASSWORD environment variable is not set"
    echo "Please export JENKINS_PASSWORD=<your-password> before running this script"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Plugin list for EKS Products CI/CD Pipeline
PLUGINS=(
    # Core CI/CD Plugins
    "workflow-aggregator"           # Pipeline
    "blueocean"                    # Blue Ocean
    "git"                          # Git
    "github"                       # GitHub
    "docker-workflow"              # Docker Pipeline
    "build-timeout"                # Build Timeout
    "timestamper"                  # Timestamper
    "ws-cleanup"                   # Workspace Cleanup
    
    # AWS Integration
    "pipeline-aws"                 # AWS Steps
    "amazon-ecr"                   # Amazon ECR
    "aws-credentials-binding"      # AWS Credentials
    
    # Quality & Security
    "sonar"                        # SonarQube Scanner
    "dependency-check-jenkins-plugin"  # OWASP Dependency Check
    "htmlpublisher"                # HTML Publisher
    "junit"                        # JUnit
    "jacoco"                       # JaCoCo
    
    # Notifications
    "slack"                        # Slack Notification
    "email-ext"                    # Email Extension
    "mailer"                       # Mailer
    
    # Kubernetes & Docker
    "kubernetes"                   # Kubernetes
    "kubernetes-credentials-provider"  # Kubernetes Credentials Provider
    "docker-commons"               # Docker Commons
    "docker-build-step"            # Docker Build Step
    
    # Utilities
    "ansicolor"                    # AnsiColor
    "build-name-setter"            # Build Name Setter
    "copyartifact"                 # Copy Artifact
    "credentials"                  # Credentials
    "credentials-binding"          # Credentials Binding
    "matrix-auth"                  # Matrix Authorization
    "role-strategy"                # Role-based Authorization
    "antisamy-markup-formatter"    # OWASP Markup Formatter
    
    # Maven & Java
    "maven-plugin"                 # Maven Integration
    "pipeline-maven"               # Pipeline Maven Integration
    "config-file-provider"         # Config File Provider
    
    # Monitoring & Reporting
    "monitoring"                   # Monitoring
    "metrics"                      # Metrics
    "prometheus"                   # Prometheus Metrics
    "performance"                  # Performance
    
    # ArgoCD Integration (if available)
    "argocd"                       # ArgoCD (if exists)
)

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Jenkins is accessible
check_jenkins_status() {
    print_status "Checking Jenkins accessibility..."
    
    if curl -s --connect-timeout 10 "$JENKINS_URL/login" > /dev/null; then
        print_success "Jenkins is accessible at $JENKINS_URL"
        return 0
    else
        print_error "Jenkins is not accessible at $JENKINS_URL"
        print_error "Please ensure Jenkins is running and accessible"
        exit 1
    fi
}

# Function to download Jenkins CLI
download_jenkins_cli() {
    print_status "Downloading Jenkins CLI..."
    
    if [ ! -f "jenkins-cli.jar" ]; then
        curl -s -O "$JENKINS_URL/jnlpJars/jenkins-cli.jar"
        if [ $? -eq 0 ]; then
            print_success "Jenkins CLI downloaded successfully"
        else
            print_error "Failed to download Jenkins CLI"
            exit 1
        fi
    else
        print_status "Jenkins CLI already exists"
    fi
}

# Function to test Jenkins CLI connection
test_jenkins_cli() {
    print_status "Testing Jenkins CLI connection..."
    
    # Test with version command
    if java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" version > /dev/null 2>&1; then
        print_success "Jenkins CLI connection successful"
        return 0
    else
        print_error "Jenkins CLI connection failed"
        print_error "Please check your credentials and Jenkins setup"
        return 1
    fi
}

# Function to install a single plugin
install_plugin() {
    local plugin=$1
    print_status "Installing plugin: $plugin"
    
    # Check if plugin is already installed
    if java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" list-plugins | grep -q "^$plugin "; then
        print_warning "Plugin $plugin is already installed"
        return 0
    fi
    
    # Install the plugin
    if java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" install-plugin "$plugin" -deploy; then
        print_success "Plugin $plugin installed successfully"
        return 0
    else
        print_error "Failed to install plugin: $plugin"
        return 1
    fi
}

# Function to install all plugins
install_all_plugins() {
    print_status "Starting plugin installation process..."
    
    local failed_plugins=()
    local installed_count=0
    local total_plugins=${#PLUGINS[@]}
    
    for plugin in "${PLUGINS[@]}"; do
        if install_plugin "$plugin"; then
            ((installed_count++))
        else
            failed_plugins+=("$plugin")
        fi
    done
    
    print_status "Plugin installation summary:"
    print_success "Successfully installed: $installed_count/$total_plugins plugins"
    
    if [ ${#failed_plugins[@]} -gt 0 ]; then
        print_warning "Failed to install the following plugins:"
        for plugin in "${failed_plugins[@]}"; do
            echo "  - $plugin"
        done
    fi
}

# Function to restart Jenkins
restart_jenkins() {
    print_status "Restarting Jenkins to activate plugins..."
    
    if java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" restart; then
        print_success "Jenkins restart initiated"
        print_status "Waiting for Jenkins to come back online..."
        
        # Wait for Jenkins to restart
        sleep 30
        
        # Check if Jenkins is back online
        local max_attempts=30
        local attempt=1
        
        while [ $attempt -le $max_attempts ]; do
            if curl -s --connect-timeout 10 "$JENKINS_URL/login" > /dev/null; then
                print_success "Jenkins is back online"
                return 0
            fi
            
            print_status "Waiting for Jenkins... (attempt $attempt/$max_attempts)"
            sleep 10
            ((attempt++))
        done
        
        print_error "Jenkins did not come back online within expected time"
        return 1
    else
        print_error "Failed to restart Jenkins"
        return 1
    fi
}

# Function to list installed plugins
list_installed_plugins() {
    print_status "Listing installed plugins..."
    
    java -jar jenkins-cli.jar -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" list-plugins | grep -E "^($(IFS='|'; echo "${PLUGINS[*]}"))" | sort
}

# Main execution
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} Jenkins Plugin Installer${NC}"
    echo -e "${BLUE} EKS Products CI/CD Pipeline${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # Check prerequisites
    if ! command -v java &> /dev/null; then
        print_error "Java is required but not installed"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is required but not installed"
        exit 1
    fi
    
    # Execute installation steps
    check_jenkins_status
    download_jenkins_cli
    
    if test_jenkins_cli; then
        install_all_plugins
        
        echo
        print_status "Would you like to restart Jenkins to activate the plugins? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            restart_jenkins
        else
            print_warning "Please restart Jenkins manually to activate the plugins"
        fi
        
        echo
        print_status "Installation completed! Installed plugins:"
        list_installed_plugins
    else
        print_error "Could not connect to Jenkins. Please check your configuration."
        exit 1
    fi
    
    echo
    print_success "Plugin installation process completed!"
    print_status "You can now proceed with configuring your CI/CD pipeline"
}

# Execute main function
main "$@"
