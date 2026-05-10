---
name: NeedLink project context
description: NeedLink project structure, tech stack, and current state
type: project
---

NeedLink is a donation coordination platform for Uganda (in-kind donations only, no payments).

**Why:** Connect NGOs and donors for physical item donations (food, clothing, medicine, supplies).

**Structure:**
- `needlink_web/` — React + Vite + Tailwind (NGO web dashboard + donor browse)
- `needlink_mobile/` — Flutter mobile app (donors primary, NGO admins secondary)
- `design-system/needlink/MASTER.md` — UI design system (Fira Code/Fira Sans, #0891B2 primary, #EA580C accent)

**Roles:** `donor` (browse/pledge) and `ngo_admin` (post needs/manage pledges/confirm deliveries)

**Backend:** Supabase (free tier) — credentials go in `needlink_web/.env` (VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY) and Flutter `--dart-define` flags.

**How to apply:** When the user asks to add features, check the existing screens/pages structure first and follow existing patterns.
