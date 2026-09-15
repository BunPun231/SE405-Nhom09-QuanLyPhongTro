package com.roomrental.modules.technician.infrastructure.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "technician_profiles")
@Getter @Setter @NoArgsConstructor
public class TechnicianProfileEntity {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "expertise", columnDefinition = "TEXT")
    private String expertiseJson; // stored as comma-separated or JSON string

    @Column(name = "is_available", nullable = false)
    private boolean available = true;

    @Column(name = "assigned_motel_ids", columnDefinition = "TEXT")
    private String assignedMotelIdsJson; // stored as comma-separated

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    // ── Array-compatible helpers ──────────────────────────────────────

    @Transient
    public String[] getExpertise() {
        if (expertiseJson == null || expertiseJson.isBlank()) return null;
        return expertiseJson.split(",");
    }

    public void setExpertise(String[] expertise) {
        this.expertiseJson = expertise == null ? null : String.join(",", expertise);
    }

    @Transient
    public Integer[] getAssignedMotelIds() {
        if (assignedMotelIdsJson == null || assignedMotelIdsJson.isBlank()) return null;
        String[] parts = assignedMotelIdsJson.split(",");
        Integer[] result = new Integer[parts.length];
        for (int i = 0; i < parts.length; i++) {
            result[i] = Integer.parseInt(parts[i].trim());
        }
        return result;
    }

    public void setAssignedMotelIds(Integer[] ids) {
        if (ids == null) { this.assignedMotelIdsJson = null; return; }
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < ids.length; i++) {
            if (i > 0) sb.append(",");
            sb.append(ids[i]);
        }
        this.assignedMotelIdsJson = sb.toString();
    }

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}
