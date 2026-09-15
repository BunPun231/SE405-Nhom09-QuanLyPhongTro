package com.roomrental.modules.auth.interfaces.rest.controller;

import com.roomrental.common.dto.ApiResponse;
import com.roomrental.modules.auth.application.dto.AuthResult;
import com.roomrental.modules.auth.application.dto.LoginCommand;
import com.roomrental.modules.auth.application.dto.RegisterCommand;
import com.roomrental.modules.auth.application.service.AuthService;
import com.roomrental.modules.auth.interfaces.rest.dto.LoginRequest;
import com.roomrental.modules.auth.interfaces.rest.dto.RegisterRequest;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public authentication endpoints (no JWT required).
 */
@RestController
@RequestMapping("/api/public/auth")
@Tag(name = "Authentication", description = "Registration and login endpoints")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    @Operation(summary = "Register new Manager (UC01)")
    public ResponseEntity<ApiResponse<AuthResult>> register(@Valid @RequestBody RegisterRequest body) {
        AuthResult result = authService.registerManager(new RegisterCommand(
                body.tenantName(),
                body.fullName(),
                body.phone(),
                body.email(),
                body.password()
        ));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(result, "Registration successful"));
    }

    @PostMapping("/login")
    @Operation(summary = "Login by phone/email (UC02)")
    public ResponseEntity<ApiResponse<AuthResult>> login(@Valid @RequestBody LoginRequest body) {
        AuthResult result = authService.login(new LoginCommand(
                body.identity(),
                body.password()
        ));
        return ResponseEntity.ok(ApiResponse.ok(result, "Login successful"));
    }

    @PostMapping("/refresh")
    @Operation(summary = "Refresh access token")
    public ResponseEntity<ApiResponse<AuthResult>> refresh(@Valid @RequestBody com.roomrental.modules.auth.interfaces.rest.dto.RefreshTokenRequest body) {
        AuthResult result = authService.refreshToken(body.refreshToken());
        return ResponseEntity.ok(ApiResponse.ok(result, "Token refreshed successfully"));
    }
}
