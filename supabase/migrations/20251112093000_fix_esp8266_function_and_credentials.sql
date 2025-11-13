-- Fix ESP8266 function access and add proper demo credentials
-- Migration: 20251112093000_fix_esp8266_function_and_credentials.sql

-- Grant execute permissions on the get_esp8266_status function to public
GRANT EXECUTE ON FUNCTION public.get_esp8266_status() TO public;
GRANT EXECUTE ON FUNCTION public.check_weight_threshold() TO public;

-- Ensure the functions return proper JSON for PostgREST
DROP FUNCTION IF EXISTS public.get_esp8266_status();
CREATE OR REPLACE FUNCTION public.get_esp8266_status()
RETURNS TABLE(
    connection_status text,
    status_message text,
    last_update timestamptz,
    data_quality_score integer
)
LANGUAGE plpgsql
SECURITY INVOKER
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_esp8266_status() TO public;
GRANT EXECUTE ON FUNCTION public.get_esp8266_status() TO anon;
GRANT EXECUTE ON FUNCTION public.get_esp8266_status() TO authenticated;

-- Update the demo user with correct credentials and ensure it has all required fields
DO $$
DECLARE
    demo_user_id UUID;
BEGIN
    -- First, get or create the auth user
    SELECT id INTO demo_user_id FROM auth.users WHERE email = 'CAPTAINSEAGUARD@gmail.com';
    
    IF demo_user_id IS NULL THEN
        -- Create the auth user with correct password hash for "S.E.A.G.U.A.R.D"
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            created_at,
            updated_at,
            role,
            aud,
            confirmation_token,
            email_change_token_new,
            recovery_token
        ) VALUES (
            gen_random_uuid(),
            '00000000-0000-0000-0000-000000000000',
            'CAPTAINSEAGUARD@gmail.com',
            crypt('S.E.A.G.U.A.R.D', gen_salt('bf')),
            NOW(),
            NOW(),
            NOW(),
            'authenticated',
            'authenticated',
            '',
            '',
            ''
        ) RETURNING id INTO demo_user_id;
    ELSE
        -- Update existing user password
        UPDATE auth.users 
        SET encrypted_password = crypt('S.E.A.G.U.A.R.D', gen_salt('bf')),
            updated_at = NOW()
        WHERE id = demo_user_id;
    END IF;
    
    -- Ensure user profile exists with all required metadata
    INSERT INTO public.user_profiles (
        id,
        full_name,
        user_role,
        organization,
        station_id,
        verification_status,
        created_at,
        updated_at
    ) VALUES (
        demo_user_id,
        'Captain Seaguard',
        'Admin',
        'SEAGUARD Maritime Systems',
        'SG-MAIN-001',
        'approved',
        NOW(),
        NOW()
    ) ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        user_role = EXCLUDED.user_role,
        organization = EXCLUDED.organization,
        station_id = EXCLUDED.station_id,
        verification_status = EXCLUDED.verification_status,
        updated_at = NOW();
        
    -- Create saved account entry
    INSERT INTO public.saved_accounts (
        user_id,
        vessel_name,
        captain_name,
        license_number,
        account_status,
        created_at,
        updated_at
    ) VALUES (
        demo_user_id,
        'S.E.A.G.U.A.R.D',
        'Captain Seaguard',
        'ML-2024-SG001',
        'active',
        NOW(),
        NOW()
    ) ON CONFLICT (user_id) DO UPDATE SET
        vessel_name = EXCLUDED.vessel_name,
        captain_name = EXCLUDED.captain_name,
        license_number = EXCLUDED.license_number,
        account_status = EXCLUDED.account_status,
        updated_at = NOW();
        
    RAISE NOTICE 'Demo user credentials updated: CAPTAINSEAGUARD@gmail.com / S.E.A.G.U.A.R.D';
END $$;

-- Add some fresh IoT data to test the ESP8266 function
INSERT INTO public.iot_data (
    temp,
    humidity,
    weight,
    ax,
    ay,
    az,
    gx,
    gy,
    gz,
    inserted_at
) VALUES 
    (28.5, 65.2, 145.7, -2.1, 1.3, 9.8, 0.02, -0.01, 0.05, NOW()),
    (28.7, 64.8, 146.2, -2.0, 1.4, 9.9, 0.01, -0.02, 0.04, NOW() - INTERVAL '30 seconds'),
    (28.3, 65.5, 144.9, -2.2, 1.2, 9.7, 0.03, 0.01, 0.06, NOW() - INTERVAL '1 minute');

-- Refresh the schema cache
NOTIFY pgrst, 'reload schema';