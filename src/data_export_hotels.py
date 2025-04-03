import requests
from pathlib import Path
import zstandard as zstd
import orjson
import asyncio
import aiofiles
import asyncpg 
import re
import time
from loguru import logger
from tqdm.asyncio import tqdm

URL = "https://partner-feedora.s3.eu-central-1.amazonaws.com/feed/preferable_inventory_feed_en_v3.jsonl.zst"

TEMP_DIR = Path(r"D:\Projects\optimize-data-import\data")
RATEHAWK_DUMP_COMPRESSED = TEMP_DIR.joinpath("ratehawk-dump.json.zst")
RATEHAWK_DUMP = TEMP_DIR.joinpath("ratehawk-dump.json")
BATCH_SIZE = 10000
DB_CONFIG = {
    "user": "postgres",
    "password": "postgres",
    "database": "postgres",
    "host": "localhost",
    "port": 5432,
}


def download_data():
    logger.info("Downloading the file...")
    response = requests.get(URL, stream=True)
    if response.status_code == 200:
        with open(RATEHAWK_DUMP_COMPRESSED, "wb") as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        logger.info("Download completed.")
    else:
        logger.info("Failed to download the file.")
        exit(1)

    logger.info("Decompressing the file...")
    try:
        with open(RATEHAWK_DUMP_COMPRESSED, "rb") as compressed_file:
            dctx = zstd.ZstdDecompressor()
            with open(RATEHAWK_DUMP, "wb") as decompressed_file:
                dctx.copy_stream(compressed_file, decompressed_file)
        logger.info("Decompression completed.")
    except Exception as e:
        logger.info(f"Error during decompression: {e}")
        exit(1)


async def stream_json(file_path):
    """Efficiently streams JSONL file line by line asynchronously"""
    async with aiofiles.open(file_path, "rb") as f:
        async for line in f:
            yield orjson.loads(line)




def transform_hotel_data(row):
    """Transforms hotel JSON into structured format"""
    address = row.get("address", "")
    apt_number_match = re.match(r"^(\d+)", address)
    apt_number = apt_number_match.group(1) if apt_number_match else ""
    return (
        row.get("id", ""),
        row.get("name", ""),
        row.get("images", []),
        row.get("phone", ""),
        [row.get("longitude", None), row.get("latitude", None)],  # Coordinates
        row.get("email", ""),
        row.get("kind", ""),
        row.get("hotel_chain", ""),
        row.get("region", {}).get("country_code", ""),  # country
        row.get("region", {}).get("name", ""),  # city
        row.get("postal_code", ""),  # zipcode
        apt_number,
        address.split(",")[-1].strip() if "," in address else address,
        address.split(",")[0].strip() if "," in address else address,
        row.get("star_rating", 0),
        str(row.get("description_struct", "")),  # description_struct
        orjson.dumps(row.get("amenity_groups", [])).decode(
            "utf-8"
        ),  # Convert to JSON string
        row.get("check_out_time", ""),
        row.get("check_in_time", ""),
        orjson.dumps(row.get("facts", {})).decode("utf-8"),  # Convert to JSON string
        row.get("front_desk_time_end", ""),
        row.get("front_desk_time_start", ""),
        str(row.get("is_closed", False)),
        orjson.dumps(row.get("metapolicy_extra_info", {})).decode(
            "utf-8"
        ),  # Convert to JSON string
        orjson.dumps(row.get("metapolicy_struct", {})).decode(
            "utf-8"
        ),  # Convert to JSON string
        orjson.dumps(row.get("policy_struct", {})).decode(
            "utf-8"
        ),  # Convert to JSON string
        ";".join(
            row.get("payment_methods", [])
        ),  # Convert list to semicolon-separated string
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
        "kitchen" in row.get("serp_filters", []),
    )


async def bulk_insert_hotels(conn, batch):
    """Performs a bulk UPSERT (Insert + Update) for hotels"""
    async with conn.transaction():
        query = """
        INSERT INTO ratehawk_hotels (code, name, images, phone_number, coordinates, email, accommodation_type, chain, 
                                    "addressCountryiso", "addressCity", "addressZipcode", "addressAptnumber", 
                                    "addressState", "addressStreetaddress", rating, description_struct, amenity_groups, 
                                    check_out_time, check_in_time, facts, front_desk_time_end, front_desk_time_start, 
                                    is_closed, metapolicy_extra_info, metapolicy_struct, policy_struct, payment_methods, 
                                    air_conditioning, beach, has_airport_transfer, has_business, has_disabled_support, 
                                    has_ecar_charger, has_fitness, has_internet, has_jacuzzi, has_kids, has_meal, 
                                    has_parking, has_pets, has_pool, has_ski, has_smoking, has_spa, kitchen)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, 
                $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41, $42, $43, $44, $45)
        ON CONFLICT (code) DO UPDATE SET
            name = EXCLUDED.name,
            images = EXCLUDED.images,
            phone_number = EXCLUDED.phone_number,
            coordinates = EXCLUDED.coordinates,
            email = EXCLUDED.email,
            accommodation_type = EXCLUDED.accommodation_type,
            chain = EXCLUDED.chain,
            "addressCountryiso" = EXCLUDED."addressCountryiso",
            "addressCity" = EXCLUDED."addressCity",
            "addressZipcode" = EXCLUDED."addressZipcode",
            "addressAptnumber" = EXCLUDED."addressAptnumber",
            "addressState" = EXCLUDED."addressState",
            "addressStreetaddress" = EXCLUDED."addressStreetaddress",
            rating = EXCLUDED.rating,
            description_struct = EXCLUDED.description_struct,
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
            air_conditioning = EXCLUDED.air_conditioning,
            beach = EXCLUDED.beach,
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
        hotel_batch = []
        progress_bar = tqdm(desc="Processing", unit=" rows", position=0)
        async for row in stream_json(file_path):
            hotel_batch.append(transform_hotel_data(row))
            if len(hotel_batch) >= BATCH_SIZE:  
                await bulk_insert_hotels(conn, hotel_batch)
                hotel_batch.clear()
                progress_bar.update(BATCH_SIZE)
                # break

        if hotel_batch:
            await bulk_insert_hotels(conn, hotel_batch)
            progress_bar.update(len(hotel_batch))
        progress_bar.close()


async def main():
    """Manages async PostgreSQL connection pool."""
    async with asyncpg.create_pool(**DB_CONFIG, min_size=5, max_size=10) as pool:
        await process_and_insert(pool, RATEHAWK_DUMP)


if __name__ == "__main__":
    logger.info("Starting the ")
    start_time = time.time()
    # download_data()
    logger.info("Starting the Hotel Data Upload...")
    upload_start_time = time.time()
    asyncio.run(main())
    end_time = time.time()
    execution_time = end_time - upload_start_time

    logger.info(f"Hotel Data upload complete ✅ : {execution_time:.2f} seconds")
