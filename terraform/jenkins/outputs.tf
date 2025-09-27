# Outputs for Jenkins Terraform deployment

output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_eip.jenkins_eip.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP address of the Jenkins server"
  value       = aws_instance.jenkins_server.private_ip
}

output "jenkins_url" {
  description = "URL to access Jenkins web interface"
  value       = "http://${aws_eip.jenkins_eip.public_ip}:8080"
}

output "jenkins_ssh_command" {
  description = "SSH command to connect to Jenkins server"
  value       = "ssh -i ~/.ssh/${var.project_name}-key ubuntu@${aws_eip.jenkins_eip.public_ip}"
}

output "jenkins_instance_id" {
  description = "EC2 Instance ID of the Jenkins server"
  value       = aws_instance.jenkins_server.id
}

output "jenkins_security_group_id" {
  description = "Security Group ID for Jenkins server"
  value       = aws_security_group.jenkins_sg.id
}

output "jenkins_vpc_id" {
  description = "VPC ID where Jenkins is deployed"
  value       = aws_vpc.jenkins_vpc.id
}

output "jenkins_subnet_id" {
  description = "Subnet ID where Jenkins is deployed"
  value       = aws_subnet.jenkins_public_subnet.id
}

output "jenkins_iam_role_arn" {
  description = "IAM Role ARN for Jenkins instance"
  value       = aws_iam_role.jenkins_role.arn
}

output "jenkins_key_pair_name" {
  description = "Key pair name for SSH access"
  value       = aws_key_pair.jenkins_key.key_name
}

output "jenkins_data_volume_id" {
  description = "EBS Volume ID for Jenkins persistent data"
  value       = aws_ebs_volume.jenkins_data.id
}

output "jenkins_admin_credentials" {
  description = "Jenkins admin login information"
  value = {
    username = var.jenkins_admin_user
    password = "Check the instance logs or use the initial admin password"
    note     = "Initial admin password can be found at: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
  }
  sensitive = false
}

output "jenkins_logs_command" {
  description = "Command to view Jenkins logs"
  value       = "sudo journalctl -u jenkins -f"
}

output "jenkins_service_commands" {
  description = "Common Jenkins service management commands"
  value = {
    status  = "sudo systemctl status jenkins"
    start   = "sudo systemctl start jenkins"
    stop    = "sudo systemctl stop jenkins"
    restart = "sudo systemctl restart jenkins"
    logs    = "sudo journalctl -u jenkins -f"
  }
}

output "jenkins_config_locations" {
  description = "Important Jenkins file and directory locations"
  value = {
    home_directory    = "/var/lib/jenkins"
    config_file      = "/etc/sysconfig/jenkins"
    log_file         = "/var/log/jenkins/jenkins.log"
    plugins_directory = "/var/lib/jenkins/plugins"
    jobs_directory   = "/var/lib/jenkins/jobs"
    workspace_directory = "/var/lib/jenkins/workspace"
  }
}

output "installed_tools" {
  description = "Tools and versions installed on Jenkins server"
  value = {
    java_version   = var.java_version
    maven_version  = var.maven_version
    node_version   = var.node_version
    docker_version = var.docker_version
    git           = "latest"
    aws_cli       = "latest"
    kubectl       = "latest"
    helm          = "latest"
    terraform     = "latest"
  }
}

output "security_notes" {
  description = "Important security information"
  value = {
    warning = "SECURITY WARNING: Change default allowed CIDR blocks from 0.0.0.0/0 to your specific IP ranges"
    ssh_access = "SSH access is enabled on port 22"
    jenkins_access = "Jenkins web interface is accessible on port 8080"
    recommendation = "Consider setting up SSL/TLS and restricting access to specific IP ranges"
  }
}

output "backup_information" {
  description = "Jenkins backup and recovery information"
  value = {
    data_volume = "/dev/xvdf mounted to /var/lib/jenkins"
    backup_command = "sudo tar -czf /tmp/jenkins-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /var/lib/jenkins ."
    restore_command = "sudo tar -xzf backup-file.tar.gz -C /var/lib/jenkins"
    ebs_snapshot = "Create EBS snapshots of volume ${aws_ebs_volume.jenkins_data.id} for backup"
  }
}

output "post_deployment_steps" {
  description = "Steps to complete after deployment"
  value = <<EOT
Next Steps:
1. Wait for the instance to fully boot (5-10 minutes)
2. Access Jenkins at: http://${aws_eip.jenkins_eip.public_ip}:8080
3. SSH to server: ssh -i ~/.ssh/${var.project_name}-key ec2-user@${aws_eip.jenkins_eip.public_ip}
4. Login with admin user: ${var.jenkins_admin_user}
5. Complete Jenkins setup wizard in the web interface
6. Install additional plugins as needed
7. Configure security settings and user accounts
8. Set up your first build job
9. Configure backup strategy for Jenkins data
10. Review and tighten security group rules

Installation logs: sudo tail -f /var/log/jenkins-full-install.log
EOT
}

output "useful_commands" {
  description = "Useful commands for managing Jenkins"
  value = {
    check_jenkins_status = "curl -s http://${aws_eip.jenkins_eip.public_ip}:8080/login"
    view_jenkins_version = "java -jar /usr/share/jenkins/jenkins.war --version"
    list_installed_plugins = "sudo ls /var/lib/jenkins/plugins/"
    check_disk_usage = "df -h /var/lib/jenkins"
    monitor_cpu_memory = "top"
    check_network_ports = "sudo netstat -tlnp | grep -E ':(8080|22)'"
  }
}

output "monitoring_endpoints" {
  description = "Monitoring and health check endpoints"
  value = {
    jenkins_health = "http://${aws_eip.jenkins_eip.public_ip}:8080/manage"
    jenkins_metrics = "http://${aws_eip.jenkins_eip.public_ip}:8080/metrics"
    system_info = "http://${aws_eip.jenkins_eip.public_ip}:8080/systemInfo"
    jenkins_log = "http://${aws_eip.jenkins_eip.public_ip}:8080/log/all"
  }
}
