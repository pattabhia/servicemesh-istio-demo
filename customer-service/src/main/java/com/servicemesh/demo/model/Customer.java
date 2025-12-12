package com.servicemesh.demo.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Customer domain model
 * Pure business entity - no infrastructure concerns
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Customer {
    private String id;
    private String name;
    private String email;
    private String tier; // BRONZE, SILVER, GOLD
}

