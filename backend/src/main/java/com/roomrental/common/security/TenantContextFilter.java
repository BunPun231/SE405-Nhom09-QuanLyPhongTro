package com.roomrental.common.security;

import com.roomrental.common.config.AppProperties;
import com.roomrental.common.util.TenantContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class TenantContextFilter extends OncePerRequestFilter {

	private final AppProperties appProperties;

	public TenantContextFilter(AppProperties appProperties) {
		this.appProperties = appProperties;
	}

	@Override
	protected void doFilterInternal(
			HttpServletRequest request,
			HttpServletResponse response,
			FilterChain filterChain
	) throws ServletException, IOException {
		String tenantHeader = appProperties.tenant().headerName();
		String tenantId = request.getHeader(tenantHeader);

		if (tenantId != null && !tenantId.isBlank()) {
			TenantContext.setCurrentTenantId(tenantId);
		}

		try {
			filterChain.doFilter(request, response);
		} finally {
			TenantContext.clear();
		}
	}
}