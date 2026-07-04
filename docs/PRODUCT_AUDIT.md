# CrossBall — Global Launch Product Audit

**Document type:** Senior cross-functional product audit  
**Audience:** Engineering, Product, Design, Growth, Security, QA  
**Version audited:** 1.0.0+1 (Flutter client + Supabase backend, migrations 001–020)  
**Audit date:** July 2026  
**Prepared as:** Staff Flutter · Mobile Architect · PM · UX Research · UI Design · Game Design · Security · Performance · Backend · LiveOps · Growth · Accessibility · QA · ASO

---

## Executive Verdict

CrossBall has a **strong product foundation**: a differentiated football intersection mechanic, a polished visual direction ("Elite Tactical Grid"), server-side answer validation, a data-driven puzzle engine, and thoughtful freemium architecture (practice quota, ad gates, premium tier).

**It is not yet ready for a global App Store feature launch.**

The gap is not vision — it is **trust, polish, and retention depth**. Critical security holes allow premium bypass and score farming. UX has navigation bugs, inconsistent visual language, and zero accessibility investment. Game design has a solid core loop but lacks visible progression hooks (achievements UI, missions, social proof). Retention systems exist in the database (GEE/LOE) but are largely invisible to players.

**Launch readiness score (internal estimate):**

| Dimension | Score | Notes |
|-----------|-------|-------|
| Core gameplay | 8/10 | Mechanic is compelling for football fans |
| Visual design | 7/10 | Strong system; inconsistent application |
| UX flows | 6/10 | Critical nav bug; error states weak |
| Security | 3/10 | Client-trusted economy — blocker |
| Retention design | 5/10 | Streak/XP exist; achievements invisible |
| Monetization ethics | 7/10 | No pay-to-win; premium bypassable |
| Accessibility | 2/10 | No Semantics layer |
| App Store readiness | 5/10 | Would pass review; unlikely to be featured |
| Scalability | 7/10 | Good backend separation; RPC exposure risk |
| Test/CI maturity | 5/10 | Logic tests only; no E2E |

**Recommendation:** Do **not** launch globally until Priority 1 security and UX blockers are resolved. Soft launch in one market after P1 + selected P2 items (~6–8 weeks focused work).

---

## Table of Contents

1. [Audit Methodology](#1-audit-methodology)
2. [Product & Game Design](#2-product--game-design)
3. [Retention & Engagement](#3-retention--engagement)
4. [Monetization](#4-monetization)
5. [UX & UI Review](#5-ux--ui-review)
6. [Accessibility](#6-accessibility)
7. [Security Audit](#7-security-audit)
8. [Performance & Architecture](#8-performance--architecture)
9. [Backend & Data Integrity](#9-backend--data-integrity)
10. [LiveOps & Growth](#10-liveops--growth)
11. [App Store & ASO Readiness](#11-app-store--aso-readiness)
12. [Quality & Technical Debt](#12-quality--technical-debt)
13. [Innovation Backlog (New Features)](#13-innovation-backlog-new-features)
14. [Prioritized Roadmap](#14-prioritized-roadmap)
15. [Recommendation Register](#15-recommendation-register)

---

## 1. Audit Methodology

Full codebase review across:

- **16 presentation screens** + **9 shared widgets**
- **17 Supabase edge functions** + **20 SQL migrations**
- **Python data pipeline** (ETL, dedup, club graph)
- **12 Flutter test files**, CI workflows
- Existing docs: `ARCHITECTURE.md`, `CROSSBALL_FULL_ANALYSIS.md`, `TESTING.md`, Stitch design system

Each recommendation follows:

| Field | Description |
|-------|-------------|
| **Problem** | What is wrong or missing |
| **Why it matters** | Business/technical/user rationale |
| **User impact** | How players experience it |
| **Technical solution** | Concrete fix |
| **Complexity** | S (days) · M (1–2 wks) · L (3+ wks) · XL (epic) |
| **Priority** | P1 Critical · P2 High · P3 QoL · P4 Future |
| **Expected benefit** | Measurable outcome |

---

## 2. Product & Game Design

### 2.1 Core Loop Assessment

**Strengths**
- Intersection mechanic is intuitive and uniquely football-native
- Rarity scoring rewards expert knowledge (mythic picks feel great)
- Server validation prevents obvious client-side cheating on *answers*
- Daily puzzle creates shared social context for challenges

**Weaknesses**
- Daily puzzle is **passive** — no pre-game hype, no "today's clubs" teaser with mystery
- Practice mode lacks **session identity** (no "Training #3", no personal bests per grid)
- No **post-game insight** ("You knew 2 mythic players — top 5% of users")
- Friend Challenge is async but **emotionally flat** — no taunt, no rematch, no notification

### 2.2 Daily Challenge — Game Design Review

| Question | Assessment |
|----------|------------|
| Engaging enough? | **Moderate.** One puzzle/day is industry-standard (Wordle-like) but needs streak visibility + share card |
| Difficulty curve? | Backend uses `hard` tier — may frustrate casual users Day 1 |
| Replay value? | Zero after completion — correct for daily, but no "review grid" mode |
| Social hook? | Challenge creation exists but buried in result screen |

**Recommendation:** Add daily completion share card (image: grid + score + streak). Consider `medium` tier for first 7 days (LiveOps cohort flag).

### 2.3 Practice Mode — Game Design Review

| Question | Assessment |
|----------|------------|
| Replayability? | **Good** with unique puzzles per session; ad friction may feel punitive at session 2 |
| Early finish? | Smart business rule; needs clearer UX copy ("Uses 1 of 5 credits") |
| Skill progression? | No visible "training level" or club mastery |
| Expert retention? | Experts will hit 5/day quickly — premium upsell is correct |

**Recommendation:** Introduce **Club Mastery** counters (times you've solved intersections involving Bayern, etc.) — data already exists in answers once server-side logging is fixed.

### 2.4 Scoring Fairness

| Vector | Status |
|--------|--------|
| Speed bonus | Fair — rewards quick thinking |
| Hint penalty | Fair — 5 pts/hint |
| Mistake penalty | Client-only on cells; session mistakes tracked |
| Premium score multiplier | Locked at 1.0 in GEE — **excellent** (no pay-to-win) |
| Challenge adjusted score | Server formula exists — **but inputs are client-trusted** |

**Exploit:** Submit fabricated `final_score` via API. See Security §7.

### 2.5 Hints — Game Design Review

Hint sequence (nationality → position → letter → league → retired → career club) is **well-designed pedagogically** — escalates specificity without spoiling immediately.

**Issue:** Premium-only career club is the most valuable hint but free users never taste it → weak premium conversion hook. Consider **one free taste** of career club hint per week.

### 2.6 Friend Challenge — Game Design Review

| Element | Assessment |
|---------|------------|
| Fun factor? | Moderate — score compare works; no in-app social layer |
| Friction? | Must complete daily first — good for daily retention, bad for viral loop |
| Code entry UX? | 8-char code — acceptable; deep link is better |
| Rematch? | None — missed engagement |

**Recommendation:** Allow challenge from **any completed session** (daily or practice), not only daily. Add "Rematch" CTA on challenge result.

### 2.7 Difficulty & Expert Retention

Expert football fans will engage if:
1. Mythic/legendary picks feel **recognized and celebrated** (animation, sound, haptic)
2. **Obscure player validation** feels fair (career detail sheet on long-press)
3. **Knowledge milestones** exist ("100 correct answers", "50 clubs mastered")

Currently: rarity tier shown in answer sheet — **good start**, no cumulative knowledge identity.

---

## 3. Retention & Engagement

### 3.1 Retention Model (Current State)

| Hook | Implemented | Visible to User |
|------|-------------|-----------------|
| Daily streak | ✅ Backend + home badge | ✅ |
| XP / Level | ✅ GEE | ✅ Home strip |
| Competitive rating | ✅ GEE | ✅ Stats |
| Achievements | ✅ DB definitions | ❌ No UI |
| Daily missions | ✅ DB definitions | ❌ No UI |
| Seasons | ✅ DB | ❌ No UI |
| Push reminders | ❌ FCM stub | ❌ |
| Community goals | ✅ LiveOps | ✅ Home (passive) |
| Social sharing | Partial | Challenge link only |
| Profile customization | Nickname only | Partial |

### 3.2 Retention Risk Analysis

| Day | Risk | Cause |
|-----|------|-------|
| D1 | Medium | Onboarding is generic; first daily may be too hard |
| D3 | High | No push; no mission UI; practice ads annoy |
| D7 | High | Streak milestone XP exists server-side but **no celebration UI** |
| D30 | Very high | No season pass, no collections, no friend activity feed |

### 3.3 Retention Recommendations (Summary)

See [§15 Recommendation Register](#15-recommendation-register) for full entries. Top retention bets:

1. **Achievement toast + gallery** (P2) — GEE data already computed
2. **Daily mission card on home** (P2) — "Solve 3 cells with rare+ picks"
3. **Push: streak at risk** (P2) — FCM + timezone-aware evening reminder
4. **Share card on daily complete** (P2) — Wordle-style viral loop
5. **7-day streak celebration** (P3) — modal + exclusive badge frame

---

## 4. Monetization

### 4.1 Current Model Assessment

| Stream | Fit | Risk |
|--------|-----|------|
| Banner | Standard; non-intrusive placement | Layout jump when ad loads |
| Interstitial | Post-daily/challenge — acceptable | None on practice — good |
| Rewarded | Practice unlock + hints — ethical | Server doesn't verify ad watched |
| Premium IAP | Clear value prop | **Bypassable via API** |

**Verdict:** Model structure is **industry-standard and ethical** (no pay-to-win). Execution is undermined by security gaps and weak premium conversion UX.

### 4.2 Premium Value Proposition Review

| Promised | Delivered | Gap |
|----------|-----------|-----|
| 10 ad-free practice | ✅ (if server quota trusted) | Bypassable premium flag |
| Advanced stats | ✅ Rarity breakdown | Rest of stats free — OK |
| No ads | ✅ Client-side | — |
| Exclusive themes | ❌ Mentioned in copy | **Not implemented** |
| 4×4 grid | ❌ Documented | **Not implemented** |

**ASO risk:** Premium screen promises features that don't exist → refund risk / review complaints.

### 4.3 Ethical Monetization Improvements

Premium features users **would happily pay for** (no gameplay advantage):

1. **Cosmetic themes** — alternate pitch skins, badge frames (already in theme system)
2. **Puzzle replay history** — review past dailies
3. **Advanced analytics** — heatmap of best clubs, avg rarity tier, response time trends
4. **Profile flair** — animated nickname, season badges
5. **Early access** — tomorrow's club hints (not answers)

**Never add:** Score multipliers, exclusive players, pay-to-skip rarity penalty.

---

## 5. UX & UI Review

### 5.1 Screen-by-Screen Verdict

| Screen | Grade | Top Issue |
|--------|-------|-----------|
| Home | B- | Fake 35% XP while loading; quick nav fall-through **(fixed in this audit)** |
| Onboarding | B+ | Generic; no interactive demo cell |
| Puzzle (play) | B | Full-screen rebuilds; 8px solved names |
| Puzzle (ad gate) | A- | Clear value prop |
| Puzzle (result) | B+ | Good hierarchy; no celebration animation |
| Player search modal | B+ | Close icon non-functional; no recent picks |
| Challenge | C+ | Plain Card; no scroll; silent errors |
| Stats | C+ | Raw error text; English rarity labels |
| Premium | B- | No purchase failure feedback; non-scrollable |
| Settings | B | Profile error hidden; misleading "Coming soon" loading |
| LiveOps widgets | C | Material Card vs glass system |

### 5.2 Visual System Consistency

**Three visual dialects coexist:**
1. Glass morphism (`CrossBallGlassPanel`) — Home, Settings, Search modal
2. Material `Card` — Challenge, Stats lock, LiveOps
3. Custom `DecoratedBox` — Puzzle grid, answer sheet

**World-class apps have one dialect.** Unify on glass system.

### 5.3 Navigation Architecture

| Issue | Severity |
|-------|----------|
| Quick nav only on Home | Confusing — Stats tab doesn't persist nav |
| `context.push` stacks routes | Back stack clutter from bottom nav |
| No shell route | Each screen isolated |
| Challenge result: home-only exit | OK |

**Recommendation:** Implement `StatefulShellRoute` with 4 branches (Home, Practice, Stats, Settings).

### 5.4 Micro-interactions & Animation Opportunities

| Moment | Current | Opportunity |
|--------|---------|-------------|
| Correct answer | Static sheet | Confetti for mythic; haptic light |
| Cell solved | Green fill | Particle burst on rarity tier |
| Daily complete | Trophy icon | Score count-up animation |
| Streak increment | None visible | Fire animation on home |
| Level up | None | Full-screen level-up modal (GEE event) |
| Practice ad gate | Static | Progress ring animation |

### 5.5 Error & Loading UX

| Pattern | Status |
|---------|--------|
| Branded loading (lime spinner) | Puzzle only |
| Skeleton screens | None |
| Retry with explanation | Partial |
| Raw exception strings | Stats, generic puzzle errors |
| Offline indicator | None visible |

---

## 6. Accessibility

### 6.1 Current State: Non-Compliant

**Zero** `Semantics`, `Tooltip`, or `semanticLabel` usage in `lib/`.

| Criterion | Status |
|-----------|--------|
| WCAG contrast (glass on dark) | Mostly OK; lime on dark passes |
| Touch targets (44×44pt) | Grid cells OK; hint chips small |
| Dynamic Type / text scaling | Not tested; fixed font sizes |
| VoiceOver / TalkBack | Grid cells unreadable as buttons |
| Color-blind safe states | Solved=green, selected=lime — distinguishable but no pattern |
| Reduce Motion | Pulse animation ignores system setting |
| Haptic feedback | None |

### 6.2 Accessibility Launch Blockers (App Store)

Apple does not always reject for accessibility, but **featured apps require strong a11y**. Minimum for launch:

1. Semantics on grid cells, buttons, progress
2. `MediaQuery.disableAnimations` respect in grid pulse
3. Localized strings (including SELECT, rarity tiers)
4. Minimum 12sp for solved player names (currently 8sp)

---

## 7. Security Audit

### 7.1 Threat Model

```
Attacker with: Supabase anon key (extractable from app bundle)
Can: Impersonate any user_uuid, call all edge functions and anon-granted RPCs
Cannot (today): Access service role key (not in client)
```

### 7.2 Critical Findings

#### SEC-01: Client-writable premium flag
- **Problem:** `sync-user` accepts `is_premium` from request body without IAP receipt validation
- **Why it matters:** Entire premium revenue model bypassed
- **User impact:** Cheaters get ad-free experience; paying users feel devalued
- **Solution:** Remove `is_premium` from client-writable fields; verify Apple/Google receipts server-side; set `premium_until`
- **Complexity:** L
- **Priority:** P1
- **Benefit:** Revenue integrity

#### SEC-02: Score / XP / rating client-controlled
- **Problem:** `complete-session` trusts client `final_score`, rarity counts, `is_perfect`
- **Why it matters:** Leaderboard and progression meaningless
- **User impact:** Competitive players abandon when cheaters dominate
- **Solution:** Server-side session: record each `validate-answer` in `answers` table; recompute score on complete; reject mismatch > tolerance
- **Complexity:** XL
- **Priority:** P1
- **Benefit:** Fair competition; trustworthy stats

#### SEC-03: `gee_process_event` callable by anon key
- **Problem:** `GRANT EXECUTE ... TO anon` on economy RPC (migration 011)
- **Why it matters:** Direct REST RPC bypasses all edge function logic
- **Solution:** Revoke anon grant; only service role via edge functions
- **Complexity:** S
- **Priority:** P1
- **Benefit:** Closes largest exploit surface

#### SEC-04: No request authentication
- **Problem:** All edge functions `verify_jwt = false`; identity = spoofable `user_uuid`
- **Solution:** Supabase Anonymous Auth JWT bound to device; or HMAC-signed device token
- **Complexity:** L
- **Priority:** P1
- **Benefit:** User impersonation prevention

### 7.3 High Findings

| ID | Issue | Priority |
|----|-------|----------|
| SEC-05 | Anti-cheat entirely client-side; server trusts `is_suspicious` | P1 |
| SEC-06 | Replay attacks on `complete-session` (no idempotency) | P1 |
| SEC-07 | `grant_practice_ad_unlock` without ad verification | P2 |
| SEC-08 | Challenge scores client-reported | P2 |
| SEC-09 | `player_progression` SELECT granted to anon (data leak) | P2 |
| SEC-10 | `validate-answer` ignores session_id; answers not persisted | P2 |
| SEC-11 | `request-hint` no server-side premium/ad gate | P2 |
| SEC-12 | Practice quota RPCs granted to anon | P2 |

### 7.4 Medium Findings

| ID | Issue | Priority |
|----|-------|----------|
| SEC-13 | Timezone offset client-controlled (quota reset abuse) | P2 |
| SEC-14 | No rate limiting on any endpoint | P2 |
| SEC-15 | Daily reward farmable via repeated complete-session | P2 |
| SEC-16 | Challenge codes brute-forceable (8 char, no rate limit) | P3 |
| SEC-17 | Push token registration for arbitrary user_uuid | P3 |

---

## 8. Performance & Architecture

### 8.1 Performance Findings

| ID | Issue | Impact | Priority |
|----|-------|--------|----------|
| PERF-01 | Full `PuzzleScreen` rebuild on every cell tap | Jank on low-end devices | P2 |
| PERF-02 | GoRouter recreated on theme/locale change | Navigation stack reset | P1 |
| PERF-03 | Triple practice quota sync on puzzle load | 3× API latency | P2 |
| PERF-04 | 9× AnimationController in grid (one per cell) | Memory + CPU | P3 |
| PERF-05 | No `RepaintBoundary` on grid | Repaint propagation | P3 |
| PERF-06 | Home watches 7 providers → full ListView rebuild | Jank on LiveOps update | P3 |
| PERF-07 | Banner ad layout jump (shrink until loaded) | CLS-style UX issue | P3 |

### 8.2 Architecture Findings

| ID | Issue | Priority |
|----|-------|----------|
| ARCH-01 | `createSession()` is client UUID only — no server session | P1 |
| ARCH-02 | `completeSession()` only queues offline — no online path | P2 |
| ARCH-03 | `http.Client` never disposed in repositories | P3 |
| ARCH-04 | `puzzleGameProvider` family without `autoDispose` | P2 |
| ARCH-05 | Demo fallback silently masks API failures in production | P2 |
| ARCH-06 | No global error handler (`FlutterError.onError`) | P2 |
| ARCH-07 | `dailyPuzzleProvider` defined but unused | P4 |
| ARCH-08 | AuthRemoteDataSource instantiated outside DI in locale/theme providers | P3 |

### 8.3 Scalability Assessment

**Backend:** Puzzle generation is DB-heavy but edge-function isolated. `club_relationships` graph refresh is batch — OK for 100 clubs. At 1M DAU, `validate-answer` and `search-players` need connection pooling + read replicas + rate limits.

**Client:** Offline-first cache is appropriate. Pending session queue needs deduplication before scale.

---

## 9. Backend & Data Integrity

### 9.1 Strengths

- Puzzle generation engine with quality gates — **rare in indie titles**
- Club slug aliasing + equivalence — handles data messiness
- GEE/LOE data-driven config — ops-friendly
- Practice quota server-side (migration 020) — correct direction

### 9.2 Gaps

| Area | Issue |
|------|-------|
| Answer audit trail | `answers` table never populated by API |
| Session lifecycle | No server `session_start` RPC |
| Idempotency | No unique constraint on completed session rewards |
| RLS | Enabled but empty policies; `player_progression` exposed |
| Premium | `premium_until` column unused |

---

## 10. LiveOps & Growth

### 10.1 Current LiveOps Maturity

| Capability | Status |
|------------|--------|
| Remote config | ✅ |
| Feature flags | ✅ Used on home |
| Announcements | ✅ |
| Community goals | ✅ Display only |
| A/B experiments | ✅ Backend; not used client-side |
| Events | ✅ Cards go to daily — not event-specific |
| Push campaigns | ❌ |

### 10.2 Growth Recommendations

1. **Daily share card** — organic acquisition (P2)
2. **Streak push notification** — D7 retention (P2)
3. **Challenge deep link landing** — improve conversion from shared links (P2)
4. **Referral:** "Invite friend, both get cosmetic" (P4)
5. **ASO keywords:** football quiz, soccer trivia, wordle football (§11)

---

## 11. App Store & ASO Readiness

### 11.1 Would Apple/Google Feature This?

**Not yet.** Featured apps demonstrate:
- Polished, consistent UI → CrossBall: **mixed Card/Glass**
- Accessibility → CrossBall: **missing**
- Unique mechanic → CrossBall: **yes ✓**
- Social/share loop → CrossBall: **weak**
- Privacy nutrition labels → Need audit for PostHog, AdMob, Supabase

### 11.2 App Store Rejection Risks

| Risk | Severity |
|------|----------|
| Premium promises non-existent features (themes, 4×4) | Medium |
| IAP not functional in review build | High if IAP_ENABLED=false |
| AdMob without ATT prompt (iOS) | High |
| Privacy policy missing third-party SDK disclosure | Medium |
| Crash on navigation edge cases | Low |

### 11.3 ASO Recommendations

| Element | Recommendation |
|---------|----------------|
| Title | CrossBall — Football Quiz Grid |
| Subtitle | Connect clubs. Name the player. |
| Keywords | football quiz, soccer trivia, wordle, daily puzzle, club quiz |
| Screenshots | Show mythic pick moment, streak, challenge compare |
| Preview video | 15s: tap cell → search → mythic celebration → share |
| Localization | EN + TR + DE store listings (app already supports) |

### 11.4 Pre-Launch Checklist

- [ ] ATT (App Tracking Transparency) flow for iOS ads
- [ ] Privacy policy URL in app + store
- [ ] IAP receipt validation server-side
- [ ] Remove or implement premium feature promises
- [ ] Force `IAP_ENABLED=true` in production `.env`
- [ ] Remove `FORCE_FREE_TIER` from production builds
- [ ] TestFlight / Internal testing with real Supabase + ads
- [ ] Crash reporting (Firebase Crashlytics or Sentry)

---

## 12. Quality & Technical Debt

### 12.1 Test Coverage

| Layer | Coverage |
|-------|----------|
| Pure logic (scoring, rarity, quota) | Good |
| Widgets | Minimal (grid smoke) |
| Notifiers (PuzzleGameNotifier) | None |
| Repositories | None |
| Edge functions | None (contract tests) |
| E2E | None |

### 12.2 CI Gaps

- Flutter SDK not pinned
- No `dart format` check
- No coverage threshold
- No build smoke (apk/ipa)
- No integration tests

### 12.3 Documentation Debt

| Doc | Status |
|-----|--------|
| ARCHITECTURE.md | Good but migration range outdated (015 vs 020) |
| README | Lists 4×4 premium — not implemented |
| CROSSBALL_FULL_ANALYSIS.md | Comprehensive |
| API contracts | Partial in ARCHITECTURE.md |

### 12.4 Code Smells

- Duplicated practice gate logic (provider + notifier + UI)
- Silent `catch (_) {}` in repositories
- Hardcoded English strings in grid, splash, stats
- `interstitialEveryNPractice` constant unused
- Splash route registered but unused

---

## 13. Innovation Backlog (New Features)

Prioritized by **engagement × feasibility**:

| Feature | Engagement | Complexity | Priority |
|---------|------------|------------|----------|
| Achievement gallery + toasts | High | M | P2 |
| Daily missions on home | High | M | P2 |
| Share card (daily result image) | High | M | P2 |
| Club Mastery progression | High | L | P2 |
| Puzzle replay / history | Medium | M | P3 |
| Player career visualization (cell detail) | High | L | P3 |
| Knowledge levels (Novice → Legend) | Medium | M | P3 |
| Season pass (cosmetic-only) | High | XL | P4 |
| Community weekly challenge | High | L | P4 |
| Football timeline mode (historical squads) | Medium | XL | P4 |
| AI-generated fun facts post-answer | Medium | L | P4 |
| Live match day themed puzzles | High | L | P4 |
| Leaderboard (rating-based) | High | L | P2 |
| Friend activity feed | Medium | XL | P4 |
| Country/League mastery tracks | Medium | L | P4 |

Full prioritized mode backlog (12 modes) and **Club × Nationality** implementation spec: [GAME_MODES_BACKLOG.md](./GAME_MODES_BACKLOG.md).

---

## 14. Prioritized Roadmap

### Phase 0 — Launch Blockers (P1) — Est. 4–6 weeks

| # | Item | Complexity | Impact |
|---|------|------------|--------|
| 1 | Revoke anon RPC grants (gee, quota) | S | Critical security |
| 2 | Server-side session + answer logging | XL | Score integrity |
| 3 | IAP receipt validation; remove client premium write | L | Revenue |
| 4 | Supabase Anonymous Auth or signed tokens | L | Identity |
| 5 | Idempotent complete-session | M | Anti-farm |
| 6 | Fix GoRouter recreation | M | Navigation stability |
| 7 | ATT + privacy policy + production env flags | M | Store approval |
| 8 | Remove/fix false premium promises | S | Store compliance |

### Phase 1 — High Impact (P2) — Est. 4–6 weeks

| # | Item | Complexity | Impact |
|---|------|------------|--------|
| 9 | Achievement UI + celebration | M | D7 retention |
| 10 | Daily missions card | M | D3 retention |
| 11 | FCM push (streak reminder) | L | D7/D30 retention |
| 12 | Share card on daily complete | M | Organic growth |
| 13 | Unify Card → GlassPanel | M | Visual polish |
| 14 | Accessibility pass (Semantics, font sizes) | M | Featured eligibility |
| 15 | Server-side hint/ad gate | M | Monetization integrity |
| 16 | Rate limiting on edge functions | M | Abuse prevention |
| 17 | Puzzle performance (selective watch, autoDispose) | M | Smooth gameplay |
| 18 | Leaderboard (rating) | L | Competitive retention |
| 19 | Error UX + l10n gaps | M | Polish |
| 20 | RLS on player_progression | S | Privacy |

### Phase 2 — Quality of Life (P3) — Est. 3–4 weeks

| # | Item | Complexity | Impact |
|---|------|------------|--------|
| 21 | StatefulShellRoute bottom nav | L | Navigation UX |
| 22 | Cosmetic premium themes (deliver promise) | M | Premium conversion |
| 23 | Recent picks in search modal | S | Search UX |
| 24 | Challenge from any completed session | S | Viral loop |
| 25 | Micro-interactions (mythic celebration) | M | Delight |
| 26 | Banner ad reserved height | S | Layout stability |
| 27 | Expand test coverage + CI hardening | L | Quality |
| 28 | Rematch on challenge result | M | Social engagement |

### Phase 3 — Future (P4) — Ongoing

Club Mastery, Season Pass, Timeline mode, AI facts, live matchday events, friend activity feed, 4×4 premium grid (if desired), tournament mode.

---

## 15. Recommendation Register

Full register of auditable recommendations. **IMP = Implemented in this audit pass.**

| ID | Problem | Why it matters | User impact | Technical solution | Complexity | Priority | Expected benefit |
|----|---------|----------------|-------------|-------------------|------------|----------|------------------|
| UX-01 | Quick nav switch fall-through | Tapping Practice also opens Stats+Settings | Confusion, stack clutter | Add `break` statements | S | P1 | **IMP:** Fixed in `home_screen.dart` |
| UX-02 | Fake 35% XP progress while loading | Misleading progress | Trust erosion | Show skeleton or null until loaded | S | P2 | Honest loading UX |
| UX-03 | Hardcoded "SELECT" on grid | Breaks TR/DE | Non-native feel | Add l10n key | S | P2 | Localization complete |
| UX-04 | 8px solved player names | Unreadable | Accessibility fail | Min 12sp, truncate with ellipsis | S | P2 | Readability |
| UX-05 | Raw error strings in UI | Scary/confusing errors | Bad experience | Map to l10n + retry | M | P2 | Professional polish |
| UX-06 | Card vs Glass inconsistency | App feels unfinished | Visual distrust | Migrate Challenge/Stats/LiveOps to glass | M | P2 | Featured-quality UI |
| UX-07 | Premium screen not scrollable | Overflow on large text | Broken layout | Wrap in SingleChildScrollView | S | P3 | Robustness |
| UX-08 | Search modal close icon dead | Expected dismiss | Frustration | Wire to Navigator.pop | S | P3 | Expected behavior |
| UX-09 | No mythic celebration | Best moment feels flat | Less delight | Animation + haptic on mythic | M | P3 | Expert retention |
| UX-10 | Banner layout jump | Jarring reflow | Cheap feel | Reserve ad height | S | P3 | Polish |
| SEC-01 | Premium bypass | Revenue loss | Paying users devalued | Receipt validation server-side | L | P1 | Revenue integrity |
| SEC-02 | Score tampering | Unfair competition | Quit competitive players | Server-side score recompute | XL | P1 | Trust |
| SEC-03 | Anon RPC on gee_process_event | Unlimited XP farm | Broken economy | Revoke anon grant | S | P1 | Closes exploit |
| SEC-04 | No auth on APIs | Impersonation | Account takeover feel | Anonymous Auth JWT | L | P1 | Security baseline |
| SEC-05 | Client-only anti-cheat | Cheaters ignored | Unfair | Server heuristics + answer timing | L | P1 | Fair play |
| SEC-06 | Replay complete-session | Reward farming | Inflated stats | Idempotency key + status check | M | P1 | Economy integrity |
| SEC-07 | Ad unlock without proof | Free premium practice | Ad revenue loss | AdMob SSV callback | M | P2 | Ad integrity |
| PERF-01 | Full puzzle screen rebuild | Jank | Sluggish taps | Selective ref.watch + Equatable state | M | P2 | 60fps gameplay |
| PERF-02 | GoRouter in build | Stack reset on theme change | Lost navigation | Provider-held router | M | P1 | Stability |
| PERF-03 | Triple quota sync | Slow practice start | Wait time | Single sync at entry | S | P2 | Faster start |
| GD-01 | No achievement UI | No completionist hook | Shorter sessions | Achievement gallery | M | P2 | D7 +15% target |
| GD-02 | Daily too hard for D1 | Churn | Quit day 1 | LiveOps easy tier for new users | M | P2 | D1 retention |
| GD-03 | Challenge requires daily | Viral friction | Fewer shares | Allow practice-origin challenges | S | P3 | Viral coefficient |
| RET-01 | No push | No D1/D7 reminder | Forgotten app | FCM + streak at risk | L | P2 | D7 +20% target |
| RET-02 | No share card | No organic growth | Less discovery | Share image generation | M | P2 | K-factor |
| MON-01 | Premium promises themes | Refund risk | Anger | Implement or remove from copy | M | P2 | Store compliance |
| MON-02 | Free taste of career hint | Weak premium hook | No upgrade desire | 1 free career hint/week | S | P3 | Premium conversion |
| A11Y-01 | Zero Semantics | Screen reader broken | Excluded users | Semantics on interactive elements | M | P2 | Inclusion + featured |
| A11Y-02 | Ignore reduce motion | Vestibular issues | Discomfort | Check disableAnimations | S | P3 | Accessibility |
| ASO-01 | No ATT prompt | iOS rejection | Can't launch iOS ads | AppTrackingTransparency flow | S | P1 | iOS launch |
| ASO-02 | No crash reporting | Blind to crashes | Bad reviews | Crashlytics/Sentry | S | P1 | Quality visibility |
| ARCH-01 | No server session start | No audit trail | Can't verify play | session_start RPC | L | P1 | Security foundation |
| QA-01 | No notifier tests | Regressions undetected | Bugs in production | PuzzleGameNotifier test suite | M | P2 | Regression safety |
| QA-02 | CI not pinned | Non-reproducible builds | CI/local drift | Pin Flutter in workflow | S | P3 | DevEx |

---

## Appendix A: Phases 0–5 Implementation Summary

| Phase | Focus | Key deliverables |
|-------|-------|------------------|
| **0** | Security | Migration 021, server sessions, authoritative scoring, ATT |
| **1** | Retention UI | Leaderboard, missions, achievements, FCM hooks, share, glass UI |
| **2** | Navigation & polish | StatefulShellRoute, premium themes, recent picks, mythic celebration, rematch |
| **3** | Mastery & grid | Club mastery, season card, 4×4 premium grid, career hint taste |
| **4** | Social & LiveOps | Timeline mode, activity feed, football facts, tournament |
| **5** | Launch polish | iOS ATT, error reporting, XP skeleton, contrast-safe typography |
| **Club Identity** | Legal-safe badges | 105 curated clubs, procedural badges, migration 025 |

See [`PHASE0_SECURITY.md`](PHASE0_SECURITY.md) for migration 021 deploy steps.

---

## Appendix B: Related Documents

- [`CROSSBALL_FULL_ANALYSIS.md`](CROSSBALL_FULL_ANALYSIS.md) — Comprehensive product/technical reference
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — System design and API contracts
- [`TESTING.md`](TESTING.md) — QA checklist
- [`design/stitch/DESIGN.md`](../design/stitch/DESIGN.md) — Visual design system

---

## Appendix C: Audit Team Sign-Off Summary

| Role | Key message |
|------|-------------|
| **Staff Flutter Engineer** | Solid Riverpod architecture; fix router stability and puzzle rebuild hot path before scale |
| **Mobile Architect** | Server-authoritative sessions are the missing foundation for everything else |
| **Product Manager** | Core loop works; retention layer is 80% built in DB, 20% visible — ship the UI |
| **UX Researcher** | Ad gate is clear; daily onboarding and error states need user testing |
| **UI Designer** | Elite Tactical Grid is strong — enforce it everywhere, add celebration moments |
| **Game Designer** | Mechanic survives expert scrutiny; add mastery + knowledge identity |
| **Security Engineer** | Do not launch globally until SEC-01 through SEC-06 resolved |
| **Performance Engineer** | Acceptable for beta; optimize puzzle provider before 100k DAU |
| **Backend Architect** | Puzzle engine is a moat; lock down RPC grants immediately |
| **LiveOps Specialist** | LOE infrastructure excellent; wire events to meaningful client actions |
| **Growth PM** | Share card + push are highest ROI retention/acquisition levers |
| **Accessibility Specialist** | Not optional for featured placement — minimum Semantics pass required |
| **QA Lead** | Expand from logic tests to notifier + integration before launch |
| **ASO Specialist** | Unique mechanic is marketable; screenshots must show mythic moment |

---

*This audit assumes good faith users today but threat models malicious actors with the public anon key — standard for mobile Supabase apps. Treat client as fully compromised.*

*Phases 0–5 and Club Identity System shipped. Next review: store launch readiness (SEC-07 AdMob SSV, full crash SDK).*
