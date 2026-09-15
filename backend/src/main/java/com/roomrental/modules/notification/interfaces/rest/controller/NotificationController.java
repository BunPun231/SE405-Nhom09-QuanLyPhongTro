package com.roomrental.modules.notification.interfaces.rest.controller;

import com.roomrental.common.util.SecurityUtils;
import com.roomrental.modules.notification.application.service.NotificationQueryService;
import com.roomrental.modules.notification.interfaces.rest.dto.NotificationResult;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "Notification - Notifications", description = "Quản lý danh sách thông báo của người dùng")
@SecurityRequirement(name = "bearerAuth")
public class NotificationController {


    private final NotificationQueryService queryService;

    public NotificationController(NotificationQueryService queryService) {
        this.queryService = queryService;
    }

    @GetMapping
    @Operation(summary = "Lấy danh sách thông báo phân trang của người dùng")
    public ResponseEntity<Page<NotificationResult>> getNotifications(
            @PageableDefault(size = 20) Pageable pageable) {
        UUID userId = SecurityUtils.getCurrentUserId();
        Page<NotificationResult> notifications = queryService.getNotificationsForUser(userId, pageable);
        return ResponseEntity.ok(notifications);
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Lấy số lượng thông báo chưa đọc của người dùng")
    public ResponseEntity<Long> getUnreadCount() {
        UUID userId = SecurityUtils.getCurrentUserId();
        long count = queryService.countUnread(userId);
        return ResponseEntity.ok(count);
    }

    @PutMapping("/read-all")
    @Operation(summary = "Đánh dấu tất cả thông báo của người dùng là đã đọc")
    public ResponseEntity<Void> markAllAsRead() {
        UUID userId = SecurityUtils.getCurrentUserId();
        queryService.markAllAsRead(userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/read")
    @Operation(summary = "Đánh dấu một thông báo cụ thể là đã đọc")
    public ResponseEntity<NotificationResult> markAsRead(@PathVariable("id") Long id) {
        UUID userId = SecurityUtils.getCurrentUserId();
        NotificationResult result = queryService.markAsRead(id, userId);
        return ResponseEntity.ok(result);
    }
}
