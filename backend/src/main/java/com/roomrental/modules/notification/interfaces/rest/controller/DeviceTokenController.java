package com.roomrental.modules.notification.interfaces.rest.controller;

import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.notification.domain.model.DeviceToken;
import com.roomrental.modules.notification.domain.repository.DeviceTokenRepository;
import com.roomrental.modules.notification.interfaces.rest.dto.DeviceTokenRegisterRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/device-tokens")
@Tag(name = "Notification - Device Tokens", description = "Đăng ký FCM tokens cho thiết bị")
@SecurityRequirement(name = "bearerAuth")
public class DeviceTokenController {


    private final DeviceTokenRepository tokenRepository;

    public DeviceTokenController(DeviceTokenRepository tokenRepository) {
        this.tokenRepository = tokenRepository;
    }

    @PostMapping
    @Operation(summary = "Đăng ký thiết bị nhận thông báo push (FCM Token)")
    public ResponseEntity<Void> registerToken(@RequestBody @Valid DeviceTokenRegisterRequest request) {
        UUID userId = SecurityUtils.getCurrentUserId();
        Optional<DeviceToken> existingOpt = tokenRepository.findByToken(request.token());

        if (existingOpt.isPresent()) {
            DeviceToken existing = existingOpt.get();
            if (!existing.getUserId().equals(userId)) {
                existing.setUserId(userId);
                existing.setUpdatedAt(OffsetDateTime.now());
                tokenRepository.save(existing);
            }
        } else {
            DeviceToken deviceToken = new DeviceToken(userId, request.token());
            tokenRepository.save(deviceToken);
        }
        return ResponseEntity.ok().build();
    }

    @DeleteMapping
    @Operation(summary = "Hủy đăng ký thiết bị nhận thông báo push")
    public ResponseEntity<Void> unregisterToken(@RequestParam("token") String token) {
        tokenRepository.deleteByToken(token);
        return ResponseEntity.noContent().build();
    }
}
