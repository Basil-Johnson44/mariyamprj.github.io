-- Location: supabase/migrations/20251112090000_fix_demo_credentials.sql
-- Schema Analysis: Existing schema with user_profiles, saved_accounts, vessel_details
-- Integration Type: Addition - Fix authentication credentials
-- Dependencies: user_profiles, saved_accounts

-- Delete existing incomplete auth users and create proper ones
DELETE FROM auth.users WHERE email LIKE '%@example.com' OR email LIKE 'CAPTAINSEAGUARD@gmail.com';
DELETE FROM public.user_profiles WHERE email LIKE '%@example.com' OR email LIKE 'CAPTAINSEAGUARD@gmail.com';
DELETE FROM public.saved_accounts WHERE account_email LIKE '%@example.com' OR account_email LIKE 'CAPTAINSEAGUARD@gmail.com';

DO $$
DECLARE
    captain_uuid UUID := gen_random_uuid();
    officer_uuid UUID := gen_random_uuid();
    saved_account_id UUID := gen_random_uuid();
    vessel_details_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete field structure (CRITICAL for login to work)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (captain_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'CAPTAINSEAGUARD@gmail.com', crypt('S.E.A.G.U.A.R.D', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Captain Seaguard", "vessel_name": "S.E.A.G.U.A.R.D Maritime", "vessel_number": "SG-001"}'::jsonb, 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (officer_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'officer@seaguard.com', crypt('officer123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Officer Maritime", "vessel_name": "Guardian Sea", "vessel_number": "SG-002"}'::jsonb,
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create user profiles
    INSERT INTO public.user_profiles (id, email, full_name, organization, phone, role, station_id, account_status, email_verified, verification_status)
    VALUES
        (captain_uuid, 'CAPTAINSEAGUARD@gmail.com', 'Captain Seaguard', 'S.E.A.G.U.A.R.D Maritime Command', '+91 9876543210', 'Admin', 'SG-HQ-01', 'active', true, 'approved'),
        (officer_uuid, 'officer@seaguard.com', 'Officer Maritime', 'Guardian Sea Operations', '+91 9876543211', 'Officer', 'SG-OP-02', 'active', true, 'approved');

    -- Create saved accounts with vessel information
    INSERT INTO public.saved_accounts (id, user_id, account_email, account_name, vessel_name, vessel_call_sign, vessel_imo_number, vessel_type, connection_status)
    VALUES
        (saved_account_id, captain_uuid, 'CAPTAINSEAGUARD@gmail.com', 'Captain Seaguard', 'S.E.A.G.U.A.R.D', 'SG001', 'IMO-SG-001-2024', 'naval', 'active'),
        (gen_random_uuid(), officer_uuid, 'officer@seaguard.com', 'Officer Maritime', 'Guardian Sea', 'GS002', 'IMO-GS-002-2024', 'patrol', 'active');

    -- Create vessel details
    INSERT INTO public.vessel_details (id, saved_account_id, vessel_length, vessel_beam, vessel_draft, gross_tonnage, net_tonnage, build_year, flag_country, port_of_registry, current_location)
    VALUES
        (vessel_details_id, saved_account_id, 45.5, 12.2, 3.8, 250, 180, 2020, 'India', 'Kochi', 
         '{"latitude": 9.970981, "longitude": 76.241914, "location_name": "Kochi Harbor"}'::jsonb),
        (gen_random_uuid(), saved_account_id, 38.0, 10.5, 3.2, 180, 120, 2019, 'India', 'Mumbai',
         '{"latitude": 19.013, "longitude": 72.856, "location_name": "Mumbai Port"}'::jsonb);

    RAISE NOTICE 'Demo credentials created successfully:';
    RAISE NOTICE 'Captain: CAPTAINSEAGUARD@gmail.com / S.E.A.G.U.A.R.D';
    RAISE NOTICE 'Officer: officer@seaguard.com / officer123';
END $$;

-- Create function to generate live IoT data variations
CREATE OR REPLACE FUNCTION public.generate_live_iot_variations()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Update iot_data with small random variations to simulate live data
    UPDATE public.iot_data
    SET 
        temperature = ROUND((20 + RANDOM() * 25)::numeric, 2),
        humidity = ROUND((40 + RANDOM() * 40)::numeric, 2),
        pressure = ROUND((1000 + RANDOM() * 50)::numeric, 2),
        wind_speed = ROUND((RANDOM() * 25)::numeric, 2),
        wave_height = ROUND((RANDOM() * 5)::numeric, 2),
        gps_latitude = 9.970981 + (RANDOM() - 0.5) * 0.001,
        gps_longitude = 76.241914 + (RANDOM() - 0.5) * 0.001,
        vessel_speed = ROUND((RANDOM() * 20)::numeric, 2),
        fuel_level = ROUND((50 + RANDOM() * 50)::numeric, 2),
        engine_rpm = ROUND((800 + RANDOM() * 2200)::numeric, 0),
        weight_sensor = ROUND((1000 + RANDOM() * 8000)::numeric, 2),
        trim_angle = ROUND((RANDOM() - 0.5) * 10::numeric, 2),
        heel_angle = ROUND((RANDOM() - 0.5) * 8::numeric, 2),
        updated_at = NOW()
    WHERE id IN (SELECT id FROM public.iot_data ORDER BY updated_at DESC LIMIT 5);
END;
$$;

-- Create function for 30-second motor timer when weight exceeds threshold
CREATE OR REPLACE FUNCTION public.check_weight_threshold()
RETURNS TABLE(
    weight_status TEXT,
    motor_timer_seconds INTEGER,
    alert_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_weight NUMERIC;
    weight_threshold NUMERIC := 8000; -- 8000kg threshold
    motor_timer INTEGER := 30; -- 30 seconds timer
BEGIN
    -- Get latest weight reading
    SELECT weight_sensor INTO current_weight
    FROM public.iot_data
    ORDER BY updated_at DESC
    LIMIT 1;

    -- Check if weight exceeds threshold
    IF current_weight > weight_threshold THEN
        RETURN QUERY SELECT 
            'THRESHOLD_EXCEEDED'::TEXT,
            motor_timer,
            ('Weight ' || ROUND(current_weight) || 'kg exceeds threshold ' || weight_threshold || 'kg. Motor shutdown in ' || motor_timer || ' seconds.')::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'NORMAL'::TEXT,
            0,
            'Weight within normal limits'::TEXT;
    END IF;
END;
$$;

-- Create ESP8266 connection status function
CREATE OR REPLACE FUNCTION public.get_esp8266_status()
RETURNS TABLE(
    connection_status TEXT,
    last_data_received TIMESTAMPTZ,
    status_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    latest_data TIMESTAMPTZ;
    time_diff INTERVAL;
BEGIN
    -- Get latest IoT data timestamp
    SELECT MAX(updated_at) INTO latest_data
    FROM public.iot_data;

    -- Calculate time difference
    time_diff := NOW() - latest_data;

    -- Determine connection status based on last data received
    IF time_diff < INTERVAL '2 minutes' THEN
        RETURN QUERY SELECT 
            'CONNECTED'::TEXT,
            latest_data,
            'ESP8266 CONNECTED - Data receiving normally'::TEXT;
    ELSIF time_diff < INTERVAL '5 minutes' THEN
        RETURN QUERY SELECT 
            'UNSTABLE'::TEXT,
            latest_data,
            'ESP8266 CONNECTION UNSTABLE - Intermittent data'::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'DISCONNECTED'::TEXT,
            latest_data,
            'ESP8266 NOT CONNECTED - No recent data'::TEXT;
    END IF;
END;
$$;