SET local check_function_bodies = off;

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON SEQUENCES FROM "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON SEQUENCES FROM "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON SEQUENCES FROM "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON FUNCTIONS FROM "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON FUNCTIONS FROM "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON FUNCTIONS FROM "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON TABLES FROM "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON TABLES FROM "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" REVOKE ALL ON TABLES FROM "service_role";

CREATE TABLE "public"."brands" (
  "id"         uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "name"       text                     NOT NULL,
  "status"     text                     NOT NULL DEFAULT 'active'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "brands_pkey" PRIMARY KEY (id),
  CONSTRAINT "brands_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text])))
);

ALTER TABLE "public"."brands"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."business_images" (
  "id"            uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "business_id"   uuid                     NOT NULL,
  "storage_key"   text                     NOT NULL,
  "alt_text"      text,
  "display_order" integer                  NOT NULL DEFAULT 0,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "business_images_display_order_check" CHECK ((display_order >= 0)),
  CONSTRAINT "business_images_pkey" PRIMARY KEY (id),
  CONSTRAINT "business_images_storage_key_check" CHECK ((TRIM(BOTH FROM storage_key) <> ''::text)),
  CONSTRAINT "business_images_storage_key_key" UNIQUE (storage_key)
);

ALTER TABLE "public"."business_images"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."business_locations" (
  "id"             uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "business_id"    uuid                     NOT NULL,
  "address_line_1" text                     NOT NULL,
  "address_line_2" text,
  "locality"       text,
  "city"           text                     NOT NULL,
  "state"          text                     NOT NULL,
  "country_code"   text                     NOT NULL,
  "postal_code"    text,
  "latitude"       numeric,
  "longitude"      numeric,
  "is_primary"     boolean                  NOT NULL,
  "status"         text                     NOT NULL DEFAULT 'active'::text,
  "created_at"     timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"     timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "business_locations_pkey" PRIMARY KEY (id),
  CONSTRAINT "business_locations_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text])))
);

ALTER TABLE "public"."business_locations"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."business_memberships" (
  "user_id"     uuid                     NOT NULL,
  "business_id" uuid                     NOT NULL,
  "role"        text                     NOT NULL,
  "status"      text                     NOT NULL DEFAULT 'active'::text,
  "created_at"  timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"  timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "business_memberships_pkey" PRIMARY KEY (user_id, business_id),
  CONSTRAINT "business_memberships_role_check" CHECK ((role = ANY (ARRAY['owner'::text, 'member'::text]))),
  CONSTRAINT "business_memberships_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text, 'revoked'::text])))
);

ALTER TABLE "public"."business_memberships"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."business_profiles" (
  "business_id"   uuid                     NOT NULL,
  "display_name"  text                     NOT NULL,
  "description"   text,
  "contact_phone" text,
  "contact_email" text,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "business_profiles_pkey" PRIMARY KEY (business_id)
);

ALTER TABLE "public"."business_profiles"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."businesses" (
  "id"         uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "status"     text                     NOT NULL DEFAULT 'active'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "businesses_pkey" PRIMARY KEY (id),
  CONSTRAINT "businesses_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text, 'archived'::text])))
);

ALTER TABLE "public"."businesses"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."product_categories" (
  "id"         uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "name"       text                     NOT NULL,
  "status"     text                     NOT NULL DEFAULT 'active'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "product_categories_pkey" PRIMARY KEY (id),
  CONSTRAINT "product_categories_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text])))
);

ALTER TABLE "public"."product_categories"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."product_images" (
  "id"            uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "product_id"    uuid                     NOT NULL,
  "storage_key"   text                     NOT NULL,
  "alt_text"      text,
  "display_order" integer                  NOT NULL DEFAULT 0,
  "created_at"    timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"    timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "product_images_display_order_check" CHECK ((display_order >= 0)),
  CONSTRAINT "product_images_pkey" PRIMARY KEY (id),
  CONSTRAINT "product_images_storage_key_check" CHECK ((TRIM(BOTH FROM storage_key) <> ''::text)),
  CONSTRAINT "product_images_storage_key_key" UNIQUE (storage_key)
);

ALTER TABLE "public"."product_images"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."products" (
  "id"                  uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "business_id"         uuid                     NOT NULL,
  "name"                text                     NOT NULL,
  "description"         text,
  "price"               numeric(12,2),
  "currency_code"       text,
  "product_category_id" uuid,
  "brand_id"            uuid,
  "availability_state"  text                     NOT NULL DEFAULT 'available'::text,
  "status"              text                     NOT NULL DEFAULT 'draft'::text,
  "created_at"          timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at"          timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "products_availability_state_check" CHECK ((availability_state = ANY (ARRAY['available'::text, 'unavailable'::text]))),
  CONSTRAINT "products_currency_code_check" CHECK (((currency_code IS NULL) OR (char_length(currency_code) = 3))),
  CONSTRAINT "products_pkey" PRIMARY KEY (id),
  CONSTRAINT "products_price_check" CHECK (((price IS NULL) OR (price >= (0)::numeric))),
  CONSTRAINT "products_status_check" CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'archived'::text])))
);

ALTER TABLE "public"."products"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."user_profiles" (
  "id"         uuid                     NOT NULL,
  "status"     text                     NOT NULL DEFAULT 'active'::text,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  "updated_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "user_profiles_pkey" PRIMARY KEY (id),
  CONSTRAINT "user_profiles_status_check" CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text])))
);

ALTER TABLE "public"."user_profiles"
  ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.create_business_with_initial_owner()
  RETURNS uuid
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog', 'public'
  AS $function$
declare
  new_business_id uuid;
  current_user_id uuid;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'authenticated user required';
  end if;

  insert into public.businesses
  default values
  returning id into new_business_id;

  insert into public.business_memberships (
    user_id,
    business_id,
    role,
    status
  )
  values (
    current_user_id,
    new_business_id,
    'owner',
    'active'
  );

  return new_business_id;
end;
$function$;

CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
begin
  insert into public.user_profiles (id)
  values (new.id);

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.has_active_business_membership (
  target_business_id uuid
)
  RETURNS boolean
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog', 'public'
  AS $function$
  select exists (
    select 1
    from public.business_memberships
    where business_memberships.user_id = auth.uid()
      and business_memberships.business_id = target_business_id
      and business_memberships.status = 'active'
  );
$function$;

CREATE OR REPLACE FUNCTION public.has_active_business_owner (
  target_business_id uuid
)
  RETURNS boolean
  LANGUAGE sql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog', 'public'
  AS $function$
  select exists (
    select 1
    from public.business_memberships
    where business_memberships.user_id = auth.uid()
      and business_memberships.business_id = target_business_id
      and business_memberships.status = 'active'
      and business_memberships.role = 'owner'
  );
$function$;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
  RETURNS event_trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$;

ALTER TABLE "public"."business_images"
  ADD CONSTRAINT "business_images_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE CASCADE;

ALTER TABLE "public"."business_locations"
  ADD CONSTRAINT "business_locations_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE "public"."business_memberships"
  ADD CONSTRAINT "business_memberships_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

ALTER TABLE "public"."business_profiles"
  ADD CONSTRAINT "business_profiles_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE "public"."products"
  ADD CONSTRAINT "products_brand_id_fkey" FOREIGN KEY (brand_id) REFERENCES public.brands(id) ON DELETE SET NULL;

ALTER TABLE "public"."products"
  ADD CONSTRAINT "products_business_id_fkey" FOREIGN KEY (business_id) REFERENCES public.businesses(id) ON DELETE RESTRICT;

ALTER TABLE "public"."product_images"
  ADD CONSTRAINT "product_images_product_id_fkey" FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;

ALTER TABLE "public"."products"
  ADD CONSTRAINT "products_product_category_id_fkey" FOREIGN KEY (product_category_id) REFERENCES public.product_categories(id) ON DELETE SET NULL;

ALTER TABLE "public"."user_profiles"
  ADD CONSTRAINT "user_profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;

ALTER TABLE "public"."business_memberships"
  ADD CONSTRAINT "business_memberships_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.user_profiles(id) ON UPDATE RESTRICT ON DELETE RESTRICT;

CREATE UNIQUE INDEX brands_name_lower_unique ON public.brands USING btree (lower(name));

CREATE INDEX business_images_business_id_idx ON public.business_images USING btree (business_id);

CREATE INDEX business_locations_business_id_idx ON public.business_locations USING btree (business_id);

CREATE UNIQUE INDEX business_locations_one_active_primary_per_business_idx ON public.business_locations USING btree (business_id)
  WHERE ((is_primary = true) AND (status = 'active'::text));

CREATE INDEX business_memberships_business_id_user_id_idx ON public.business_memberships USING btree (business_id, user_id);

CREATE UNIQUE INDEX product_categories_name_key ON public.product_categories USING btree (name);

CREATE INDEX product_images_product_id_idx ON public.product_images USING btree (product_id);

CREATE INDEX products_brand_id_idx ON public.products USING btree (brand_id);

CREATE INDEX products_business_id_idx ON public.products USING btree (business_id);

CREATE INDEX products_product_category_id_idx ON public.products USING btree (product_category_id);

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_auth_user();

CREATE TRIGGER set_brands_updated_at
  BEFORE UPDATE ON public.brands
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_business_images_updated_at
  BEFORE UPDATE ON public.business_images
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_business_locations_updated_at
  BEFORE UPDATE ON public.business_locations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_business_memberships_updated_at
  BEFORE UPDATE ON public.business_memberships
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_business_profiles_updated_at
  BEFORE UPDATE ON public.business_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_businesses_updated_at
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_product_categories_updated_at
  BEFORE UPDATE ON public.product_categories
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_product_images_updated_at
  BEFORE UPDATE ON public.product_images
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE POLICY "brands_select_active" ON "public"."brands"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((status = 'active'::text));

CREATE POLICY "business_images_delete_member" ON "public"."business_images"
  FOR DELETE
  TO "authenticated"
  USING (public.has_active_business_membership(business_id));

CREATE POLICY "business_images_insert_member" ON "public"."business_images"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (public.has_active_business_membership(business_id));

CREATE POLICY "business_images_select_public_or_member" ON "public"."business_images"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.businesses
  WHERE ((businesses.id = business_images.business_id) AND ((businesses.status = 'active'::text) OR public.has_active_business_membership(business_images.business_id))))));

CREATE POLICY "business_images_update_member" ON "public"."business_images"
  FOR UPDATE
  TO "authenticated"
  USING (public.has_active_business_membership(business_id))
  WITH CHECK (public.has_active_business_membership(business_id));

CREATE POLICY "business_locations_delete_member" ON "public"."business_locations"
  FOR DELETE
  TO "authenticated"
  USING (public.has_active_business_membership(business_id));

CREATE POLICY "business_locations_insert_member" ON "public"."business_locations"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (public.has_active_business_membership(business_id));

CREATE POLICY "business_locations_select_public_or_member" ON "public"."business_locations"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((((status = 'active'::text) AND (EXISTS ( SELECT 1
   FROM public.businesses
  WHERE ((businesses.id = business_locations.business_id) AND (businesses.status = 'active'::text))))) OR public.has_active_business_membership(business_id)));

CREATE POLICY "business_locations_update_member" ON "public"."business_locations"
  FOR UPDATE
  TO "authenticated"
  USING (public.has_active_business_membership(business_id))
  WITH CHECK (public.has_active_business_membership(business_id));

CREATE POLICY "business_memberships_delete_owner" ON "public"."business_memberships"
  FOR DELETE
  TO "authenticated"
  USING (public.has_active_business_owner(business_id));

CREATE POLICY "business_memberships_insert_owner" ON "public"."business_memberships"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (public.has_active_business_owner(business_id));

CREATE POLICY "business_memberships_select_authorized_business" ON "public"."business_memberships"
  FOR SELECT
  TO "authenticated"
  USING (public.has_active_business_membership(business_id));

CREATE POLICY "business_memberships_update_owner" ON "public"."business_memberships"
  FOR UPDATE
  TO "authenticated"
  USING (public.has_active_business_owner(business_id))
  WITH CHECK (public.has_active_business_owner(business_id));

CREATE POLICY "business_profiles_delete_member" ON "public"."business_profiles"
  FOR DELETE
  TO "authenticated"
  USING (public.has_active_business_membership(business_id));

CREATE POLICY "business_profiles_insert_member" ON "public"."business_profiles"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (public.has_active_business_membership(business_id));

CREATE POLICY "business_profiles_select_public_or_member" ON "public"."business_profiles"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.businesses
  WHERE ((businesses.id = business_profiles.business_id) AND ((businesses.status = 'active'::text) OR public.has_active_business_membership(business_profiles.business_id))))));

CREATE POLICY "business_profiles_update_member" ON "public"."business_profiles"
  FOR UPDATE
  TO "authenticated"
  USING (public.has_active_business_membership(business_id))
  WITH CHECK (public.has_active_business_membership(business_id));

CREATE POLICY "businesses_delete_owner" ON "public"."businesses"
  FOR DELETE
  TO "authenticated"
  USING (public.has_active_business_owner(id));

CREATE POLICY "businesses_select_public_or_member" ON "public"."businesses"
  FOR SELECT
  TO "anon", "authenticated"
  USING (((status = 'active'::text) OR public.has_active_business_membership(id)));

CREATE POLICY "businesses_update_member" ON "public"."businesses"
  FOR UPDATE
  TO "authenticated"
  USING (public.has_active_business_membership(id))
  WITH CHECK (public.has_active_business_membership(id));

CREATE POLICY "product_categories_select_active" ON "public"."product_categories"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((status = 'active'::text));

CREATE POLICY "product_images_delete_member" ON "public"."product_images"
  FOR DELETE
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.products
  WHERE ((products.id = product_images.product_id) AND public.has_active_business_membership(products.business_id)))));

CREATE POLICY "product_images_insert_member" ON "public"."product_images"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.products
  WHERE ((products.id = product_images.product_id) AND public.has_active_business_membership(products.business_id)))));

CREATE POLICY "product_images_select_public_or_member" ON "public"."product_images"
  FOR SELECT
  TO "anon", "authenticated"
  USING (((EXISTS ( SELECT 1
   FROM (public.products
     JOIN public.businesses ON ((businesses.id = products.business_id)))
  WHERE ((products.id = product_images.product_id) AND (products.status = 'active'::text) AND (businesses.status = 'active'::text)))) OR (EXISTS ( SELECT 1
   FROM public.products
  WHERE ((products.id = product_images.product_id) AND public.has_active_business_membership(products.business_id))))));

CREATE POLICY "product_images_update_member" ON "public"."product_images"
  FOR UPDATE
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.products
  WHERE ((products.id = product_images.product_id) AND public.has_active_business_membership(products.business_id)))))
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.products
  WHERE ((products.id = product_images.product_id) AND public.has_active_business_membership(products.business_id)))));

CREATE POLICY "products_delete_member" ON "public"."products"
  FOR DELETE
  TO "authenticated"
  USING (public.has_active_business_membership(business_id));

CREATE POLICY "products_insert_member" ON "public"."products"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (public.has_active_business_membership(business_id));

CREATE POLICY "products_select_public_or_member" ON "public"."products"
  FOR SELECT
  TO "anon", "authenticated"
  USING ((((status = 'active'::text) AND (EXISTS ( SELECT 1
   FROM public.businesses
  WHERE ((businesses.id = products.business_id) AND (businesses.status = 'active'::text))))) OR public.has_active_business_membership(business_id)));

CREATE POLICY "products_update_member" ON "public"."products"
  FOR UPDATE
  TO "authenticated"
  USING (public.has_active_business_membership(business_id))
  WITH CHECK (public.has_active_business_membership(business_id));

CREATE POLICY "user_profiles_select_own" ON "public"."user_profiles"
  FOR SELECT
  TO "authenticated"
  USING ((id = auth.uid()));

CREATE POLICY "user_profiles_update_own" ON "public"."user_profiles"
  FOR UPDATE
  TO "authenticated"
  USING ((id = auth.uid()))
  WITH CHECK ((id = auth.uid()));

CREATE EVENT TRIGGER "ensure_rls"
  ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
  EXECUTE FUNCTION "public"."rls_auto_enable"();

REVOKE ALL ON FUNCTION "public"."create_business_with_initial_owner"() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."create_business_with_initial_owner"() TO "authenticated", "postgres";

GRANT EXECUTE ON FUNCTION "public"."handle_new_auth_user"() TO PUBLIC, "postgres";

REVOKE ALL ON FUNCTION "public"."has_active_business_membership"(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."has_active_business_membership"(uuid) TO "authenticated", "postgres";

REVOKE ALL ON FUNCTION "public"."has_active_business_owner"(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "public"."has_active_business_owner"(uuid) TO "authenticated", "postgres";

GRANT EXECUTE ON FUNCTION "public"."rls_auto_enable"() TO PUBLIC, "postgres";

GRANT EXECUTE ON FUNCTION "public"."set_updated_at"() TO PUBLIC, "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."brands" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."brands" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."brands" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."business_images" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."business_images" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."business_images" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."business_locations" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."business_locations" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."business_locations" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."business_memberships" TO "anon";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."business_memberships" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."business_memberships" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."business_memberships" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."business_profiles" TO "anon";

GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."business_profiles" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."business_profiles" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."business_profiles" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."businesses" TO "anon";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."businesses" TO "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."businesses" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."businesses" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."product_categories" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."product_categories" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."product_categories" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."product_images" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."product_images" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."product_images" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."products" TO "anon";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."products" TO "authenticated", "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."products" TO "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."user_profiles" TO "anon", "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."user_profiles" TO "postgres";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."user_profiles" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES TO "anon";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES TO "authenticated";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLES TO "service_role";

