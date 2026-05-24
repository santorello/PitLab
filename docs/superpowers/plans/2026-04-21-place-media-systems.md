# Place And Media Systems Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build shared place-search/map primitives and shared media-progress primitives, integrate them into the first key screens, and update project documentation.

**Architecture:** Introduce reusable shared models/services/widgets first, then wire them into onboarding and spot submission for places, and the current image-heavy screens for media progress. Keep provider-specific behavior behind shared abstractions and keep media progress compatible with future Supabase Storage uploads.

**Tech Stack:** Flutter, Riverpod, flutter_map, HTTP APIs, MapTiler geocoding/maps, existing local image preparation utilities.

---

### Task 1: Shared Place Foundation

**Files:**
- Create: `app/lib/shared/places/place_selection.dart`
- Create: `app/lib/shared/places/place_search_service.dart`
- Create: `app/lib/shared/places/place_search_provider.dart`
- Test: `app/test/place_system_test.dart`

- [ ] Define the canonical place model and provider interface.
- [ ] Add a MapTiler-backed implementation with lightweight caching and result mapping.
- [ ] Add tests for result normalization and selection serialization.

### Task 2: Shared Place Widgets

**Files:**
- Create: `app/lib/shared/widgets/place_picker_field.dart`
- Create: `app/lib/shared/widgets/place_map_preview_card.dart`
- Modify: `app/lib/features/onboarding/presentation/onboarding_screen.dart`
- Modify: `app/lib/features/submissions/presentation/submit_place_screen.dart`
- Test: `app/test/place_system_test.dart`

- [ ] Build a reusable autocomplete picker widget.
- [ ] Build a compact shared map preview widget with marker and provider attribution.
- [ ] Replace onboarding local search logic with the shared picker.
- [ ] Replace submit-place spot address flow with shared picker-assisted selection while preserving manual fallback.

### Task 3: Shared Media Upload State

**Files:**
- Create: `app/lib/shared/media/media_upload_state.dart`
- Create: `app/lib/shared/media/media_upload_controller.dart`
- Modify: `app/lib/shared/widgets/image_transfer_progress_card.dart`
- Test: `app/test/media_upload_progress_test.dart`

- [ ] Define reusable upload stage/state models.
- [ ] Implement aggregate progress helpers for preparation-first workflows.
- [ ] Upgrade the shared progress card to render richer progress states and animation-friendly labels.
- [ ] Add tests for aggregate progress and stage transitions.

### Task 4: Adopt Shared Media Progress In Existing Flows

**Files:**
- Modify: `app/lib/features/events/presentation/events_screen.dart`
- Modify: `app/lib/features/submissions/presentation/submit_place_screen.dart`
- Modify: `app/lib/features/shops/presentation/shop_editor_screen.dart`
- Modify: `app/lib/features/profile/presentation/profile_screen.dart`
- Modify: `app/lib/features/tracks/presentation/track_editor_screen.dart`

- [ ] Replace duplicated counters with shared media progress state where practical.
- [ ] Expose preparation stage clearly instead of showing a misleading flat 0%-100% jump.
- [ ] Keep current local conversion behavior stable while improving feedback.

### Task 5: Documentation

**Files:**
- Modify: `docs/api-registry.md`
- Modify: `docs/media-strategy.md`
- Modify: `docs/architecture.md`
- Modify: `docs/development-checklist.md`
- Modify: `VERSION.md`

- [ ] Document MapTiler as the active non-commercial place/map provider for this phase.
- [ ] Document the shared place and media systems added in this session.
- [ ] Note the current limitation that true network byte progress becomes fully available as flows move to Storage-backed uploads.

### Task 6: Verification And Handoff

**Files:**
- Review modified files only

- [ ] Run targeted tests if Flutter is available in the environment.
- [ ] If Flutter is unavailable, perform static sanity review of imports, reused APIs, and data flow.
- [ ] Summarize completed work, residual risks, and next rollout step.
