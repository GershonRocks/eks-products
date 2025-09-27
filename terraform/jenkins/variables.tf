# Variables for Jenkins Terraform deployment

variable "aws_region" {
  description = "AWS region for Jenkins deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "jenkins-cicd"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access Jenkins"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Change this to your IP range for security
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type for Jenkins server"
  type        = string
  default     = "t3.medium"
  
  validation {
    condition = contains([
      "t3.small", "t3.medium", "t3.large", "t3.xlarge",
      "m5.large", "m5.xlarge", "m5.2xlarge",
      "c5.large", "c5.xlarge", "c5.2xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type suitable for Jenkins."
  }
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30
}

variable "jenkins_volume_size" {
  description = "Size of the Jenkins data EBS volume in GB"
  type        = number
  default     = 50
}

variable "public_key" {
  description = "Public key for SSH access to Jenkins server"
  type        = string
  # You'll need to provide this when running terraform apply
  # Example: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... user@hostname
}

# Jenkins Configuration
variable "jenkins_admin_user" {
  description = "Jenkins admin username"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Jenkins admin password"
  type        = string
  sensitive   = true
  # You should provide this as an environment variable or via terraform.tfvars
}

# Tool Versions
variable "maven_version" {
  description = "Maven version to install"
  type        = string
  default     = "3.9.5"
}

variable "node_version" {
  description = "Node.js version to install"
  type        = string
  default     = "18"
}

variable "java_version" {
  description = "Java version for Jenkins"
  type        = string
  default     = "21"
}

variable "docker_version" {
  description = "Docker version to install"
  type        = string
  default     = "latest"
}

# Jenkins Plugins Configuration
variable "jenkins_plugins" {
  description = "List of Jenkins plugins to install"
  type        = list(string)
  default = [
    # Essential plugins
    "blueocean",
    "workflow-aggregator",
    "pipeline-stage-view",
    "pipeline-maven",
    
    # Build tools
    "maven-plugin",
    "gradle",
    "nodejs",
    "ant",
    
    # Version control
    "git",
    "github",
    "github-branch-source",
    "bitbucket",
    "gitlab-plugin",
    
    # Docker & Kubernetes
    "docker-plugin",
    "docker-workflow",
    "kubernetes",
    "kubernetes-cli",
    
    # Security & Quality
    "sonar",
    "snyk-security-scanner",
    "owasp-dependency-check",
    "checkmarx",
    
    # Cloud providers
    "ec2",
    "aws-credentials",
    "aws-parameter-store",
    "amazon-ecr",
    "aws-codebuild",
    
    # Notifications
    "slack",
    "email-ext",
    "mailer",
    "build-monitor-plugin",
    
    # Utilities
    "timestamper",
    "ws-cleanup",
    "build-timeout",
    "credentials-binding",
    "ssh-agent",
    "publish-over-ssh",
    
    # Reporting
    "junit",
    "jacoco",
    "html-publisher",
    "cobertura",
    "performance",
    
    # Automation
    "parameterized-trigger",
    "build-pipeline-plugin",
    "delivery-pipeline-plugin",
    "workflow-multibranch",
    
    # Monitoring
    "monitoring",
    "prometheus",
    "datadog",
    
    # Additional tools
    "terraform",
    "ansible",
    "puppet",
    "artifactory"
  ]
}

# Backup Configuration
variable "enable_backup" {
  description = "Enable automated backup of Jenkins data"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain Jenkins backups"
  type        = number
  default     = 30
}

# Monitoring Configuration
variable "enable_cloudwatch_monitoring" {
  description = "Enable CloudWatch monitoring for Jenkins instance"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 14
}

# SSL Configuration
variable "enable_ssl" {
  description = "Enable SSL/HTTPS for Jenkins"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name for Jenkins (required if SSL is enabled)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "AWS Certificate Manager ARN for SSL certificate"
  type        = string
  default     = ""
}

# Scaling Configuration
variable "enable_auto_shutdown" {
  description = "Enable automatic shutdown during off-hours to save costs"
  type        = bool
  default     = false
}

variable "shutdown_time" {
  description = "Time to shutdown instance (24h format, e.g., '18:00')"
  type        = string
  default     = "18:00"
}

variable "startup_time" {
  description = "Time to startup instance (24h format, e.g., '08:00')"
  type        = string
  default     = "08:00"
}

variable "timezone" {
  description = "Timezone for auto-shutdown schedule"
  type        = string
  default     = "UTC"
}
