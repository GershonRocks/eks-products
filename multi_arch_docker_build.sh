# Build for ARM64 (your M3)
docker build --platform=linux/arm64 -t eks-products-app:arm64 .

# Test locally on your M3
docker run -d --name eks-products-test \
  -p 8080:8080 \
  -e MANAGEMENT_HEALTH_REDIS_ENABLED=false \
  -e SPRING_CACHE_TYPE=none \
  eks-products-app:arm64

# Check it's running
docker ps
curl http://localhost:8080/actuator/health
