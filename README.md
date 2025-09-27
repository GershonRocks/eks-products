# 🚀 EKS Products Microservice

<div align="center">

![Java](https://img.shields.io/badge/Java-25-orange?style=for-the-badge&logo=openjdk)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-green?style=for-the-badge&logo=springboot)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-blue?style=for-the-badge&logo=kubernetes)
![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange?style=for-the-badge&logo=amazon-aws)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

*A high-performance Spring Boot microservice for product pricing, built for cloud-native environments*

[Features](#-features) • [Quick Start](#-quick-start) • [API Documentation](#-api-documentation) • [Deployment](#-deployment) • [Monitoring](#-monitoring)

</div>

---

## 📋 Overview

EKS Products is a production-ready microservice that provides fast and reliable product pricing information. Built with Spring Boot and optimized for Kubernetes environments, it leverages Redis caching for high performance and includes comprehensive DevOps tooling for modern cloud deployments.

### 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Load Balancer │    │  EKS Products   │    │     Redis       │
│    (ALB/NLB)    │───▶│   Microservice  │───▶│     Cache       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │  SQLite Database│
                       │   (Persistent)  │
                       └─────────────────┘
```

## ✨ Features

- 🔄 **RESTful API** - Complete CRUD operations for product management
- ⚡ **High Performance** - Redis caching with configurable TTL
- 📊 **Production Ready** - Health checks, metrics, and observability
- 🌐 **Cloud Native** - Kubernetes-ready with auto-scaling capabilities
- 🔧 **Infrastructure as Code** - Terraform for AWS resource management
- 🚀 **GitOps Deployment** - ArgoCD for continuous deployment
- 📦 **Package Management** - Helm charts for easy deployment
- 🐳 **Containerized** - Multi-architecture Docker support
- 🔍 **Monitoring** - Prometheus metrics and Spring Boot Actuator
- 🧪 **Testing Ready** - Load testing scripts included

## 🚀 Quick Start

### Prerequisites

Ensure you have the following installed:

| Tool | Version | Purpose |
|------|---------|---------|
| ☕ Java | 25+ | Runtime environment |
| 📦 Maven | 3.8+ | Build tool |
| 🐳 Docker | Latest | Containerization |
| ⚙️ kubectl | Latest | Kubernetes CLI |
| 📊 Helm | 3.19+ | Package manager |
| 🏗️ Terraform | Latest | Infrastructure provisioning |

### 🏃‍♂️ Local Development

1. **Clone & Navigate**
   ```bash
   git clone <repository-url>
   cd eks-products
   ```

2. **Start Dependencies**
   ```bash
   # Start Redis cache
   docker run -d -p 6379:6379 --name redis redis:7-alpine
   ```

3. **Run Application**
   ```bash
   # Start the microservice
   mvn spring-boot:run -Dspring.profiles.active=local
   ```

4. **Verify Deployment**
   ```bash
   # Test health endpoint
   curl http://localhost:8080/actuator/health
   
   # Test API endpoint
   curl http://localhost:8080/api/products/PROD-001/price
   ```

## 📚 API Documentation

### Core Endpoints

| Method | Endpoint | Description | Example |
|--------|----------|-------------|---------|
| `GET` | `/api/products/{id}/price` | 💰 Get product price | `/api/products/PROD-001/price` |
| `GET` | `/api/products/{id}` | 📦 Get product details | `/api/products/PROD-001` |
| `GET` | `/api/products` | 📋 List all products | `/api/products?page=0&size=10` |
| `POST` | `/api/products` | ➕ Create new product | Body: `{"name": "...", "price": 99.99}` |
| `DELETE` | `/api/products/{id}` | 🗑️ Delete product | `/api/products/PROD-001` |

### Monitoring Endpoints

| Endpoint | Description |
|----------|-------------|
| `/actuator/health` | 🏥 Application health status |
| `/actuator/metrics` | 📊 Application metrics |
| `/actuator/prometheus` | 📈 Prometheus-formatted metrics |

### Example API Calls

<details>
<summary>📖 Click to expand API examples</summary>

```bash
# Get product price
curl -X GET "http://localhost:8080/api/products/PROD-001/price" \
  -H "Accept: application/json"

# Create a new product
curl -X POST "http://localhost:8080/api/products" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "PROD-002",
    "name": "Sample Product",
    "price": 29.99,
    "description": "A sample product for testing"
  }'

# Get all products with pagination
curl -X GET "http://localhost:8080/api/products?page=0&size=10" \
  -H "Accept: application/json"
```

</details>

## 🏗️ Deployment

### 🏠 Local Kubernetes (Minikube)

<details>
<summary>📖 Step-by-step local deployment</summary>

```bash
# 1. Start Minikube cluster
minikube start --cpus=4 --memory=4096 --driver=docker

# 2. Build and load Docker image
docker build -t eks-products:latest .
minikube image load eks-products:latest

# 3. Install dependencies and deploy
helm dependency update helm/eks-products
helm install eks-products helm/eks-products -f helm/eks-products/values-local.yaml

# 4. Access the application
minikube service eks-products-service --url
```

</details>

### ☁️ AWS EKS Production

<details>
<summary>📖 Production deployment guide</summary>

```bash
# 1. Provision AWS infrastructure
cd terraform
terraform init
terraform plan -var="environment=production"
terraform apply

# 2. Configure kubectl for EKS
aws eks update-kubeconfig --name eks-products-cluster --region us-east-1

# 3. Deploy application using Helm
helm repo add eks-products ./helm/eks-products
helm install eks-products eks-products/eks-products -f helm/eks-products/values-prod.yaml

# 4. Verify deployment
kubectl get pods -n eks-products
kubectl get svc eks-products-service -n eks-products
```

</details>

### 🔄 GitOps with ArgoCD

<details>
<summary>📖 GitOps deployment setup</summary>

```bash
# 1. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Apply ArgoCD application
kubectl apply -f argocd/application.yaml

# 3. Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

</details>

## 📊 Monitoring

### Health Checks

```bash
# Application health
curl http://<SERVICE_URL>/actuator/health

# Detailed health information
curl http://<SERVICE_URL>/actuator/health/readiness
curl http://<SERVICE_URL>/actuator/health/liveness
```

### Performance Monitoring

- **📈 Prometheus Metrics**: Available at `/actuator/prometheus`
- **📊 Application Metrics**: Available at `/actuator/metrics`
- **🔍 Custom Metrics**: Cache hit rates, API response times, database connections

### Load Testing

```bash
# Install Apache Bench
apt-get update && apt-get install -y apache2-utils

# Run performance test
ab -n 10000 -c 100 -H "Accept: application/json" \
   http://<LOAD_BALANCER_URL>/api/products/PROD-001/price

# Advanced testing with multiple endpoints
for endpoint in price details; do
  ab -n 5000 -c 50 http://<URL>/api/products/PROD-001/$endpoint
done
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_HOST` | `localhost` | Redis server hostname |
| `REDIS_PORT` | `6379` | Redis server port |
| `SQLITE_PATH` | `./data/products.db` | SQLite database file path |
| `SPRING_PROFILES_ACTIVE` | `local` | Spring Boot profile (`local`/`prod`) |
| `CACHE_TTL` | `600` | Cache time-to-live (seconds) |
| `SERVER_PORT` | `8080` | Application server port |
| `MANAGEMENT_PORT` | `8081` | Management/actuator port |

### Profiles

- **`local`**: SQLite database, local Redis, debug logging
- **`docker`**: Containerized dependencies, production logging
- **`prod`**: Production settings, external databases, security enabled

## 🔧 CI/CD Pipeline

### GitHub Actions Workflow

The automated pipeline includes:

1. **🧪 Test Phase**
   - Unit tests execution
   - Integration tests
   - Code quality checks

2. **🏗️ Build Phase**
   - Maven compilation
   - Docker image creation
   - Multi-architecture builds

3. **🚀 Deploy Phase**
   - Push to ECR registry
   - Helm chart validation
   - EKS deployment

### Pipeline Status

![Build Status](https://github.com/your-username/eks-products/workflows/CI-CD/badge.svg)
![Security Scan](https://github.com/your-username/eks-products/workflows/Security-Scan/badge.svg)

## 🛠️ Troubleshooting

<details>
<summary>🔍 Common Issues & Solutions</summary>

### Application Issues

```bash
# Check application logs
kubectl logs -f deployment/eks-products -n eks-products

# Check pod status
kubectl describe pod <pod-name> -n eks-products

# View events
kubectl get events -n eks-products --sort-by='.lastTimestamp'
```

### Redis Connection Issues

```bash
# Test Redis connectivity
kubectl exec -it deployment/redis -n eks-products -- redis-cli ping

# Check Redis logs
kubectl logs deployment/redis -n eks-products
```

### Performance Issues

```bash
# Scale application manually
kubectl scale deployment/eks-products --replicas=5 -n eks-products

# Check resource utilization
kubectl top pods -n eks-products
kubectl top nodes
```

### Database Issues

```bash
# Check database file permissions
kubectl exec -it deployment/eks-products -n eks-products -- ls -la /data/

# Verify database connectivity
kubectl exec -it deployment/eks-products -n eks-products -- \
  java -jar app.jar --spring.profiles.active=prod --spring.datasource.url=jdbc:sqlite:/data/products.db
```

</details>

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**⭐ Star this repository if you find it helpful!**

Made with ❤️ by [Gershon](https://github.com/gershonrocks)

</div>
