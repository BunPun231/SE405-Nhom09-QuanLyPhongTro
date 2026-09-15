package com.roomrental.modules.contract.application.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Command DTO cho tạo/cập nhật hợp đồng.
 */
public record ContractCreateCommand(
        Long roomId,
        String primaryResidentUserId,
        String primaryResidentPhone,
        String primaryResidentFullName,
        String primaryResidentEmail,
        String primaryResidentIdCardNumber,
        String primaryResidentIdCardFrontUrl,
        String primaryResidentIdCardBackUrl,
        BigDecimal rentPrice,
        LocalDate startDate,
        LocalDate endDate,
        BigDecimal depositAmount,
        String depositStatus,
        LocalDate billingDate,
        Integer billingCycleDay,
        Integer paymentCycleMonths,
        List<String> residentUserIds,
        List<ContractServiceItemCommand> serviceItems
) {
}
