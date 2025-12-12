#!/bin/bash

# Build script for Service Mesh Demo
# This script builds both manual sidecar (v1.0) and service mesh (v2.0) versions

set -e

echo "🔧 Service Mesh Demo - Build Script"
echo "===================================="
echo ""

# Parse command line arguments
VERSION="${1:-all}"  # Default to 'all' if no argument provided

# Set JAVA_HOME to Java 24
export JAVA_HOME=/Users/pamperayani/Library/Java/JavaVirtualMachines/openjdk-24.0.2/Contents/Home

# Verify Java version
echo "Using Java version:"
$JAVA_HOME/bin/java -version
echo ""

# Check if minikube is running and use its Docker daemon
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo "📦 Detected minikube - using minikube's Docker daemon"
    eval $(minikube docker-env)
else
    echo "⚠️  Warning: minikube not running. Images will be built in local Docker."
    echo "   Run 'minikube start' first for Kubernetes deployment."
fi
echo ""

# Build customer-service JAR
echo "📦 Building customer-service JAR..."
cd customer-service
mvn clean package
cd ..
echo "✅ customer-service JAR built successfully"
echo ""

# Build Docker images based on version argument
echo "🐳 Building Docker images..."
echo ""

if [ "$VERSION" = "all" ] || [ "$VERSION" = "v1" ]; then
    echo "Building v1.0 (Manual Sidecar Pattern)..."
    echo "----------------------------------------"

    # Build customer-service v1.0
    echo "Building customer-service:1.0..."
    docker build -t customer-service:1.0 customer-service/
    echo "✅ customer-service:1.0 built"

    # Build logging-sidecar
    echo "Building logging-sidecar:1.0..."
    docker build -t logging-sidecar:1.0 logging-sidecar/
    echo "✅ logging-sidecar:1.0 built"
    echo ""
fi

if [ "$VERSION" = "all" ] || [ "$VERSION" = "v2" ]; then
    echo "Building v2.0 (Service Mesh)..."
    echo "-------------------------------"

    # Build customer-service v2.0
    echo "Building customer-service:2.0..."
    docker build -t customer-service:2.0 customer-service/
    echo "✅ customer-service:2.0 built"
    echo ""
fi

echo "🎉 Build completed successfully!"
echo ""
echo "📋 Next steps:"
echo ""

if [ "$VERSION" = "all" ] || [ "$VERSION" = "v1" ]; then
    echo "For Manual Sidecar Pattern (v1.0):"
    echo "  1. Deploy: kubectl apply -f k8s/deployment.yaml -f k8s/service.yaml"
    echo "  2. Check: kubectl get pods"
    echo "  3. Access: kubectl port-forward svc/customer-service 8080:80"
    echo "  4. Test: curl http://localhost:8080/api/customers"
    echo ""
fi

if [ "$VERSION" = "all" ] || [ "$VERSION" = "v2" ]; then
    echo "For Service Mesh (v2.0):"
    echo "  1. Install Istio: make install-istio"
    echo "  2. Install Observability: make install-observability"
    echo "  3. Deploy: kubectl apply -f k8s/deployment-istio.yaml -f k8s/service.yaml"
    echo "  4. Check: kubectl get pods"
    echo "  5. Dashboards: make dashboards"
    echo "  6. Test: curl http://localhost:8080/api/customers"
    echo ""
fi

echo "💡 Quick commands:"
echo "  make help           - See all available commands"
echo "  make deploy         - Deploy v1.0 (manual sidecar)"
echo "  make deploy-mesh    - Deploy v2.0 (service mesh)"
echo "  make dashboards     - Open all observability dashboards"
echo ""

