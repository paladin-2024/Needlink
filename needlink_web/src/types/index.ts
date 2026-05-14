import type { Tables, Enums } from './database.types'

// ── Enums (derived from DB) ──────────────────────────────────
export type Role         = Enums<'user_role'>
export type ItemCategory = Enums<'item_category'>
export type Urgency      = Enums<'urgency_level'>
export type NeedStatus   = Enums<'need_status'>
export type PledgeStatus = Enums<'pledge_status'>

// ── Row types (derived from DB) ──────────────────────────────
export type Profile  = Tables<'profiles'>
export type Ngo      = Tables<'ngos'>
export type Delivery = Tables<'deliveries'>

export type DonationNeed = Tables<'donation_needs'> & {
  ngo?: Ngo | null
}

export type Pledge = Tables<'pledges'> & {
  donation_need?: DonationNeed | null
  donor?: Pick<Profile, 'full_name' | 'phone'> | null
}
