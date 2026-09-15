package com.roomrental.modules.finance.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record PaymentConfigRegisterRequest(
    @NotBlank(message = "API Key không được để trống")
    String sePayApiKey,
    
    @NotBlank(message = "Số tài khoản không được để trống")
    String accountNumber,
    
    @NotBlank(message = "Tên ngân hàng không được để trống")
    String bankName
) {}
