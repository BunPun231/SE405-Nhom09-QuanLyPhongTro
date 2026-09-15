package com.roomrental.common.event;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

/**
 * Synchronous listener that intercepts all LoggableEvent instances published by Business Services.
 * Captures IP address and User-Agent from the current HTTP request (on the main thread)
 * and re-publishes as an EnrichedLogEvent for async processing by downstream listeners.
 */
@Component
public class DomainEventPublisher {

    private final ApplicationEventPublisher publisher;

    public DomainEventPublisher(ApplicationEventPublisher publisher) {
        this.publisher = publisher;
    }

    /**
     * Intercepts any LoggableEvent, enriches it with request metadata,
     * then publishes the enriched event for async listeners.
     */
    @EventListener
    public void onLoggableEvent(LoggableEvent event) {
        String ip = extractIpAddress();
        String ua = extractUserAgent();
        publisher.publishEvent(new EnrichedLogEvent(event, ip, ua));
    }

    private String extractIpAddress() {
        try {
            ServletRequestAttributes attrs =
                    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs == null) return null;
            HttpServletRequest request = attrs.getRequest();
            String forwarded = request.getHeader("X-Forwarded-For");
            if (forwarded != null && !forwarded.isBlank()) {
                return forwarded.split(",")[0].trim();
            }
            return request.getRemoteAddr();
        } catch (Exception e) {
            return null;
        }
    }

    private String extractUserAgent() {
        try {
            ServletRequestAttributes attrs =
                    (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attrs == null) return null;
            return attrs.getRequest().getHeader("User-Agent");
        } catch (Exception e) {
            return null;
        }
    }
}
