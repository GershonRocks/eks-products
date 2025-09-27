# Jenkins Terraform Deployment Makefile
# This Makefile provides convenient commands for Jenkins infrastructure management

.PHONY: help init plan apply destroy validate format check-vars ssh backup status logs clean

# Default values
ENVIRONMENT ?= dev
REGION ?= us-east-1

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

# Help target
help: ## Show this help message
	@echo "$(GREEN)Jenkins Terraform Deployment Commands$(NC)"
	@echo "======================================"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "$(YELLOW)%-15s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make init                    # Initialize Terraform"
	@echo "  make plan                    # Review deployment plan"
	@echo "  make apply                   # Deploy Jenkins infrastructure"
	@echo "  make ssh                     # SSH to Jenkins server"
	@echo "  make status                  # Check Jenkins status"
	@echo "  make destroy                 # Destroy infrastructure"

init: ## Initialize Terraform
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	terraform init
	@echo "$(GREEN)Terraform initialized successfully!$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(GREEN)Validating Terraform configuration...$(NC)"
	terraform validate
	@echo "$(GREEN)Configuration is valid!$(NC)"

format: ## Format Terraform files
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)Files formatted successfully!$(NC)"

check-vars: ## Check if required variables are set
	@echo "$(GREEN)Checking required variables...$(NC)"
	@if [ ! -f terraform.tfvars ]; then \
		echo "$(RED)Error: terraform.tfvars not found!$(NC)"; \
		echo "$(YELLOW)Please copy terraform.tfvars.example to terraform.tfvars and customize it$(NC)"; \
		exit 1; \
	fi
	@if ! grep -q "public_key.*ssh-\(rsa\|ed25519\)" terraform.tfvars; then \
		echo "$(RED)Error: public_key not set in terraform.tfvars!$(NC)"; \
		echo "$(YELLOW)Please add your SSH public key to terraform.tfvars$(NC)"; \
		exit 1; \
	fi
	@if ! grep -q "jenkins_admin_password.*=" terraform.tfvars && [ -z "$$TF_VAR_jenkins_admin_password" ]; then \
		echo "$(RED)Error: jenkins_admin_password not set!$(NC)"; \
		echo "$(YELLOW)Please set jenkins_admin_password in terraform.tfvars or as environment variable$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Required variables are set!$(NC)"

plan: check-vars ## Show Terraform deployment plan
	@echo "$(GREEN)Creating Terraform plan...$(NC)"
	terraform plan
	@echo "$(GREEN)Plan created successfully!$(NC)"

apply: check-vars ## Deploy Jenkins infrastructure
	@echo "$(GREEN)Deploying Jenkins infrastructure...$(NC)"
	terraform apply -auto-approve
	@echo "$(GREEN)Deployment completed!$(NC)"
	@echo ""
	@echo "$(YELLOW)Jenkins is starting up. This may take 5-10 minutes.$(NC)"
	@echo "$(YELLOW)Access Jenkins at:$(NC) $$(terraform output -raw jenkins_url)"
	@echo ""
	@echo "$(GREEN)Next steps:$(NC)"
	@terraform output -raw post_deployment_steps

apply-interactive: check-vars ## Deploy with interactive confirmation
	@echo "$(GREEN)Deploying Jenkins infrastructure (interactive)...$(NC)"
	terraform apply
	@if [ $$? -eq 0 ]; then \
		echo "$(GREEN)Deployment completed!$(NC)"; \
		echo "$(YELLOW)Access Jenkins at:$(NC) $$(terraform output -raw jenkins_url)"; \
	fi

destroy: ## Destroy Jenkins infrastructure
	@echo "$(RED)WARNING: This will destroy all Jenkins infrastructure and data!$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to cancel, or Enter to continue...$(NC)"
	@read dummy
	terraform destroy

destroy-force: ## Force destroy without confirmation (DANGEROUS)
	@echo "$(RED)Force destroying Jenkins infrastructure...$(NC)"
	terraform destroy -auto-approve
	@echo "$(RED)Infrastructure destroyed!$(NC)"

output: ## Show Terraform outputs
	@echo "$(GREEN)Terraform outputs:$(NC)"
	terraform output

ssh: ## SSH to Jenkins server
	@echo "$(GREEN)Connecting to Jenkins server...$(NC)"
	@SSH_CMD=$$(terraform output -raw jenkins_ssh_command 2>/dev/null); \
	if [ $$? -eq 0 ] && [ -n "$$SSH_CMD" ]; then \
		echo "$(YELLOW)Running: $$SSH_CMD$(NC)"; \
		$$SSH_CMD; \
	else \
		echo "$(RED)Error: Cannot get SSH command. Is the infrastructure deployed?$(NC)"; \
		exit 1; \
	fi

status: ## Check Jenkins service status
	@echo "$(GREEN)Checking Jenkins status...$(NC)"
	@JENKINS_IP=$$(terraform output -raw jenkins_public_ip 2>/dev/null); \
	if [ $$? -eq 0 ] && [ -n "$$JENKINS_IP" ]; then \
		echo "$(YELLOW)Jenkins IP: $$JENKINS_IP$(NC)"; \
		echo "$(YELLOW)Checking web interface...$(NC)"; \
		if curl -s -o /dev/null -w "%{http_code}" http://$$JENKINS_IP:8080 | grep -q "200\|403"; then \
			echo "$(GREEN)✓ Jenkins web interface is responding$(NC)"; \
		else \
			echo "$(RED)✗ Jenkins web interface is not responding$(NC)"; \
		fi; \
	else \
		echo "$(RED)Error: Cannot get Jenkins IP. Is the infrastructure deployed?$(NC)"; \
	fi

logs: ## View Jenkins logs
	@echo "$(GREEN)Viewing Jenkins logs...$(NC)"
	@SSH_CMD=$$(terraform output -raw jenkins_ssh_command 2>/dev/null); \
	if [ $$? -eq 0 ] && [ -n "$$SSH_CMD" ]; then \
		$$SSH_CMD "sudo journalctl -u jenkins -f"; \
	else \
		echo "$(RED)Error: Cannot connect to server. Is the infrastructure deployed?$(NC)"; \
	fi

backup: ## Create Jenkins backup
	@echo "$(GREEN)Creating Jenkins backup...$(NC)"
	@SSH_CMD=$$(terraform output -raw jenkins_ssh_command 2>/dev/null); \
	if [ $$? -eq 0 ] && [ -n "$$SSH_CMD" ]; then \
		$$SSH_CMD "sudo /usr/local/bin/jenkins-backup.sh"; \
		echo "$(GREEN)Backup completed!$(NC)"; \
	else \
		echo "$(RED)Error: Cannot connect to server. Is the infrastructure deployed?$(NC)"; \
	fi

restart: ## Restart Jenkins service
	@echo "$(GREEN)Restarting Jenkins service...$(NC)"
	@SSH_CMD=$$(terraform output -raw jenkins_ssh_command 2>/dev/null); \
	if [ $$? -eq 0 ] && [ -n "$$SSH_CMD" ]; then \
		$$SSH_CMD "sudo systemctl restart jenkins"; \
		echo "$(GREEN)Jenkins restarted!$(NC)"; \
		echo "$(YELLOW)Waiting for Jenkins to start...$(NC)"; \
		sleep 30; \
		make status; \
	else \
		echo "$(RED)Error: Cannot connect to server. Is the infrastructure deployed?$(NC)"; \
	fi

install-plugins: ## Install additional Jenkins plugins
	@echo "$(GREEN)Installing additional Jenkins plugins...$(NC)"
	@echo "$(YELLOW)Available plugins will be shown in Jenkins web interface$(NC)"
	@echo "$(YELLOW)Access Jenkins at:$(NC) $$(terraform output -raw jenkins_url)/manage/pluginManager/available"

update-security: ## Update security group rules
	@echo "$(GREEN)Updating security group...$(NC)"
	terraform plan -target=aws_security_group.jenkins_sg
	terraform apply -target=aws_security_group.jenkins_sg

clean: ## Clean Terraform files
	@echo "$(GREEN)Cleaning Terraform files...$(NC)"
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate.backup
	@echo "$(GREEN)Cleaned successfully!$(NC)"

refresh: ## Refresh Terraform state
	@echo "$(GREEN)Refreshing Terraform state...$(NC)"
	terraform refresh

state-list: ## List Terraform state resources
	@echo "$(GREEN)Terraform state resources:$(NC)"
	terraform state list

setup: ## Initial setup - copy example config and initialize
	@echo "$(GREEN)Setting up Jenkins Terraform deployment...$(NC)"
	@if [ ! -f terraform.tfvars ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "$(YELLOW)Created terraform.tfvars from example$(NC)"; \
		echo "$(RED)IMPORTANT: Edit terraform.tfvars with your configuration!$(NC)"; \
		echo "$(YELLOW)Required changes:$(NC)"; \
		echo "  - Set your SSH public key"; \
		echo "  - Set Jenkins admin password"; \
		echo "  - Restrict allowed_cidr_blocks for security"; \
	else \
		echo "$(YELLOW)terraform.tfvars already exists$(NC)"; \
	fi
	make init
	@echo "$(GREEN)Setup completed!$(NC)"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Edit terraform.tfvars with your configuration"
	@echo "  2. Run 'make plan' to review the deployment"
	@echo "  3. Run 'make apply' to deploy Jenkins"

quick-deploy: setup plan apply ## Quick deployment (setup, plan, apply)
	@echo "$(GREEN)Quick deployment completed!$(NC)"

monitoring: ## Open CloudWatch monitoring
	@echo "$(GREEN)Opening CloudWatch monitoring...$(NC)"
	@REGION=$$(terraform output -raw aws_region 2>/dev/null || echo "us-east-1"); \
	echo "$(YELLOW)CloudWatch Console:$(NC)"; \
	echo "https://$$REGION.console.aws.amazon.com/cloudwatch/home?region=$$REGION#metricsV2:graph=~();search=Jenkins"

cost: ## Estimate monthly costs
	@echo "$(GREEN)Estimated monthly costs:$(NC)"
	@echo "$(YELLOW)EC2 t3.medium (24/7):$(NC) ~$$30-35/month"
	@echo "$(YELLOW)EBS gp3 50GB:$(NC) ~$$5/month"
	@echo "$(YELLOW)EBS gp3 30GB (root):$(NC) ~$$3/month"
	@echo "$(YELLOW)Elastic IP:$(NC) ~$$3.6/month"
	@echo "$(YELLOW)Data transfer:$(NC) Variable"
	@echo "$(GREEN)Total estimated:$(NC) ~$$40-50/month"
	@echo ""
	@echo "$(YELLOW)Cost optimization tips:$(NC)"
	@echo "  - Enable auto-shutdown for non-production environments"
	@echo "  - Use smaller instance types for development"
	@echo "  - Monitor CloudWatch for right-sizing opportunities"

info: ## Show deployment information
	@echo "$(GREEN)Jenkins Deployment Information$(NC)"
	@echo "==============================="
	@if terraform state list > /dev/null 2>&1; then \
		echo "$(YELLOW)Status:$(NC) Deployed"; \
		echo "$(YELLOW)Jenkins URL:$(NC) $$(terraform output -raw jenkins_url)"; \
		echo "$(YELLOW)Public IP:$(NC) $$(terraform output -raw jenkins_public_ip)"; \
		echo "$(YELLOW)SSH Command:$(NC) $$(terraform output -raw jenkins_ssh_command)"; \
		echo "$(YELLOW)Instance ID:$(NC) $$(terraform output -raw jenkins_instance_id)"; \
	else \
		echo "$(YELLOW)Status:$(NC) Not deployed"; \
	fi
	@echo ""
	@echo "$(GREEN)Available commands:$(NC) make help"
