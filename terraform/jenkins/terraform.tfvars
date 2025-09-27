# Example Terraform variables file for Jenkins deployment
# Copy this file to terraform.tfvars and customize the values

# AWS Configuration
aws_region = "us-east-1"
environment = "dev"
project_name = "jenkins-cicd"

# Network Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

# SECURITY WARNING: Restrict this to your specific IP ranges for production
# Example: ["1.2.3.4/32", "10.0.0.0/8"]
allowed_cidr_blocks = ["0.0.0.0/0"]

# EC2 Configuration
instance_type = "t3.medium"
root_volume_size = 30
jenkins_volume_size = 50

# SSH Key Configuration
# Generate with: ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
# Then copy the contents of ~/.ssh/id_rsa.pub
public_key = "ssh-ed25519 abcd lavital@gmail.com"

# Jenkins Configuration
jenkins_admin_user = "admin"
# IMPORTANT: Use a strong password or set via environment variable
jenkins_admin_password = "ChangeMe@1234"

# Tool Versions
maven_version = "3.9.5"
node_version = "18"
java_version = "21"
docker_version = "latest"

# Optional Features
enable_backup = true
backup_retention_days = 30
enable_cloudwatch_monitoring = true
log_retention_days = 14

# SSL Configuration (optional)
enable_ssl = false
domain_name = ""
certificate_arn = ""

# Auto-shutdown Configuration (optional - for cost savings)
enable_auto_shutdown = false
shutdown_time = "18:00"
startup_time = "08:00"
timezone = "UTC"
