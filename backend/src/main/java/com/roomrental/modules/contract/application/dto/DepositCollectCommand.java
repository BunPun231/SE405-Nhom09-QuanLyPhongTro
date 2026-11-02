package com.roomrental.modules.contract.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * UC69: Ghi nhan thu tien coc (so tien, ngay thu thuc te, phuong thuc).
 * Tat ca truong deu tuy chon de tuong thich client cu (goi khong body).
 */
public record DepositCollectCommand(
        BigDecimal amount,
        LocalDate collectedDate,
        String paymentMethod,
        String note
) {
    public static DepositCollectCommand empty() {
        return new DepositCollectCommand(null, null, null, null);
    }
}
