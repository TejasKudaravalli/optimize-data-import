import asyncio
import asyncpg
import orjson

# PostgreSQL Connection Settings
DB_CONFIG = {
    "user": "postgres",
    "password": "yourpassword",
    "database": "yourdatabase",
    "host": "localhost",
    "port": 5432
}

JSON_FILE_PATH = "large_file.jsonl"  # Adjust path as needed
BATCH_SIZE = 10_000  # Number of rows per batch insert


async def get_db_connection():
    """Creates an async connection pool to PostgreSQL"""
    return await asyncpg.create_pool(**DB_CONFIG)


async def stream_json(file_path):
    """Streams large JSONL file line by line using yield (memory-efficient)"""
    with open(file_path, "rb") as f:
        for line in f:
            yield orjson.loads(line)  # Super-fast JSON parsing


def transform_hotel_data(row):
    """Transforms hotel JSON into structured format"""
    return (
        row.get("id", ""),
        row.get("name", ""),
        row.get("images", []),  # List of images
        row.get("phone", ""),
        [row.get("longitude", None), row.get("latitude", None)],  # Coordinates
        row.get("email", ""),
        row.get("kind", ""),
        row.get("hotel_chain", ""),
        row.get("region", {}).get("country_code", ""),
        row.get("region", {}).get("name", ""),
        row.get("postal_code", ""),
        row.get("address", "").split(",")[0] if "," in row.get("address", "") else row.get("address", ""),
        row.get("star_rating", 0),
        str(row.get("description_struct", "")),  # Convert dict to JSON string
        orjson.dumps(row.get("amenity_groups", [])),  # Convert to JSON string
        row.get("check_out_time", ""),
        row.get("check_in_time", ""),
        orjson.dumps(row.get("facts", {})),  # Convert to JSON string
        row.get("front_desk_time_end", ""),
        row.get("front_desk_time_start", ""),
        row.get("is_closed", False),
        orjson.dumps(row.get("metapolicy_extra_info", {})),  # Convert to JSON string
        orjson.dumps(row.get("metapolicy_struct", {})),  # Convert to JSON string
        orjson.dumps(row.get("policy_struct", {})),  # Convert to JSON string
        ";".join(row.get("payment_methods", [])),  # Convert list to semicolon-separated string
        "air_conditioning" in row.get("serp_filters", []),
        "beach" in row.get("serp_filters", []),
        "has_airport_transfer" in row.get("serp_filters", []),
        "has_business" in row.get("serp_filters", []),
        "has_disabled_support" in row.get("serp_filters", []),
        "has_ecar_charger" in row.get("serp_filters", []),
        "has_fitness" in row.get("serp_filters", []),
        "has_internet" in row.get("serp_filters", []),
        "has_jacuzzi" in row.get("serp_filters", []),
        "has_kids" in row.get("serp_filters", []),
        "has_meal" in row.get("serp_filters", []),
        "has_parking" in row.get("serp_filters", []),
        "has_pets" in row.get("serp_filters", []),
        "has_pool" in row.get("serp_filters", []),
        "has_ski" in row.get("serp_filters", []),
        "has_smoking" in row.get("serp_filters", []),
        "has_spa" in row.get("serp_filters", []),
        "kitchen" in row.get("serp_filters", [])
    )


async def bulk_insert_hotels(conn, batch):
    """Performs a bulk UPSERT (Insert + Update) for hotels"""
    query = """
    INSERT INTO ratehawk_hotels (id, name, images, phone, coordinates, email, kind, hotel_chain, 
                                 country_code, region_name, postal_code, address, star_rating, 
                                 description, amenity_groups, check_out_time, check_in_time, 
                                 facts, front_desk_time_end, front_desk_time_start, is_closed, 
                                 metapolicy_extra_info, metapolicy_struct, policy_struct, payment_methods, 
                                 has_air_conditioning, has_beach, has_airport_transfer, has_business, has_disabled_support, 
                                 has_ecar_charger, has_fitness, has_internet, has_jacuzzi, has_kids, has_meal, has_parking, 
                                 has_pets, has_pool, has_ski, has_smoking, has_spa, kitchen)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, 
            $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42)
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        images = EXCLUDED.images,
        phone = EXCLUDED.phone,
        coordinates = EXCLUDED.coordinates,
        email = EXCLUDED.email,
        kind = EXCLUDED.kind,
        hotel_chain = EXCLUDED.hotel_chain,
        country_code = EXCLUDED.country_code,
        region_name = EXCLUDED.region_name,
        postal_code = EXCLUDED.postal_code,
        address = EXCLUDED.address,
        star_rating = EXCLUDED.star_rating,
        description = EXCLUDED.description,
        amenity_groups = EXCLUDED.amenity_groups,
        check_out_time = EXCLUDED.check_out_time,
        check_in_time = EXCLUDED.check_in_time,
        facts = EXCLUDED.facts,
        front_desk_time_end = EXCLUDED.front_desk_time_end,
        front_desk_time_start = EXCLUDED.front_desk_time_start,
        is_closed = EXCLUDED.is_closed,
        metapolicy_extra_info = EXCLUDED.metapolicy_extra_info,
        metapolicy_struct = EXCLUDED.metapolicy_struct,
        policy_struct = EXCLUDED.policy_struct,
        payment_methods = EXCLUDED.payment_methods,
        has_air_conditioning = EXCLUDED.has_air_conditioning,
        has_beach = EXCLUDED.has_beach,
        has_airport_transfer = EXCLUDED.has_airport_transfer,
        has_business = EXCLUDED.has_business,
        has_disabled_support = EXCLUDED.has_disabled_support,
        has_ecar_charger = EXCLUDED.has_ecar_charger,
        has_fitness = EXCLUDED.has_fitness,
        has_internet = EXCLUDED.has_internet,
        has_jacuzzi = EXCLUDED.has_jacuzzi,
        has_kids = EXCLUDED.has_kids,
        has_meal = EXCLUDED.has_meal,
        has_parking = EXCLUDED.has_parking,
        has_pets = EXCLUDED.has_pets,
        has_pool = EXCLUDED.has_pool,
        has_ski = EXCLUDED.has_ski,
        has_smoking = EXCLUDED.has_smoking,
        has_spa = EXCLUDED.has_spa,
        kitchen = EXCLUDED.kitchen;
    """
    await conn.executemany(query, batch)


async def process_and_insert(pool, file_path):
    """Processes JSON file and inserts/updates data in PostgreSQL"""
    async with pool.acquire() as conn:
        batch = []
        async for row in stream_json(file_path):
            batch.append(transform_hotel_data(row))

            if len(batch) >= BATCH_SIZE:
                await bulk_insert_hotels(conn, batch)
                batch = []

        if batch:
            await bulk_insert_hotels(conn, batch)


async def main():
    """Main async function to process and insert JSON data into PostgreSQL"""
    pool = await get_db_connection()
    try:
        await process_and_insert(pool, JSON_FILE_PATH)
    finally:
        await pool.close()


if __name__ == "__main__":
    asyncio.run(main())
