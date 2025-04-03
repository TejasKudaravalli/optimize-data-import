#!/bin/bash
# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e
# Redirect all stdout and stderr logs to the dedicated log-file
# exec >> /import_data.log 2>&1
echo "Current date and time: $(date)"


RATEHAWK_COMPRESSED_DUMP_URL="https://partner-feedora.s3.eu-central-1.amazonaws.com/feed/preferable_inventory_feed_en_v3.jsonl.zst"

# Create a Temporary directory
TEMP_DIR=$(mktemp -d)
# Ensure the TEMP_DIR is always removed on script exit
trap '[[ -d "$TEMP_DIR" ]] && "rm -rf ""$TEMP_DIR" && echo "Temporary directory and its contents have been removed."' EXIT

RATEHAWK_DUMP_COMPRESSED="$TEMP_DIR/ratehawk-dump.json.zst"
RATEHAWK_DUMP="$TEMP_DIR/ratehawk-dump.json"
RATEHAWK_HOTELS_CSV="$TEMP_DIR/ratehawk-hotels.csv"
RATEHAWK_ROOMS_CSV="$TEMP_DIR/ratehawk-rooms.csv"
CHUNK_DIR_PREFIX="$TEMP_DIR/chunk_"

DB_USER="postgres"
DB_NAME="postgres"
DOCKER_EXEC="docker exec -it my-postgres"
PSQL_EXEC="psql -U $DB_USER -d $DB_NAME"


#################################################################################
#####################   Download and decompress DUMP   ##########################
#################################################################################

# Download and install curl and zstd
# apt install curl zstd

curl -o "$RATEHAWK_DUMP_COMPRESSED" "$RATEHAWK_COMPRESSED_DUMP_URL"
zstd --rm -d -o "$RATEHAWK_DUMP" "$RATEHAWK_DUMP_COMPRESSED"

# Check if the uncompressed dump file already exists
if [ ! -f "$RATEHAWK_DUMP" ]; then
  echo "Dump file not found. Proceeding with download and decompression..."
  
  # Check if the compressed dump file already exists
  if [ ! -f "$RATEHAWK_DUMP_COMPRESSED" ]; then
    echo "Compressed dump file not found. Downloading..."
    # Download the dump file
    curl -o "$RATEHAWK_DUMP_COMPRESSED" "$RATEHAWK_COMPRESSED_DUMP_URL"
    echo "Compressed Ratehawk dump file downloaded to $RATEHAWK_DUMP_COMPRESSED"
  else
    echo "Compressed dump file already exists. Skipping download."
  fi
  
  echo "Decompressing... $RATEHAWK_DUMP_COMPRESSED into $RATEHAWK_DUMP"
  # Decompress the compressed dump file (-d to decompress, -o to specify output file, --rm to remove the compressed file after successful decompression)
  zstd --rm -d -o "$RATEHAWK_DUMP" "$RATEHAWK_DUMP_COMPRESSED"
  echo "Ratehawk dump file decompressed to $RATEHAWK_DUMP"
else
  echo "Dump file already exists. Skipping download and decompression."
fi


#################################################################################
##########################   Split into Chunks   ################################
#################################################################################

# First remove any previously created chunk files
rm -f "$CHUNK_DIR_PREFIX"*
# Split the dump file into chunks of 10,000 lines each
split -l 10000 "$RATEHAWK_DUMP" "$CHUNK_DIR_PREFIX"

#################################################################################
############################   Convert to CSV   #################################
#################################################################################

echo "Start converting dump.jsonl to hotels.csv and rooms.csv"

# Step 3: Define two jq scripts for generating different CSV outputs
jq_hotels='
  . as $raw_data |
  [
    ($raw_data.id // ""),  # Empty string instead of "null"
    ($raw_data.name // ""),
    ($raw_data.images // [] | map("\"" + . + "\"") | join(",") | if length > 0 then "{" + . + "}" else "{}" end),
    ($raw_data.phone // ""),
    ([$raw_data.longitude, $raw_data.latitude] | 
      if .[0] != null and .[1] != null then 
        "{" + (map(tostring) | join(",")) + "}" 
      else 
        "{}" 
      end
    ),
    ($raw_data.email // ""),
    ($raw_data.kind // ""),
    ($raw_data.hotel_chain // ""),
    ($raw_data.region.country_code // ""),
    ($raw_data.region.name // ""),
    ($raw_data.postal_code // ""),
    (if $raw_data.address | contains(",") then 
        ($raw_data.address | split(",")[0]) 
     else 
        ($raw_data.address // "") 
     end),
    ($raw_data.star_rating // 0 | tonumber),
    ($raw_data.description_struct // null | if . == null then "" else tostring end),
    ($raw_data.amenity_groups // [] | @json),
    ($raw_data.check_out_time // ""),
    ($raw_data.check_in_time // ""),
    ($raw_data.facts // {} | @json),
    ($raw_data.front_desk_time_end // ""),
    ($raw_data.front_desk_time_start // ""),
    ($raw_data.is_closed // false),
    ($raw_data.metapolicy_extra_info // {} | @json),
    ($raw_data.metapolicy_struct // {} | @json),
    ($raw_data.policy_struct // {} | @json),
    ($raw_data.payment_methods // [] | join(";")),
    ($raw_data.serp_filters | index("air_conditioning") | if . != null then true else false end),
    ($raw_data.serp_filters | index("beach") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_airport_transfer") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_business") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_disabled_support") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_ecar_charger") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_fitness") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_internet") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_jacuzzi") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_kids") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_meal") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_parking") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_pets") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_pool") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_ski") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_smoking") | if . != null then true else false end),
    ($raw_data.serp_filters | index("has_spa") | if . != null then true else false end),
    ($raw_data.serp_filters | index("kitchen") | if . != null then true else false end)
  ] | @csv
  '

jq_rooms='
    . as $hotel | .room_groups[] | [
    (.name // ""),
    (.images // [] | map("\"" + . + "\"") | join(",") | if length > 0 then "{" + . + "}" else "{}" end),
    (.rg_ext // {} | @json),
    ($hotel.id // ""),
    (.name_struct.bathroom // ""),
    (.name_struct.bedding_type // ""),
    (.room_amenities // [] | map("\"" + . + "\"") | join(",") | if length > 0 then "{" + . + "}" else "{}" end)
  ] | @csv'

# Download and install jq
# apt install jq

for chunk in "$CHUNK_DIR_PREFIX"*; do
  # Process for the first CSV file
  jq -r "$jq_hotels" "$chunk" > "${chunk}_hotels.csv" &
  
  # Process for the second CSV file
  jq -r "$jq_rooms" "$chunk" > "${chunk}_rooms.csv" & 
done

# Step 5: Wait for all background jobs to complete
wait

echo "Chunks converted"

# Step 6: Combine outputs into their respective final files
cat "$CHUNK_DIR_PREFIX"*_hotels.csv > "$RATEHAWK_HOTELS_CSV"
cat "$CHUNK_DIR_PREFIX"*_rooms.csv > "$RATEHAWK_ROOMS_CSV"

echo "Chunks combined into final files"
echo "Dump converted to .CSV-file at $RATEHAWK_HOTELS_CSV"
echo "Dump converted to .CSV-file at $RATEHAWK_ROOMS_CSV"


#################################################################################
###########################   DB import   ################################
#################################################################################

HOTEL_COLUMN_NAMES='"code","name","images","phone_number","coordinates","email","accommodation_type","chain","addressCountryiso","addressCity","addressZipcode","addressStreetaddress","rating","description_struct","amenity_groups","check_out_time","check_in_time","facts","front_desk_time_end","front_desk_time_start","is_closed","metapolicy_extra_info","metapolicy_struct","policy_struct","payment_methods","air_conditioning","beach","has_airport_transfer","has_business","has_disabled_support","has_ecar_charger","has_fitness","has_internet","has_jacuzzi","has_kids","has_meal","has_parking","has_pets","has_pool","has_ski","has_smoking","has_spa","kitchen"'
ROOM_COLUMN_NAMES='"name","images","rg_ext","hotelCode","bathroom","bedding_type","room_amenities"'

echo "Start importing hotels CSV into postgres table"

# $DOCKER_EXEC $PSQL_EXEC -c '\COPY ratehawk_hotels("$HOTEL_COLUMN_NAMES") FROM $RATEHAWK_HOTELS_CSV WITH (FORMAT csv, FORCE_NULL($HOTEL_COLUMN_NAMES));'
psql -U "$DB_USER" -d "$DB_NAME" -c '\COPY ratehawk_hotels("code","name","images","phone_number","coordinates","email","accommodation_type","chain","addressCountryiso","addressCity","addressZipcode","addressStreetaddress","rating","description_struct","amenity_groups","check_out_time","check_in_time","facts","front_desk_time_end","front_desk_time_start","is_closed","metapolicy_extra_info","metapolicy_struct","policy_struct","payment_methods","air_conditioning","beach","has_airport_transfer","has_business","has_disabled_support","has_ecar_charger","has_fitness","has_internet","has_jacuzzi","has_kids","has_meal","has_parking","has_pets","has_pool","has_ski","has_smoking","has_spa","kitchen") FROM '$RATEHAWK_HOTELS_CSV' WITH (FORMAT csv, FORCE_NULL("images","phone_number","coordinates","email","accommodation_type","chain","addressCountryiso","addressZipcode","description_struct","amenity_groups","check_out_time","check_in_time","facts","front_desk_time_end","front_desk_time_start","is_closed","metapolicy_extra_info","metapolicy_struct","policy_struct","payment_methods","air_conditioning","beach","has_airport_transfer","has_business","has_disabled_support","has_ecar_charger","has_fitness","has_internet","has_jacuzzi","has_kids","has_meal","has_parking","has_pets","has_pool","has_ski","has_smoking","has_spa","kitchen"));'

echo "Hotels copied to postgres table ratehawk_hotels"

echo "Start importing rooms CSV into postgres table"

# $DOCKER_EXEC $PSQL_EXEC -c '\COPY ratehawk_rooms("$ROOM_COLUMN_NAMES") FROM $RATEHAWK_ROOMS_CSV WITH (FORMAT csv, NULL "null", DELIMITER ",");'
psql -U "$DB_USER" -d "$DB_NAME" -c '\COPY ratehawk_rooms("name","images","rg_ext","hotelCode","bathroom","bedding_type","room_amenities") FROM '$RATEHAWK_ROOMS_CSV' WITH (FORMAT CSV, FORCE_NULL("name","images","rg_ext","hotelCode","bathroom","bedding_type","room_amenities"))'

echo "Rooms copied to postgres table ratehawk_roooms"


#################################################################################
###########################   Cleanup & Vacuum   ################################
#################################################################################
# TODO: VACCUUM POSTGRES ETC.

echo "Current date and time: $(date)"




