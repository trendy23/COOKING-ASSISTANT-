# Requirements Specification — Cooking Assistant App

*Draft v1 — Phase 2 deliverable (ICT 2140)*

## 1. Project Overview

A fully offline mobile application that helps users with no prior cooking
experience discover dishes based on their available ingredients and personal
constraints, then guides them through preparation using an "Interactive
Virtual Kitchen" — a simple, animated, step-by-step cooking walkthrough.

## 2. Actors

| Actor | Description |
|---|---|
| Freemium User | Default role for any local profile. Full access to core features, with certain premium content locked. |
| Premium User | Unlocked locally via a redeem code (no external payment or server validation). |

*(No Admin actor — content is bundled with the app at build time; no
account/tier management by a third party is required.)*

## 3. Functional Requirements

| ID | Requirement |
|---|---|
| FR1 | The system shall allow a user to create or select a local profile to access the home screen (no external authentication). |
| FR2 | The system shall allow a user to input ingredients, time constraints, energy level, cultural preference, and dietary restrictions, and return recommended dishes matching these criteria. |
| FR3 | The system shall allow a user to select a recommended dish and enter its **Interactive Virtual Kitchen** — a step-by-step walkthrough with simple visuals/animations designed for users with no prior cooking experience. |
| FR4 | The system shall allow a user to save/favorite recipes for quick access later. |
| FR5 | The system shall offer three recipe display modes — Silent, Normal, and Interactive — selectable by the user. |
| FR6 | The system shall allow a Freemium user to unlock Premium status locally by entering a valid redeem code. |
| FR7 | The system shall limit Freemium users to a capped number of dish recommendation requests per session/day; Premium users shall have unlimited requests. |
| FR8 | The system shall grant Freemium users access to the Interactive Virtual Kitchen for a limited set of starter recipes only; Premium users shall have full access across all recipes. |
| FR9 | The system shall allow both Freemium and Premium users to save/favorite recipes, with no restriction on tier (superseding the original blanket favoriting cap discussed by the team). |

## 4. Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR1 | The system shall function fully offline, with no dependency on network connectivity or a backend server. |
| NFR2 | Recipe recommendation results shall load within 2 seconds of input submission. |
| NFR3 | The UI shall be simple and intuitive for users with no prior cooking or technical experience. |

## 5. Key Feasibility Decisions (for Chapter 3 — Methodology)

- **No backend/server** — all recipe content, images, and step animations are
  bundled with the app (or seeded into a local database on first launch),
  not fetched from the internet.
- **Recommendation logic** is rule/filter-based: hard-filter by non-negotiable
  constraints (e.g. dietary restriction), then rank remaining matches by soft
  preferences (time, energy, culture). No AI/ML dependency.
- **Premium tier** is enforced entirely on-device via a redeem code check —
  appropriate for a fully offline app, though not resistant to tampering
  (acceptable trade-off for this project's scope; worth noting as a
  limitation in your report).

## 6. Descoped Requirements (documented trade-off)

| Descoped Item | Reason |
|---|---|
| Hands-free / low-touch UI (originally NFR3) | Would realistically require voice recognition or similar AI-driven interaction to be meaningful, which is beyond the team's current skillset and the project's time budget. Descoped in favor of a straightforward touch UI, prioritizing a fully working core feature set over a partially working advanced one. |

*Note: keep this table — it's good material for your report's "Recommendations
for Further Studies" section, showing deliberate scope reasoning rather than
an omission.*

## 7. Status

All functional and non-functional requirements resolved. Ready for Phase 3
(UML Design).
