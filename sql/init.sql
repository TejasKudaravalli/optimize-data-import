-- Create the countries table

CREATE TABLE IF NOT EXISTS public.countries (
    name character varying NOT NULL,
    iso character varying NOT NULL,
    continent character varying NOT NULL,
    region character varying NOT NULL,
    "phonePrefix" character varying(10) NOT NULL,
    "flagEmoticon" character varying(64) NOT NULL,
    "flagImage" character varying(128) NOT NULL
);
-- Drop the constraint if it exists, before adding it to make it idempotent.
ALTER TABLE ONLY public.countries DROP CONSTRAINT IF EXISTS "PK_a1c0d005a87cc318b4ddda4d925";
ALTER TABLE ONLY public.countries ADD CONSTRAINT "PK_a1c0d005a87cc318b4ddda4d925" PRIMARY KEY (iso);



-- Create the hotels table

CREATE TABLE IF NOT EXISTS public.ratehawk_hotels (
    code text NOT NULL,
    name text NOT NULL,
    images text[],
    phone_number text,
    coordinates double precision[],
    email character varying(128),
    accommodation_type character varying(128),
    chain character varying(128),
    "addressCountryiso" character varying,
    "addressCity" text NOT NULL,
    "addressZipcode" character varying(128) DEFAULT ''::character varying,
    "addressAptnumber" character varying(128) DEFAULT ''::character varying NOT NULL,
    "addressState" character varying(64) DEFAULT ''::character varying NOT NULL,
    "addressStreetaddress" character varying(256) DEFAULT ''::character varying NOT NULL,
    rating smallint DEFAULT '0'::smallint NOT NULL,
    description_struct text,
    amenity_groups text,
    check_out_time text,
    check_in_time text,
    facts text,
    front_desk_time_end text,
    front_desk_time_start text,
    is_closed text,
    metapolicy_extra_info text,
    metapolicy_struct text,
    policy_struct text,
    payment_methods text,
    air_conditioning boolean,
    beach boolean,
    has_airport_transfer boolean,
    has_business boolean,
    has_disabled_support boolean,
    has_ecar_charger boolean,
    has_fitness boolean,
    has_internet boolean,
    has_jacuzzi boolean,
    has_kids boolean,
    has_meal boolean,
    has_parking boolean,
    has_pets boolean,
    has_pool boolean,
    has_ski boolean,
    has_smoking boolean,
    has_spa boolean,
    kitchen boolean
);
-- Drop the constraint if it exists, before adding it to make it idempotent.
ALTER TABLE ONLY public.ratehawk_hotels DROP CONSTRAINT IF EXISTS "PK_cbc92a694122140dcf136c60552";
ALTER TABLE ONLY public.ratehawk_hotels ADD CONSTRAINT "PK_cbc92a694122140dcf136c60552" PRIMARY KEY (code);
CREATE INDEX IF NOT EXISTS idx_air_conditioning_true ON public.ratehawk_hotels USING btree (air_conditioning) WHERE (air_conditioning = true);
CREATE INDEX IF NOT EXISTS idx_beach_true ON public.ratehawk_hotels USING btree (beach) WHERE (beach = true);
-- Create the trigram extension for the gin index
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_gin ON public.ratehawk_hotels USING gin (name public.gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_has_airport_transfer_true ON public.ratehawk_hotels USING btree (has_airport_transfer) WHERE (has_airport_transfer = true);
CREATE INDEX IF NOT EXISTS idx_has_business_true ON public.ratehawk_hotels USING btree (has_business) WHERE (has_business = true);
CREATE INDEX IF NOT EXISTS idx_has_disabled_support_true ON public.ratehawk_hotels USING btree (has_disabled_support) WHERE (has_disabled_support = true);
CREATE INDEX IF NOT EXISTS idx_has_ecar_charger_true ON public.ratehawk_hotels USING btree (has_ecar_charger) WHERE (has_ecar_charger = true);
CREATE INDEX IF NOT EXISTS idx_has_fitness_true ON public.ratehawk_hotels USING btree (has_fitness) WHERE (has_fitness = true);
CREATE INDEX IF NOT EXISTS idx_has_internet_true ON public.ratehawk_hotels USING btree (has_internet) WHERE (has_internet = true);
CREATE INDEX IF NOT EXISTS idx_has_jacuzzi_true ON public.ratehawk_hotels USING btree (has_jacuzzi) WHERE (has_jacuzzi = true);
CREATE INDEX IF NOT EXISTS idx_has_kids_true ON public.ratehawk_hotels USING btree (has_kids) WHERE (has_kids = true);
CREATE INDEX IF NOT EXISTS idx_has_meal_true ON public.ratehawk_hotels USING btree (has_meal) WHERE (has_meal = true);
CREATE INDEX IF NOT EXISTS idx_has_parking_true ON public.ratehawk_hotels USING btree (has_parking) WHERE (has_parking = true);
CREATE INDEX IF NOT EXISTS idx_has_pets_true ON public.ratehawk_hotels USING btree (has_pets) WHERE (has_pets = true);
CREATE INDEX IF NOT EXISTS idx_has_pool_true ON public.ratehawk_hotels USING btree (has_pool) WHERE (has_pool = true);
CREATE INDEX IF NOT EXISTS idx_has_ski_true ON public.ratehawk_hotels USING btree (has_ski) WHERE (has_ski = true);
CREATE INDEX IF NOT EXISTS idx_has_smoking_true ON public.ratehawk_hotels USING btree (has_smoking) WHERE (has_smoking = true);
CREATE INDEX IF NOT EXISTS idx_has_spa_true ON public.ratehawk_hotels USING btree (has_spa) WHERE (has_spa = true);
CREATE INDEX IF NOT EXISTS idx_kitchen_true ON public.ratehawk_hotels USING btree (kitchen) WHERE (kitchen = true);
CREATE INDEX IF NOT EXISTS ratehawk_hotels_accommodation_type_idx ON public.ratehawk_hotels USING btree (accommodation_type);
CREATE INDEX IF NOT EXISTS "ratehawk_hotels_addressCity_idx" ON public.ratehawk_hotels USING btree ("addressCity");
CREATE INDEX IF NOT EXISTS "ratehawk_hotels_addressCountryiso_idx" ON public.ratehawk_hotels USING btree ("addressCountryiso");
CREATE INDEX IF NOT EXISTS ratehawk_hotels_code_idx ON public.ratehawk_hotels USING hash (code);
CREATE INDEX IF NOT EXISTS ratehawk_hotels_fulltext_idx ON public.ratehawk_hotels USING gin (to_tsvector('english'::regconfig, ((name || ' '::text) || "addressCity")));
CREATE INDEX IF NOT EXISTS ratehawk_hotels_name_idx ON public.ratehawk_hotels USING btree (name);
CREATE INDEX IF NOT EXISTS ratehawk_hotels_name_tsvector_idx ON public.ratehawk_hotels USING gin (to_tsvector('english'::regconfig, name));
CREATE INDEX IF NOT EXISTS ratehawk_hotels_rating_idx ON public.ratehawk_hotels USING btree (rating);
CREATE INDEX IF NOT EXISTS ratehawk_hotels_rating_idx_asc ON public.ratehawk_hotels USING btree (rating);
CREATE INDEX IF NOT EXISTS ratehawk_hotels_rating_idx_desc ON public.ratehawk_hotels USING btree (rating DESC);
CREATE INDEX IF NOT EXISTS ratehawk_hotelscity_tsvector_idx ON public.ratehawk_hotels USING gin (to_tsvector('english'::regconfig, "addressCity"));
-- Drop the constraint if it exists, before adding it to make it idempotent.
ALTER TABLE ONLY public.ratehawk_hotels DROP CONSTRAINT IF EXISTS "FK_63d2f7931ddf56f807995b9d83d";
ALTER TABLE ONLY public.ratehawk_hotels ADD CONSTRAINT "FK_63d2f7931ddf56f807995b9d83d" FOREIGN KEY ("addressCountryiso") REFERENCES public.countries(iso);


-- Create the rooms table
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS public.ratehawk_rooms (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying(128),
    images text[],
    rg_ext text,
    "hotelCode" character varying,
    bathroom text DEFAULT ''::text,
    bedding_type text DEFAULT ''::text,
    room_amenities text[]
);
-- Drop the constraint if it exists, before adding it to make it idempotent.
ALTER TABLE ONLY public.ratehawk_rooms DROP CONSTRAINT IF EXISTS "PK_c5a4febaa19522374d5d18ba195";
ALTER TABLE ONLY public.ratehawk_rooms ADD CONSTRAINT "PK_c5a4febaa19522374d5d18ba195" PRIMARY KEY (id);
CREATE INDEX IF NOT EXISTS idx_room_amenities ON public.ratehawk_rooms USING btree (room_amenities);
CREATE INDEX IF NOT EXISTS "ratehawk_rooms_hotelCode_idx" ON public.ratehawk_rooms USING btree ("hotelCode");
-- Drop the constraint if it exists, before adding it to make it idempotent.
ALTER TABLE ONLY public.ratehawk_rooms DROP CONSTRAINT IF EXISTS "FK_21f305e487d051f73027910d2ef";
ALTER TABLE ONLY public.ratehawk_rooms ADD CONSTRAINT "FK_21f305e487d051f73027910d2ef" FOREIGN KEY ("hotelCode") REFERENCES public.ratehawk_hotels(code);


-- Create the scores table
CREATE TABLE IF NOT EXISTS public.ratehawk_scores (
    code text NOT NULL,
    hid bigint,
    hotel_rating double precision,
    hotel_cleanness double precision,
    hotel_location double precision,
    hotel_price double precision,
    hotel_services double precision,
    hotel_room text,
    hotel_meal text,
    hotel_wifi text,
    hotel_hygiene text
);
-- Drop the constraint if it exists, before adding it to make it idempotent.
-- ALTER TABLE ONLY public.ratehawk_scores DROP CONSTRAINT IF EXISTS "";
ALTER TABLE ONLY public.ratehawk_scores ADD CONSTRAINT ratehawk_scores_pkey PRIMARY KEY (code);
CREATE INDEX IF NOT EXISTS ratehawk_scores_hotel_rating_idx ON public.ratehawk_scores USING btree (hotel_rating);
CREATE INDEX IF NOT EXISTS ratehawk_scores_hotel_rating_idx1 ON public.ratehawk_scores USING btree (hotel_rating DESC);


-- Create the reviews table
CREATE TABLE public.ratehawk_reviews (
    code text,
    hid bigint,
    review_id bigint NOT NULL,
    review_plus text,
    review_minus text,
    created text,
    author text,
    adults bigint,
    children text,
    room_name text,
    nights bigint,
    images text,
    traveller_type text,
    trip_type text,
    review_rating double precision,
    review_cleanness bigint,
    review_location bigint,
    review_price text,
    review_services bigint,
    review_room text,
    review_meal text,
    review_wifi text,
    review_hygiene text
);
-- Drop the constraint if it exists, before adding it to make it idempotent.
-- ALTER TABLE ONLY public.ratehawk_reviews DROP CONSTRAINT IF EXISTS "";
ALTER TABLE ONLY public.ratehawk_reviews ADD CONSTRAINT ratehawk_reviews_pkey PRIMARY KEY (review_id);
CREATE INDEX IF NOT EXISTS ratehawk_reviews_code_idx ON public.ratehawk_reviews USING btree (code);


-- Populate the countries table

INSERT INTO "public"."countries" ("name", "iso", "continent", "region", "phonePrefix", "flagEmoticon", "flagImage")
  VALUES ('Andorra', 'AD', 'Europe', 'Europe', '+376', '🇦🇩', 'https://flagcdn.com/ad.svg'), ('United Arab Emirates', 'AE', 'Asia', 'Asia', '+971', '🇦🇪', 'https://flagcdn.com/ae.svg'), ('Afghanistan', 'AF', 'Asia', 'Asia', '+93', '🇦🇫', 'https://upload.wikimedia.org/wikipedia/commons/5/5c/Flag_of_the_Taliban.svg'), ('Antigua and Barbuda', 'AG', 'North America', 'Americas', '+1268', '🇦🇬', 'https://flagcdn.com/ag.svg'), ('Anguilla', 'AI', 'North America', 'Americas', '+1264', '🇦🇮', 'https://flagcdn.com/ai.svg'), ('Albania', 'AL', 'Europe', 'Europe', '+355', '🇦🇱', 'https://flagcdn.com/al.svg'), ('Armenia', 'AM', 'Asia', 'Asia', '+374', '🇦🇲', 'https://flagcdn.com/am.svg'), ('Angola', 'AO', 'Africa', 'Africa', '+244', '🇦🇴', 'https://flagcdn.com/ao.svg'), ('Antarctica', 'AQ', 'Antarctica', 'Antarctic', '0', '🇦🇶', 'https://flagcdn.com/aq.svg'), ('Argentina', 'AR', 'South America', 'Americas', '+54', '🇦🇷', 'https://flagcdn.com/ar.svg'), ('American Samoa', 'AS', 'Oceania', 'Oceania', '+1684', '🇦🇸', 'https://flagcdn.com/as.svg'), ('Austria', 'AT', 'Europe', 'Europe', '+43', '🇦🇹', 'https://flagcdn.com/at.svg'), ('Australia', 'AU', 'Oceania', 'Oceania', '+61', '🇦🇺', 'https://flagcdn.com/au.svg'), ('Aruba', 'AW', 'North America', 'Americas', '+297', '🇦🇼', 'https://flagcdn.com/aw.svg'), ('Åland Islands', 'AX', 'Europe', 'Europe', '+35818', '🇦🇽', 'https://flagcdn.com/ax.svg'), ('Azerbaijan', 'AZ', 'Europe, Asia', 'Asia', '+994', '🇦🇿', 'https://flagcdn.com/az.svg'), ('Bosnia and Herzegovina', 'BA', 'Europe', 'Europe', '+387', '🇧🇦', 'https://flagcdn.com/ba.svg'), ('Barbados', 'BB', 'North America', 'Americas', '+1246', '🇧🇧', 'https://flagcdn.com/bb.svg'), ('Bangladesh', 'BD', 'Asia', 'Asia', '+880', '🇧🇩', 'https://flagcdn.com/bd.svg'), ('Belgium', 'BE', 'Europe', 'Europe', '+32', '🇧🇪', 'https://flagcdn.com/be.svg'), ('Burkina Faso', 'BF', 'Africa', 'Africa', '+226', '🇧🇫', 'https://flagcdn.com/bf.svg'), ('Bulgaria', 'BG', 'Europe', 'Europe', '+359', '🇧🇬', 'https://flagcdn.com/bg.svg'), ('Bahrain', 'BH', 'Asia', 'Asia', '+973', '🇧🇭', 'https://flagcdn.com/bh.svg'), ('Burundi', 'BI', 'Africa', 'Africa', '+257', '🇧🇮', 'https://flagcdn.com/bi.svg'), ('Benin', 'BJ', 'Africa', 'Africa', '+229', '🇧🇯', 'https://flagcdn.com/bj.svg'), ('Saint Barthélemy', 'BL', 'North America', 'Americas', '+590', '🇧🇱', 'https://flagcdn.com/bl.svg'), ('Bermuda', 'BM', 'North America', 'Americas', '+1441', '🇧🇲', 'https://flagcdn.com/bm.svg'), ('Brunei', 'BN', 'Asia', 'Asia', '+673', '🇧🇳', 'https://flagcdn.com/bn.svg'), ('Bolivia', 'BO', 'South America', 'Americas', '+591', '🇧🇴', 'https://flagcdn.com/bo.svg'), ('Caribbean Netherlands', 'BQ', 'North America', 'Americas', '+599', '🇧🇶', 'https://flagcdn.com/bq.svg'), ('Brazil', 'BR', 'South America', 'Americas', '+55', '🇧🇷', 'https://flagcdn.com/br.svg'), ('Bahamas', 'BS', 'North America', 'Americas', '+1242', '🇧🇸', 'https://flagcdn.com/bs.svg'), ('Bhutan', 'BT', 'Asia', 'Asia', '+975', '🇧🇹', 'https://flagcdn.com/bt.svg'), ('Bouvet Island', 'BV', 'Antarctica', 'Antarctic', '+47', '🇧🇻', 'https://flagcdn.com/bv.svg'), ('Botswana', 'BW', 'Africa', 'Africa', '+267', '🇧🇼', 'https://flagcdn.com/bw.svg'), ('Belarus', 'BY', 'Europe', 'Europe', '+375', '🇧🇾', 'https://flagcdn.com/by.svg'), ('Belize', 'BZ', 'North America', 'Americas', '+501', '🇧🇿', 'https://flagcdn.com/bz.svg'), ('Canada', 'CA', 'North America', 'Americas', '+1', '🇨🇦', 'https://flagcdn.com/ca.svg'), ('Cocos (Keeling) Islands', 'CC', 'Asia', 'Oceania', '+61', '🇨🇨', 'https://flagcdn.com/cc.svg'), ('DR Congo', 'CD', 'Africa', 'Africa', '+243', '🇨🇩', 'https://flagcdn.com/cd.svg'), ('Central African Republic', 'CF', 'Africa', 'Africa', '+236', '🇨🇫', 'https://flagcdn.com/cf.svg'), ('Republic of the Congo', 'CG', 'Africa', 'Africa', '+242', '🇨🇬', 'https://flagcdn.com/cg.svg'), ('Switzerland', 'CH', 'Europe', 'Europe', '+41', '🇨🇭', 'https://flagcdn.com/ch.svg'), ('Ivory Coast', 'CI', 'Africa', 'Africa', '+225', '🇨🇮', 'https://flagcdn.com/ci.svg'), ('Cook Islands', 'CK', 'Oceania', 'Oceania', '+682', '🇨🇰', 'https://flagcdn.com/ck.svg'), ('Chile', 'CL', 'South America', 'Americas', '+56', '🇨🇱', 'https://flagcdn.com/cl.svg'), ('Cameroon', 'CM', 'Africa', 'Africa', '+237', '🇨🇲', 'https://flagcdn.com/cm.svg'), ('China', 'CN', 'Asia', 'Asia', '+86', '🇨🇳', 'https://flagcdn.com/cn.svg'), ('Colombia', 'CO', 'South America', 'Americas', '+57', '🇨🇴', 'https://flagcdn.com/co.svg'), ('Costa Rica', 'CR', 'North America', 'Americas', '+506', '🇨🇷', 'https://flagcdn.com/cr.svg'), ('Cuba', 'CU', 'North America', 'Americas', '+53', '🇨🇺', 'https://flagcdn.com/cu.svg'), ('Cape Verde', 'CV', 'Africa', 'Africa', '+238', '🇨🇻', 'https://flagcdn.com/cv.svg'), ('Curaçao', 'CW', 'North America', 'Americas', '+599', '🇨🇼', 'https://flagcdn.com/cw.svg'), ('Christmas Island', 'CX', 'Asia', 'Oceania', '+61', '🇨🇽', 'https://flagcdn.com/cx.svg'), ('Cyprus', 'CY', 'Europe', 'Europe', '+357', '🇨🇾', 'https://flagcdn.com/cy.svg'), ('Czechia', 'CZ', 'Europe', 'Europe', '+420', '🇨🇿', 'https://flagcdn.com/cz.svg'), ('Germany', 'DE', 'Europe', 'Europe', '+49', '🇩🇪', 'https://flagcdn.com/de.svg'), ('Djibouti', 'DJ', 'Africa', 'Africa', '+253', '🇩🇯', 'https://flagcdn.com/dj.svg'), ('Denmark', 'DK', 'Europe', 'Europe', '+45', '🇩🇰', 'https://flagcdn.com/dk.svg'), ('Dominica', 'DM', 'North America', 'Americas', '+1767', '🇩🇲', 'https://flagcdn.com/dm.svg'), ('Dominican Republic', 'DO', 'North America', 'Americas', '+1849', '🇩🇴', 'https://flagcdn.com/do.svg'), ('Algeria', 'DZ', 'Africa', 'Africa', '+213', '🇩🇿', 'https://flagcdn.com/dz.svg'), ('Ecuador', 'EC', 'South America', 'Americas', '+593', '🇪🇨', 'https://flagcdn.com/ec.svg'), ('Estonia', 'EE', 'Europe', 'Europe', '+372', '🇪🇪', 'https://flagcdn.com/ee.svg'), ('Egypt', 'EG', 'Africa', 'Africa', '+20', '🇪🇬', 'https://flagcdn.com/eg.svg'), ('Western Sahara', 'EH', 'Africa', 'Africa', '+2125289', '🇪🇭', 'https://flagcdn.com/eh.svg'), ('Eritrea', 'ER', 'Africa', 'Africa', '+291', '🇪🇷', 'https://flagcdn.com/er.svg'), ('Spain', 'ES', 'Europe', 'Europe', '+34', '🇪🇸', 'https://flagcdn.com/es.svg'), ('Ethiopia', 'ET', 'Africa', 'Africa', '+251', '🇪🇹', 'https://flagcdn.com/et.svg'), ('Finland', 'FI', 'Europe', 'Europe', '+358', '🇫🇮', 'https://flagcdn.com/fi.svg'), ('Fiji', 'FJ', 'Oceania', 'Oceania', '+679', '🇫🇯', 'https://flagcdn.com/fj.svg'), ('Falkland Islands', 'FK', 'South America', 'Americas', '+500', '🇫🇰', 'https://flagcdn.com/fk.svg'), ('Micronesia', 'FM', 'Oceania', 'Oceania', '+691', '🇫🇲', 'https://flagcdn.com/fm.svg'), ('Faroe Islands', 'FO', 'Europe', 'Europe', '+298', '🇫🇴', 'https://flagcdn.com/fo.svg'), ('France', 'FR', 'Europe', 'Europe', '+33', '🇫🇷', 'https://flagcdn.com/fr.svg'), ('Gabon', 'GA', 'Africa', 'Africa', '+241', '🇬🇦', 'https://flagcdn.com/ga.svg'), ('United Kingdom', 'GB', 'Europe', 'Europe', '+44', '🇬🇧', 'https://flagcdn.com/gb.svg'), ('Grenada', 'GD', 'North America', 'Americas', '+1473', '🇬🇩', 'https://flagcdn.com/gd.svg'), ('Georgia', 'GE', 'Asia', 'Asia', '+995', '🇬🇪', 'https://flagcdn.com/ge.svg'),('Georgia','AB','Asia','Asia','+995','🇬🇪','https://flagcdn.com/ge.svg'),('Georgia','OS','Asia','Asia','+995','🇬🇪','https://flagcdn.com/ge.svg'), ('French Guiana', 'GF', 'South America', 'Americas', '+594', '🇬🇫', 'https://flagcdn.com/gf.svg'), ('Guernsey', 'GG', 'Europe', 'Europe', '+44', '🇬🇬', 'https://flagcdn.com/gg.svg'), ('Ghana', 'GH', 'Africa', 'Africa', '+233', '🇬🇭', 'https://flagcdn.com/gh.svg'), ('Gibraltar', 'GI', 'Europe', 'Europe', '+350', '🇬🇮', 'https://flagcdn.com/gi.svg'), ('Greenland', 'GL', 'North America', 'Americas', '+299', '🇬🇱', 'https://flagcdn.com/gl.svg'), ('Gambia', 'GM', 'Africa', 'Africa', '+220', '🇬🇲', 'https://flagcdn.com/gm.svg'), ('Guinea', 'GN', 'Africa', 'Africa', '+224', '🇬🇳', 'https://flagcdn.com/gn.svg'), ('Guadeloupe', 'GP', 'North America', 'Americas', '+590', '🇬🇵', 'https://flagcdn.com/gp.svg'), ('Equatorial Guinea', 'GQ', 'Africa', 'Africa', '+240', '🇬🇶', 'https://flagcdn.com/gq.svg'), ('Greece', 'GR', 'Europe', 'Europe', '+30', '🇬🇷', 'https://flagcdn.com/gr.svg'), ('South Georgia', 'GS', 'Antarctica', 'Antarctic', '+500', '🇬🇸', 'https://flagcdn.com/gs.svg'), ('Guatemala', 'GT', 'North America', 'Americas', '+502', '🇬🇹', 'https://flagcdn.com/gt.svg'), ('Guam', 'GU', 'Oceania', 'Oceania', '+1671', '🇬🇺', 'https://flagcdn.com/gu.svg'), ('Guinea-Bissau', 'GW', 'Africa', 'Africa', '+245', '🇬🇼', 'https://flagcdn.com/gw.svg'), ('Guyana', 'GY', 'South America', 'Americas', '+592', '🇬🇾', 'https://flagcdn.com/gy.svg'), ('Hong Kong', 'HK', 'Asia', 'Asia', '+852', '🇭🇰', 'https://flagcdn.com/hk.svg'), ('Heard Island and McDonald Islands', 'HM', 'Antarctica', 'Antarctic', '0', '🇭🇲', 'https://flagcdn.com/hm.svg'), ('Honduras', 'HN', 'North America', 'Americas', '+504', '🇭🇳', 'https://flagcdn.com/hn.svg'), ('Croatia', 'HR', 'Europe', 'Europe', '+385', '🇭🇷', 'https://flagcdn.com/hr.svg'), ('Haiti', 'HT', 'North America', 'Americas', '+509', '🇭🇹', 'https://flagcdn.com/ht.svg'), ('Hungary', 'HU', 'Europe', 'Europe', '+36', '🇭🇺', 'https://flagcdn.com/hu.svg'), ('Indonesia', 'ID', 'Asia', 'Asia', '+62', '🇮🇩', 'https://flagcdn.com/id.svg'), ('Ireland', 'IE', 'Europe', 'Europe', '+353', '🇮🇪', 'https://flagcdn.com/ie.svg'), ('Israel', 'IL', 'Asia', 'Asia', '+972', '🇮🇱', 'https://flagcdn.com/il.svg'), ('Isle of Man', 'IM', 'Europe', 'Europe', '+44', '🇮🇲', 'https://flagcdn.com/im.svg'), ('India', 'IN', 'Asia', 'Asia', '+91', '🇮🇳', 'https://flagcdn.com/in.svg'), ('British Indian Ocean Territory', 'IO', 'Asia', 'Africa', '+246', '🇮🇴', 'https://flagcdn.com/io.svg'), ('Iraq', 'IQ', 'Asia', 'Asia', '+964', '🇮🇶', 'https://flagcdn.com/iq.svg'), ('Iran', 'IR', 'Asia', 'Asia', '+98', '🇮🇷', 'https://flagcdn.com/ir.svg'), ('Iceland', 'IS', 'Europe', 'Europe', '+354', '🇮🇸', 'https://flagcdn.com/is.svg'), ('Italy', 'IT', 'Europe', 'Europe', '+39', '🇮🇹', 'https://flagcdn.com/it.svg'), ('Jersey', 'JE', 'Europe', 'Europe', '+44', '🇯🇪', 'https://flagcdn.com/je.svg'), ('Jamaica', 'JM', 'North America', 'Americas', '+1876', '🇯🇲', 'https://flagcdn.com/jm.svg'), ('Jordan', 'JO', 'Asia', 'Asia', '+962', '🇯🇴', 'https://flagcdn.com/jo.svg'), ('Japan', 'JP', 'Asia', 'Asia', '+81', '🇯🇵', 'https://flagcdn.com/jp.svg'), ('Kenya', 'KE', 'Africa', 'Africa', '+254', '🇰🇪', 'https://flagcdn.com/ke.svg'), ('Kyrgyzstan', 'KG', 'Asia', 'Asia', '+996', '🇰🇬', 'https://flagcdn.com/kg.svg'), ('Cambodia', 'KH', 'Asia', 'Asia', '+855', '🇰🇭', 'https://flagcdn.com/kh.svg'), ('Kiribati', 'KI', 'Oceania', 'Oceania', '+686', '🇰🇮', 'https://flagcdn.com/ki.svg'), ('Comoros', 'KM', 'Africa', 'Africa', '+269', '🇰🇲', 'https://flagcdn.com/km.svg'), ('Saint Kitts and Nevis', 'KN', 'North America', 'Americas', '+1869', '🇰🇳', 'https://flagcdn.com/kn.svg'), ('North Korea', 'KP', 'Asia', 'Asia', '+850', '🇰🇵', 'https://flagcdn.com/kp.svg'), ('South Korea', 'KR', 'Asia', 'Asia', '+82', '🇰🇷', 'https://flagcdn.com/kr.svg'), ('Kuwait', 'KW', 'Asia', 'Asia', '+965', '🇰🇼', 'https://flagcdn.com/kw.svg'), ('Cayman Islands', 'KY', 'North America', 'Americas', '+1345', '🇰🇾', 'https://flagcdn.com/ky.svg'), ('Kazakhstan', 'KZ', 'Asia', 'Asia', '+77', '🇰🇿', 'https://flagcdn.com/kz.svg'), ('Laos', 'LA', 'Asia', 'Asia', '+856', '🇱🇦', 'https://flagcdn.com/la.svg'), ('Lebanon', 'LB', 'Asia', 'Asia', '+961', '🇱🇧', 'https://flagcdn.com/lb.svg'), ('Saint Lucia', 'LC', 'North America', 'Americas', '+1758', '🇱🇨', 'https://flagcdn.com/lc.svg'), ('Liechtenstein', 'LI', 'Europe', 'Europe', '+423', '🇱🇮', 'https://flagcdn.com/li.svg'), ('Sri Lanka', 'LK', 'Asia', 'Asia', '+94', '🇱🇰', 'https://flagcdn.com/lk.svg'), ('Liberia', 'LR', 'Africa', 'Africa', '+231', '🇱🇷', 'https://flagcdn.com/lr.svg'), ('Lesotho', 'LS', 'Africa', 'Africa', '+266', '🇱🇸', 'https://flagcdn.com/ls.svg'), ('Lithuania', 'LT', 'Europe', 'Europe', '+370', '🇱🇹', 'https://flagcdn.com/lt.svg'), ('Luxembourg', 'LU', 'Europe', 'Europe', '+352', '🇱🇺', 'https://flagcdn.com/lu.svg'), ('Latvia', 'LV', 'Europe', 'Europe', '+371', '🇱🇻', 'https://flagcdn.com/lv.svg'), ('Libya', 'LY', 'Africa', 'Africa', '+218', '🇱🇾', 'https://flagcdn.com/ly.svg'), ('Morocco', 'MA', 'Africa', 'Africa', '+212', '🇲🇦', 'https://flagcdn.com/ma.svg'), ('Monaco', 'MC', 'Europe', 'Europe', '+377', '🇲🇨', 'https://flagcdn.com/mc.svg'), ('Moldova', 'MD', 'Europe', 'Europe', '+373', '🇲🇩', 'https://flagcdn.com/md.svg'), ('Montenegro', 'ME', 'Europe', 'Europe', '+382', '🇲🇪', 'https://flagcdn.com/me.svg'), ('Saint Martin', 'MF', 'North America', 'Americas', '+590', '🇲🇫', 'https://flagcdn.com/mf.svg'), ('Madagascar', 'MG', 'Africa', 'Africa', '+261', '🇲🇬', 'https://flagcdn.com/mg.svg'), ('Marshall Islands', 'MH', 'Oceania', 'Oceania', '+692', '🇲🇭', 'https://flagcdn.com/mh.svg'), ('North Macedonia', 'MK', 'Europe', 'Europe', '+389', '🇲🇰', 'https://flagcdn.com/mk.svg'), ('Mali', 'ML', 'Africa', 'Africa', '+223', '🇲🇱', 'https://flagcdn.com/ml.svg'), ('Myanmar', 'MM', 'Asia', 'Asia', '+95', '🇲🇲', 'https://flagcdn.com/mm.svg'), ('Mongolia', 'MN', 'Asia', 'Asia', '+976', '🇲🇳', 'https://flagcdn.com/mn.svg'), ('Macau', 'MO', 'Asia', 'Asia', '+853', '🇲🇴', 'https://flagcdn.com/mo.svg'), ('Northern Mariana Islands', 'MP', 'Oceania', 'Oceania', '+1670', '🇲🇵', 'https://flagcdn.com/mp.svg'), ('Martinique', 'MQ', 'North America', 'Americas', '+596', '🇲🇶', 'https://flagcdn.com/mq.svg'), ('Mauritania', 'MR', 'Africa', 'Africa', '+222', '🇲🇷', 'https://flagcdn.com/mr.svg'), ('Montserrat', 'MS', 'North America', 'Americas', '+1664', '🇲🇸', 'https://flagcdn.com/ms.svg'), ('Malta', 'MT', 'Europe', 'Europe', '+356', '🇲🇹', 'https://flagcdn.com/mt.svg'), ('Mauritius', 'MU', 'Africa', 'Africa', '+230', '🇲🇺', 'https://flagcdn.com/mu.svg'), ('Maldives', 'MV', 'Asia', 'Asia', '+960', '🇲🇻', 'https://flagcdn.com/mv.svg'), ('Malawi', 'MW', 'Africa', 'Africa', '+265', '🇲🇼', 'https://flagcdn.com/mw.svg'), ('Mexico', 'MX', 'North America', 'Americas', '+52', '🇲🇽', 'https://flagcdn.com/mx.svg'), ('Malaysia', 'MY', 'Asia', 'Asia', '+60', '🇲🇾', 'https://flagcdn.com/my.svg'), ('Mozambique', 'MZ', 'Africa', 'Africa', '+258', '🇲🇿', 'https://flagcdn.com/mz.svg'), ('Namibia', 'NA', 'Africa', 'Africa', '+264', '🇳🇦', 'https://flagcdn.com/na.svg'), ('New Caledonia', 'NC', 'Oceania', 'Oceania', '+687', '🇳🇨', 'https://flagcdn.com/nc.svg'), ('Niger', 'NE', 'Africa', 'Africa', '+227', '🇳🇪', 'https://flagcdn.com/ne.svg'), ('Norfolk Island', 'NF', 'Oceania', 'Oceania', '+672', '🇳🇫', 'https://flagcdn.com/nf.svg'), ('Nigeria', 'NG', 'Africa', 'Africa', '+234', '🇳🇬', 'https://flagcdn.com/ng.svg'), ('Nicaragua', 'NI', 'North America', 'Americas', '+505', '🇳🇮', 'https://flagcdn.com/ni.svg'), ('Netherlands', 'NL', 'Europe', 'Europe', '+31', '🇳🇱', 'https://flagcdn.com/nl.svg'), ('Norway', 'NO', 'Europe', 'Europe', '+47', '🇳🇴', 'https://flagcdn.com/no.svg'), ('Nepal', 'NP', 'Asia', 'Asia', '+977', '🇳🇵', 'https://flagcdn.com/np.svg'), ('Nauru', 'NR', 'Oceania', 'Oceania', '+674', '🇳🇷', 'https://flagcdn.com/nr.svg'), ('Niue', 'NU', 'Oceania', 'Oceania', '+683', '🇳🇺', 'https://flagcdn.com/nu.svg'), ('New Zealand', 'NZ', 'Oceania', 'Oceania', '+64', '🇳🇿', 'https://flagcdn.com/nz.svg'), ('Oman', 'OM', 'Asia', 'Asia', '+968', '🇴🇲', 'https://flagcdn.com/om.svg'), ('Panama', 'PA', 'North America', 'Americas', '+507', '🇵🇦', 'https://flagcdn.com/pa.svg'), ('Peru', 'PE', 'South America', 'Americas', '+51', '🇵🇪', 'https://flagcdn.com/pe.svg'), ('French Polynesia', 'PF', 'Oceania', 'Oceania', '+689', '🇵🇫', 'https://flagcdn.com/pf.svg'), ('Papua New Guinea', 'PG', 'Oceania', 'Oceania', '+675', '🇵🇬', 'https://flagcdn.com/pg.svg'), ('Philippines', 'PH', 'Asia', 'Asia', '+63', '🇵🇭', 'https://flagcdn.com/ph.svg'), ('Pakistan', 'PK', 'Asia', 'Asia', '+92', '🇵🇰', 'https://flagcdn.com/pk.svg'), ('Poland', 'PL', 'Europe', 'Europe', '+48', '🇵🇱', 'https://flagcdn.com/pl.svg'), ('Saint Pierre and Miquelon', 'PM', 'North America', 'Americas', '+508', '🇵🇲', 'https://flagcdn.com/pm.svg'), ('Pitcairn Islands', 'PN', 'Oceania', 'Oceania', '+64', '🇵🇳', 'https://flagcdn.com/pn.svg'), ('Puerto Rico', 'PR', 'North America', 'Americas', '+1939', '🇵🇷', 'https://flagcdn.com/pr.svg'), ('Palestine', 'PS', 'Asia', 'Asia', '+970', '🇵🇸', 'https://flagcdn.com/ps.svg'), ('Portugal', 'PT', 'Europe', 'Europe', '+351', '🇵🇹', 'https://flagcdn.com/pt.svg'), ('Palau', 'PW', 'Oceania', 'Oceania', '+680', '🇵🇼', 'https://flagcdn.com/pw.svg'), ('Paraguay', 'PY', 'South America', 'Americas', '+595', '🇵🇾', 'https://flagcdn.com/py.svg'), ('Qatar', 'QA', 'Asia', 'Asia', '+974', '🇶🇦', 'https://flagcdn.com/qa.svg'), ('Réunion', 'RE', 'Africa', 'Africa', '+262', '🇷🇪', 'https://flagcdn.com/re.svg'), ('Romania', 'RO', 'Europe', 'Europe', '+40', '🇷🇴', 'https://flagcdn.com/ro.svg'), ('Serbia', 'RS', 'Europe', 'Europe', '+381', '🇷🇸', 'https://flagcdn.com/rs.svg'), ('Russia', 'RU', 'Europe, Asia', 'Europe', '+79', '🇷🇺', 'https://flagcdn.com/ru.svg'), ('Rwanda', 'RW', 'Africa', 'Africa', '+250', '🇷🇼', 'https://flagcdn.com/rw.svg'), ('Saudi Arabia', 'SA', 'Asia', 'Asia', '+966', '🇸🇦', 'https://flagcdn.com/sa.svg'), ('Solomon Islands', 'SB', 'Oceania', 'Oceania', '+677', '🇸🇧', 'https://flagcdn.com/sb.svg'), ('Seychelles', 'SC', 'Africa', 'Africa', '+248', '🇸🇨', 'https://flagcdn.com/sc.svg'), ('Sudan', 'SD', 'Africa', 'Africa', '+249', '🇸🇩', 'https://flagcdn.com/sd.svg'), ('Sweden', 'SE', 'Europe', 'Europe', '+46', '🇸🇪', 'https://flagcdn.com/se.svg'), ('Singapore', 'SG', 'Asia', 'Asia', '+65', '🇸🇬', 'https://flagcdn.com/sg.svg'), ('Saint Helena, Ascension and Tristan da Cunha', 'SH', 'Africa', 'Africa', '+247', '🇸🇭', 'https://flagcdn.com/sh.svg'), ('Slovenia', 'SI', 'Europe', 'Europe', '+386', '🇸🇮', 'https://flagcdn.com/si.svg'), ('Svalbard and Jan Mayen', 'SJ', 'Europe', 'Europe', '+4779', '🇸🇯', 'https://flagcdn.com/sj.svg'), ('Slovakia', 'SK', 'Europe', 'Europe', '+421', '🇸🇰', 'https://flagcdn.com/sk.svg'), ('Sierra Leone', 'SL', 'Africa', 'Africa', '+232', '🇸🇱', 'https://flagcdn.com/sl.svg'), ('San Marino', 'SM', 'Europe', 'Europe', '+378', '🇸🇲', 'https://flagcdn.com/sm.svg'), ('Senegal', 'SN', 'Africa', 'Africa', '+221', '🇸🇳', 'https://flagcdn.com/sn.svg'), ('Somalia', 'SO', 'Africa', 'Africa', '+252', '🇸🇴', 'https://flagcdn.com/so.svg'), ('Suriname', 'SR', 'South America', 'Americas', '+597', '🇸🇷', 'https://flagcdn.com/sr.svg'), ('South Sudan', 'SS', 'Africa', 'Africa', '+211', '🇸🇸', 'https://flagcdn.com/ss.svg'), ('São Tomé and Príncipe', 'ST', 'Africa', 'Africa', '+239', '🇸🇹', 'https://flagcdn.com/st.svg'), ('El Salvador', 'SV', 'North America', 'Americas', '+503', '🇸🇻', 'https://flagcdn.com/sv.svg'), ('Sint Maarten', 'SX', 'North America', 'Americas', '+1721', '🇸🇽', 'https://flagcdn.com/sx.svg'), ('Syria', 'SY', 'Asia', 'Asia', '+963', '🇸🇾', 'https://flagcdn.com/sy.svg'), ('Eswatini', 'SZ', 'Africa', 'Africa', '+268', '🇸🇿', 'https://flagcdn.com/sz.svg'), ('Turks and Caicos Islands', 'TC', 'North America', 'Americas', '+1649', '🇹🇨', 'https://flagcdn.com/tc.svg'), ('Chad', 'TD', 'Africa', 'Africa', '+235', '🇹🇩', 'https://flagcdn.com/td.svg'), ('French Southern and Antarctic Lands', 'TF', 'Antarctica', 'Antarctic', '+262', '🇹🇫', 'https://flagcdn.com/tf.svg'), ('Togo', 'TG', 'Africa', 'Africa', '+228', '🇹🇬', 'https://flagcdn.com/tg.svg'), ('Thailand', 'TH', 'Asia', 'Asia', '+66', '🇹🇭', 'https://flagcdn.com/th.svg'), ('Tajikistan', 'TJ', 'Asia', 'Asia', '+992', '🇹🇯', 'https://flagcdn.com/tj.svg'), ('Tokelau', 'TK', 'Oceania', 'Oceania', '+690', '🇹🇰', 'https://flagcdn.com/tk.svg'), ('Timor-Leste', 'TL', 'Oceania', 'Asia', '+670', '🇹🇱', 'https://flagcdn.com/tl.svg'), ('Turkmenistan', 'TM', 'Asia', 'Asia', '+993', '🇹🇲', 'https://flagcdn.com/tm.svg'), ('Tunisia', 'TN', 'Africa', 'Africa', '+216', '🇹🇳', 'https://flagcdn.com/tn.svg'), ('Tonga', 'TO', 'Oceania', 'Oceania', '+676', '🇹🇴', 'https://flagcdn.com/to.svg'), ('Turkey', 'TR', 'Europe, Asia', 'Asia', '+90', '🇹🇷', 'https://flagcdn.com/tr.svg'), ('Trinidad and Tobago', 'TT', 'North America', 'Americas', '+1868', '🇹🇹', 'https://flagcdn.com/tt.svg'), ('Tuvalu', 'TV', 'Oceania', 'Oceania', '+688', '🇹🇻', 'https://flagcdn.com/tv.svg'), ('Taiwan', 'TW', 'Asia', 'Asia', '+886', '🇹🇼', 'https://flagcdn.com/tw.svg'), ('Tanzania', 'TZ', 'Africa', 'Africa', '+255', '🇹🇿', 'https://flagcdn.com/tz.svg'), ('Ukraine', 'UA', 'Europe', 'Europe', '+380', '🇺🇦', 'https://flagcdn.com/ua.svg'), ('Uganda', 'UG', 'Africa', 'Africa', '+256', '🇺🇬', 'https://flagcdn.com/ug.svg'), ('United States Minor Outlying Islands', 'UM', 'Oceania', 'Americas', '+268', '🇺🇲', 'https://flagcdn.com/um.svg'), ('United States', 'US', 'North America', 'Americas', '+1989', '🇺🇸', 'https://flagcdn.com/us.svg'), ('Uruguay', 'UY', 'South America', 'Americas', '+598', '🇺🇾', 'https://flagcdn.com/uy.svg'), ('Uzbekistan', 'UZ', 'Asia', 'Asia', '+998', '🇺🇿', 'https://flagcdn.com/uz.svg'), ('Vatican City', 'VA', 'Europe', 'Europe', '+379', '🇻🇦', 'https://flagcdn.com/va.svg'), ('Saint Vincent and the Grenadines', 'VC', 'North America', 'Americas', '+1784', '🇻🇨', 'https://flagcdn.com/vc.svg'), ('Venezuela', 'VE', 'South America', 'Americas', '+58', '🇻🇪', 'https://flagcdn.com/ve.svg'), ('British Virgin Islands', 'VG', 'North America', 'Americas', '+1284', '🇻🇬', 'https://flagcdn.com/vg.svg'), ('United States Virgin Islands', 'VI', 'North America', 'Americas', '+1340', '🇻🇮', 'https://flagcdn.com/vi.svg'), ('Vietnam', 'VN', 'Asia', 'Asia', '+84', '🇻🇳', 'https://flagcdn.com/vn.svg'), ('Vanuatu', 'VU', 'Oceania', 'Oceania', '+678', '🇻🇺', 'https://flagcdn.com/vu.svg'), ('Wallis and Futuna', 'WF', 'Oceania', 'Oceania', '+681', '🇼🇫', 'https://flagcdn.com/wf.svg'), ('Samoa', 'WS', 'Oceania', 'Oceania', '+685', '🇼🇸', 'https://flagcdn.com/ws.svg'), ('Kosovo', 'XK', 'Europe', 'Europe', '+383', '🇽🇰', 'https://flagcdn.com/xk.svg'), ('Yemen', 'YE', 'Asia', 'Asia', '+967', '🇾🇪', 'https://flagcdn.com/ye.svg'), ('Mayotte', 'YT', 'Africa', 'Africa', '+262', '🇾🇹', 'https://flagcdn.com/yt.svg'), ('South Africa', 'ZA', 'Africa', 'Africa', '+27', '🇿🇦', 'https://flagcdn.com/za.svg'), ('Zambia', 'ZM', 'Africa', 'Africa', '+260', '🇿🇲', 'https://flagcdn.com/zm.svg'), ('Zimbabwe', 'ZW', 'Africa', 'Africa', '+263', '🇿🇼', 'https://flagcdn.com/zw.svg')
  ON CONFLICT (iso) DO NOTHING;