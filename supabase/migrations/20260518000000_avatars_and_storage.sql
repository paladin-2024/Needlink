-- ============================================================
-- Migration: avatars, logos, delivery proofs
-- ============================================================

-- 1. Avatar URL on profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Logo URL on NGOs
ALTER TABLE public.ngos
  ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- 3. Delivery proof URL on pledges
ALTER TABLE public.pledges
  ADD COLUMN IF NOT EXISTS delivery_proof_url TEXT;

-- ============================================================
-- 4. Auto-create profile row on user sign-up (idempotent)
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    NEW.email
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 5. Storage buckets
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('avatars',         'avatars',         true, 5242880, ARRAY['image/jpeg','image/png','image/webp']),
  ('logos',           'logos',           true, 5242880, ARRAY['image/jpeg','image/png','image/webp']),
  ('delivery-proofs', 'delivery-proofs', false, 10485760, ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 6. Storage RLS policies
-- ============================================================

-- avatars: owner can upload/update/delete; anyone can read
CREATE POLICY "avatars_select" ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "avatars_insert" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_update" ON storage.objects FOR UPDATE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_delete" ON storage.objects FOR DELETE
  USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- logos: NGO admin can upload/update/delete; anyone can read
CREATE POLICY "logos_select" ON storage.objects FOR SELECT
  USING (bucket_id = 'logos');

CREATE POLICY "logos_insert" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'logos' AND
    EXISTS (
      SELECT 1 FROM public.ngos
      WHERE id::text = (storage.foldername(name))[1]
        AND admin_id = auth.uid()
    )
  );

CREATE POLICY "logos_update" ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'logos' AND
    EXISTS (
      SELECT 1 FROM public.ngos
      WHERE id::text = (storage.foldername(name))[1]
        AND admin_id = auth.uid()
    )
  );

CREATE POLICY "logos_delete" ON storage.objects FOR DELETE
  USING (
    bucket_id = 'logos' AND
    EXISTS (
      SELECT 1 FROM public.ngos
      WHERE id::text = (storage.foldername(name))[1]
        AND admin_id = auth.uid()
    )
  );

-- delivery-proofs: donor who made the pledge can upload; NGO admin can read
CREATE POLICY "proofs_insert" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'delivery-proofs' AND
    EXISTS (
      SELECT 1 FROM public.pledges
      WHERE id::text = (storage.foldername(name))[1]
        AND donor_id = auth.uid()
    )
  );

CREATE POLICY "proofs_select" ON storage.objects FOR SELECT
  USING (
    bucket_id = 'delivery-proofs' AND (
      EXISTS (
        SELECT 1 FROM public.pledges p
        JOIN public.donation_needs dn ON dn.id = p.need_id
        JOIN public.ngos n ON n.id = dn.ngo_id
        WHERE p.id::text = (storage.foldername(name))[1]
          AND (p.donor_id = auth.uid() OR n.admin_id = auth.uid())
      )
    )
  );
