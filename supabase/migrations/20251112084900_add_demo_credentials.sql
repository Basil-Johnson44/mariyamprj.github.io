-- Location: supabase/migrations/20251112084900_add_demo_credentials.sql
-- Schema Analysis: Existing auth system with user_profiles, saved_accounts, vessel_details tables
-- Integration Type: Additive - Add demo user credentials
-- Dependencies: user_profiles (existing), saved_accounts (existing), vessel_details (existing)

-- Add demo credentials for CAPTAINSEAGUARD@gmail.com
DO $$
DECLARE
    captain_uuid UUID := gen_random_uuid();
    saved_account_uuid UUID := gen_random_uuid();
    vessel_detail_uuid UUID := gen_random_uuid();
BEGIN
    -- Create complete auth.users record with all required fields
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES (
        captain_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'CAPTAINSEAGUARD@gmail.com', crypt('S.E.A.G.U.A.R.D', gen_salt('bf', 10)), now(),
        now(), now(),
        '{"full_name": "Captain SeaGuard", "vessel_name": "USS GUARDIAN", "vessel_number": "SG-2024-001"}'::jsonb,
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );

    -- Create user profile
    INSERT INTO public.user_profiles (
        id, email, full_name, role, organization, station_id,
        account_status, verification_status, email_verified
    ) VALUES (
        captain_uuid, 'CAPTAINSEAGUARD@gmail.com', 'Captain SeaGuard', 'Admin'::user_role,
        'SeaGuard Maritime Division', 'SG-HQ-001',
        'active'::account_status, 'approved'::verification_status, true
    );

    -- Create saved account with vessel information
    INSERT INTO public.saved_accounts (
        id, user_id, account_name, account_email, vessel_name, vessel_call_sign,
        vessel_imo_number, vessel_type, connection_status
    ) VALUES (
        saved_account_uuid, captain_uuid, 'Captain SeaGuard', 'CAPTAINSEAGUARD@gmail.com',
        'USS GUARDIAN', 'SG-2024-001', 'IMO-SG-2024-001', 'naval'::vessel_type,
        'active'::connection_status
    );

    -- Create vessel details
    INSERT INTO public.vessel_details (
        id, saved_account_id, vessel_length, vessel_beam, vessel_draft,
        gross_tonnage, net_tonnage, build_year, flag_country, port_of_registry,
        current_location
    ) VALUES (
        vessel_detail_uuid, saved_account_uuid, 85.5, 12.8, 4.2,
        850, 600, 2024, 'United States', 'Norfolk Naval Base',
        '{"latitude": 36.8468, "longitude": -76.2951, "name": "Norfolk Naval Station"}'::jsonb
    );

    RAISE NOTICE 'Demo credentials created successfully: CAPTAINSEAGUARD@gmail.com / S.E.A.G.U.A.R.D';
END $$;