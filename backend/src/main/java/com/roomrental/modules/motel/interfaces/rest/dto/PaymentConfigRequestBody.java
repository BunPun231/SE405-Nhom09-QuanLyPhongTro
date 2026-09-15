package com.roomrental.modules.motel.interfaces.rest.dto;

import jakarta.validation.constraints.NotBlank;

public record PaymentConfigRequestBody(
    @NotBlank(message = "Số tài khoản ngân hàng không được để trống")
    String accountNumber,

    @NotBlank(message = "Tên ngân hàng không được để trống")
    String bankName
) {}
