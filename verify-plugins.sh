#!/bin/bash

# Jenkins Plugin Verification Script
# Checks if all required plugins are installed and active

JENKINS_URL="http://54.166.37.229:8080"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_PASSWORD="${JENKINS_PASSWORD:-}"

# Check if password is set
if [ -z "$JENKINS_PASSWORD" ]; then
    echo "Error: JENKINS_PASSWORD environment variable is not set"
    echo "Please export JENKINS_PASSWORD=<your-password> before running this script"
    exit 1
fi

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

# Required plugins for the CI/CD pipeline
REQUIRED_PLUGINS=(
    # Core CI/CD
    "workflow-aggregator:Pipeline"
    "blueocean:Blue Ocean"
    "git:Git"
    "github:GitHub"
    
    # Docker & Containers
    "docker-workflow:Docker Pipeline"
    "docker-commons:Docker Commons"
    "docker-build-step:Docker Build Step"
    
    # AWS Integration
    "pipeline-aws:Pipeline AWS Steps"
    "amazon-ecr:Amazon ECR"
    "aws-credentials:AWS Credentials"
    
    # Kubernetes
    "kubernetes:Kubernetes"
    "kubernetes-credentials-provider:Kubernetes Credentials Provider"
    
    # Build Tools
    "maven-plugin:Maven Integration"
    "pipeline-maven:Pipeline Maven Integration"
    
    # Quality & Security
    "sonar:SonarQube Scanner"
    "snyk-security-scanner:Snyk Security Scanner"
    "jacoco:JaCoCo"
    "htmlpublisher:HTML Publisher"
    "dependency-check-jenkins-plugin:OWASP Dependency Check"
    
    # Utilities
    "ansicolor:AnsiColor"
    "timestamper:Timestamper"
    "ws-cleanup:Workspace Cleanup"
    "build-timeout:Build Timeout"
    "copyartifact:Copy Artifact"
    "build-name-setter:Build Name Setter"
    "config-file-provider:Config File Provider"
    
    # Notifications
    "slack:Slack Notification"
    "email-ext:Email Extension"
    "mailer:Mailer"
    
    # Security
    "credentials:Credentials"
    "credentials-binding:Credentials Binding"
    "matrix-auth:Matrix Authorization"
    "role-strategy:Role-based Authorization"
    
    # Monitoring
    "monitoring:Monitoring"
    "metrics:Metrics"
    "prometheus:Prometheus Metrics"
    "performance:Performance"
)

# Function to check plugins via filesystem
check_plugins_filesystem() {
    print_status "Checking plugins via filesystem..."
    
    ssh ubuntu@54.166.37.229 << 'EOF'
echo "📁 Jenkins plugins directory contents:"
echo "Total .jpi files: $(find /var/lib/jenkins/plugins -name "*.jpi" 2>/dev/null | /usr/bin/wc -l)"
echo "Total plugin directories: $(find /var/lib/jenkins/plugins -maxdepth 1 -type d 2>/dev/null | /usr/bin/wc -l)"

echo
echo "🔍 Key plugins verification:"

PLUGINS_TO_CHECK=("blueocean" "docker-workflow" "docker-commons" "pipeline-aws" "amazon-ecr" "aws-credentials" "kubernetes" "maven-plugin" "pipeline-maven" "jacoco" "slack" "sonar" "snyk-security-scanner" "ansicolor" "htmlpublisher")

for plugin in "${PLUGINS_TO_CHECK[@]}"; do
    if [ -f "/var/lib/jenkins/plugins/${plugin}.jpi" ] || [ -d "/var/lib/jenkins/plugins/${plugin}" ]; then
        echo "✅ $plugin"
    else
        echo "❌ $plugin"
    fi
done
EOF
}

# Function to check plugins via Jenkins API
check_plugins_api() {
    print_status "Checking plugins via Jenkins API..."
    
    # Get plugin list from Jenkins
    local plugin_data=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
        "$JENKINS_URL/pluginManager/api/json?tree=plugins[shortName,longName,active,enabled]")
    
    if [[ $? -eq 0 ]] && [[ -n "$plugin_data" ]]; then
        echo "$plugin_data" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    plugins = data.get('plugins', [])
    
    # Create a dict for quick lookup
    installed_plugins = {p['shortName']: p for p in plugins}
    
    required = [
        'workflow-aggregator', 'blueocean', 'git', 'github',
        'docker-workflow', 'docker-commons', 'docker-build-step',
        'pipeline-aws', 'amazon-ecr', 'aws-credentials',
        'kubernetes', 'kubernetes-credentials-provider',
        'maven-plugin', 'pipeline-maven',
        'sonar', 'snyk-security-scanner', 'jacoco', 'htmlpublisher',
        'ansicolor', 'slack', 'timestamper', 'ws-cleanup',
        'credentials', 'credentials-binding', 'matrix-auth'
    ]
    
    print('\\n📊 Plugin Status Report:')
    print('=' * 60)
    
    installed_count = 0
    missing_count = 0
    
    for plugin_name in required:
        if plugin_name in installed_plugins:
            plugin_info = installed_plugins[plugin_name]
            status = '🟢 Active' if plugin_info.get('active', False) else '🟡 Inactive'
            enabled = '✅ Enabled' if plugin_info.get('enabled', False) else '❌ Disabled'
            print(f'✅ {plugin_name:<30} {status} {enabled}')
            installed_count += 1
        else:
            print(f'❌ {plugin_name:<30} Not installed')
            missing_count += 1
    
    print('\\n' + '=' * 60)
    print(f'📈 Summary: {installed_count}/{len(required)} plugins installed')
    print(f'✅ Installed: {installed_count}')
    print(f'❌ Missing: {missing_count}')
    
    if missing_count == 0:
        print('\\n🎉 All required plugins are installed!')
    else:
        print(f'\\n⚠️  {missing_count} plugins still missing')
        
except Exception as e:
    print(f'Error parsing plugin data: {e}')
    sys.exit(1)
" 2>/dev/null
    else
        print_warning "Could not retrieve plugin data via API, using filesystem check only"
        return 1
    fi
}

# Function to test Jenkins functionality
test_jenkins_functionality() {
    print_status "Testing Jenkins functionality..."
    
    # Test basic connectivity
    if curl -s -f "$JENKINS_URL/api/json" > /dev/null; then
        print_success "✅ Jenkins API is accessible"
    else
        print_error "❌ Jenkins API is not accessible"
        return 1
    fi
    
    # Test authentication
    if curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/api/json" | grep -q "jobs"; then
        print_success "✅ Jenkins authentication works"
    else
        print_error "❌ Jenkins authentication failed"
        return 1
    fi
    
    # Check if Blue Ocean is accessible
    local blue_ocean_status=$(curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL/blue/")
    if [[ "$blue_ocean_status" == "200" ]]; then
        print_success "✅ Blue Ocean UI is accessible"
    else
        print_warning "⚠️  Blue Ocean UI returned status: $blue_ocean_status"
    fi
    
    return 0
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE} Jenkins Plugin Verification${NC}"
    echo -e "${BLUE} EKS Products CI/CD Pipeline${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    
    print_status "Verifying Jenkins plugin installation..."
    
    # Check filesystem
    check_plugins_filesystem
    
    echo
    
    # Check via API
    if check_plugins_api; then
        echo
    fi
    
    # Test functionality
    if test_jenkins_functionality; then
        echo
        print_success "🎉 Jenkins verification completed successfully!"
        print_status "🌐 Access Jenkins at: $JENKINS_URL"
        print_status "🔷 Blue Ocean UI: $JENKINS_URL/blue/"
        print_status "🔑 Login: $JENKINS_USER / [password]"
        
        echo
        print_status "🚀 Next steps:"
        echo "  1. Access Jenkins web interface"
        echo "  2. Navigate to Manage Jenkins → Manage Plugins → Installed"
        echo "  3. Verify all plugins are active"
        echo "  4. Test your CI/CD pipeline with the Jenkinsfile"
        
    else
        print_error "❌ Jenkins functionality test failed"
        return 1
    fi
}

# Execute main function
main "$@"
