package com.roomrental.modules.resident.application.service;

import com.roomrental.modules.resident.application.dto.ResidentViews;

import java.time.LocalDate;
import java.util.List;

/** Exposes package-private rules of the resident module to tests. */
public final class ResidentQueryServiceTestAccess {
    private ResidentQueryServiceTestAccess() {}

    public static String blockReason(String status, List<ResidentViews.ContractItem> contracts,
                                     ResidentViews.Summary summary) {
        return ResidentQueryService.deactivateBlockReason(status, contracts, summary);
    }

    public static String normalize(String status) {
        return ResidentQueryService.normalizeFilter(status);
    }

    public static long stay(LocalDate in, LocalDate out) {
        return ResidentQueryService.stayDays(in, out);
    }

    public static String mask(String idCard) {
        return ResidentService.mask(idCard);
    }
}
