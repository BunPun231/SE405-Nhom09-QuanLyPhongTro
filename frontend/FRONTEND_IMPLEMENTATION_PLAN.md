# Frontend Implementation Plan

## Scope

This document is the working TODO / implementation plan for the frontend only.

Backend work is considered frozen for now. Frontend tasks should consume the current API contract and focus on usability, completeness, and consistency.

## Goals

- Finish the main landlord workflow end-to-end in the UI.
- Keep the interface simple for non-technical users.
- Align all screens with the current backend behavior and data shapes.
- Preserve the existing React + Vite + PWA stack.

## Assumptions

- Authentication and core backend endpoints already exist.
- Room and service IDs may be encoded in API calls, but the UI should continue to show human-readable labels.
- Mobile usability matters, but the first pass should prioritize desktop workflows that managers use daily.

## Priority 1: Core Navigation And Auth

- [ ] Verify the route map and navigation structure across the app.
- [ ] Polish login, logout, and session restore flows.
- [ ] Ensure tenant context is loaded before protected pages render.
- [ ] Add or fix empty, loading, and error states for shell-level screens.

## Priority 2: Motel And Room Management

- [ ] Complete motel profile screens.
- [ ] Finish room list, room detail, and room creation/edit flows.
- [ ] Add bulk room creation if the current UX still requires too many manual steps.
- [ ] Make room status, occupancy, and pricing easy to scan.
- [ ] Verify encoded room IDs do not leak into the visible UI.

## Priority 3: Resident And Contract Flows

- [ ] Finish resident list, resident detail, and resident onboarding screens.
- [ ] Complete contract creation and contract editing UX.
- [ ] Add appendix and contract adjustment views.
- [ ] Make deposit, liquidation, and contract history states easy to understand.
- [ ] Show contract snapshots or history when backend data is available.

## Priority 4: Billing And Metering

- [ ] Complete meter reading submission, approval, and history screens.
- [ ] Add OCR-assisted reading preview and validation UX.
- [ ] Finish invoice list, invoice detail, and invoice settlement screens.
- [ ] Surface calculation snapshot data in a readable way.
- [ ] Add clear handling for missing readings, rejected readings, and unpaid invoices.

## Priority 5: Services And Pricing

- [ ] Finish service management screens.
- [ ] Add pricing history and tier presentation where supported by the API.
- [ ] Ensure bulk price changes and appendices are understandable to users.
- [ ] Review forms for electricity, water, and extra services.

## Priority 6: Maintenance, Reports, And Settings

- [ ] Complete maintenance ticket and maintenance detail screens.
- [ ] Finish the reports area for revenue, occupancy, and debt summaries.
- [ ] Complete profile and motel settings screens.
- [ ] Decide whether billing settings remain API-backed or local-only in the UI.

## Priority 7: PWA And Offline UX

- [ ] Verify service worker registration and offline availability.
- [ ] Improve offline queue visibility and retry behavior.
- [ ] Add explicit sync status so users know when data is pending upload.
- [ ] Test the app on narrow screens and slower network conditions.

## Priority 8: Design And Polish

- [ ] Unify spacing, typography, and form patterns across modules.
- [ ] Reduce duplicated UI logic in shared components.
- [ ] Add consistent toast, confirmation, and destructive action patterns.
- [ ] Review accessibility for keyboard navigation and contrast.

## Implementation Order

1. Finish navigation, auth, and shell states.
2. Close the main landlord workflow: motel, rooms, residents, contracts.
3. Finish billing: meter readings, invoices, settlements, snapshots.
4. Clean up services, maintenance, reports, and settings.
5. Polish offline behavior, responsiveness, and visual consistency.

## Definition Of Done

- Major screens are reachable from the main navigation.
- Core CRUD flows work without broken states.
- Loading, error, and empty states are present on critical pages.
- Forms validate correctly and show useful feedback.
- The app builds successfully and remains usable on desktop and mobile.

## Notes

- Keep backend changes out of this plan unless a UI blocker requires a small contract adjustment.
- If a task is not needed for the current release, leave it unchecked instead of deleting it.