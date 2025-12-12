package com.servicemesh.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Customer Service - Business Application
 * 
 * This is a simple REST service that demonstrates the Sidecar Pattern.
 * 
 * Key Design Principles:
 * 1. This service focuses ONLY on business logic (customer management)
 * 2. Cross-cutting concerns (logging infrastructure) are delegated to the sidecar
 * 3. The service is unaware of WHERE logs go - it just sends them to localhost:8080
 * 4. This decoupling allows the logging infrastructure to evolve independently
 * 
 * In a Service Mesh (Istio + Envoy):
 * - This app wouldn't even know about the sidecar
 * - Envoy would intercept ALL traffic transparently
 * - Logs, metrics, traces would be collected automatically
 * - No code changes needed to add observability
 */
@SpringBootApplication
public class CustomerServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CustomerServiceApplication.class, args);
    }
}

