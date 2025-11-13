-- Fix authentication constraint violation - organization and station_id required
-- Schema Analysis: Existing auth system with handle_new_user trigger 
-- Issue: Manual user_profiles insert conflicts with trigger, missing required NOT NULL fields
-- Solution: Let trigger handle profile creation, just set proper metadata

-- 1. Create ESP8266 status function (missing function causing errors)
CREATE OR REPLACE FUNCTION public.get_esp8266_status()
RETURNS TABLE(
    connection_status TEXT,
    status_message TEXT,
    last_update TIMESTAMPTZ,
    data_quality_score INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    latest_data_time TIMESTAMPTZ;
    time_diff_minutes INTEGER;
    connection_quality INTEGER;
BEGIN
    -- Get the most recent data timestamp
    SELECT MAX(inserted_at) INTO latest_data_time
    FROM public.iot_data;
    
    -- If no data exists, return disconnected
    IF latest_data_time IS NULL THEN
        RETURN QUERY SELECT 
            'DISCONNECTED'::TEXT,
            'No data received from ESP8266'::TEXT,
            NULL::TIMESTAMPTZ,
            0::INTEGER;
        RETURN;
    END IF;
    
    -- Calculate time difference in minutes
    time_diff_minutes := EXTRACT(EPOCH FROM (NOW() - latest_data_time)) / 60;
    
    -- Determine connection status based on data freshness
    IF time_diff_minutes <= 2 THEN
        connection_quality := 95;
        RETURN QUERY SELECT 
            'CONNECTED'::TEXT,
            'ESP8266 online - receiving real-time data'::TEXT,
            latest_data_time,
            connection_quality;
    ELSIF time_diff_minutes <= 5 THEN
        connection_quality := 75;
        RETURN QUERY SELECT 
            'UNSTABLE'::TEXT,
            FORMAT('Last data received %s minutes ago - connection unstable', time_diff_minutes)::TEXT,
            latest_data_time,
            connection_quality;
    ELSIF time_diff_minutes <= 15 THEN
        connection_quality := 25;
        RETURN QUERY SELECT 
            'POOR'::TEXT,
            FORMAT('Poor connection - last data %s minutes ago', time_diff_minutes)::TEXT,
            latest_data_time,
            connection_quality;
    ELSE
        connection_quality := 0;
        RETURN QUERY SELECT 
            'DISCONNECTED'::TEXT,
            FORMAT('ESP8266 appears offline - no data for %s minutes', time_diff_minutes)::TEXT,
            latest_data_time,
            connection_quality;
    END IF;
END;
$$;

-- 2. Create weight threshold check function for 30-second motor timer
CREATE OR REPLACE FUNCTION public.check_weight_threshold()
RETURNS TABLE(
    weight_status TEXT,
    current_weight INTEGER,
    threshold_exceeded BOOLEAN,
    motor_timer_seconds INTEGER,
    alert_message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    latest_weight INTEGER;
    weight_threshold INTEGER := 180; -- Warning threshold
    critical_threshold INTEGER := 200; -- Critical threshold
BEGIN
    -- Get the most recent weight reading
    SELECT weight INTO latest_weight
    FROM public.iot_data
    ORDER BY inserted_at DESC
    LIMIT 1;
    
    -- If no data, return normal status
    IF latest_weight IS NULL THEN
        RETURN QUERY SELECT 
            'NORMAL'::TEXT,
            0::INTEGER,
            false::BOOLEAN,
            0::INTEGER,
            'No weight data available'::TEXT;
        RETURN;
    END IF;
    
    -- Check thresholds and return appropriate status
    IF latest_weight >= critical_threshold THEN
        RETURN QUERY SELECT 
            'CRITICAL_EXCEEDED'::TEXT,
            latest_weight,
            true::BOOLEAN,
            30::INTEGER, -- 30 second motor timer
            FORMAT('CRITICAL: Weight %skg exceeds maximum capacity %skg', latest_weight, critical_threshold)::TEXT;
    ELSIF latest_weight >= weight_threshold THEN
        RETURN QUERY SELECT 
            'THRESHOLD_EXCEEDED'::TEXT,
            latest_weight,
            true::BOOLEAN,
            30::INTEGER, -- 30 second motor timer
            FORMAT('WARNING: Weight %skg exceeds safe threshold %skg', latest_weight, weight_threshold)::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'NORMAL'::TEXT,
            latest_weight,
            false::BOOLEAN,
            0::INTEGER,
            FORMAT('Weight %skg within safe limits', latest_weight)::TEXT;
    END IF;
END;
$$;

-- 3. Clean up any existing problematic demo credentials
DELETE FROM auth.users WHERE email IN ('CAPTAINSEAGUARD@gmail.com', 'officer@seaguard.com');
DELETE FROM public.user_profiles WHERE email IN ('CAPTAINSEAGUARD@gmail.com', 'officer@seaguard.com');

-- 4. Create correct demo credentials with ALL required metadata
-- The handle_new_user trigger will automatically create user_profiles with proper fields
DO $$
DECLARE
    captain_uuid UUID := gen_random_uuid();
    officer_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete metadata (trigger will create profiles automatically)
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
         jsonb_build_object(
             'full_name', 'Captain Seaguard',
             'organization', 'S.E.A.G.U.A.R.D Maritime Division',
             'station_id', 'SG-001-HQ',
             'role', 'Admin',
             'vessel_number', 'SG-001',
             'vessel_name', 'S.E.A.G.U.A.R.D',
             'license_number', 'ML-2024-SG001',
             'phone', '+1-555-SEAGUARD'
         ), 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (officer_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'officer@seaguard.com', crypt('officer123', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object(
             'full_name', 'First Officer',
             'organization', 'S.E.A.G.U.A.R.D Maritime Division',
             'station_id', 'SG-001-DECK',
             'role', 'Officer',
             'vessel_number', 'SG-001',
             'vessel_name', 'S.E.A.G.U.A.R.D',
             'license_number', 'ML-2024-OF001',
             'phone', '+1-555-OFFICER'
         ), 
         '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- No manual user_profiles insert needed - handle_new_user trigger will create them automatically
    -- with proper organization and station_id from raw_user_meta_data
END $$;

-- 5. Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.get_esp8266_status() TO public;
GRANT EXECUTE ON FUNCTION public.check_weight_threshold() TO public;

-- 6. Add fresh IoT data for testing ESP8266 connection status
INSERT INTO public.iot_data (temp, humidity, weight, ax, ay, az, inserted_at) VALUES
    (28.5, 65.2, 145, 12, -3, 9.81, NOW() - INTERVAL '30 seconds'),
    (29.1, 64.8, 148, 15, -5, 9.85, NOW() - INTERVAL '15 seconds'),
    (29.3, 63.9, 142, 8, -2, 9.79, NOW());

-- 7. Verify demo user creation (optional - for debugging)
DO $$
BEGIN
    RAISE NOTICE 'Demo users created. Captain: CAPTAINSEAGUARD@gmail.com / S.E.A.G.U.A.R.D';
    RAISE NOTICE 'Demo users created. Officer: officer@seaguard.com / officer123';
    RAISE NOTICE 'User profiles will be auto-created by handle_new_user trigger';
END $$;

COMMENT ON FUNCTION public.get_esp8266_status() IS 'Returns ESP8266 connection status based on data freshness and quality for dashboard monitoring';
COMMENT ON FUNCTION public.check_weight_threshold() IS 'Checks current weight against safety thresholds and returns 30-second motor timer info';