# 🚀 Service Mesh Demo: Complete E2E Observability Stack

A **production-grade**, learning-focused repository demonstrating the evolution from **manual Sidecar Pattern** to **Service Mesh** with complete observability using **Istio, Grafana, Loki, Prometheus, and Jaeger**.

## ✅ What's Deployed and Working

This repository contains a **fully functional observability stack** that you can run locally:

| Component            | Status           | Purpose                                      |
| -------------------- | ---------------- | -------------------------------------------- |
| **Istio 1.28.1**     | ✅ Running       | Service mesh control plane                   |
| **Envoy Proxy**      | ✅ Auto-injected | Universal sidecar (replaces manual sidecars) |
| **Customer Service** | ✅ Running       | Spring Boot REST API (Java 24)               |
| **Grafana**          | ✅ Running       | Unified visualization dashboard              |
| **Loki**             | ✅ Running       | Log aggregation (like Elasticsearch in ELK)  |
| **Fluent Bit**       | ✅ Running       | Log shipping (like Logstash/Filebeat in ELK) |
| **Prometheus**       | ✅ Running       | Metrics collection and storage               |
| **Jaeger**           | ✅ Running       | Distributed tracing                          |
| **Kiali**            | ✅ Running       | Service mesh visualization                   |

---

## 🎯 Learning Journey

This repository takes you through **3 phases** of evolution:

### Phase 1: Manual Sidecar Pattern (Learning)

- ✅ Custom Python logging sidecar
- ✅ Manual integration with Spring Boot
- ✅ Understanding the fundamentals

### Phase 2: Service Mesh Migration (Production)

- ✅ Istio installation and configuration
- ✅ Automatic Envoy sidecar injection
- ✅ Simplified application code

### Phase 3: Complete Observability (Enterprise)

- ✅ Logs: Fluent Bit → Loki → Grafana
- ✅ Metrics: Prometheus → Grafana
- ✅ Traces: Jaeger → Grafana
- ✅ Visualization: Kiali for service mesh topology

---

## 📊 Complete Observability Stack - Detailed Sequence Flow

### 🔍 Comparison: ELK Stack vs. PLG Stack (This Repo)

If you've worked with **ELK Stack**, here's how this compares:

| ELK Stack                   | PLG Stack (This Repo) | Purpose                                  |
| --------------------------- | --------------------- | ---------------------------------------- |
| **Elasticsearch**           | **Loki**              | Log storage and indexing                 |
| **Logstash** / **Filebeat** | **Fluent Bit**        | Log collection and shipping              |
| **Kibana**                  | **Grafana**           | Visualization and querying               |
| ❌ No equivalent            | **Prometheus**        | Metrics storage (separate from logs)     |
| ❌ No equivalent            | **Jaeger**            | Distributed tracing                      |
| ❌ No equivalent            | **Istio + Envoy**     | Service mesh (automatic instrumentation) |

**Key Differences:**

| Aspect              | ELK Stack                     | PLG + Service Mesh                 |
| ------------------- | ----------------------------- | ---------------------------------- |
| **Log Indexing**    | Full-text indexing (heavy)    | Label-based indexing (lightweight) |
| **Query Language**  | Lucene / KQL                  | LogQL (like PromQL)                |
| **Resource Usage**  | High (Elasticsearch is heavy) | Low (Loki is lightweight)          |
| **Metrics**         | Separate tool (Metricbeat)    | Integrated (Prometheus)            |
| **Tracing**         | Separate tool (APM)           | Integrated (Jaeger)                |
| **Instrumentation** | Manual (agents in app)        | Automatic (Envoy sidecar)          |
| **Cost**            | High (storage + compute)      | Low (efficient storage)            |

---

## 🔄 Complete Data Flow - Step by Step

### 1️⃣ **Application Generates Logs**

```java
// In CustomerService.java
logger.info("Customer created: id={}, name={}, tier={}",
    customer.getId(), customer.getName(), customer.getTier());
```

**Output to stdout:**

```
2025-12-12 09:03:00 - Customer created: id=090b926e..., name=Test User 5, tier=GOLD
```

---

### 2️⃣ **Kubernetes Captures Logs**

Kubernetes automatically captures stdout/stderr from all containers and writes them to:

```
/var/log/containers/<pod-name>_<namespace>_<container-name>-<container-id>.log
```

**Example:**

```
/var/log/containers/customer-service-845fc9d6b6-v4pkt_default_customer-service-daaf10160e279f8f.log
```

**Format:** JSON (CRI - Container Runtime Interface)

```json
{
  "log": "2025-12-12 09:03:00 - Customer created: id=090b926e..., name=Test User 5, tier=GOLD\n",
  "stream": "stdout",
  "time": "2025-12-12T09:03:00.633184338Z"
}
```

---

### 3️⃣ **Fluent Bit Collects Logs** (Like Logstash/Filebeat in ELK)

**What is Fluent Bit?**

- Lightweight log processor and forwarder (written in C)
- Runs as a **DaemonSet** (one pod per Kubernetes node)
- Reads log files from `/var/log/containers/`
- Enriches logs with Kubernetes metadata
- Forwards to Loki

**Fluent Bit Process:**

1. **Tail** log files (watches for new lines)
2. **Parse** JSON (CRI format)
3. **Filter** with Kubernetes metadata:
   - Pod name
   - Namespace
   - Container name
   - Labels (app, version, etc.)
4. **Output** to Loki via HTTP

**Enriched Log:**

```json
{
  "log": "2025-12-12 09:03:00 - Customer created: id=090b926e..., name=Test User 5, tier=GOLD\n",
  "stream": "stdout",
  "time": "2025-12-12T09:03:00.633184338Z",
  "kubernetes": {
    "pod_name": "customer-service-845fc9d6b6-v4pkt",
    "namespace_name": "default",
    "container_name": "customer-service",
    "labels": {
      "app": "customer-service",
      "version": "v2"
    }
  }
}
```

**ELK Equivalent:**

- **Filebeat** (lightweight) or **Logstash** (heavy) would do the same
- Filebeat reads logs → enriches → sends to Elasticsearch
- Logstash can do more complex transformations

---

### 4️⃣ **Loki Stores Logs** (Like Elasticsearch in ELK)

**What is Loki?**

- Log aggregation system designed by Grafana Labs
- **Does NOT index log content** (unlike Elasticsearch)
- Only indexes **labels** (metadata)
- Stores log content as compressed chunks

**How Loki Works:**

1. Receives logs from Fluent Bit via HTTP (port 3100)
2. Extracts labels: `{namespace="default", container="customer-service", app="customer-service"}`
3. Stores log content in chunks (compressed)
4. Creates index for labels only

**Storage Structure:**

```
Index (labels):
  {namespace="default", container="customer-service"} → Chunk ID: 12345

Chunks (compressed log content):
  Chunk 12345: [log1, log2, log3, ...]
```

**ELK Equivalent:**

- **Elasticsearch** indexes EVERYTHING (full-text search)
- Loki only indexes labels (much lighter)
- Elasticsearch: "Find all logs containing 'error'" (fast)
- Loki: "Find all logs from {app='customer-service'} containing 'error'" (fast for label filter, slower for text search)

**Why Loki is Lighter:**

- Elasticsearch: 1GB logs → 3-5GB storage (with indexes)
- Loki: 1GB logs → 1.2GB storage (compressed, minimal index)

---

### 5️⃣ **Grafana Queries and Visualizes** (Like Kibana in ELK)

**What is Grafana?**

- Unified visualization platform
- Supports multiple data sources (Loki, Prometheus, Jaeger, etc.)
- Uses **LogQL** to query Loki (similar to PromQL)

**Query Example:**

```logql
{container="customer-service"} | json | line_format "{{.log}}"
```

**Breakdown:**

1. `{container="customer-service"}` - Filter by label (fast, uses index)
2. `| json` - Parse JSON structure
3. `| line_format "{{.log}}"` - Extract just the log field

**Output in Grafana:**

```
2025-12-12 09:03:00 - Customer created: id=090b926e..., name=Test User 5, tier=GOLD
```

**ELK Equivalent:**

- **Kibana** queries Elasticsearch using KQL or Lucene
- Example: `kubernetes.container_name:"customer-service" AND message:"Customer created"`

### 6️⃣ **Prometheus Collects Metrics** (No Direct ELK Equivalent)

**What is Prometheus?**

- Time-series database for metrics (not logs)
- Scrapes metrics from applications via HTTP endpoints
- Stores metrics with labels (similar to Loki's approach)

**How Prometheus Works:**

1. **Scrapes** metrics from `/actuator/prometheus` endpoint (Spring Boot)
2. **Scrapes** metrics from Envoy sidecar (automatic)
3. **Stores** time-series data with labels
4. **Queries** using PromQL

**Example Metrics:**

```
http_requests_total{method="POST", endpoint="/api/customers", status="200"} 42
http_request_duration_seconds{method="POST", endpoint="/api/customers"} 0.123
```

**ELK Equivalent:**

- **Metricbeat** collects metrics → sends to Elasticsearch
- But Elasticsearch is not optimized for time-series data
- Prometheus is purpose-built for metrics

**Why Separate Metrics from Logs?**

- Logs: High cardinality, text-based, event-driven
- Metrics: Low cardinality, numeric, time-series
- Different storage and query patterns

---

### 7️⃣ **Jaeger Collects Distributed Traces** (Like Elastic APM)

**What is Jaeger?**

- Distributed tracing system (created by Uber)
- Tracks requests across multiple services
- Shows latency, dependencies, and errors

**How Jaeger Works with Istio:**

1. **Envoy sidecar** automatically generates trace spans
2. **Trace context** propagated via HTTP headers (e.g., `x-b3-traceid`)
3. **Spans** sent to Jaeger collector
4. **Jaeger UI** visualizes the trace

**Example Trace:**

```
Request: POST /api/customers
├─ Span 1: Envoy ingress (5ms)
├─ Span 2: customer-service.createCustomer() (120ms)
│  ├─ Span 3: Database insert (80ms)
│  └─ Span 4: Cache update (15ms)
└─ Span 5: Envoy egress (3ms)
Total: 128ms
```

**ELK Equivalent:**

- **Elastic APM** does distributed tracing
- Requires manual instrumentation (agents in app)
- Istio + Jaeger: **Automatic** (no code changes)

**Key Benefit:**

- See exactly where time is spent in a request
- Identify slow services or database queries
- Debug microservice interactions

---

### 8️⃣ **Envoy Proxy - The Universal Sidecar** (No ELK Equivalent)

**What is Envoy?**

- High-performance proxy written in C++
- Created by Lyft, now part of CNCF
- Automatically injected by Istio into every pod

**What Envoy Does:**

1. **Intercepts all traffic** (inbound and outbound) via iptables
2. **Generates access logs** (like nginx/Apache logs)
3. **Collects metrics** (request count, latency, errors)
4. **Generates trace spans** (for Jaeger)
5. **Enforces policies** (retries, timeouts, circuit breakers)
6. **Provides mTLS** (automatic encryption between services)

**Envoy Access Log Example:**

```
[2025-12-12T09:03:00.633Z] "POST /api/customers HTTP/1.1" 200 - via_upstream - "-" 0 156 125 124 "-" "curl/7.64.1" "090b926e-1ac8-4388-a121-098b39316112" "customer-service:80" "127.0.0.1:9090" inbound|9090|| 127.0.0.6:45678 10.244.0.5:9090 10.244.0.1:54321 outbound_.80_._.customer-service.default.svc.cluster.local default
```

**Breakdown:**

- `POST /api/customers HTTP/1.1` - Request method and path
- `200` - Response status code
- `125` - Total duration (ms)
- `124` - Upstream duration (ms)
- `090b926e-...` - Trace ID (links to Jaeger)

**ELK Equivalent:**

- **No direct equivalent** - you'd need to manually configure nginx/Apache logs
- Envoy does this **automatically** for every service

**Why Envoy is Powerful:**

- **Zero code changes** - app doesn't know Envoy exists
- **Automatic observability** - logs, metrics, traces for free
- **Consistent** - same sidecar for all services (Java, Python, Go, etc.)

---

### 9️⃣ **Istio Control Plane** (No ELK Equivalent)

**What is Istio?**

- Service mesh control plane
- Manages and configures all Envoy sidecars
- Provides centralized policy and configuration

**Istio Components:**

1. **Istiod** - Control plane (combines Pilot, Citadel, Galley)
   - Service discovery
   - Configuration distribution
   - Certificate management (mTLS)

**How Istio Works:**

1. **Mutating Webhook** - Automatically injects Envoy sidecar into pods
2. **Configuration** - Pushes config to all Envoy sidecars
3. **Telemetry** - Configures what logs/metrics/traces to collect
4. **Security** - Manages mTLS certificates

**Example: Automatic Sidecar Injection**

```yaml
# You deploy this:
apiVersion: apps/v1
kind: Deployment
metadata:
  name: customer-service
spec:
  template:
    spec:
      containers:
        - name: customer-service
          image: customer-service:2.0
# Istio automatically injects Envoy:
# Pod now has 2 containers: customer-service + istio-proxy
```

**ELK Equivalent:**

- **No equivalent** - ELK is just for observability
- Istio is a **service mesh** - handles traffic, security, observability

---

### 🔟 **Kiali - Service Mesh Visualization** (No ELK Equivalent)

**What is Kiali?**

- Web UI for Istio service mesh
- Shows service topology, traffic flow, health

**What You Can See:**

1. **Service Graph** - Visual map of all services and their connections
2. **Traffic Flow** - Request rates, success rates, latency
3. **Configuration** - Istio resources (VirtualServices, DestinationRules)
4. **Traces** - Integration with Jaeger

**Example View:**

```
customer-service (v2)
  ↓ 100 req/s (99.5% success)
database-service
  ↓ 50 req/s (100% success)
cache-service
```

**ELK Equivalent:**

- **No equivalent** - Kibana shows logs, not service topology
- Kiali is specific to service mesh

---



---

## 🚀 Quick Start - Access Your Observability Stack

### ✅ Everything is Already Running!

If you've followed the setup, all components are deployed. Here's how to access them:

### 1️⃣ **View Logs in Grafana** (Recommended Start)

```bash
# Port forward Grafana (if not already running)
kubectl port-forward -n istio-system svc/grafana 3000:3000
```

**Open:** http://localhost:3000
**Login:** `admin` / `admin`

**Query logs:**

1. Go to **Explore** (compass icon 🧭)
2. Select **Loki** data source
3. Query: `{container="customer-service"} | json | line_format "{{.log}}"`
4. See clean logs! 🎉

**📖 Detailed Guide:** [`docs/QUICK_START.md`](docs/QUICK_START.md)

---

### 2️⃣ **View Distributed Traces in Jaeger**

```bash
kubectl port-forward -n istio-system svc/tracing 16686:80
```

**Open:** http://localhost:16686

**What to do:**

1. Select **customer-service** from the Service dropdown
2. Click **Find Traces**
3. Click on a trace to see the timeline
4. See request flow and latency breakdown

---

### 3️⃣ **View Service Mesh Topology in Kiali**

```bash
kubectl port-forward -n istio-system svc/kiali 20001:20001
```

**Open:** http://localhost:20001

**What to do:**

1. Go to **Graph** (left sidebar)
2. Select **default** namespace
3. See service topology and traffic flow
4. Click on services to see details

---

### 4️⃣ **View Metrics in Prometheus**

```bash
kubectl port-forward -n istio-system svc/prometheus 9090:9090
```

**Open:** http://localhost:9090

**Example queries:**

- `istio_requests_total{destination_service="customer-service.default.svc.cluster.local"}`
- `rate(istio_requests_total[5m])`

---

### 5️⃣ **Generate Test Traffic**

```bash
# Port forward to customer-service
kubectl port-forward svc/customer-service 8080:80

# Create customers
for i in {1..10}; do
  curl -X POST http://localhost:8080/api/customers \
    -H "Content-Type: application/json" \
    -d "{\"name\": \"User $i\", \"email\": \"user$i@example.com\", \"tier\": \"GOLD\"}"
  echo ""
  sleep 1
done

# Get all customers
curl http://localhost:8080/api/customers | jq
```

**Then refresh Grafana/Jaeger/Kiali to see the new data!**

---

## 🛠️ Setup from Scratch (If Starting Fresh)

### Prerequisites

- Docker
- Kubernetes cluster (minikube recommended)
- kubectl
- **Java 24** and Maven
- Istio CLI (`istioctl`)


**Quick summary:**

1. Install Istio
2. Build and deploy customer-service
3. Deploy observability stack (Loki, Fluent Bit, Grafana, Prometheus, Jaeger)
4. Access dashboards

---

---

## 🎓 Key Concepts Summary

### 📊 Observability Stack (PLG)

| Component      | Role                               | ELK Equivalent             |
| -------------- | ---------------------------------- | -------------------------- |
| **Loki**       | Log storage (label-based indexing) | Elasticsearch              |
| **Fluent Bit** | Log collection and shipping        | Logstash/Filebeat          |
| **Grafana**    | Unified visualization              | Kibana                     |
| **Prometheus** | Metrics storage                    | Metricbeat → Elasticsearch |
| **Jaeger**     | Distributed tracing                | Elastic APM                |

### 🔄 Service Mesh Components

| Component | Role                                   |
| --------- | -------------------------------------- |
| **Istio** | Control plane (manages Envoy sidecars) |
| **Envoy** | Data plane (universal sidecar proxy)   |
| **Kiali** | Service mesh visualization             |

### 🎯 Key Benefits Over ELK

1. **Lighter Weight:** Loki uses 60-70% less storage than Elasticsearch
2. **Automatic Instrumentation:** Envoy provides logs/metrics/traces with zero code changes
3. **Unified Platform:** Grafana shows logs, metrics, and traces in one place
4. **Cloud-Native:** Built for Kubernetes from the ground up
5. **Lower Cost:** Reduced infrastructure and operational costs

---

## 🚀 What You've Learned

### Phase 1: Manual Sidecar Pattern ✅

- Built a custom logging sidecar in Python
- Integrated with Spring Boot via HTTP
- Understood the fundamentals of sidecar pattern
- Learned what coupling remains

### Phase 2: Service Mesh Migration ✅

- Installed Istio service mesh
- Automatic Envoy sidecar injection
- Simplified application code (removed manual sidecar integration)
- Zero-code observability

### Phase 3: Complete Observability ✅

- **Logs:** Fluent Bit → Loki → Grafana
- **Metrics:** Prometheus → Grafana
- **Traces:** Jaeger → Grafana
- **Topology:** Kiali for service mesh visualization

### Real-World Skills ✅

- Production-grade observability stack
- Same tools used by Netflix, Uber, Google, Lyft
- Understanding of ELK vs PLG tradeoffs
- Service mesh architecture and benefits

---

## 🎯 Next Steps

### 1. Explore the Dashboards

- **Grafana:** Query logs with LogQL, create custom dashboards
- **Jaeger:** Analyze distributed traces, find slow requests
- **Kiali:** Visualize service topology, traffic flow
- **Prometheus:** Query metrics with PromQL

### 2. Add More Services

- Deploy additional microservices
- See automatic sidecar injection
- Observe service-to-service communication
- Test mTLS encryption

### 3. Advanced Istio Features

- Traffic management (canary deployments, A/B testing)
- Fault injection (chaos engineering)
- Circuit breakers and retries
- Rate limiting and quotas

### 4. Production Considerations

- Persistent storage for Loki/Prometheus
- High availability for Istio control plane
- Resource limits and autoscaling
- Security policies and RBAC

---

## 📖 External Resources

- [Istio Documentation](https://istio.io/latest/docs/)
- [Envoy Proxy Documentation](https://www.envoyproxy.io/docs)
- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)
- [Fluent Bit Documentation](https://docs.fluentbit.io/)

---

