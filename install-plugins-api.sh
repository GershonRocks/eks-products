#!/bin/bash

# Jenkins Plugin Installation via REST API
# More reliable than CLI for authentication

set -e

JENKINS_URL="http://54.166.37.229:8080"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_PASSWORD="${JENKINS_PASSWORD:-}"

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
NC='\033[0m'

# Function to print colored output
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Complete list of plugins needed for the CI/CD pipeline
REQUIRED_PLUGINS=(
    # Core CI/CD
    "blueocean"
    "docker-workflow"
    "pipeline-aws"
    "amazon-ecr" 
    "aws-credentials-binding"
    
    # Kubernetes & Docker
    "kubernetes"
    "kubernetes-credentials-provider"
    "docker-commons"
    "docker-build-step"
    
    # Build & Quality
    "maven-plugin"
    "pipeline-maven"
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
    
    # Additional useful plugins
    "role-strategy"
    "monitoring"
    "metrics"
    "prometheus"
)

# Function to check if Jenkins is accessible
check_jenkins() {
    print_status "Checking Jenkins accessibility..."
    if curl -s -f "$JENKINS_URL/login" > /dev/null; then
        print_success "Jenkins is accessible"
        return 0
    else
        print_error "Jenkins is not accessible at $JENKINS_URL"
        return 1
    fi
}

# Function to get Jenkins crumb for CSRF protection
get_crumb() {
    print_status "Getting Jenkins crumb for CSRF protection..."
    CRUMB=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
    
    if [[ -n "$CRUMB" ]]; then
        print_success "Got Jenkins crumb: ${CRUMB:0:20}..."
        echo "$CRUMB"
    else
        print_warning "Could not get Jenkins crumb (might not be required)"
        echo ""
    fi
}

# Function to install a plugin via REST API
install_plugin_api() {
    local plugin=$1
    local crumb=$2
    
    print_status "Installing plugin: $plugin"
    
    # Prepare the POST data
    local post_data="<jenkins><install plugin=\"$plugin@latest\" /></jenkins>"
    
    # Set up headers
    local headers=()
    headers+=("-H" "Content-Type: text/xml")
    if [[ -n "$crumb" ]]; then
        headers+=("-H" "$crumb")
    fi
    
    # Make the API call
    local response=$(curl -s -w "%{http_code}" -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "${headers[@]}" \
        -X POST \
        -d "$post_data" \
        "$JENKINS_URL/pluginManager/installNecessaryPlugins")
    
    local http_code="${response: -3}"
    local body="${response%???}"
    
    if [[ "$http_code" == "200" ]] || [[ "$http_code" == "302" ]]; then
        print_success "Plugin $plugin installation initiated"
        return 0
    else
        print_error "Failed to install $plugin (HTTP: $http_code)"
        return 1
    fi
}

# Function to check plugin installation status
check_installation_status() {
    print_status "Checking plugin installation status..."
    
    local max_attempts=60  # 5 minutes
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Check if Jenkins is installing plugins
        local status=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
            "$JENKINS_URL/updateCenter/api/json?tree=jobs[name,status]" 2>/dev/null)
        
        if [[ "$status" == *"Installing"* ]] || [[ "$status" == *"Pending"* ]]; then
            print_status "Plugins still installing... (attempt $attempt/$max_attempts)"
            sleep 5
            ((attempt++))
        else
            print_success "Plugin installation completed"
            return 0
        fi
    done
    
    print_warning "Installation status check timed out"
    return 1
}

# Function to restart Jenkins safely
restart_jenkins() {
    print_status "Initiating Jenkins restart..."
    
    local crumb=$(get_crumb)
    local headers=()
    if [[ -n "$crumb" ]]; then
        headers+=("-H" "$crumb")
    fi
    
    curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "${headers[@]}" \
        -X POST \
        "$JENKINS_URL/safeRestart"
    
    print_status "Jenkins restart initiated, waiting for it to come back online..."
    sleep 30
    
    # Wait for Jenkins to restart
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$JENKINS_URL/login" > /dev/null 2>&1; then
            print_success "Jenkins is back online"
            return 0
        fi
        print_status "Waiting for Jenkins... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    print_error "Jenkins did not come back online within expected time"
    return 1
}

# Function to list installed plugins
list_installed_plugins() {
    print_status "Listing installed plugins..."
    
    curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/pluginManager/api/json?depth=1" | \
    python3 -c "
import json, sys
data = json.load(sys.stdin)
plugins = data.get('plugins', [])
required = '''${REQUIRED_PLUGINS[*]}'''.split()

print('\\n📋 Plugin Installation Status:')
print('=' * 50)

installed = []
missing = []

for plugin_name in required:
    found = any(p['shortName'] == plugin_name for p in plugins if p.get('active', False))
    if found:
        print(f'✅ {plugin_name}')
        installed.append(plugin_name)
    else:
        print(f'❌ {plugin_name}')
        missing.append(plugin_name)

print(f'\\n📊 Summary:')
print(f'✅ Installed: {len(installed)}/{len(required)}')
print(f'❌ Missing: {len(missing)}/{len(required)}')

if missing:
    print(f'\\n❌ Still missing: {", ".join(missing)}')
" 2>/dev/null || {
        print_warning "Could not parse plugin list, checking manually..."
        curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
            "$JENKINS_URL/pluginManager/api/json?tree=plugins[shortName,active]" | \
        grep -E "(shortName|active)" | head -20
    }
}

# Main execution
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} Jenkins Plugin Installer (API)${NC}"
    echo -e "${BLUE} EKS Products CI/CD Pipeline${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # Check if required tools are available
    for tool in curl python3; do
        if ! command -v $tool &> /dev/null; then
            print_error "$tool is required but not installed"
            exit 1
        fi
    done
    
    # Execute installation steps
    if ! check_jenkins; then
        exit 1
    fi
    
    local crumb=$(get_crumb)
    
    print_status "Installing ${#REQUIRED_PLUGINS[@]} required plugins..."
    
    local failed_plugins=()
    local success_count=0
    
    for plugin in "${REQUIRED_PLUGINS[@]}"; do
        if install_plugin_api "$plugin" "$crumb"; then
            ((success_count++))
        else
            failed_plugins+=("$plugin")
        fi
        sleep 1  # Rate limiting
    done
    
    echo
    print_status "Plugin installation requests sent:"
    print_success "Successfully requested: $success_count/${#REQUIRED_PLUGINS[@]} plugins"
    
    if [ ${#failed_plugins[@]} -gt 0 ]; then
        print_warning "Failed to request installation for:"
        for plugin in "${failed_plugins[@]}"; do
            echo "  - $plugin"
        done
    fi
    
    echo
    print_status "Waiting for plugin installations to complete..."
    check_installation_status
    
    echo
    print_status "Restarting Jenkins to activate plugins..."
    if restart_jenkins; then
        echo
        print_status "Verifying plugin installation..."
        list_installed_plugins
    else
        print_error "Jenkins restart failed, please restart manually"
    fi
    
    echo
    print_success "Plugin installation process completed!"
    print_status "Access Jenkins at: $JENKINS_URL"
}

# Execute main function
main "$@"
