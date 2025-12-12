# Makefile for Service Mesh Demo
# Provides convenient commands for building, deploying, and testing

.PHONY: help build-all build-customer build-sidecar deploy undeploy test clean logs

# Default target
help:
	@echo "Service Mesh Demo - Available Commands:"
	@echo ""
	@echo "🏗️  Build Commands:"
	@echo "  make build-all        - Build both Docker images (v1.0 manual sidecar)"
	@echo "  make build-mesh       - Build customer-service v2.0 for service mesh"
	@echo "  make build-customer   - Build customer-service image"
	@echo "  make build-sidecar    - Build logging-sidecar image"
	@echo ""
	@echo "🚀 Deployment Commands:"
	@echo "  make deploy           - Deploy manual sidecar version (v1.0)"
	@echo "  make deploy-mesh      - Deploy service mesh version (v2.0)"
	@echo "  make undeploy         - Remove from Kubernetes"
	@echo ""
	@echo "🔧 Istio & Observability:"
	@echo "  make install-istio    - Install Istio service mesh"
	@echo "  make install-observability - Install Loki, Grafana, Prometheus, Jaeger"
	@echo "  make uninstall-istio  - Uninstall Istio"
	@echo "  make dashboards       - Open all observability dashboards"
	@echo ""
	@echo "🧪 Testing & Monitoring:"
	@echo "  make test             - Run API tests"
	@echo "  make generate-traffic - Generate test traffic"
	@echo "  make logs             - Tail logs from all containers"
	@echo "  make logs-customer    - Tail logs from customer-service"
	@echo "  make logs-grafana     - View logs in Grafana (opens browser)"
	@echo ""
	@echo "🔄 Cluster Management:"
	@echo "  make start            - Start minikube cluster"
	@echo "  make stop             - Stop minikube cluster (preserves state)"
	@echo "  make restart          - Restart minikube cluster"
	@echo "  make delete           - Delete minikube cluster (clean slate)"
	@echo "  make status           - Show cluster and pod status"
	@echo ""
	@echo "🧹 Cleanup:"
	@echo "  make clean            - Clean build artifacts"
	@echo "  make clean-all        - Clean everything including Docker images"
	@echo ""

# Build all images (manual sidecar version)
build-all: build-customer build-sidecar

# Build service mesh version (v2.0)
build-mesh:
	@echo "🏗️  Building customer-service v2.0 for service mesh..."
	@eval $$(minikube docker-env) && \
	cd customer-service && mvn clean package && \
	docker build -t customer-service:2.0 .
	@echo "✅ customer-service:2.0 built successfully"

# Build customer service (v1.0)
build-customer:
	@echo "🏗️  Building customer-service v1.0..."
	@eval $$(minikube docker-env) && \
	cd customer-service && mvn clean package && \
	docker build -t customer-service:1.0 .
	@echo "✅ customer-service:1.0 built successfully"

# Build logging sidecar
build-sidecar:
	@echo "🏗️  Building logging-sidecar..."
	@eval $$(minikube docker-env) && \
	docker build -t logging-sidecar:1.0 logging-sidecar/
	@echo "✅ logging-sidecar:1.0 built successfully"

# Deploy manual sidecar version (v1.0)
deploy:
	@echo "🚀 Deploying manual sidecar version (v1.0)..."
	kubectl apply -f k8s/deployment.yaml
	kubectl apply -f k8s/service.yaml
	kubectl apply -f k8s/configmap.yaml
	@echo "⏳ Waiting for Pod to be ready..."
	kubectl wait --for=condition=ready pod -l app=customer-service --timeout=120s
	@echo "✅ Deployment complete"
	@echo ""
	@echo "Access the service:"
	@echo "  kubectl port-forward svc/customer-service 8080:80"
	@echo "  curl http://localhost:8080/api/customers"

# Deploy service mesh version (v2.0)
deploy-mesh:
	@echo "🚀 Deploying service mesh version (v2.0)..."
	kubectl apply -f k8s/deployment-istio.yaml
	kubectl apply -f k8s/service.yaml
	@echo "⏳ Waiting for Pod to be ready..."
	kubectl wait --for=condition=ready pod -l app=customer-service --timeout=120s
	@echo "✅ Deployment complete"
	@echo ""
	@echo "Access the service:"
	@echo "  kubectl port-forward svc/customer-service 8080:80"
	@echo "  curl http://localhost:8080/api/customers"

# Undeploy from Kubernetes
undeploy:
	@echo "🗑️  Removing from Kubernetes..."
	kubectl delete -f k8s/deployment-istio.yaml --ignore-not-found=true
	kubectl delete -f k8s/deployment.yaml --ignore-not-found=true
	kubectl delete -f k8s/service.yaml --ignore-not-found=true
	kubectl delete -f k8s/configmap.yaml --ignore-not-found=true
	@echo "✅ Undeployment complete"

# Run API tests
test:
	@echo "Testing API endpoints..."
	@echo ""
	@echo "1. Health check:"
	curl -s http://localhost:9090/actuator/health | jq .
	@echo ""
	@echo "2. Get all customers:"
	curl -s http://localhost:9090/api/customers | jq .
	@echo ""
	@echo "3. Create customer:"
	curl -s -X POST http://localhost:9090/api/customers \
		-H "Content-Type: application/json" \
		-d '{"name":"Test User","email":"test@example.com","tier":"GOLD"}' | jq .
	@echo ""
	@echo "✓ Tests complete"

# Tail logs from both containers
logs:
	@POD=$$(kubectl get pod -l app=customer-service -o jsonpath='{.items[0].metadata.name}'); \
	echo "Tailing logs from Pod: $$POD"; \
	kubectl logs -f $$POD --all-containers=true

# Tail logs from customer-service
logs-customer:
	@POD=$$(kubectl get pod -l app=customer-service -o jsonpath='{.items[0].metadata.name}'); \
	echo "Tailing logs from customer-service in Pod: $$POD"; \
	kubectl logs -f $$POD -c customer-service

# Tail logs from logging-sidecar
logs-sidecar:
	@POD=$$(kubectl get pod -l app=customer-service -o jsonpath='{.items[0].metadata.name}'); \
	echo "Tailing logs from logging-sidecar in Pod: $$POD"; \
	kubectl logs -f $$POD -c logging-sidecar

# Port forward to service
port-forward:
	@echo "Forwarding localhost:9090 to service..."
	@echo "Access API at: http://localhost:9090/api/customers"
	kubectl port-forward svc/customer-service 9090:80

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	cd customer-service && mvn clean
	@echo "✓ Clean complete"

# Setup minikube environment
minikube-setup:
	@echo "Setting up minikube environment..."
	@echo "Pointing Docker to minikube's Docker daemon..."
	@eval $$(minikube docker-env)
	@echo "✓ Run: eval \$$(minikube docker-env)"
	@echo "✓ Then run: make build-all"

# Show Pod status
status:
	@echo "Pod Status:"
	kubectl get pods -l app=customer-service
	@echo ""
	@echo "Service Status:"
	kubectl get svc customer-service
	@echo ""
	@echo "Endpoints:"
	kubectl get endpoints customer-service

# Describe Pod (useful for debugging)
describe:
	@POD=$$(kubectl get pod -l app=customer-service -o jsonpath='{.items[0].metadata.name}'); \
	kubectl describe pod $$POD

# Scale deployment
scale:
	@echo "Current replicas:"
	@kubectl get deployment customer-service -o jsonpath='{.spec.replicas}'
	@echo ""
	@read -p "Enter desired replicas: " REPLICAS; \
	kubectl scale deployment customer-service --replicas=$$REPLICAS
	@echo "✓ Scaled to $$REPLICAS replicas"

# Quick start (build + deploy + port-forward)
quickstart: build-all deploy port-forward

# Install Istio
install-istio:
	@echo "📦 Installing Istio..."
	@cd istio-1.28.1 && \
	export PATH=$$PWD/bin:$$PATH && \
	istioctl install --set profile=demo -y
	@echo "🏷️  Enabling Istio sidecar injection for default namespace..."
	kubectl label namespace default istio-injection=enabled --overwrite
	@echo "✅ Istio installed successfully"

# Install observability stack
install-observability:
	@echo "📊 Installing observability stack..."
	kubectl apply -f k8s/loki.yaml
	kubectl apply -f k8s/fluent-bit.yaml
	kubectl apply -f k8s/grafana-datasources.yaml
	kubectl apply -f k8s/istio-telemetry.yaml
	@echo "⏳ Waiting for components to be ready..."
	@sleep 10
	kubectl wait --for=condition=ready pod -l app=loki -n istio-system --timeout=120s || true
	kubectl wait --for=condition=ready pod -l app=fluent-bit -n istio-system --timeout=120s || true
	@echo "✅ Observability stack installed"

# Uninstall Istio
uninstall-istio:
	@echo "🗑️  Uninstalling Istio..."
	@cd istio-1.28.1 && \
	export PATH=$$PWD/bin:$$PATH && \
	istioctl uninstall --purge -y
	kubectl delete namespace istio-system --ignore-not-found=true
	@echo "✅ Istio uninstalled"

# Open all dashboards
dashboards:
	@echo "🌐 Opening observability dashboards..."
	@echo "Starting port-forwards in background..."
	@pkill -f "kubectl port-forward" || true
	@sleep 2
	@kubectl port-forward -n istio-system svc/grafana 3000:3000 > /dev/null 2>&1 &
	@kubectl port-forward -n istio-system svc/jaeger-query 16686:16686 > /dev/null 2>&1 &
	@kubectl port-forward -n istio-system svc/kiali 20001:20001 > /dev/null 2>&1 &
	@kubectl port-forward -n istio-system svc/prometheus 9090:9090 > /dev/null 2>&1 &
	@kubectl port-forward svc/customer-service 8080:80 > /dev/null 2>&1 &
	@sleep 3
	@echo "✅ Dashboards available at:"
	@echo "   Grafana:    http://localhost:3000 (admin/admin)"
	@echo "   Jaeger:     http://localhost:16686"
	@echo "   Kiali:      http://localhost:20001"
	@echo "   Prometheus: http://localhost:9090"
	@echo "   App:        http://localhost:8080"

# Generate test traffic
generate-traffic:
	@echo "🚦 Generating test traffic..."
	@for i in 1 2 3 4 5; do \
		curl -s -X POST http://localhost:8080/api/customers \
			-H "Content-Type: application/json" \
			-d "{\"name\":\"User $$i\",\"email\":\"user$$i@example.com\",\"tier\":\"GOLD\"}" && \
		echo " ✓ Created User $$i"; \
		sleep 1; \
	done
	@echo "✅ Test traffic generated"

# View logs in Grafana
logs-grafana:
	@echo "📊 Opening Grafana Explore..."
	@open "http://localhost:3000/explore?orgId=1&left=%7B%22datasource%22:%22loki%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22%7Bcontainer%3D%5C%22customer-service%5C%22%7D%20%7C%20json%20%7C%20line_format%20%5C%22%7B%7B.log%7D%7D%5C%22%22%7D%5D%7D"

# Start minikube
start:
	@echo "🚀 Starting minikube..."
	minikube start --cpus=4 --memory=8192 --disk-size=20g
	@echo "✅ Minikube started"

# Stop minikube (preserves state)
stop:
	@echo "🛑 Stopping minikube..."
	@pkill -f "kubectl port-forward" || true
	minikube stop
	@echo "✅ Minikube stopped (state preserved)"

# Restart minikube
restart: stop start
	@echo "✅ Minikube restarted"

# Delete minikube (clean slate)
delete:
	@echo "⚠️  Deleting minikube cluster..."
	@pkill -f "kubectl port-forward" || true
	minikube delete
	@echo "✅ Minikube deleted"

# Clean all (including Docker images)
clean-all: clean
	@echo "🧹 Cleaning Docker images..."
	@eval $$(minikube docker-env) && \
	docker rmi customer-service:1.0 customer-service:2.0 logging-sidecar:1.0 || true
	@echo "✅ All clean"

