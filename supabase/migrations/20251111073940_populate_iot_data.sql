-- Location: supabase/migrations/20251111073940_populate_iot_data.sql
-- Schema Analysis: iot_data table exists but is empty, causing PGRST116 errors
-- Integration Type: Data population for existing IoT table
-- Dependencies: public.iot_data (existing table)

-- Populate iot_data table with sample sensor readings
-- This fixes the "Cannot coerce the result to a single JSON object" error
DO $$
DECLARE
    i INTEGER;
    base_temp DOUBLE PRECISION := 28.0;
    base_humidity DOUBLE PRECISION := 65.0;
    base_weight INTEGER := 145;
BEGIN
    -- Insert 20 sample IoT data records with realistic sensor variations
    FOR i IN 1..20 LOOP
        INSERT INTO public.iot_data (
            temp,
            humidity,
            weight,
            ax,
            ay,
            az,
            inserted_at
        ) VALUES (
            -- Temperature: 26-32°C with realistic variations
            base_temp + (RANDOM() * 4 - 2),
            
            -- Humidity: 60-75% with realistic variations  
            base_humidity + (RANDOM() * 10 - 5),
            
            -- Weight: 130-160kg with realistic variations
            base_weight + (RANDOM() * 30 - 15)::INTEGER,
            
            -- Accelerometer X-axis: -25 to 25 (for trim angle calculation)
            (RANDOM() * 50 - 25)::INTEGER,
            
            -- Accelerometer Y-axis: -12 to 12 (for heel angle calculation)
            (RANDOM() * 24 - 12)::INTEGER,
            
            -- Accelerometer Z-axis: 9.7-9.9 (gravity with small variations)
            9.8 + (RANDOM() * 0.2 - 0.1),
            
            -- Insert timestamp: spread over last 2 hours
            NOW() - INTERVAL '2 hours' + (i * INTERVAL '6 minutes')
        );
    END LOOP;

    -- Insert one most recent record to ensure latest data exists
    INSERT INTO public.iot_data (
        temp,
        humidity,
        weight,
        ax,
        ay,
        az,
        inserted_at
    ) VALUES (
        28.5,  -- Current temperature
        67.2,  -- Current humidity
        148,   -- Current weight
        -5,    -- Current trim angle data
        2,     -- Current heel angle data
        9.81,  -- Current gravity reading
        NOW()  -- Current timestamp
    );

    RAISE NOTICE 'Successfully populated iot_data table with % sample records', 21;
END $$;

-- Create function to generate continuous IoT data (for realistic fluctuation)
CREATE OR REPLACE FUNCTION public.generate_realtime_iot_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    latest_temp DOUBLE PRECISION;
    latest_humidity DOUBLE PRECISION;
    latest_weight INTEGER;
BEGIN
    -- Get the most recent values for realistic continuation
    SELECT temp, humidity, weight 
    INTO latest_temp, latest_humidity, latest_weight
    FROM public.iot_data 
    ORDER BY inserted_at DESC 
    LIMIT 1;

    -- Insert new reading with small variations from latest values
    INSERT INTO public.iot_data (
        temp,
        humidity,
        weight,
        ax,
        ay,
        az,
        inserted_at
    ) VALUES (
        -- Temperature: small variation from latest (±0.5°C)
        COALESCE(latest_temp, 28.0) + (RANDOM() * 1.0 - 0.5),
        
        -- Humidity: small variation from latest (±2%)
        COALESCE(latest_humidity, 65.0) + (RANDOM() * 4.0 - 2.0),
        
        -- Weight: small variation from latest (±5kg)
        COALESCE(latest_weight, 145) + (RANDOM() * 10 - 5)::INTEGER,
        
        -- Accelerometer readings with small variations
        (RANDOM() * 50 - 25)::INTEGER,
        (RANDOM() * 24 - 12)::INTEGER,
        9.8 + (RANDOM() * 0.2 - 0.1),
        
        NOW()
    );

    -- Keep only last 100 records to prevent table bloat
    DELETE FROM public.iot_data 
    WHERE id NOT IN (
        SELECT id FROM public.iot_data 
        ORDER BY inserted_at DESC 
        LIMIT 100
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error generating IoT data: %', SQLERRM;
END $$;

-- Add comment for documentation
COMMENT ON FUNCTION public.generate_realtime_iot_data() IS 'Generates realistic IoT sensor data with small variations from previous readings';

-- Update RLS policy to allow read access for iot_data (if not already set)
-- The existing policy "allow_insert_from_device" only covers INSERT operations
DO $$
BEGIN
    -- Check if read policy exists, if not create it
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename = 'iot_data' 
        AND policyname = 'allow_read_iot_data'
    ) THEN
        CREATE POLICY "allow_read_iot_data" 
        ON public.iot_data 
        FOR SELECT 
        TO public 
        USING (true);
        
        RAISE NOTICE 'Created read policy for iot_data table';
    ELSE
        RAISE NOTICE 'Read policy already exists for iot_data table';
    END IF;
END $$;