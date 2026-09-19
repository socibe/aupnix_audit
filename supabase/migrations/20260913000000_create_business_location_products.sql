-- AUPNIX: establish the Product × Physical Business Location relationship.

ALTER TABLE public.products
  ADD CONSTRAINT products_id_business_id_key
  UNIQUE (id, business_id);

ALTER TABLE public.business_locations
  ADD CONSTRAINT business_locations_id_business_id_key
  UNIQUE (id, business_id);

CREATE TABLE public.business_location_products (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL,
  product_id uuid NOT NULL,
  business_location_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'active'::text,
  availability_state text NOT NULL DEFAULT 'available'::text,
  quantity integer,
  price numeric(12,2),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),

  CONSTRAINT business_location_products_pkey
    PRIMARY KEY (id),

  CONSTRAINT business_location_products_status_check
    CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text])),

  CONSTRAINT business_location_products_availability_state_check
    CHECK (availability_state = ANY (ARRAY['available'::text, 'unavailable'::text])),

  CONSTRAINT business_location_products_quantity_check
    CHECK ((quantity IS NULL) OR (quantity >= 0)),

  CONSTRAINT business_location_products_price_check
    CHECK ((price IS NULL) OR (price >= (0)::numeric)),

  CONSTRAINT business_location_products_product_location_key
    UNIQUE (product_id, business_location_id),

  CONSTRAINT business_location_products_product_business_fkey
    FOREIGN KEY (product_id, business_id)
    REFERENCES public.products (id, business_id)
    ON DELETE CASCADE,

  CONSTRAINT business_location_products_location_business_fkey
    FOREIGN KEY (business_location_id, business_id)
    REFERENCES public.business_locations (id, business_id)
    ON DELETE CASCADE
);

CREATE INDEX business_location_products_product_id_idx
  ON public.business_location_products USING btree (product_id);

CREATE INDEX business_location_products_business_location_id_idx
  ON public.business_location_products USING btree (business_location_id);

CREATE INDEX business_location_products_business_id_idx
  ON public.business_location_products USING btree (business_id);

CREATE TRIGGER set_business_location_products_updated_at
  BEFORE UPDATE ON public.business_location_products
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.business_location_products
  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "business_location_products_delete_member"
  ON public.business_location_products
  FOR DELETE
  TO authenticated
  USING (public.has_active_business_membership(business_id));

CREATE POLICY "business_location_products_insert_member"
  ON public.business_location_products
  FOR INSERT
  TO authenticated
  WITH CHECK (public.has_active_business_membership(business_id));

CREATE POLICY "business_location_products_select_public_or_member"
  ON public.business_location_products
  FOR SELECT
  TO anon, authenticated
  USING (
    (
      status = 'active'::text
      AND availability_state = 'available'::text
      AND EXISTS (
        SELECT 1
        FROM public.products
        WHERE products.id = business_location_products.product_id
          AND products.business_id = business_location_products.business_id
          AND products.status = 'active'::text
      )
      AND EXISTS (
        SELECT 1
        FROM public.business_locations
        JOIN public.businesses
          ON businesses.id = business_locations.business_id
        WHERE business_locations.id = business_location_products.business_location_id
          AND business_locations.business_id = business_location_products.business_id
          AND business_locations.status = 'active'::text
          AND businesses.status = 'active'::text
      )
    )
    OR public.has_active_business_membership(business_id)
  );

CREATE POLICY "business_location_products_update_member"
  ON public.business_location_products
  FOR UPDATE
  TO authenticated
  USING (public.has_active_business_membership(business_id))
  WITH CHECK (public.has_active_business_membership(business_id));

GRANT SELECT, INSERT, UPDATE, DELETE
  ON TABLE public.business_location_products
  TO authenticated;
