# FamilyApp — Design

_Status: Draft v0.2 · Last updated 2026-05-30_

This document defines **what FamilyApp is, what it does, and — just as importantly —
what it deliberately does not do**, plus the **requirements, architecture, a critical review
of the design, and a staged delivery plan**. It is the scope contract for the project.
Decisions are grounded in [`competitive-research.md`](./competitive-research.md) and the
architecture research summarised throughout.

---

## 1. Purpose

FamilyApp is a **private, self-hosted family hub**: one shared place — an always-on iPad on
the wall plus everyone's phones — where the family sees *what's happening this week*, *open
tasks and who owns them*, *the meal plan*, *upcoming events*, and *recognition for chores*
(stars/points). It is also where the family **proposes improvements** and **agrees house
rules** together.

The point is **ownership**: our data lives on our own server, tailored to our family, and it
keeps working even if a commercial product changes terms or shuts down.

## 2. Principles (non-negotiable)

1. **Privacy-first.** Data stays on hardware we control. No third-party account required for
   core use. No ads, no telemetry, no data sale.
2. **Platform-independent.** No *load-bearing* dependency on any single vendor cloud (Apple,
   Amazon, Google). Vendor integrations are optional conveniences (see §11 for where this is
   imperfect and why).
3. **Reuse over rebuild.** Integrate solid open-source, self-hostable, standards-based
   components (calendar, recipes, chores) rather than reimplement them.
4. **Adoption-first.** The #1 success predictor in this category is *the whole family actually
   using it*. Low setup and low input friction beat feature count.
5. **Self-hostable on modest hardware, 24/7, low power.**

## 3. Users

- **Parents/guardians** — admins; manage members, rules, rewards, meal plan, approvals.
- **Children** — view the week, complete their chores, earn stars, post ideas.
- **The iPad hub** — a shared, always-on, kiosk display anyone walking by can read/tap.

---

## 4. User requirements

### Functional (FR)
- **FR1 Weekly overview** — a glanceable "this week" home screen: today/this week's events,
  today's meal, each person's open tasks, recent star awards.
- **FR2 Tasks & chores** — assignable, recurring/one-off, with a clear owner and a
  done→approve flow.
- **FR3 Recognition** — stars/points/badges for completed chores, redeemable for
  family-defined rewards; **non-monetary**; designed against "reward fatigue."
- **FR4 Meal plan** — the week's meals visible on hub and phones; "what's for dinner" is a
  first-class, instantly answerable question.
- **FR5 Shared calendar** — per-member, color-coded events; subscribable natively in Apple
  Calendar; create/edit from FamilyApp.
- **FR6 House rules** — collaboratively edited, visible, versioned, with simple
  acknowledgement.
- **FR7 Idea/suggestion board** — anyone (incl. kids) posts improvement ideas; upvote/discuss/
  mark adopted.
- **FR8 Members & roles** — admin (parent) vs member (child) permissions; child-friendly
  sign-in.
- **FR9 Hub kiosk mode** — always-on wall display; **iPhone companion** clients.
- **FR10 Voice (optional)** — ask "what's for dinner?" / "what's on today?" and receive spoken
  reminders/announcements.
- **FR11 Reminders/notifications** — push reminders to phones (and/or speak them on the hub).
- **FR12 Remote use** — family members can use the app **away from home**, securely.

### Non-functional (NFR)
- **NFR1 Privacy** — all family data persists on the home server; no required third-party
  account; the only data that may leave the house is the optional voice path (§11) and remote
  access traffic over an encrypted tunnel.
- **NFR2 Self-hosted, Docker-based** — the server is a **Docker Compose stack** on a home host,
  with persistent data on an **external SSD** (firm decision, §6/§7).
- **NFR3 Availability & graceful degradation** — target ≥99% home uptime; the hub must show the
  last-known week if the backend is briefly unavailable; survive power loss without data
  corruption.
- **NFR4 Performance** — core questions ("dinner / this week / my chores") answered in <3 s on
  the hub.
- **NFR5 Low power** — idle draw modest enough to run 24/7.
- **NFR6 Backup & restore** — automated, encrypted backups to Synology; **restore must be
  tested**, not just configured.
- **NFR7 Security** — per-user auth, TLS everywhere (incl. LAN), no default credentials,
  defined patching cadence for all containers.
- **NFR8 Maintainability** — one person can update, back up, and recover the stack from a
  written runbook.

---

## 5. What FamilyApp DOES / DOES NOT do

### DOES (v1 core)
Weekly overview dashboard · tasks/chores with owners · non-monetary stars/recognition · meal
plan · shared calendar/events · house rules · family idea board · iPad kiosk hub + phone
clients · members & roles · optional HA-brokered voice · reminders.

### DOES NOT (non-goals — intentional boundaries)
- **Not a cloud SaaS** — no mandatory vendor account, no paywall, core data never required in
  someone else's cloud.
- **Not a money/allowance/banking app** — stars only, no debit cards or real-money payouts
  (the deliberate split from Greenlight/GoHenry/BusyKid).
- **Not a location tracker.** **Not a chat/messaging platform** (the idea board is structured
  suggestions, not chat).
- **Not a smart-home controller** — that is Home Assistant's job; FamilyApp *uses* HA, it does
  not replace it.
- **Not a calendar/recipe/chore engine from scratch** — we reuse CalDAV + Mealie + Donetick.
- **Cannot make Alexa private** — if Alexa is used, the voice transcript and spoken answer
  transit Amazon (§11). Only our data and logic stay local.
- **Not multi-family/multi-tenant; not Android/Windows native; no ads/telemetry.**
- **Not guaranteed offline-first in v1** (depends on backend/sync choice — see Open Decisions).

---

## 6. Architecture

**Hosting decision (firm):** a **single always-on Docker host** running a **Docker Compose**
stack, with all persistent volumes on an **external SSD** (USB3/NVMe, UASP enclosure).
Recommended hardware: an **x86 mini-PC** or **Raspberry Pi 5 (8 GB) + NVMe/SSD**. Synology is a
**backup target only** and need not run 24/7.

```
        ┌──────────────────────────────┐     ┌───────────────────────┐
        │  iPad hub (wall, kiosk)       │     │  iPhones (companions)  │
        └───────────────┬──────────────┘     └───────────┬───────────┘
                        │  HTTPS REST/realtime            │
                        │  (LAN; or via Tailscale away)   │
                        └────────────────┬────────────────┘
                                         ▼
   ┌─────────────────────────────────────────────────────────────────────┐
   │  HOME DOCKER HOST (mini-PC / Pi5) — Docker Compose, data on ext. SSD  │
   │                                                                       │
   │   caddy/traefik (reverse proxy + LAN TLS via Let's Encrypt DNS-01)    │
   │   ├── familyapp-backend  (custom: dashboard, rules, ideas, members,   │
   │   │                       recognition; PocketBase)                    │
   │   ├── mealie             (meal plan / recipes / shopping)             │
   │   ├── donetick           (chores + points/rewards)                    │
   │   ├── radicale|baikal     (CalDAV calendar — native Apple subscribe)  │
   │   ├── home-assistant      (Container) — integration glue + voice      │
   │   ├── mosquitto (optional MQTT)   watchtower (optional updates)       │
   │   ├── cloudflared (tunnel — ONLY the HA Alexa endpoint, if Alexa on)  │
   │   └── tailscale (private remote access for family devices)            │
   └───────────────────────────────────┬───────────────────────────────────┘
                                        │ scheduled encrypted backup
                                        ▼
                              Synology (powered on for backups only)

   Alexa path (optional, NOT private): Echo ⇄ Amazon cloud (STT/NLU)
       → HA Custom Skill intent → reads Mealie/calendar → speaks answer
   Fully-local voice (v2): HA Assist + Voice PE (no Amazon)
```

**Why Home Assistant runs as a *container* here (important):** Home Assistant OS (what HA
Green/Yellow ship with) only runs Docker via **managed add-ons**, *not* arbitrary Docker
Compose. Since we want a normal Compose stack, we run **Home Assistant Container** on the same
host. Trade-off: we lose the HAOS Supervisor/Add-on Store and managed backups — which we don't
need, because we manage our own Compose stack and backups. HACS, the Mealie integration, Nabu
Casa, AWS-Lambda skills, and Alexa Media Player all still work on HA Container.

**Why not HA Green as the app host:** HAOS add-on model (no free Compose), 4 GB soldered RAM,
32 GB eMMC, and **USB 2.0** (slow external SSD) make it the *minimum* viable host at best.
Keep HA Green only if you specifically want a separate dedicated HA appliance (two-box setup).

## 7. Reuse vs build

| Capability | Decision | Component |
|---|---|---|
| Calendar / events | **Reuse** | CalDAV server (Radicale or Baïkal) — native Apple subscribe; HA reads same feed |
| Meal planning / recipes | **Reuse** | Mealie — official HA integration, REST API |
| Chores + stars/rewards | **Reuse** | Donetick — built-in family gamification, REST + webhooks |
| Weekly dashboard | **Build** | FamilyApp client + backend (aggregates the above) |
| House rules | **Build** | FamilyApp backend (CRUD + versioning) |
| Idea/suggestion board | **Build** | FamilyApp backend (CRUD + votes) |
| Voice / Alexa | **Reuse/broker** | Home Assistant |
| Smart home | **Out of scope** | Home Assistant (separate concern) |

---

## 8. Critical review — logic errors, omissions, hidden dependencies

> This is a deliberately skeptical pass. Each item has a **resolution** folded into the
> requirements/plan. Items still needing *your* call are in §9.

### Resolved by the architecture above
- **C1 — "Docker on HAOS" was a contradiction.** HAOS can't run arbitrary Compose; it only
  runs add-ons. **Resolution:** single Docker-Compose host with HA as a container (§6).
- **C2 — External SSD over USB 2.0.** On HA Green an external SSD is throttled to USB 2.0.
  **Resolution:** host is a mini-PC/Pi5 with USB3/NVMe; SSD via UASP enclosure.
- **C3 — Two-always-on-boxes creep.** Earlier draft implied HA *and* a separate app host.
  **Resolution:** one box runs both; Synology stays off except for backups.

### Omissions now added as requirements
- **C4 — Remote access was missing.** Phones away from home couldn't reach a LAN-only server
  (FR12). **Resolution:** **Tailscale** (WireGuard mesh, private, no open ports). Cloudflare
  Tunnel is used *only* for the narrow public Alexa endpoint, not general access.
- **C5 — Authentication/identity undefined.** Hub is shared/always-on — who can approve chores
  or edit rules? **Resolution:** FamilyApp backend is the **identity master**; per-member
  accounts; child-friendly PIN on the hub; admin actions (approvals, rule edits, reward
  redemption) require an admin PIN even on the shared hub (FR8, NFR7).
- **C6 — Identity duplicated across 4 systems.** Members exist in FamilyApp, Mealie, Donetick,
  and CalDAV. **Resolution:** FamilyApp is the master; it provisions/maps accounts in the
  reused services via their APIs. v1 simplification: Mealie uses one household account (meal
  plan is family-wide); per-member only where it matters (Donetick chores, recognition).
- **C7 — Recognition source-of-truth ambiguity.** Points could live in Donetick *or* the
  custom backend. **Resolution:** **Donetick owns chore points**; the FamilyApp backend reads
  them via API and *also* awards "bonus" recognition for non-chore events (e.g., an adopted
  idea). The backend is the single place the UI reads a member's total.
- **C8 — Event authoring path unspecified.** CalDAV subscribe is read-friendly, but who
  *writes* events? **Resolution:** the **backend exposes an events API that proxies to CalDAV**
  (server-side CalDAV client), so clients don't each implement CalDAV; Apple Calendar can still
  write directly for adults.
- **C9 — Reminders/push to phones glossed over.** **Resolution (v1):** reuse the **Home
  Assistant Companion app** for push (it relays to APNs without us running our own push infra)
  and/or speak reminders on the hub/Alexa. Note this still touches Apple's APNs (§11).
- **C10 — Local HTTPS / iOS ATS.** Native apps + self-signed certs trip Apple's App Transport
  Security. **Resolution:** **Caddy/Traefik + Let's Encrypt DNS-01** for an internal domain
  (split-horizon DNS) → real certs on the LAN, no ATS exceptions. (Adds a small dependency: a
  domain + a DNS provider with an API.)
- **C11 — Backup detail & SSD as single point of failure.** **Resolution:** scheduled,
  encrypted backups of all Docker volumes + DB dumps to Synology; **periodic test restore**
  (NFR6); document RPO/RTO; a single SSD is acceptable *only because* backups exist.
- **C12 — Maintenance/patching burden (bus factor).** Self-hosting is ongoing work.
  **Resolution:** pin image versions, scheduled update window (Watchtower optional), a written
  **runbook**, and an honest acknowledgement that the family depends on one maintainer.
- **C13 — Power loss corrupting the DB.** **Resolution:** SQLite WAL (PocketBase) tolerates
  power loss reasonably; **a small UPS is recommended** for the host + SSD.
- **C14 — Single point of failure for the household.** If the server is down there's no
  dinner/calendar/chores. **Resolution:** hub caches the last-known week and degrades to
  read-only; this is an explicit NFR3 requirement, not an afterthought.
- **C15 — Idea board moderation.** Kids posting freely needs light parental moderation.
  **Resolution:** admins can hide/remove posts; default is visible-to-family only.

### The big hidden dependency (needs your decision — see §9)
- **C16 — A *native SwiftUI* app re-introduces Apple as a gatekeeper, which fights the
  independence principle.** To install a native app on the family's iPads/iPhones you need the
  **Apple Developer Program ($99/yr)** and distribution via **TestFlight (builds expire ~90
  days)** or the App Store — plus signing, ATS, and APNs. That's real, recurring dependence on
  Apple's platform for *distribution*, exactly what Principle 2 warns against. The scaffolded
  SwiftUI app is great UX, but a **self-hosted PWA** (served from the Docker host, installed to
  the home screen) needs *no* Apple Developer account, deploys/updates instantly, and is
  cross-platform — at the cost of less-native polish, weaker iOS push, and fiddlier kiosk
  behavior. **This is a genuine fork that changes the client stack; decide before building the
  client (Stage 3).**

---

## 9. Decisions

**Resolved**
- Server is **Docker Compose**, data on **external SSD** (user decision).
- Host = **single mini-PC / Pi5 + SSD**; **HA as a container**; **Synology = backups only**.
- Reuse **Mealie / Donetick / CalDAV**; build dashboard / rules / ideas / recognition / members.
- Remote access = **Tailscale**; Alexa exposure (if used) = **Cloudflare Tunnel + mTLS**.
- LAN TLS = **Caddy/Traefik + Let's Encrypt DNS-01**.
- Recognition points master = **Donetick**, surfaced via backend.

**Still open (need your call)**
1. **Client stack: native SwiftUI vs self-hosted PWA** (C16). Biggest decision; affects Apple
   Developer Program, distribution, push, and the existing scaffold.
2. **Custom backend: PocketBase (lightest, REST, no offline sync) vs Couchbase Lite + CouchDB
   (true offline-first, heavier).** Drives whether v1 is offline-capable.
3. **Voice now or later: HA-brokered Alexa in v1 (not private) vs defer to local HA Assist (v2).**
4. **Internal domain + DNS provider** for Let's Encrypt DNS-01 (needed for clean LAN TLS).

---

## 10. Delivery plan — stages & milestones

Each stage ends in a verifiable milestone. Stages are mostly sequential; Stage 4 (voice) can
run in parallel once Stage 1 is done.

### Stage 0 — Foundations / infrastructure
Provision the host + OS + Docker; mount external SSD for all volumes; set up reverse proxy +
LAN TLS; Tailscale; backups to Synology; HA container baseline; UPS.
- **M0 — "Stack is alive & safe":** Compose stack boots from SSD; HTTPS works on LAN and via
  Tailscale; an automated backup runs **and a test restore succeeds**; UPS shuts down cleanly.
- _Depends on:_ decisions §9.4 (domain). _Risks:_ SSD/enclosure reliability; DNS-01 setup.

### Stage 1 — Reused services + identity
Deploy Mealie, Donetick, CalDAV; define the family member list; map/provision accounts (C6);
subscribe Apple Calendar to CalDAV; verify HA reads Mealie + calendar.
- **M1 — "Meals, chores, calendar usable":** family can plan a meal, assign a chore, add an
  event; events appear in Apple Calendar; HA shows a "dinner today" sensor.
- _Depends on:_ M0. _Risks:_ identity mapping complexity.

### Stage 2 — Custom backend
Stand up the backend (per §9.2); data model for members, house rules, idea board, recognition
aggregation; events API proxying CalDAV (C8); auth + roles + admin PIN (C5); read Donetick
points (C7).
- **M2 — "Backend API live":** authenticated REST API serves dashboard data, rules, ideas, and
  a member's total stars; admin-gated actions enforced.
- _Depends on:_ M1, decision §9.2. _Risks:_ CalDAV write proxy edge cases.

### Stage 3 — Client(s) + hub
Build the client per §9.1 (native vs PWA): weekly dashboard, tasks, meals, calendar, rules,
idea board; iPad **kiosk mode** with offline last-week cache (C14); child PIN / admin PIN.
- **M3 — "Family adoption test":** the whole family uses the hub + phones for **one week**;
  core questions answered in <3 s; ≥1 idea posted and ≥1 chore approved by each member.
- _Depends on:_ M2, decision §9.1. _Risks:_ adoption (the real risk); distribution friction if
  native.

### Stage 4 — Voice & reminders (optional in v1)
HA Custom Skill intents for "what's for dinner" / "what's on today" reading Mealie + calendar;
reminders via HA Companion push (C9) and/or hub/Alexa announcements; expose only the Alexa
endpoint via Cloudflare Tunnel + mTLS.
- **M4 — "Ask & be reminded":** a child asks the voice assistant and gets the right dinner/
  events answer; a scheduled reminder reaches a phone and/or the hub.
- _Depends on:_ M1 (data) + decision §9.3. _Risks:_ Alexa custom-skill flakiness; Alexa Media
  Player is unofficial and may break — don't make safety-critical reminders depend on it.

### Stage 5 — Hardening & handover
Backup/restore drill; monitoring + alerting (host, containers, disk, backup success); security
review (auth, exposed surface, secrets); update strategy; write the **runbook** (C12).
- **M5 — "Production-ready":** documented runbook; alerting verified; second restore drill from
  Synology passes; patching cadence agreed.
- _Depends on:_ M0–M4.

### Later / v2 (explicitly deferred)
Fully-local voice (HA Assist + Voice PE) · offline-first sync · AI input capture (flyer→event)
· hub photo/screensaver mode · shopping lists (via Mealie/Grocy) · per-member hub
personalization.

---

## 11. Privacy reality check (where independence is imperfect)

- **Voice:** any Alexa path sends the voice transcript + spoken answer through Amazon —
  unavoidable. The fully-private alternative is deferred HA Assist (v2).
- **Phone push notifications:** iOS push ultimately goes through Apple's APNs (even via the HA
  Companion relay). Local/hub announcements avoid this.
- **Native app distribution:** if we go native (C16/§9.1), installing/updating the app depends
  on Apple's Developer Program/TestFlight/App Store. A PWA avoids this.
- **Optional edge services:** Cloudflare (Alexa tunnel) and Tailscale (coordination server)
  sit in their respective paths. Both can be self-hosted/replaced later (e.g., Headscale for
  Tailscale) if desired.
- **Everything else** — meals, chores, calendar, rules, ideas, recognition, members — stays on
  the home server.

## 12. Success criteria

- Whole family (incl. second parent and kids) actively using it within a month.
- "Dinner / this week / my chores" answerable in <3 s on the hub and by voice.
- Adding an event/task/idea takes seconds from any device, home or away.
- Runs unattended at low power; **survives a vendor policy change with core features intact**;
  a restore from backup has been proven to work.

## 13. Research caveats

Prices, power figures, eMMC-wear percentages, and some project stats in the source research
were single-sourced or vendor-blocked (HTTP 403). Treat specific numbers as indicative and
verify before committing hardware/spend. See the ⚠️ flags in
[`competitive-research.md`](./competitive-research.md).
