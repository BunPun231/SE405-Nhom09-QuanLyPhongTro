package com.roomrental.modules.auth.application.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.roomrental.common.exception.BaseException;
import com.roomrental.modules.auth.application.dto.WorkspaceConfigDto;
import com.roomrental.modules.auth.domain.model.Tenant;
import com.roomrental.modules.auth.domain.repository.TenantRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class WorkspaceService {

    private final TenantRepository tenantRepository;
    private final ObjectMapper objectMapper;

    public WorkspaceService(TenantRepository tenantRepository, ObjectMapper objectMapper) {
        this.tenantRepository = tenantRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional(readOnly = true)
    public WorkspaceConfigDto getWorkspaceConfig(UUID tenantId) {
        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> BaseException.notFound("Tenant", tenantId));

        String rawConfig = tenant.getWorkspaceConfig();
        if (rawConfig == null || rawConfig.isBlank()) {
            return getDefaultConfig();
        }

        try {
            return objectMapper.readValue(rawConfig, WorkspaceConfigDto.class);
        } catch (Exception e) {
            return getDefaultConfig();
        }
    }

    @Transactional
    public WorkspaceConfigDto updateWorkspaceConfig(UUID tenantId, WorkspaceConfigDto request) {
        Tenant tenant = tenantRepository.findById(tenantId)
                .orElseThrow(() -> BaseException.notFound("Tenant", tenantId));

        Map<String, Boolean> mergedModules = new HashMap<>(getDefaultConfig().modules());
        if (request != null && request.modules() != null) {
            mergedModules.putAll(request.modules());
        }

        WorkspaceConfigDto updatedConfig = new WorkspaceConfigDto(mergedModules);

        try {
            String jsonConfig = objectMapper.writeValueAsString(updatedConfig);
            tenant.setWorkspaceConfig(jsonConfig);
            tenantRepository.save(tenant);
        } catch (Exception e) {
            throw new BaseException(HttpStatus.BAD_REQUEST, "INVALID_CONFIG", "Failed to process workspace configuration");
        }


        return updatedConfig;
    }

    public WorkspaceConfigDto getDefaultConfig() {
        Map<String, Boolean> defaultModules = Map.of(
                "motel", true,
                "contract", true,
                "resident", true,
                "finance", true,
                "service", true,
                "technician", true,
                "report", true
        );
        return new WorkspaceConfigDto(defaultModules);
    }
}
