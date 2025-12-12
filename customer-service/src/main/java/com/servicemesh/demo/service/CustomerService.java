package com.servicemesh.demo.service;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import com.servicemesh.demo.model.Customer;

/**
 * Business logic for customer management
 *
 * SERVICE MESH VERSION:
 * - Uses standard SLF4J logging (stdout)
 * - No manual sidecar integration
 * - Envoy automatically captures logs, metrics, and traces
 * - Pure business logic with zero infrastructure concerns
 */
@Service
public class CustomerService {

    private static final Logger logger = LoggerFactory.getLogger(CustomerService.class);
    private final Map<String, Customer> customerStore = new ConcurrentHashMap<>();

    public CustomerService() {
        // Seed some data
        seedData();
    }

    private void seedData() {
        createCustomer(new Customer("1", "Alice Johnson", "alice@example.com", "GOLD"));
        createCustomer(new Customer("2", "Bob Smith", "bob@example.com", "SILVER"));
        createCustomer(new Customer("3", "Charlie Brown", "charlie@example.com", "BRONZE"));
    }

    public Customer createCustomer(Customer customer) {
        if (customer.getId() == null) {
            customer.setId(UUID.randomUUID().toString());
        }
        customerStore.put(customer.getId(), customer);

        // Simple stdout logging - Envoy captures this automatically
        logger.info("Customer created: id={}, name={}, tier={}",
                customer.getId(), customer.getName(), customer.getTier());

        return customer;
    }

    public Optional<Customer> getCustomer(String id) {
        Customer customer = customerStore.get(id);

        if (customer != null) {
            logger.info("Customer retrieved: id={}, name={}", id, customer.getName());
        } else {
            logger.warn("Customer not found: id={}", id);
        }

        return Optional.ofNullable(customer);
    }

    public Map<String, Customer> getAllCustomers() {
        logger.info("All customers retrieved: count={}", customerStore.size());
        return new HashMap<>(customerStore);
    }

    public void deleteCustomer(String id) {
        Customer removed = customerStore.remove(id);
        if (removed != null) {
            logger.info("Customer deleted: id={}, name={}", id, removed.getName());
        } else {
            logger.warn("Attempted to delete non-existent customer: id={}", id);
        }
    }
}
