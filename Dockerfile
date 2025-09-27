# Multi-arch build for ARM64 and AMD64
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-21 AS builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Build metadata
ARG BUILD_VERSION="unknown"
ARG GIT_COMMIT="unknown"
ARG BUILD_DATE="unknown"

WORKDIR /app

# Copy POM first for better cache utilization
COPY pom.xml .
COPY owasp-suppressions.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build application with metadata
RUN mvn clean package -DskipTests -B \
    -Dproject.version=${BUILD_VERSION} \
    -Dgit.commit=${GIT_COMMIT} \
    -Dbuild.date=${BUILD_DATE}

# Runtime stage - Eclipse Temurin supports ARM64
FROM eclipse-temurin:21-jre-alpine

# Build metadata labels
ARG BUILD_VERSION="unknown"
ARG GIT_COMMIT="unknown"
ARG BUILD_DATE="unknown"

LABEL maintainer="GershonRocks" \
      version="${BUILD_VERSION}" \
      git.commit="${GIT_COMMIT}" \
      build.date="${BUILD_DATE}" \
      description="EKS Products API - Spring Boot microservice" \
      org.opencontainers.image.source="https://github.com/GershonRocks/eks-products" \
      org.opencontainers.image.version="${BUILD_VERSION}" \
      org.opencontainers.image.revision="${GIT_COMMIT}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="EKS Products API" \
      org.opencontainers.image.description="Spring Boot microservice for product management on EKS"

# Install runtime dependencies and create non-root user
RUN apk add --no-cache bash curl dumb-init && \
    addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser && \
    mkdir -p /app/data /app/logs && \
    chown -R appuser:appuser /app

WORKDIR /app

# Copy application JAR
COPY --from=builder --chown=appuser:appuser /app/target/*.jar app.jar

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]
CMD ["java", \
     "-XX:+UseContainerSupport", \
     "-XX:MaxRAMPercentage=75", \
     "-XX:+HeapDumpOnOutOfMemoryError", \
     "-XX:HeapDumpPath=/app/logs/", \
     "-Djava.security.egd=file:/dev/./urandom", \
     "-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE:kubernetes}", \
     "-jar", "app.jar"]
