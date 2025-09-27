.PHONY: help build run test clean docker-build docker-run k8s-deploy

help:
	@echo "Available targets:"
	@echo "  build        - Build the application"
	@echo "  run          - Run the application locally"
	@echo "  test         - Run tests"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-run   - Run with Docker Compose"
	@echo "  k8s-deploy   - Deploy to Kubernetes"
	@echo "  clean        - Clean build artifacts"

build:
	mvn clean package

run:
	mvn spring-boot:run -Dspring.profiles.active=local

test:
	mvn test

docker-build:
	docker build -t eks-products:latest .

docker-run:
	docker-compose up -d

k8s-deploy:
	kubectl apply -f k8s/

clean:
	mvn clean
	docker-compose down
	rm -rf target/ data/

minikube-setup:
	minikube start --cpus=4 --memory=4096
	minikube addons enable ingress
	minikube addons enable metrics-server

helm-deploy:
	helm dependency update helm/eks-products
	helm install eks-products helm/eks-products

helm-upgrade:
	helm upgrade eks-products helm/eks-products

terraform-init:
	cd terraform && terraform init

terraform-plan:
	cd terraform && terraform plan

terraform-apply:
	cd terraform && terraform apply -auto-approve

terraform-destroy:
	cd terraform && terraform destroy
