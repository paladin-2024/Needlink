# NeedLink Platform Redesign — Design Spec
**Date:** 2026-05-14
**Status:** Approved for implementation

---

## 1. Overview

A full design elevation of the NeedLink platform covering:
- Mobile app (Flutter) — the primary surface for donors and NGO admins
- Web portal (React) — rebuilt from scratch as a super admin management portal

The redesign sharpens the existing cyan brand identity, fixes architectural scope issues, removes redundant screens, and elevates every surface with stronger hierarchy, purposeful animation, and consistent design tokens.

---

## 2. Design Direction

**Elevated Current** — keep the cyan/teal DNA but sharpen everything.

| Token | Value | Use |
|---|---|---|
| `kPrimary` | `#0891B2` | Buttons, progress fills, active states |
| `kPrimaryDark` | `#0E7490` | Hover/pressed states |
| `kForeground` | `#164E63` | Headings, primary text |
| `kDark` | `#071D2C` | Darkest text, sidebar backgrounds |
| `kAccent` | `#EA580C` | Secondary CTA, category highlights |
| `kMatched` | `#16A34A` | Success, confirmed, fulfilled |
| `kUrgent` | `#EF4444` | Urgent badges, errors, rejected |
| `kBackground` | `#F0FDFF` | App scaffold background |
| `kSurface` | `#FFFFFF` | Cards, sheets, nav bars |
| `kMuted` | `#E8F1F6` | Chip backgrounds, inactive states |
| `kMutedFg` | `#64748B` | Secondary text, labels |
| `kBorder` | `#E8EDF2` | Card borders, dividers |

**Typography** (unchanged — already strong):
- Headings: Sora, weight 700/800/900
- Body: Plus Jakarta Sans, weight 400/600/700/800
- Data/labels: JetBrains Mono, weight 400/500

---

## 3. What Gets Removed

### Web portal — delete entirely:
- `src/pages/Landing.tsx`
- `src/pages/auth/Register.tsx`
- `src/pages/donor/DonorHome.tsx`
- `src/pages/donor/MyPledges.tsx`
- `src/pages/donor/NeedDetail.tsx`
- `src/pages/ngo/NgoDashboard.tsx`
- `src/pages/ngo/NgoNeeds.tsx`
- `src/pages/ngo/NgoPledges.tsx`
- `src/pages/ngo/NgoReports.tsx`
- `src/pages/ngo/CreateNeed.tsx`

### Mobile app — delete:
- `lib/screens/donor/tracking_screen.dart` (list — replaced by expandable cards in Pledges)
- The `/donor/tracking` route entry in `router.dart`
- The Tracking tab entry from `DonorShell` in `widgets/app_shell.dart`

---

## 4. Mobile App Changes

### 4a. Auth screens — Floating Card + Google OAuth

**Pattern:** Full-bleed gradient background (top 45% of screen), white card slides up from the bottom (rounded top corners 24px), logo and tagline centered on the gradient.

**Card contents:**
- Title: "Join NeedLink" (register) / "Welcome back" (login)
- Donor / NGO Admin toggle — segmented control, full width, inside card
- "Continue with Google" button — prominent, full width, white with Google logo, subtle border
- OR divider
- Email + Password inputs (floating labels, 12px border-radius)
- Primary CTA button (gradient, full width, Sora font, 54px height)
- Footer link to toggle between login/register

**Google auth:** `supabase.auth.signInWithOAuth(provider: OAuthProvider.google)`. Role must be captured after Google sign-in via a role-selection sheet if the profile row doesn't exist yet.

**Web admin login:** Email + password only. No Google. Single centered card on a dark `#0C1A22` background. NeedLink logo + "Admin Portal" label above the card.

### 4b. Donor Home — Bento Editorial NeedCard

**Layout:**
- `SliverAppBar` with pinned search bar + horizontal category filter chips (unchanged pattern, elevated visuals)
- First card in list = **hero card** if a need is marked urgent: full-bleed gradient, large Sora title, inline progress + "Pledge" button
- Remaining cards = **compact list cards**: left-side color stripe (category color), title, NGO name, progress bar, metadata row

**Hero card anatomy:**
- Background: `linear-gradient(140deg, #0C4A6E, #0891B2)` with subtle dot-grid overlay (existing CustomPainter, keep)
- Urgency pill: red background, white text, uppercase "URGENT"
- Title: Sora 18px, weight 900, white
- NGO name: Plus Jakarta Sans 9px, white 70% opacity
- Progress: large percentage label (Sora, white) + remaining count + white fill bar
- "Pledge" button: white background, `#0891B2` text, 10px border-radius

**Compact list card anatomy:**
- White background, `kBorder` border, 14px border-radius
- Left stripe: 5px wide, color = category color (cyan=education, green=clothing, orange=medicine, etc.)
- Title: Plus Jakarta Sans 10px, weight 800, `kForeground`
- NGO + category: Plus Jakarta Sans 8px, `kMutedFg`
- Progress bar: 4px height, `kBorder` track, category color fill
- Metadata row: `percentage · N remaining` left, deadline right

### 4c. Donor Navigation — 3 tabs

Remove the Tracking tab. Donor shell now has:

| Index | Route | Label |
|---|---|---|
| 0 | `/donor` | Discover |
| 1 | `/donor/pledges` | Pledges |
| 2 | `/donor/profile` | Profile |

### 4d. Pledges screen — Expandable Cards (merged tracking)

**Header:** "My Pledges" title + subtitle "N active donations". Filter tabs: All / Active / Delivered.

**Card — collapsed state:**
- White card, 14px border-radius, shadow (`0 1px 6px rgba(0,0,0,0.06)`)
- Left side: need title (Sora 11px 900) + NGO name + quantity
- Right side: status badge pill + chevron `›`

**Card — expanded state (tapped):**
- Header area unchanged
- Expanded section: light `#F0FDFF` background, top divider
- Section label: "Delivery Timeline" (uppercase, 7px, muted)
- Timeline rows: dot (filled=done, outline=pending) + vertical connector line + label + timestamp
- Steps: Pledge Submitted → Confirmed by NGO → In Transit → Delivered
- Connector color: `kPrimary` for completed steps, `kBorder` for future steps

**Navigation:** Tapping a collapsed card expands it inline (AnimatedContainer). Existing `TrackingDetailScreen` route `/donor/tracking/:id` can remain for deep-link access but is no longer a tab.

### 4e. NGO Dashboard — Action-First

**Header (white):**
- Row: org name (Sora 13px 900) + "Post Need" button (cyan pill, top right)
- Subtitle: admin name + role
- Mini stats row: 3 tiles in `#F0FDFF` — Active Needs (cyan), To Confirm (red if > 0), Fulfilled %

**Body:**
- Section: "Needs Confirming" with red count pill. Each pledge card:
  - Avatar circle (donor initial, cyan gradient)
  - Donor name + quantity + delivery date
  - Need name in `kPrimary`
  - Action row: Reject (red ghost) + Confirm Pledge (cyan filled, 2x width)
- Section: "Active Needs" — compact tiles with left color stripe + name + inline progress bar + percentage

**Note:** "Post Need" button in header replaces the current FloatingActionButton.

### 4f. Other screens — elevation rules

Apply consistently across all remaining screens:

- **Cards:** Replace flat bordered cards with cards having `box-shadow: 0 2px 12px rgba(8,145,178,0.1), 0 1px 3px rgba(0,0,0,0.05)` — subtle cyan-tinted shadow
- **Section headers:** Sora font, 11-12px, weight 800, `kForeground`
- **Empty states:** Icon + heading (Sora 15px) + subtext (PJS 13px) + optional action button
- **Urgency badges:** Red pill with white text, uppercase — no emoji
- **Progress bars:** 6-8px height (currently 7px — keep), category-colored fill, `kMuted` track
- **Bottom navigation:** Keep current `NavigationBar` widget. Active indicator: pill shape, `kPrimary` background

---

## 5. Web Admin Portal (Full Rebuild)

### Architecture

Single-page app with a persistent labeled sidebar (layout C). Protected by super admin session only — no self-registration.

**Route structure:**
```
/login              → AdminLoginPage
/admin              → redirect to /admin/overview
/admin/overview     → OverviewPage
/admin/ngos         → NgoManagementPage
/admin/users        → UserManagementPage
/admin/needs        → NeedsOverviewPage
/admin/pledges      → PledgesOverviewPage
/admin/reports      → ReportsPage
/admin/settings     → SettingsPage
```

### Sidebar

Dark background `#0C1A22`, full height, 220px wide, fixed.

- Top: NeedLink logo + "Admin Portal" label (uppercase, letter-spaced, muted cyan)
- Section label "Management" → items: Overview, NGOs, Donors, Needs
- Section label "System" → items: Pledges, Reports, Settings
- Each nav item: dot indicator + label, active state = `rgba(8,145,178,0.2)` bg + `#7BC5D4` text
- Bottom: signed-in admin email + logout button

### Pages

**Overview:** 4 KPI cards (Total NGOs, Total Donors, Open Needs, Total Pledges) + 30-day pledge activity bar chart (Recharts) + pending NGO approvals list

**NGO Management:**
- KPI row: Total / Pending / Verified NGO counts
- Pending approval table: NGO name, location, registration number, Verify / Reject buttons
- All NGOs table: name, location, status chip, needs count, action menu

**User Management:**
- Donors table: name, email, join date, pledge count, status
- Suspend / Reinstate action per row

**Needs Overview:**
- All donation needs across all NGOs, filterable by status/category
- Read-only view for super admin (NGOs manage their own needs on mobile)

**Pledges Overview:** System-wide pledge list with status filter

**Reports:** Platform-wide analytics — fulfillment rate trend, top NGOs by pledges, category breakdown (pie chart), monthly growth

### Styling

Tailwind CSS 4, existing token names adapted:
- `primary`: `#0891B2`
- `foreground`: `#164E63`
- `background`: `#F0FDFF`
- `surface`: `#FFFFFF`
- `dark-sidebar`: `#0C1A22`

---

## 6. Google Auth Implementation

**Supabase config:** Enable Google OAuth provider in Supabase dashboard.

**Mobile flow:**
1. Tap "Continue with Google" → `supabase.auth.signInWithOAuth(provider: OAuthProvider.google, redirectTo: ...)`
2. After redirect: check if `profiles` row exists for `user.id`
3. If not: show role selection bottom sheet (Donor / NGO Admin), insert profile row, then route
4. If yes: read role, route to donor or NGO shell as normal

**Web admin:** Google auth disabled. Admin login is email/password only via `supabase.auth.signInWithPassword`. After login, the web app fetches `profiles.role` and redirects to `/login` if the value is not `super_admin`. The super admin account is created manually in Supabase Auth — there is no self-registration path for this role.

---

## 7. Screens Summary (Post-Redesign)

### Mobile
| Screen | Role | Status |
|---|---|---|
| LoginScreen | All | Rebuild (floating card + Google) |
| RegisterScreen | Donor + NGO | Rebuild (floating card + Google) |
| DonorHomeScreen | Donor | Rebuild (bento editorial cards) |
| NeedDetailScreen | Donor | Elevate (keep structure, sharpen visuals) |
| MyPledgesScreen | Donor | Rebuild (expandable cards + tracking) |
| TrackingDetailScreen | Donor | Keep (accessible via pledge card expand) |
| DonorProfileScreen | Donor | Elevate |
| NgoHomeScreen | NGO Admin | Rebuild (action-first) |
| CreateNeedScreen | NGO Admin | Elevate (keep 3-step form, sharpen) |
| NgoPledgesScreen | NGO Admin | Elevate |
| ImpactReportsScreen | NGO Admin | Elevate |
| NgoSettingsScreen | NGO Admin | Elevate |
| **TrackingScreen** | — | **Delete** |

### Web
| Page | Role | Status |
|---|---|---|
| AdminLoginPage | Super Admin | Build new |
| OverviewPage | Super Admin | Build new |
| NgoManagementPage | Super Admin | Build new |
| UserManagementPage | Super Admin | Build new |
| NeedsOverviewPage | Super Admin | Build new |
| PledgesOverviewPage | Super Admin | Build new |
| ReportsPage | Super Admin | Build new |
| SettingsPage | Super Admin | Build new |
| **All existing pages** | — | **Delete** |

---

## 8. Out of Scope

- Push notifications
- Real-time updates (Supabase Realtime)
- NGO registration flow on mobile (exists, unchanged)
- Database schema changes
- Supabase RLS policy changes




● The Google OAuth flow for mobile goes like this:
App → Google → Supabase callback → App deep link

Three things need to be correct:

  ---
1. Google Cloud Console → Web OAuth client → Authorized redirect URIs

Must have exactly (type it, don't paste):
https://bxkztuzxnjqrgpyisqmn.supabase.co/auth/v1/callback

  ---
- Redirect URLs: add mean

  ---
3. Supabase Dashboard → Authentication → Providers → Google

Make sure you used the Web client credentials (not the Android client):
- Client ID → from the Web OAuth client
- Client Secret → from the Web OAuth client

  ---
Do all three, save each one, then try Google Sign In again. Which step are you on? 