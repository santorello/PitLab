# Place And Media Systems Design

## Goal

Standardize two cross-cutting systems in PitLap:

- place search, selection, and map preview/picking
- image preparation, upload state, and progress presentation

The outcome should let PitLap reuse the same primitives across onboarding, spot submission, editors, and future map-heavy experiences without duplicating feature logic.

## Context

Today the codebase already has:

- a first location autocomplete in onboarding powered by Open-Meteo geocoding
- a real spot map screen powered by `flutter_map`
- several image-picking flows that convert files to local `data:image` URLs
- a shared `ImageTransferProgressCard`, but progress logic is duplicated per screen and only tracks completed items

The current setup works for pre-alpha but has three structural limits:

1. place handling is fragmented and not stored as one canonical selection object
2. map provider choice is not standardized for future reuse
3. media progress is not byte-accurate and cannot become truly real until uploads move toward shared storage-backed flows

## Decisions

### 1. Place system

PitLap will introduce a shared place layer with provider abstraction and a concrete MapTiler-backed implementation for the current non-commercial phase.

We will standardize on:

- `PlaceSelection` as canonical app model
- `PlaceSearchProvider` interface for autocomplete + details
- `MapTilerPlaceSearchService` as active provider
- reusable UI widgets for search suggestions and compact map preview

The abstraction keeps the app ready for future provider replacement without rewriting screens.

### 2. Map provider

The active provider will be MapTiler during local/pre-alpha/non-commercial development. This is acceptable for the current phase, but the design must keep provider metadata explicit because a commercial rollout may require a pricing-plan change or provider swap.

### 3. Media system

PitLap will introduce a shared media upload state model that separates:

- file preparation
- upload transport
- server-side processing or persistence completion

This system will support both current local-preparation flows and future true network uploads. It will improve UI immediately while remaining compatible with later Supabase Storage integration.

### 4. Progress semantics

The app will stop pretending that “files completed / files total” is full upload progress.

Instead:

- current local-only flows will expose explicit preparation progress and per-file stage labels
- future network-backed flows will expose actual byte progress during upload
- the shared UI will visually distinguish preparation from upload

## Architecture

### Place domain

Create a shared model with:

- display label
- title / subtitle breakdown
- latitude / longitude
- provider id
- provider name
- optional country / region / address fragments

This object should be serializable and suitable for reuse in forms, profile preferences, and map markers.

### Place services

Introduce a shared place service module under `shared` rather than feature-local onboarding code. The onboarding-specific Open-Meteo service will be replaced by the shared provider-oriented implementation.

Minimum responsibilities:

- autocomplete search
- in-memory request cache
- debounced access from UI
- provider metadata included in the result

### Place UI

Introduce reusable widgets:

- `PlacePickerField`: text input + suggestion list + selected result handling
- `PlaceMapPreviewCard`: compact map with marker and attribution label

First integrations:

- onboarding preferred city
- submit place spot address / map point

Future integrations are expected for track editor, shop editor, and event creation.

### Media domain

Introduce shared upload state objects with:

- file id
- filename / label
- current stage
- stage progress
- transferred bytes / total bytes when available
- completion or failure state

### Media controller

Add a shared controller/helper that can drive:

- item preparation progress for local image conversion
- aggregate progress across multiple files
- a consistent UI model for all current screens

For this session we will standardize the state and UI contract first. We will not fully migrate all features to Supabase Storage in one pass, but the new controller must be compatible with that next step.

### Media UI

Replace the simplistic progress card semantics with a richer card that can show:

- active stage text
- aggregate percentage
- item counters
- optional transferred bytes when known
- animated visual feedback even while no file has yet completed

## Data Handling

### Place persistence

This session will prioritize canonical selection in UI and value flow. We will persist standardized labels immediately where already supported, while keeping room for later schema expansion to lat/lon on profiles and other entities.

### Media persistence

This session will not expand schema for every media-bearing entity. Instead it will improve app-side media handling, reduce duplication, and document the path to Supabase Storage rollout.

## Error Handling

### Place search

- empty suggestions should be a valid state
- provider errors should degrade to manual text entry where that already exists
- UI should never block form completion solely because autocomplete failed

### Media

- per-file failures should not wipe the whole selection
- progress UI should expose failed items clearly
- the controller should allow partial success

## Testing Strategy

Add focused unit/widget tests for:

- place result mapping and selection serialization
- media progress aggregation and stage transitions
- regressions around cache serialization that must not store oversized inline images in local web storage

## Scope Boundaries For This Session

Included:

- shared place models/services/widgets
- MapTiler-backed search implementation
- first integrations in onboarding and submit place
- shared media progress model/widget improvements
- adoption in the most visible current image flows
- documentation updates across project docs touched by this session

Not included:

- full Supabase Storage rollout for every entity
- complete migration of every editor to place picker in one pass
- backend schema redesign for every place-bearing record

## Rollout Notes

- provider choice must be documented in `api-registry.md`
- map attribution/legal notes must stay explicit
- future commercial rollout must revisit MapTiler plan suitability
- media strategy docs must explicitly note that true byte-level upload progress depends on storage-backed uploads
