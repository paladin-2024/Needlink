-- ============================================================
-- Migration: saved_needs, notifications, featured, geo, verification
-- ============================================================

-- 1. Featured flag on donation_needs
ALTER TABLE public.donation_needs
  ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT false;

-- 2. Latitude / longitude on NGOs (for map view)
ALTER TABLE public.ngos
  ADD COLUMN IF NOT EXISTS latitude  DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- 3. Saved needs
CREATE TABLE IF NOT EXISTS public.saved_needs (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  donor_id   UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  need_id    UUID NOT NULL REFERENCES public.donation_needs(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (donor_id, need_id)
);


ALTER TABLE public.saved_needs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "saved_needs_select" ON public.saved_needs FOR SELECT
  USING (auth.uid() = donor_id);

CREATE POLICY "saved_needs_insert" ON public.saved_needs FOR INSERT
  WITH CHECK (auth.uid() = donor_id);

CREATE POLICY "saved_needs_delete" ON public.saved_needs FOR DELETE
  USING (auth.uid() = donor_id);

-- 4. In-app notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  type       TEXT NOT NULL DEFAULT 'system',
  read       BOOLEAN NOT NULL DEFAULT false,
  data       JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select" ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- 5. Verification requests
CREATE TABLE IF NOT EXISTS public.verification_requests (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ngo_id     UUID NOT NULL REFERENCES public.ngos(id) ON DELETE CASCADE,
  status     TEXT NOT NULL DEFAULT 'pending',
  notes      TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vreq_select" ON public.verification_requests FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.ngos WHERE id = ngo_id AND admin_id = auth.uid())
  );

CREATE POLICY "vreq_insert" ON public.verification_requests FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.ngos WHERE id = ngo_id AND admin_id = auth.uid())
  );

-- 6. DB trigger: notify donor when pledge status changes
CREATE OR REPLACE FUNCTION public.notify_pledge_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  need_name TEXT;
  notif_title TEXT;
  notif_body TEXT;
BEGIN
  IF OLD.status = NEW.status THEN RETURN NEW; END IF;

  SELECT item_name INTO need_name
  FROM public.donation_needs WHERE id = NEW.need_id;

  IF NEW.status = 'confirmed' THEN
    notif_title := 'Pledge Confirmed ✓';
    notif_body  := 'Your pledge for "' || COALESCE(need_name, 'a need') || '" has been confirmed!';
  ELSIF NEW.status = 'rejected' THEN
    notif_title := 'Pledge Update';
    notif_body  := 'Your pledge for "' || COALESCE(need_name, 'a need') || '" was not accepted.';
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, title, body, type, data)
  VALUES (
    NEW.donor_id,
    notif_title,
    notif_body,
    'pledge_update',
    jsonb_build_object('pledge_id', NEW.id, 'need_id', NEW.need_id)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_pledge_status_change ON public.pledges;
CREATE TRIGGER on_pledge_status_change
  AFTER UPDATE OF status ON public.pledges
  FOR EACH ROW EXECUTE FUNCTION public.notify_pledge_status_change();
