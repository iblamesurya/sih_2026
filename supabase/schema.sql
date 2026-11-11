-- =============================================================================
-- PrawnGuard.ai (SIH 2026) — Enterprise Aquaculture Intelligence Platform
-- Complete PostgreSQL Schema, Indexes, RLS Policies & RPC Functions
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. PROFILES
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE,
    full_name TEXT NOT NULL DEFAULT 'Farmer',
    preferred_locale TEXT NOT NULL DEFAULT 'te' CHECK (preferred_locale IN ('en', 'te')),
    role TEXT NOT NULL DEFAULT 'farmer' CHECK (role IN ('farmer', 'admin', 'technician')),
    subscription_tier TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro')),
    daily_scan_count INTEGER NOT NULL DEFAULT 0,
    last_scan_date DATE NOT NULL DEFAULT CURRENT_DATE,
    monthly_feed_calc_count INTEGER NOT NULL DEFAULT 0,
    monthly_report_export_count INTEGER NOT NULL DEFAULT 0,
    quota_reset_month TEXT NOT NULL DEFAULT to_char(CURRENT_DATE, 'YYYY-MM'),
    last_gps_lat DOUBLE PRECISION,
    last_gps_lng DOUBLE PRECISION,
    district TEXT DEFAULT 'West Godavari',
    state TEXT DEFAULT 'Andhra Pradesh',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 2. FARMS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.farms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    location_name TEXT,
    district TEXT DEFAULT 'West Godavari',
    state TEXT DEFAULT 'Andhra Pradesh',
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    total_area_ha DOUBLE PRECISION NOT NULL DEFAULT 1.0 CHECK (total_area_ha > 0),
    water_source TEXT DEFAULT 'Brackish Borewell / Creek',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 3. PONDS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.ponds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    farmer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    farm_id UUID REFERENCES public.farms(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    species TEXT NOT NULL DEFAULT 'L. vannamei',
    area_ha DOUBLE PRECISION NOT NULL DEFAULT 1.0 CHECK (area_ha > 0),
    stocking_density DOUBLE PRECISION NOT NULL DEFAULT 50.0 CHECK (stocking_density >= 0),
    doc INTEGER NOT NULL DEFAULT 1 CHECK (doc >= 0),
    stocking_date DATE NOT NULL DEFAULT CURRENT_DATE,
    initial_abw DOUBLE PRECISION NOT NULL DEFAULT 0.02 CHECK (initial_abw >= 0),
    current_abw DOUBLE PRECISION NOT NULL DEFAULT 15.0 CHECK (current_abw >= 0),
    survival_rate DOUBLE PRECISION NOT NULL DEFAULT 0.85 CHECK (survival_rate >= 0 AND survival_rate <= 1.0),
    status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Fallow', 'Harvested', 'Maintenance')),
    version INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 4. CROP CYCLES
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.crop_cycles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pond_id UUID NOT NULL REFERENCES public.ponds(id) ON DELETE CASCADE,
    cycle_number INTEGER NOT NULL DEFAULT 1,
    species TEXT NOT NULL DEFAULT 'L. vannamei',
    hatchery_source TEXT,
    pl_stage INTEGER DEFAULT 12,
    stocked_count INTEGER NOT NULL DEFAULT 100000 CHECK (stocked_count >= 0),
    stocking_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expected_harvest_date DATE,
    actual_harvest_date DATE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'aborted')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 5. WATER LOGS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.water_logs (
    id TEXT PRIMARY KEY DEFAULT ('wlog_' || extract(epoch from now())::bigint::text),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pond_id TEXT NOT NULL,
    ph DOUBLE PRECISION CHECK (ph >= 0 AND ph <= 14),
    dissolved_oxygen DOUBLE PRECISION CHECK (dissolved_oxygen >= 0 AND dissolved_oxygen <= 30),
    salinity DOUBLE PRECISION CHECK (salinity >= 0 AND salinity <= 60),
    temperature DOUBLE PRECISION CHECK (temperature >= 0 AND temperature <= 50),
    ammonia DOUBLE PRECISION CHECK (ammonia >= 0 AND ammonia <= 20),
    alkalinity DOUBLE PRECISION CHECK (alkalinity >= 0 AND alkalinity <= 500),
    turbidity_cm DOUBLE PRECISION,
    overall_severity TEXT DEFAULT 'optimal' CHECK (overall_severity IN ('optimal', 'watch', 'urgent')),
    source TEXT DEFAULT 'manual' CHECK (source IN ('manual', 'voice_nlu', 'iot_sensor')),
    idempotency_key UUID UNIQUE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 6. FEED LOGS
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.feed_logs (
    id TEXT PRIMARY KEY DEFAULT ('feed_' || extract(epoch from now())::bigint::text),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pond_id TEXT NOT NULL,
    doc INTEGER DEFAULT 1,
    biomass_kg DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (biomass_kg >= 0),
    feeding_rate DOUBLE PRECISION DEFAULT 0.05,
    daily_feed_kg DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (daily_feed_kg >= 0),
    meal_number INTEGER CHECK (meal_number BETWEEN 1 AND 4),
    scheduled_time TEXT,
    feed_kg DOUBLE PRECISION CHECK (feed_kg >= 0),
    percent_share DOUBLE PRECISION,
    meal1_kg DOUBLE PRECISION DEFAULT 0,
    meal2_kg DOUBLE PRECISION DEFAULT 0,
    meal3_kg DOUBLE PRECISION DEFAULT 0,
    meal4_kg DOUBLE PRECISION DEFAULT 0,
    meal1_completed BOOLEAN NOT NULL DEFAULT FALSE,
    meal2_completed BOOLEAN NOT NULL DEFAULT FALSE,
    meal3_completed BOOLEAN NOT NULL DEFAULT FALSE,
    meal4_completed BOOLEAN NOT NULL DEFAULT FALSE,
    check_tray_status TEXT DEFAULT 'normal' CHECK (check_tray_status IN ('clean', 'trace', 'normal', 'heavy', 'uneaten')),
    tray_adjustment DOUBLE PRECISION DEFAULT 0.0,
    temperature_c DOUBLE PRECISION DEFAULT 28.5,
    idempotency_key UUID UNIQUE,
    fed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 7. DISEASE SCANS (PrawnDoc Vision AI)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.disease_scans (
    id TEXT PRIMARY KEY DEFAULT ('scan_' || extract(epoch from now())::bigint::text),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pond_id TEXT NOT NULL DEFAULT '1',
    image_hash TEXT,
    image_storage_path TEXT,
    disease_code TEXT NOT NULL,
    disease_name TEXT NOT NULL,
    telugu_name TEXT,
    confidence DOUBLE PRECISION NOT NULL CHECK (confidence >= 0.0 AND confidence <= 1.0),
    severity TEXT NOT NULL DEFAULT 'watch' CHECK (severity IN ('optimal', 'watch', 'urgent', 'critical', 'high', 'medium', 'low')),
    is_emergency_harvest BOOLEAN NOT NULL DEFAULT FALSE,
    immediate_action TEXT,
    telugu_action TEXT,
    treatment_plan JSONB DEFAULT '[]'::jsonb,
    water_context JSONB DEFAULT '{}'::jsonb,
    farmer_notes TEXT,
    idempotency_key UUID UNIQUE,
    scanned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 8. GROWTH SAMPLES
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.growth_samples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pond_id TEXT NOT NULL,
    crop_cycle_id UUID REFERENCES public.crop_cycles(id) ON DELETE SET NULL,
    doc INTEGER NOT NULL CHECK (doc >= 0),
    sample_count INTEGER NOT NULL DEFAULT 50 CHECK (sample_count > 0),
    total_weight_g DOUBLE PRECISION NOT NULL CHECK (total_weight_g > 0),
    abw_g DOUBLE PRECISION NOT NULL CHECK (abw_g > 0),
    adg_g_per_day DOUBLE PRECISION DEFAULT 0.25,
    estimated_survival_rate DOUBLE PRECISION DEFAULT 0.85 CHECK (estimated_survival_rate >= 0 AND estimated_survival_rate <= 1.0),
    sampled_at DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 9. ABW SAMPLES
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.abw_samples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pond_id TEXT NOT NULL,
    doc INTEGER NOT NULL CHECK (doc >= 0),
    abw_grams DOUBLE PRECISION NOT NULL CHECK (abw_grams > 0),
    previous_abw_grams DOUBLE PRECISION,
    adg_grams DOUBLE PRECISION,
    uniformity_pct DOUBLE PRECISION DEFAULT 85.0,
    shell_condition TEXT DEFAULT 'Hard / Normal',
    gut_fullness_pct DOUBLE PRECISION DEFAULT 90.0,
    idempotency_key UUID UNIQUE,
    sampled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 10. EXPENSES (PrawnCredit Ledger)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.expenses (
    id TEXT PRIMARY KEY DEFAULT ('exp_' || extract(epoch from now())::bigint::text),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pond_id TEXT NOT NULL,
    pond_name TEXT NOT NULL DEFAULT 'Pond 1',
    category TEXT NOT NULL CHECK (category IN ('feed', 'seedPL', 'probioticsChemicals', 'powerFuel', 'labor', 'equipmentMaintenance', 'other')),
    amount DOUBLE PRECISION NOT NULL CHECK (amount >= 0),
    supplier TEXT,
    notes TEXT,
    idempotency_key UUID UNIQUE,
    expense_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 11. HARVESTS (PrawnCredit Cashflow)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.harvests (
    id TEXT PRIMARY KEY DEFAULT ('hrv_' || extract(epoch from now())::bigint::text),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pond_id TEXT NOT NULL,
    pond_name TEXT NOT NULL DEFAULT 'Pond 1',
    harvest_type TEXT NOT NULL DEFAULT 'Partial' CHECK (harvest_type IN ('Partial', 'Complete', 'Emergency')),
    biomass_kg DOUBLE PRECISION NOT NULL CHECK (biomass_kg >= 0),
    count_per_kg INTEGER NOT NULL CHECK (count_per_kg > 0),
    price_per_kg DOUBLE PRECISION NOT NULL CHECK (price_per_kg >= 0),
    total_revenue DOUBLE PRECISION GENERATED ALWAYS AS (biomass_kg * price_per_kg) STORED,
    fcr DOUBLE PRECISION NOT NULL DEFAULT 1.3 CHECK (fcr >= 0),
    buyer_name TEXT,
    idempotency_key UUID UNIQUE,
    harvest_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 12. MARKET PRICES (Mandi & Exporter Rates)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.market_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hub_name TEXT NOT NULL DEFAULT 'Bhimavaram (West Godavari, AP)',
    species TEXT NOT NULL DEFAULT 'L. vannamei',
    count_grade TEXT NOT NULL,
    count_per_kg INTEGER NOT NULL CHECK (count_per_kg > 0),
    price_inr_per_kg DOUBLE PRECISION NOT NULL CHECK (price_inr_per_kg > 0),
    price_change_inr DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    demand_level TEXT NOT NULL DEFAULT 'High' CHECK (demand_level IN ('Low', 'Moderate', 'Stable', 'High', 'Very High')),
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 13. ADMIN ANNOUNCEMENTS (State Fisheries & PrawnDoc Advisories)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.admin_announcements (
    id TEXT PRIMARY KEY DEFAULT ('ann_' || extract(epoch from now())::bigint::text),
    title TEXT NOT NULL,
    telugu_title TEXT,
    body TEXT NOT NULL,
    telugu_body TEXT,
    category TEXT NOT NULL DEFAULT 'Disease Warning' CHECK (category IN ('Weather Advisory', 'Disease Warning', 'Scheme & Subsidy', 'Market Update', 'General')),
    priority TEXT NOT NULL DEFAULT 'High' CHECK (priority IN ('Normal', 'High', 'Critical')),
    target_region TEXT NOT NULL DEFAULT 'All Andhra Pradesh',
    author TEXT NOT NULL DEFAULT 'State Fisheries Dept & PrawnGuard AI',
    recipient_count INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Archived', 'Draft')),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 14. ACTIVITY EVENTS (Audit & Telemetry Event Stream)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.activity_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    pond_id TEXT,
    event_type TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'watch', 'urgent', 'critical')),
    title TEXT NOT NULL,
    description TEXT,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 15. NOTIFICATION PREFERENCES
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    critical_water_alerts BOOLEAN NOT NULL DEFAULT TRUE,
    hypoxia_weather_warnings BOOLEAN NOT NULL DEFAULT TRUE,
    feed_schedule_reminders BOOLEAN NOT NULL DEFAULT TRUE,
    mandi_price_updates BOOLEAN NOT NULL DEFAULT TRUE,
    disease_outbreak_broadcasts BOOLEAN NOT NULL DEFAULT TRUE,
    sms_fallback_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    whatsapp_alerts_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    quiet_hours_start TIME DEFAULT '22:30',
    quiet_hours_end TIME DEFAULT '05:00',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- 16. MUTATION LEDGER (Idempotency Tracking)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.mutation_ledger (
    idempotency_key UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    payload JSONB,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- INDEXES FOR HIGH-THROUGHPUT AQUACULTURE TELEMETRY QUERIES
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_farms_owner_id ON public.farms(owner_id);
CREATE INDEX IF NOT EXISTS idx_ponds_user_id ON public.ponds(user_id);
CREATE INDEX IF NOT EXISTS idx_ponds_farmer_id ON public.ponds(farmer_id);
CREATE INDEX IF NOT EXISTS idx_ponds_farm_id ON public.ponds(farm_id);
CREATE INDEX IF NOT EXISTS idx_crop_cycles_pond_id ON public.crop_cycles(pond_id);
CREATE INDEX IF NOT EXISTS idx_water_logs_pond_recorded ON public.water_logs(pond_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_water_logs_user_id ON public.water_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_water_logs_user_recorded ON public.water_logs(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_feed_logs_pond_fed ON public.feed_logs(pond_id, fed_at DESC);
CREATE INDEX IF NOT EXISTS idx_feed_logs_user_id ON public.feed_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_feed_logs_user_fed ON public.feed_logs(user_id, fed_at DESC);
CREATE INDEX IF NOT EXISTS idx_disease_scans_user_scanned ON public.disease_scans(user_id, scanned_at DESC);
CREATE INDEX IF NOT EXISTS idx_disease_scans_pond_id ON public.disease_scans(pond_id);
CREATE INDEX IF NOT EXISTS idx_disease_scans_image_hash ON public.disease_scans(image_hash);
CREATE INDEX IF NOT EXISTS idx_growth_samples_pond_doc ON public.growth_samples(pond_id, doc DESC);
CREATE INDEX IF NOT EXISTS idx_abw_samples_pond_doc ON public.abw_samples(pond_id, doc DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user_date ON public.expenses(user_id, expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_pond_id ON public.expenses(pond_id);
CREATE INDEX IF NOT EXISTS idx_harvests_user_date ON public.harvests(user_id, harvest_date DESC);
CREATE INDEX IF NOT EXISTS idx_harvests_pond_id ON public.harvests(pond_id);
CREATE INDEX IF NOT EXISTS idx_market_prices_hub_count ON public.market_prices(hub_name, count_per_kg, effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_market_prices_effective_date ON public.market_prices(effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_admin_announcements_status ON public.admin_announcements(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_events_user_created ON public.activity_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mutation_ledger_user_applied ON public.mutation_ledger(user_id, applied_at DESC);

-- =============================================================================
-- ATOMIC QUOTA RPC: increment_scan_count
-- =============================================================================
CREATE OR REPLACE FUNCTION public.increment_scan_count(
    p_user_id UUID DEFAULT auth.uid(),
    p_free_daily_limit INTEGER DEFAULT 3
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_tier TEXT;
    v_count INTEGER;
    v_last_date DATE;
    v_allowed BOOLEAN;
    v_remaining INTEGER;
BEGIN
    IF p_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to increment scan count';
    END IF;

    SELECT subscription_tier, daily_scan_count, last_scan_date
    INTO v_tier, v_count, v_last_date
    FROM public.profiles
    WHERE id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'allowed', true,
            'daily_scan_count', 1,
            'remaining', p_free_daily_limit - 1,
            'tier', 'free'
        );
    END IF;

    -- Reset counter if date rolled over
    IF v_last_date IS NULL OR v_last_date < CURRENT_DATE THEN
        v_count := 0;
        v_last_date := CURRENT_DATE;
    END IF;

    IF v_tier = 'pro' THEN
        v_count := v_count + 1;
        v_allowed := TRUE;
        v_remaining := 999999;
    ELSE
        IF v_count >= p_free_daily_limit THEN
            v_allowed := FALSE;
            v_remaining := 0;
        ELSE
            v_count := v_count + 1;
            v_allowed := TRUE;
            v_remaining := GREATEST(0, p_free_daily_limit - v_count);
        END IF;
    END IF;

    UPDATE public.profiles
    SET daily_scan_count = v_count,
        last_scan_date = v_last_date,
        updated_at = NOW()
    WHERE id = p_user_id;

    RETURN jsonb_build_object(
        'allowed', v_allowed,
        'daily_scan_count', v_count,
        'remaining', v_remaining,
        'tier', v_tier
    );
END;
$$;

-- =============================================================================
-- IMMUTABLE ROLE & ADMIN HELPER: is_admin
-- =============================================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
        OR (auth.jwt() ->> 'role') = 'service_role',
        FALSE
    );
$$;

-- =============================================================================
-- PRIVILEGE ESCALATION PREVENTION TRIGGER: prevent_role_escalation
-- =============================================================================
CREATE OR REPLACE FUNCTION public.prevent_role_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
        IF NOT (
            (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
            OR (auth.jwt() ->> 'role') = 'service_role'
        ) THEN
            RAISE EXCEPTION 'Unauthorized: only admin or service_role can modify user roles'
                USING ERRCODE = '42501';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_role_escalation ON public.profiles;
CREATE TRIGGER trg_prevent_role_escalation
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.prevent_role_escalation();

-- =============================================================================
-- OPTIMISTIC CONCURRENCY TRIGGER: increment_pond_version
-- =============================================================================
CREATE OR REPLACE FUNCTION public.increment_pond_version()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.version IS DISTINCT FROM OLD.version THEN
        RAISE EXCEPTION 'Optimistic concurrency error: pond version mismatch (current %, provided %)',
            OLD.version, NEW.version
            USING ERRCODE = 'P0002';
    END IF;
    NEW.version := OLD.version + 1;
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_increment_pond_version ON public.ponds;
CREATE TRIGGER trg_increment_pond_version
    BEFORE UPDATE ON public.ponds
    FOR EACH ROW
    EXECUTE FUNCTION public.increment_pond_version();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ponds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crop_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.water_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disease_scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.growth_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.abw_samples ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.harvests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.market_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mutation_ledger ENABLE ROW LEVEL SECURITY;

-- Profiles: users can view and update their own profile
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Farms: owner full CRUD
CREATE POLICY "farms_all_own" ON public.farms
    FOR ALL USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);

-- Ponds: owner full CRUD
CREATE POLICY "ponds_all_own" ON public.ponds
    FOR ALL USING (auth.uid() = user_id OR auth.uid() = farmer_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR auth.uid() = farmer_id OR public.is_admin());

-- Crop cycles: owner full CRUD
CREATE POLICY "crop_cycles_all_own" ON public.crop_cycles
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- Water logs: transitive isolation through ponds
CREATE POLICY "water_logs_all_own" ON public.water_logs
    FOR ALL USING (
        (auth.uid() = user_id OR public.is_admin()) AND
        EXISTS (
            SELECT 1 FROM public.ponds p
            WHERE p.id::text = water_logs.pond_id
              AND (p.user_id = auth.uid() OR p.farmer_id = auth.uid() OR public.is_admin())
        )
    )
    WITH CHECK (
        (auth.uid() = user_id OR public.is_admin()) AND
        EXISTS (
            SELECT 1 FROM public.ponds p
            WHERE p.id::text = water_logs.pond_id
              AND (p.user_id = auth.uid() OR p.farmer_id = auth.uid() OR public.is_admin())
        )
    );

-- Feed logs: transitive isolation through ponds
CREATE POLICY "feed_logs_all_own" ON public.feed_logs
    FOR ALL USING (
        (auth.uid() = user_id OR public.is_admin()) AND
        EXISTS (
            SELECT 1 FROM public.ponds p
            WHERE p.id::text = feed_logs.pond_id
              AND (p.user_id = auth.uid() OR p.farmer_id = auth.uid() OR public.is_admin())
        )
    )
    WITH CHECK (
        (auth.uid() = user_id OR public.is_admin()) AND
        EXISTS (
            SELECT 1 FROM public.ponds p
            WHERE p.id::text = feed_logs.pond_id
              AND (p.user_id = auth.uid() OR p.farmer_id = auth.uid() OR public.is_admin())
        )
    );

-- Disease scans: owner full CRUD
CREATE POLICY "disease_scans_all_own" ON public.disease_scans
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- Growth samples: owner full CRUD
CREATE POLICY "growth_samples_all_own" ON public.growth_samples
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- ABW samples: owner full CRUD
CREATE POLICY "abw_samples_all_own" ON public.abw_samples
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- Expenses: transitive isolation through ponds
CREATE POLICY "expenses_all_own" ON public.expenses
    FOR ALL USING (
        (auth.uid() = user_id OR public.is_admin()) AND
        EXISTS (
            SELECT 1 FROM public.ponds p
            WHERE p.id::text = expenses.pond_id
              AND (p.user_id = auth.uid() OR p.farmer_id = auth.uid() OR public.is_admin())
        )
    )
    WITH CHECK (
        (auth.uid() = user_id OR public.is_admin()) AND
        EXISTS (
            SELECT 1 FROM public.ponds p
            WHERE p.id::text = expenses.pond_id
              AND (p.user_id = auth.uid() OR p.farmer_id = auth.uid() OR public.is_admin())
        )
    );

-- Harvests: transitive isolation through ponds
CREATE POLICY "harvests_all_own" ON public.harvests
    FOR ALL USING (
        (auth.uid() = user_id OR public.is_admin()) AND
        EXISTS (
            SELECT 1 FROM public.ponds p
            WHERE p.id::text = harvests.pond_id
              AND (p.user_id = auth.uid() OR p.farmer_id = auth.uid() OR public.is_admin())
        )
    )
    WITH CHECK (
        (auth.uid() = user_id OR public.is_admin()) AND
        EXISTS (
            SELECT 1 FROM public.ponds p
            WHERE p.id::text = harvests.pond_id
              AND (p.user_id = auth.uid() OR p.farmer_id = auth.uid() OR public.is_admin())
        )
    );

-- Market prices: public read for all authenticated/anon users; immutable admin write
CREATE POLICY "market_prices_select_all" ON public.market_prices
    FOR SELECT USING (true);
CREATE POLICY "market_prices_write_admin" ON public.market_prices
    FOR ALL USING (public.is_admin());

-- Admin announcements: public read for all users; immutable admin write
CREATE POLICY "admin_announcements_select_all" ON public.admin_announcements
    FOR SELECT USING (true);
CREATE POLICY "admin_announcements_write_admin" ON public.admin_announcements
    FOR ALL USING (public.is_admin());

-- Activity events: owner full CRUD
CREATE POLICY "activity_events_all_own" ON public.activity_events
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- Notification preferences: owner full CRUD
CREATE POLICY "notification_preferences_all_own" ON public.notification_preferences
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- Mutation ledger: owner full CRUD
CREATE POLICY "mutation_ledger_all_own" ON public.mutation_ledger
    FOR ALL USING (auth.uid() = user_id OR public.is_admin())
    WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- =============================================================================
-- ATOMIC IDEMPOTENT MUTATION RPC: apply_idempotent_mutation
-- =============================================================================
CREATE OR REPLACE FUNCTION public.apply_idempotent_mutation(
    p_idempotency_key UUID,
    p_table_name TEXT,
    p_operation TEXT,
    p_payload JSONB,
    p_base_version INT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_inserted_key UUID;
    v_current_version INT;
    v_record_id TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required for mutation' USING ERRCODE = '42501';
    END IF;

    -- 1. Atomic insertion into mutation_ledger to eliminate TOCTOU races
    INSERT INTO public.mutation_ledger (
        idempotency_key, user_id, table_name, operation, payload, applied_at
    ) VALUES (
        p_idempotency_key, v_user_id, p_table_name, p_operation, p_payload, NOW()
    )
    ON CONFLICT (idempotency_key) DO NOTHING
    RETURNING idempotency_key INTO v_inserted_key;

    IF v_inserted_key IS NULL THEN
        RETURN jsonb_build_object(
            'status', 'duplicate',
            'applied', true,
            'idempotency_key', p_idempotency_key
        );
    END IF;

    v_record_id := p_payload->>'id';

    -- 2. Optimistic Concurrency check for ponds
    IF p_table_name = 'ponds' AND UPPER(p_operation) IN ('UPDATE', 'UPSERT') THEN
        IF p_base_version IS NOT NULL AND (p_payload->>'id') IS NOT NULL THEN
            SELECT version INTO v_current_version
            FROM public.ponds
            WHERE id = (p_payload->>'id')::uuid;

            IF FOUND AND v_current_version != p_base_version THEN
                RAISE EXCEPTION 'Optimistic concurrency error: pond version mismatch (current %, expected %)',
                    v_current_version, p_base_version
                    USING ERRCODE = 'P0002';
            END IF;
        END IF;
    END IF;

    -- 3. Execute mutation dynamically by table
    IF p_table_name = 'water_logs' THEN
        IF UPPER(p_operation) = 'INSERT' THEN
            INSERT INTO public.water_logs (
                id, user_id, pond_id, ph, dissolved_oxygen, salinity,
                temperature, ammonia, alkalinity, turbidity_cm,
                overall_severity, source, recorded_at, idempotency_key
            ) VALUES (
                COALESCE(v_record_id, 'wlog_' || extract(epoch from now())::bigint::text),
                v_user_id,
                p_payload->>'pond_id',
                (p_payload->>'ph')::DOUBLE PRECISION,
                (p_payload->>'dissolved_oxygen')::DOUBLE PRECISION,
                (p_payload->>'salinity')::DOUBLE PRECISION,
                (p_payload->>'temperature')::DOUBLE PRECISION,
                (p_payload->>'ammonia')::DOUBLE PRECISION,
                (p_payload->>'alkalinity')::DOUBLE PRECISION,
                (p_payload->>'turbidity_cm')::DOUBLE PRECISION,
                COALESCE(p_payload->>'overall_severity', 'optimal'),
                COALESCE(p_payload->>'source', 'manual'),
                COALESCE((p_payload->>'recorded_at')::TIMESTAMPTZ, NOW()),
                p_idempotency_key
            )
            ON CONFLICT (idempotency_key) DO NOTHING;
        END IF;

    ELSIF p_table_name = 'feed_logs' THEN
        IF UPPER(p_operation) = 'INSERT' THEN
            INSERT INTO public.feed_logs (
                id, user_id, pond_id, doc, biomass_kg, feeding_rate, daily_feed_kg,
                meal_number, scheduled_time, feed_kg, percent_share,
                meal1_kg, meal2_kg, meal3_kg, meal4_kg,
                meal1_completed, meal2_completed, meal3_completed, meal4_completed,
                check_tray_status, tray_adjustment, temperature_c, fed_at, idempotency_key
            ) VALUES (
                COALESCE(v_record_id, 'feed_' || extract(epoch from now())::bigint::text),
                v_user_id,
                p_payload->>'pond_id',
                COALESCE((p_payload->>'doc')::INTEGER, 1),
                COALESCE((p_payload->>'biomass_kg')::DOUBLE PRECISION, 0),
                COALESCE((p_payload->>'feeding_rate')::DOUBLE PRECISION, 0.05),
                COALESCE((p_payload->>'daily_feed_kg')::DOUBLE PRECISION, 0),
                (p_payload->>'meal_number')::INTEGER,
                p_payload->>'scheduled_time',
                (p_payload->>'feed_kg')::DOUBLE PRECISION,
                (p_payload->>'percent_share')::DOUBLE PRECISION,
                COALESCE((p_payload->>'meal1_kg')::DOUBLE PRECISION, 0),
                COALESCE((p_payload->>'meal2_kg')::DOUBLE PRECISION, 0),
                COALESCE((p_payload->>'meal3_kg')::DOUBLE PRECISION, 0),
                COALESCE((p_payload->>'meal4_kg')::DOUBLE PRECISION, 0),
                COALESCE((p_payload->>'meal1_completed')::BOOLEAN, FALSE),
                COALESCE((p_payload->>'meal2_completed')::BOOLEAN, FALSE),
                COALESCE((p_payload->>'meal3_completed')::BOOLEAN, FALSE),
                COALESCE((p_payload->>'meal4_completed')::BOOLEAN, FALSE),
                COALESCE(p_payload->>'check_tray_status', 'normal'),
                COALESCE((p_payload->>'tray_adjustment')::DOUBLE PRECISION, 0.0),
                COALESCE((p_payload->>'temperature_c')::DOUBLE PRECISION, 28.5),
                COALESCE((p_payload->>'fed_at')::TIMESTAMPTZ, NOW()),
                p_idempotency_key
            )
            ON CONFLICT (idempotency_key) DO NOTHING;
        END IF;

    ELSIF p_table_name = 'ponds' THEN
        IF UPPER(p_operation) = 'INSERT' THEN
            INSERT INTO public.ponds (
                id, user_id, farmer_id, farm_id, name, species, area_ha,
                stocking_density, doc, stocking_date, initial_abw,
                current_abw, survival_rate, status, version
            ) VALUES (
                COALESCE((p_payload->>'id')::uuid, gen_random_uuid()),
                v_user_id,
                v_user_id,
                (p_payload->>'farm_id')::UUID,
                p_payload->>'name',
                COALESCE(p_payload->>'species', 'L. vannamei'),
                COALESCE((p_payload->>'area_ha')::DOUBLE PRECISION, 1.0),
                COALESCE((p_payload->>'stocking_density')::DOUBLE PRECISION, 50.0),
                COALESCE((p_payload->>'doc')::INTEGER, 1),
                COALESCE((p_payload->>'stocking_date')::DATE, CURRENT_DATE),
                COALESCE((p_payload->>'initial_abw')::DOUBLE PRECISION, 0.02),
                COALESCE((p_payload->>'current_abw')::DOUBLE PRECISION, 15.0),
                COALESCE((p_payload->>'survival_rate')::DOUBLE PRECISION, 0.85),
                COALESCE(p_payload->>'status', 'Active'),
                1
            );
        ELSIF UPPER(p_operation) = 'UPDATE' THEN
            UPDATE public.ponds
            SET name = COALESCE(p_payload->>'name', name),
                current_abw = COALESCE((p_payload->>'current_abw')::DOUBLE PRECISION, current_abw),
                doc = COALESCE((p_payload->>'doc')::INTEGER, doc),
                survival_rate = COALESCE((p_payload->>'survival_rate')::DOUBLE PRECISION, survival_rate),
                status = COALESCE(p_payload->>'status', status),
                updated_at = NOW()
            WHERE id = (p_payload->>'id')::uuid
              AND (user_id = v_user_id OR farmer_id = v_user_id OR public.is_admin());
        END IF;

    ELSIF p_table_name = 'expenses' THEN
        IF UPPER(p_operation) = 'INSERT' THEN
            INSERT INTO public.expenses (
                id, user_id, pond_id, pond_name, category,
                amount, supplier, notes, expense_date, idempotency_key
            ) VALUES (
                COALESCE(v_record_id, 'exp_' || extract(epoch from now())::bigint::text),
                v_user_id,
                p_payload->>'pond_id',
                COALESCE(p_payload->>'pond_name', 'Pond 1'),
                p_payload->>'category',
                (p_payload->>'amount')::DOUBLE PRECISION,
                p_payload->>'supplier',
                p_payload->>'notes',
                COALESCE((p_payload->>'expense_date')::TIMESTAMPTZ, NOW()),
                p_idempotency_key
            )
            ON CONFLICT (idempotency_key) DO NOTHING;
        END IF;

    ELSIF p_table_name = 'harvests' THEN
        IF UPPER(p_operation) = 'INSERT' THEN
            INSERT INTO public.harvests (
                id, user_id, pond_id, pond_name, harvest_type,
                biomass_kg, count_per_kg, price_per_kg, fcr,
                buyer_name, harvest_date, idempotency_key
            ) VALUES (
                COALESCE(v_record_id, 'hrv_' || extract(epoch from now())::bigint::text),
                v_user_id,
                p_payload->>'pond_id',
                COALESCE(p_payload->>'pond_name', 'Pond 1'),
                COALESCE(p_payload->>'harvest_type', 'Partial'),
                (p_payload->>'biomass_kg')::DOUBLE PRECISION,
                (p_payload->>'count_per_kg')::INTEGER,
                (p_payload->>'price_per_kg')::DOUBLE PRECISION,
                COALESCE((p_payload->>'fcr')::DOUBLE PRECISION, 1.3),
                p_payload->>'buyer_name',
                COALESCE((p_payload->>'harvest_date')::TIMESTAMPTZ, NOW()),
                p_idempotency_key
            )
            ON CONFLICT (idempotency_key) DO NOTHING;
        END IF;
    END IF;

    RETURN jsonb_build_object(
        'status', 'success',
        'idempotency_key', p_idempotency_key,
        'table_name', p_table_name,
        'operation', p_operation,
        'applied_at', NOW()
    );
END;
$$;
