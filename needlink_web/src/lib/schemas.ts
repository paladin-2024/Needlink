import { z } from 'zod'

export const NgoSchema = z.object({
  name: z.string(),
  location: z.string(),
  verified: z.boolean().optional().default(false),
})

export const NeedSchema = z.object({
  id: z.string(),
  item_name: z.string(),
  category: z.string(),
  quantity_needed: z.number(),
  quantity_pledged: z.number(),
  urgency: z.string(),
  ngo: NgoSchema.optional().nullable(),
})

export const PledgeQuantitySchema = z.object({
  quantity: z.number().nullable(),
})

export type NeedRow = z.infer<typeof NeedSchema>
export type NgoRow = z.infer<typeof NgoSchema>
