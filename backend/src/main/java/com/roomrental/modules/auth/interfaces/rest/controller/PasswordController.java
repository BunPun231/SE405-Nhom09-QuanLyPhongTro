package com.roomrental.modules.auth.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.auth.application.dto.ChangePasswordCommand;
import com.roomrental.modules.auth.application.dto.ForgotPasswordCommand;
import com.roomrental.modules.auth.application.dto.ResetPasswordCommand;
import com.roomrental.modules.auth.application.service.AuthService;
import com.roomrental.modules.auth.interfaces.rest.dto.ChangePasswordRequest;
import com.roomrental.modules.auth.interfaces.rest.dto.ForgotPasswordRequest;
import com.roomrental.modules.auth.interfaces.rest.dto.ResetPasswordRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Password Management", description = "Endpoints for password management")
@RequiredArgsConstructor
public class PasswordController {

    private final AuthService authService;

    @PostMapping("/forgot-password")
    @Operation(summary = "Forgot password (UC06)")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest body) {
        authService.forgotPassword(new ForgotPasswordCommand(body.identity()));
        return ResponseEntity.ok(ApiResponse.ok(null, "OTP sent to your email/phone"));
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Reset password with OTP (UC06)")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@Valid @RequestBody ResetPasswordRequest body) {
        authService.resetPassword(new ResetPasswordCommand(
                body.identity(),
                body.otp(),
                body.newPassword(),
                body.confirmPassword()
        ));
        return ResponseEntity.ok(ApiResponse.ok(null, "Password reset successfully"));
    }

    @PostMapping("/change-password")
    @Operation(summary = "Change password (UC05)")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<ApiResponse<Void>> changePassword(@Valid @RequestBody ChangePasswordRequest body) {
        UUID userId = SecurityUtils.getCurrentUserId();
        authService.changePassword(userId, new ChangePasswordCommand(
                body.oldPassword(),
                body.newPassword(),
                body.confirmPassword()
        ));
        return ResponseEntity.ok(ApiResponse.ok(null, "Password changed successfully"));
    }
}
