# Jenkins Plugins Management via Terraform
# This file can be used to manage Jenkins plugins declaratively

terraform {
  required_providers {
    jenkins = {
      source  = "taiidani/jenkins"
      version = "~> 0.10"
    }
  }
}

# Configure Jenkins provider
provider "jenkins" {
  server_url = var.jenkins_url
  username   = var.jenkins_admin_user
  password   = var.jenkins_admin_password
}

# Define plugins to install
locals {
  jenkins_plugins = [
    # Core CI/CD Plugins
    "workflow-aggregator",
    "blueocean",
    "git",
    "github",
    "docker-workflow",
    "build-timeout",
    "timestamper",
    "ws-cleanup",
    
    # AWS Integration
    "pipeline-aws",
    "amazon-ecr",
    "aws-credentials-binding",
    
    # Quality & Security
    "sonar",
    "dependency-check-jenkins-plugin",
    "htmlpublisher",
    "junit",
    "jacoco",
    
    # Notifications
    "slack",
    "email-ext",
    "mailer",
    
    # Kubernetes & Docker
    "kubernetes",
    "kubernetes-credentials-provider",
    "docker-commons",
    "docker-build-step",
    
    # Utilities
    "ansicolor",
    "build-name-setter",
    "copyartifact",
    "credentials",
    "credentials-binding",
    "matrix-auth",
    "role-strategy",
    "antisamy-markup-formatter",
    
    # Maven & Java
    "maven-plugin",
    "pipeline-maven",
    "config-file-provider",
    
    # Monitoring & Reporting
    "monitoring",
    "metrics",
    "prometheus",
    "performance",
  ]
}

# Install Jenkins plugins
resource "jenkins_plugin" "plugins" {
  for_each = toset(local.jenkins_plugins)
  
  name    = each.value
  version = "latest"
}

# Variables for Jenkins configuration
variable "jenkins_url" {
  description = "Jenkins server URL"
  type        = string
  default     = "http://54.166.37.229:8080"
}

variable "jenkins_admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
}

# Output plugin status
output "installed_plugins" {
  description = "List of installed Jenkins plugins"
  value       = local.jenkins_plugins
}
