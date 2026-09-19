-- Retailer onboarding Step 2: authorize authenticated business-image persistence

GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE public.business_images
TO authenticated;
