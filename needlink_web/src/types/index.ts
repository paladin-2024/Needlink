export type Role = 'donor' | 'ngo_admin'

export interface Profile {
  id: string
  full_name: string
  role: Role
  phone: string | null
  created_at: string
}

export interface Ngo {
  id: string
  admin_id: string
  name: string
  location: string
  registration_number: string | null
  contact_email: string
  verified: boolean
  created_at: string
}

export type ItemCategory = 'food' | 'clothing' | 'medicine' | 'supplies'
export type Urgency = 'normal' | 'urgent'
export type NeedStatus = 'open' | 'matched' | 'closed'

export interface DonationNeed {
  id: string
  ngo_id: string
  item_name: string
  category: ItemCategory
  quantity_needed: number
  quantity_pledged: number
  urgency: Urgency
  status: NeedStatus
  deadline: string
  description: string | null
  created_at: string
  ngo?: Ngo
}

export type PledgeStatus = 'pending' | 'matched' | 'in_transit' | 'confirmed' | 'rejected'

export interface Pledge {
  id: string
  need_id: string
  donor_id: string
  quantity: number
  delivery_date: string
  notes: string | null
  status: PledgeStatus
  created_at: string
  donation_need?: DonationNeed
  donor?: Profile
}

export interface Delivery {
  id: string
  pledge_id: string
  confirmed_by: string
  confirmed_at: string
  notes: string | null
}
