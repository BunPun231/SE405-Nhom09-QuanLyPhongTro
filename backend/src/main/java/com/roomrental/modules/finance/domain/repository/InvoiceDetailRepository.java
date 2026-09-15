package com.roomrental.modules.finance.domain.repository;

import com.roomrental.modules.finance.domain.model.InvoiceDetail;

import java.util.List;

public interface InvoiceDetailRepository {
    InvoiceDetail save(InvoiceDetail detail);
    List<InvoiceDetail> saveAll(List<InvoiceDetail> details);
    List<InvoiceDetail> findByInvoiceId(Long invoiceId);
    void deleteByInvoiceId(Long invoiceId);
}
