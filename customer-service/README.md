# Customer Service

## Overview

A Spring Boot REST service that demonstrates the **Sidecar Pattern** for logging.

This is a **business application** - it focuses solely on customer management logic and delegates cross-cutting concerns (logging infrastructure) to a separate sidecar container.

## Architecture Decision

### What This Service Does
- ✅ Exposes REST API for customer CRUD operations
- ✅ Sends structured log events to sidecar via HTTP
- ✅ Focuses on business logic only

### What This Service Does NOT Do
- ❌ Does NOT implement log aggregation
- ❌ Does NOT know where logs are stored
- ❌ Does NOT contain logging infrastructure code

### Why This Matters

**Before Sidecar Pattern:**
```java
// Every service needs this
LogstashAppender appender = new LogstashAppender();
appender.setHost("logstash.prod.company.com");
appender.setPort(5000);
// ... 50 more lines of config
```

**With Sidecar Pattern:**
```java
// Just send to localhost - sidecar handles the rest
restTemplate.postForEntity("http://localhost:8080/logs", event, String.class);
```

**With Service Mesh (Istio + Envoy):**
```java
// Just write to stdout - Envoy captures everything
System.out.println(jsonLog);
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/customers` | List all customers |
| GET | `/api/customers/{id}` | Get customer by ID |
| POST | `/api/customers` | Create new customer |
| DELETE | `/api/customers/{id}` | Delete customer |
| GET | `/actuator/health` | Health check |

## Configuration

See `application.yml`:

```yaml
sidecar:
  logging:
    url: http://localhost:8080/logs  # Sidecar endpoint
    enabled: true
```

**Key Point:** The URL is `localhost` because the sidecar runs in the **same Pod** as this service. They share the network namespace.

## Building

```bash
# Build JAR
mvn clean package

# Build Docker image
docker build -t customer-service:1.0 .
```

## Running Locally (Without Sidecar)

```bash
mvn spring-boot:run
```

Logs will fail to send to sidecar (expected), but the service will still work.

## Running in Kubernetes (With Sidecar)

See `../k8s/deployment.yaml` - the sidecar is deployed in the same Pod.

## Coupling Analysis

### Removed Coupling ✅
- Language-specific logging libraries
- Direct connection to log aggregation systems
- Knowledge of log storage location

### Remaining Coupling ❌
- Must explicitly call sidecar HTTP endpoint
- Must know sidecar exists at localhost:8080
- Must handle sidecar failures

### Service Mesh Evolution 🚀
In Istio + Envoy, even this remaining coupling is removed:
- App writes to stdout
- Envoy intercepts ALL traffic automatically
- No code changes needed for observability

