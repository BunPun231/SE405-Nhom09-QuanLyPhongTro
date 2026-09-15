package com.roomrental.config;

import com.cloudinary.Cloudinary;
import com.roomrental.common.config.AppProperties;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class CloudinaryConfig {

    @Value("${app.cloudinary.cloud-name:test}")
    private String cloudName;

    @Value("${app.cloudinary.api-key:test}")
    private String apiKey;

    @Value("${app.cloudinary.api-secret:test}")
    private String apiSecret;

    @Bean
    public Cloudinary cloudinary() {
        Map<String, String> config = new HashMap<>();
        config.put("cloud_name", cloudName);
        config.put("api_key", apiKey);
        config.put("api_secret", apiSecret);
        return new Cloudinary(config);
    }
}
