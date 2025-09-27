package com.gershonrocks.eks_products.controller;

import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/products")
public class ProductController {
    
    private static final Map<String, BigDecimal> products = new HashMap<>();
    
    static {
        products.put("PROD-001", new BigDecimal("999.99"));
        products.put("PROD-002", new BigDecimal("29.99"));
        products.put("PROD-003", new BigDecimal("79.99"));
        products.put("PROD-004", new BigDecimal("349.99"));
        products.put("PROD-005", new BigDecimal("149.99"));
    }
    
    @GetMapping("/{productId}/price")
    public Map<String, Object> getPrice(@PathVariable String productId) {
        Map<String, Object> response = new HashMap<>();
        response.put("productId", productId);
        response.put("price", products.getOrDefault(productId, new BigDecimal("0.00")));
        return response;
    }
    
    @GetMapping("/test")
    public String test() {
        return "Controller is working!";
    }
}
