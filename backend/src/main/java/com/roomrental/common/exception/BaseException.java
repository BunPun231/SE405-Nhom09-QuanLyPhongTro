package com.roomrental.common.exception;

import org.springframework.http.HttpStatus;

/**
 * Base runtime exception for all business/application errors.
 * Subclass or use static factories for specific error types.
 */
public class BaseException extends RuntimeException {

    private final HttpStatus status;
    private final String code;

    public BaseException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getCode() {
        return code;
    }

    // ── Static factories for common error patterns ────────────────────

    public static BaseException notFound(String entity, Object id) {
        return new BaseException(HttpStatus.NOT_FOUND, "NOT_FOUND",
                entity + " not found with id: " + id);
    }

    public static BaseException conflict(String message) {
        return new BaseException(HttpStatus.CONFLICT, "CONFLICT", message);
    }

    public static BaseException badRequest(String message) {
        return new BaseException(HttpStatus.BAD_REQUEST, "BAD_REQUEST", message);
    }

    public static BaseException unauthorized(String message) {
        return new BaseException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", message);
    }

    public static BaseException forbidden(String message) {
        return new BaseException(HttpStatus.FORBIDDEN, "FORBIDDEN", message);
    }
}
