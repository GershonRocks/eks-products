module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "19.17.2"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    main = {
      desired_size = var.desired_capacity
      min_size     = var.min_size
      max_size     = var.max_size

      instance_types = [var.instance_type]
      capacity_type  = "ON_DEMAND"
      
      disk_size = 50
    }
  }

  tags = var.tags
}

# Configure kubectl
resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
  }

  depends_on = [module.eks]
}

# Output cluster details
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "load_balancer_hostname" {
  description = "Load balancer hostname (run kubectl get svc to get this after deployment)"
  value       = "Run: kubectl get svc -n eks-products eks-products-service"
}
