# FamilyApp — Design

_Status: Draft v0.1 · Last updated 2026-05-30_

This document defines **what FamilyApp is, what it does, and — just as importantly —
what it deliberately does not do.** It is the scope contract for the project. Decisions
here are grounded in the competitive and architecture research in
[`competitive-research.md`](./competitive-research.md) and the architecture findings
summarised below.

---

## 1. Purpose

FamilyApp is a **private, self-hosted family hub**: one shared place — an always-on iPad
on the wall plus everyone's iPhones — where the family can see *what's happening this week*,
*open tasks and who owns them*, *the meal plan*, *upcoming events*, and *recognition for
chores* (stars/points). It's also where the family **proposes improvements** and **agrees
house rules** together.

The point is **ownership**: our data lives on our own server, tailored to our family's
needs, and it keeps working even if a commercial product changes its terms or shuts down.

## 2. Principles (non-negotiable)

1. **Privacy-first.** Family data stays on hardware we control. No third-party account is
   required to use the core app. No ads, no analytics/telemetry, no data sale.
2. **Platform-independent.** No hard dependency on any single vendor's cloud (Apple, Amazon,
   Google) for *core* function. Vendor integrations are optional conveniences, not load-bearing.
3. **Reuse over rebuild.** Where a solid open-source, self-hostable, standards-based component
   exists (calendar, recipes, chores), we integrate it rather than reimplement it.
4. **Adoption-first.** The #1 predictor of success in this category is *the whole family
   actually using it*. Low setup friction and low input friction beat feature count.
5. **Self-hostable on modest hardware.** Must run 24/7 at low power on a home device.

## 3. Users

- **Parents/guardians** — admins; manage members, rules, rewards, meal plan, approvals.
- **Children** — view the week, see/complete their chores, earn stars, post ideas.
- **The iPad hub** — a shared, always-on, kiosk-mode display anyone walking by can read/tap.

---

## 4. What FamilyApp DOES (in scope)

### v1 — Core (the "what's cooking" hub)
- **Weekly overview dashboard.** A glanceable "this week" home screen for the iPad hub:
  today/this-week's events, today's meal, each person's open tasks, recent star awards.
- **Tasks & chores with owners.** Assignable, recurring/one-off tasks; clear owner;
  done/approve flow. (Engine: **Donetick** — see §7.)
- **Recognition / stars.** Points/stars/badges for completing chores, redeemable for
  family-defined rewards. Designed against "reward fatigue" (recognition framing, optional
  sibling view) and **explicitly non-monetary**.
- **Meal plan.** The week's meals visible on the hub and phones; "what's for dinner" is a
  first-class answer. (Engine: **Mealie** — see §7.)
- **Shared calendar / upcoming events.** Per-member, color-coded; subscribable natively in
  Apple Calendar. (Engine: **CalDAV server** — see §7.)
- **House rules.** A collaboratively edited, visible list of family rules. CRUD, versioned,
  with simple agreement/acknowledgement.
- **Family idea / suggestion board.** Anyone (incl. kids) can post "ideas for improvement";
  family can upvote/discuss/mark adopted. This is a deliberate differentiator — no mainstream
  competitor has it.
- **iPad hub (kiosk) mode + iPhone companion clients.** SwiftUI; always-on wall display +
  phones. (See the app scaffold in this repo.)
- **Member management & roles.** Admin (parent) vs member (child) permissions.

### v1 — Voice (convenience layer, optional)
- **Ask a voice assistant** "what's for dinner?", "what's on today?" and get spoken
  **announcements/reminders** — brokered through Home Assistant (see §6). Voice is an
  *add-on*; the app is fully usable without it.

### Later / v2 (explicitly deferred, not v1)
- Shopping lists (likely via Mealie/Grocy rather than custom).
- Photo/screensaver mode for the hub.
- AI input capture (snap a school flyer → event/task).
- Fully-local voice via Home Assistant Assist (replacing/augmenting Alexa).
- Per-member device personalization on the hub.

---

## 5. What FamilyApp DOES NOT do (non-goals)

These are intentional boundaries. If we want one later, it's a deliberate scope change.

- **Not a cloud SaaS.** No mandatory vendor account; no subscription paywall; core data never
  required to live in someone else's cloud. (Directly opposite to Cozi/Skylight/Hearth models.)
- **Not a money / allowance / banking app.** No debit cards, no real-money payouts, no
  investing. Recognition is **stars/points/badges only**. (Unlike Greenlight, GoHenry, BusyKid,
  Homey, FamZoo.)
- **Not a location tracker.** No GPS/family location sharing. (Unlike FamilyWall/Life360.)
- **Not a messaging / chat platform.** We don't build family chat; use existing tools. (The
  idea board is structured suggestions, not a chat.)
- **Not a smart-home controller.** FamilyApp does not control lights/locks/thermostats. That is
  Home Assistant's job; FamilyApp *uses* Home Assistant, it does not replace or duplicate it.
- **Not a calendar/recipe/chore engine from scratch.** We reuse CalDAV + Mealie + Donetick. We
  do not reimplement recurring-event logic, recipe import, or a chore scheduler.
- **Not a private voice assistant (in the Alexa path).** If Alexa is used, the **voice
  transcript and the spoken answer transit Amazon's cloud — unavoidably** (see §6). FamilyApp
  cannot make Alexa private. Only our *data and logic* stay self-hosted. The fully-private voice
  option (HA Assist) is a deferred v2 path.
- **Not multi-family / multi-tenant.** v1 is single-family, single-household. No SaaS for others.
- **Not Android / Windows native, not a public web app (v1).** Clients are iPad + iPhone
  (SwiftUI). A read-only web view may come later; native Android/Windows is out of scope.
- **No ads, no telemetry, no third-party trackers — ever.**
- **Not guaranteed offline-first in v1.** Offline editing/sync on phones is a *possible* goal
  but depends on the backend choice (see §8 Open Decisions); v1 may assume the home LAN/server
  is reachable.

---

## 6. Architecture overview

```
        ┌─────────────────────────────┐        ┌──────────────────────┐
        │  iPad hub (wall, kiosk)      │        │  iPhones (companions) │
        │  SwiftUI — NavigationSplit   │        │  SwiftUI              │
        └──────────────┬──────────────┘        └───────────┬──────────┘
                       │  REST / realtime (LAN, TLS)        │
                       └─────────────────┬──────────────────┘
                                         ▼
        ┌───────────────────────────────────────────────────────────────┐
        │  HOME SERVER (always-on, low power)                            │
        │                                                               │
        │   ┌───────────────────────────┐   reuse (self-hosted):       │
        │   │ FamilyApp backend (custom) │   ┌─────────────┐           │
        │   │  - dashboard aggregation   │   │ Mealie      │ meals     │
        │   │  - house rules             │◄─▶│ Donetick    │ chores/⭐ │
        │   │  - idea board              │   │ CalDAV      │ calendar  │
        │   │  - recognition/points*     │   │ (Radicale/  │           │
        │   │  - auth / members          │   │  Baïkal)    │           │
        │   └─────────────┬─────────────┘   └─────────────┘           │
        │                 │ local REST / WebSocket / MQTT              │
        │                 ▼                                            │
        │   ┌───────────────────────────┐                             │
        │   │ Home Assistant (the glue)  │  ── brokers voice/Alexa ──┐ │
        │   └───────────────────────────┘                           │ │
        └───────────────────────────────────────────────────────────┼─┘
                                                                      │
   Alexa path (optional, NOT private):   Echo ⇄ Amazon cloud (STT/NLU)┘
       → HA Custom Skill intent → reads Mealie/calendar → speaks answer
       exposed via Cloudflare Tunnel (mTLS) or AWS Lambda proxy
   Fully-local path (v2):   HA Assist + Voice PE (no Amazon)

   Backups → Synology (powered on for scheduled backups only; not 24/7)
```

**Key decisions baked in:**
- A **small custom backend** owns only what's genuinely custom (dashboard, house rules, idea
  board, recognition, members). Everything else is a **reused service**.
- **Home Assistant is the integration hub** and the realistic path to Alexa/voice and any
  wall-display/MQTT glue. The backend talks to HA locally via REST/WebSocket (long-lived token)
  or MQTT.
- **Synology is a backup target, not the always-on host** — matching the preference to keep it
  powered off most of the time.

\* Recognition/points may instead come straight from **Donetick** (it has built-in
family gamification); see Open Decisions.

## 7. Reuse vs build

| Capability | Decision | Component | Why |
|---|---|---|---|
| Shared calendar / events | **Reuse** | CalDAV server (**Radicale** or **Baïkal**) | iPhone/iPad subscribe natively (zero client code); HA reads same feed; standards-based, durable |
| Meal planning / recipes | **Reuse** | **Mealie** (AGPL, active, REST API) | Official Home Assistant integration; powers "what's for dinner" with no bespoke plumbing |
| Chores + stars/rewards | **Reuse** | **Donetick** (AGPL, Go, REST + webhooks) | Only researched project with built-in *family* gamification + assignment + dashboard view |
| Weekly overview dashboard | **Build** | FamilyApp SwiftUI + backend | No off-the-shelf fit; aggregates the reused services into one glanceable hub |
| House rules | **Build** | FamilyApp backend (simple CRUD) | Genuine white space; trivial to build; not worth dragging in Nextcloud |
| Idea / suggestion board | **Build** | FamilyApp backend (CRUD + votes) | Genuine white space; no family-app competitor has it |
| Voice / Alexa | **Reuse/broker** | Home Assistant | HA already provides intent endpoint + Mealie/calendar entities + announcements |
| Smart home | **Out of scope** | Home Assistant (separate) | Not FamilyApp's job |

## 8. Open decisions (need a call before build)

1. **Custom backend technology.** Trade-off:
   - **PocketBase** — single ~tiny Go binary, SQLite, REST + realtime + auth + admin UI;
     smallest footprint (ideal for constrained hardware). *But* no official Swift SDK (use REST
     directly) and no built-in offline sync; pre-1.0.
   - **Supabase (self-hosted)** — Postgres, official **Swift SDK**, more power. *But* 10+
     containers, **needs ~8 GB RAM** — too heavy for a Home Assistant Green.
   - **Couchbase Lite (native Swift) + CouchDB/Sync Gateway** — the only true **offline-first
     bidirectional sync** into SwiftUI. *But* heaviest ops.
   - _Recommendation:_ **PocketBase** unless offline-first on kids' phones is a hard v1
     requirement (then Couchbase Lite). Avoid Supabase if hosting on HA Green.
2. **Voice: Alexa now, or hold for fully-local HA Assist?** Alexa works with existing Echo
   hardware but routes voice through Amazon (not private) and the nicest push-announcement path
   (Alexa Media Player) is unofficial and can break. HA Assist + Voice PE is fully private and a
   good fit for these *structured* queries, but needs HA Voice hardware and has narrower
   free-form understanding. _Recommendation:_ ship v1 with HA-brokered Alexa as an optional
   convenience; plan HA Assist as the private default in v2.
3. **Hosting device.** HA Green *can* host a PocketBase-class backend **only if** the DB is
   moved to a USB SSD (its soldered 32 GB eMMC wears out under DB writes; 4 GB RAM, USB 2.0,
   slow CPU). _Recommendation:_ for headroom prefer **HA Yellow (NVMe)** or a **Raspberry Pi 5
   (8 GB) + NVMe**; treat HA Green as the minimum viable host. Synology = backups only.
4. **Internet exposure for Alexa.** **Cloudflare Tunnel + mTLS** (no open ports; Cloudflare
   sees edge traffic) vs **AWS Lambda thin proxy** (adds AWS) vs **Nabu Casa** (~$6.50–7.50/mo,
   easiest, but custom-skill path reportedly flaky). _Recommendation:_ Cloudflare Tunnel with
   mTLS for the custom-skill endpoint.

## 9. Data & privacy

- All family data persists on the home server (FamilyApp backend + Mealie + Donetick + CalDAV).
- No account on any third-party service is required to run the app on the home LAN.
- The **only** data that leaves the house is: (a) if Alexa is enabled, the voice transcript and
  spoken answer (via Amazon — documented non-goal of privacy for that path); (b) if Cloudflare
  Tunnel/Lambda is used for Alexa, that request path. Everything else stays local.
- Backups are encrypted and pushed to Synology on a schedule; Synology need not run 24/7.

## 10. Success criteria

- The whole family (incl. the second parent and the kids) actually uses it within a month.
- "What's for dinner / what's on this week / what are my chores" answerable in <3 seconds on
  the hub, and by voice.
- Adding an event/task/idea takes seconds, from any device.
- Runs unattended on home hardware at low power; survives a vendor (Amazon/Apple) policy change
  with core features intact.

## 11. Research caveats

Pricing, hardware power figures, eMMC-wear percentages, and some project stats in the source
research were single-sourced or vendor-blocked (HTTP 403). Treat specific numbers as indicative
and verify on live pages before committing hardware/spend. See the ⚠️ flags in
[`competitive-research.md`](./competitive-research.md).
