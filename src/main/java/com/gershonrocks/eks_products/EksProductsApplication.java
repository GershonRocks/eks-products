package com.gershonrocks.eks_products;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class EksProductsApplication {
    public static void main(String[] args) {
        SpringApplication.run(EksProductsApplication.class, args);
    }
}
