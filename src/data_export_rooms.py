import requests
from pathlib import Path
import zstandard as zstd
import orjson
import asyncio
import asyncpg
import time
from loguru import logger
from tqdm.asyncio import tqdm


URL = "https://partner-feedora.s3.eu-central-1.amazonaws.com/feed/preferable_inventory_feed_en_v3.jsonl.zst"

TEMP_DIR = Path(r"D:\Projects\optimize-data-import\data")
RATEHAWK_DUMP_COMPRESSED = TEMP_DIR.joinpath("ratehawk-dump.json.zst")
RATEHAWK_DUMP = TEMP_DIR.joinpath("ratehawk-dump.json")
BATCH_SIZE = 5000
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
    """Streams large JSONL file line by line using yield (memory-efficient)"""
    with open(file_path, "rb") as f:
        for line in f:
            yield orjson.loads(line)


def transform_room_data(row):
    hotel_id = row.get("id", "")
    return [
        (
            room.get("name", ""),
            room.get("images", []),
            orjson.dumps(room.get("rg_ext", {})).decode("utf-8"),
            hotel_id,
            room.get("name_struct", {}).get("bathroom", ""),
            room.get("name_struct", {}).get("bedding_type", ""),
            room.get("room_amenities", []),
        )
        for room in row.get("room_groups", [])
    ]


async def bulk_insert_rooms(conn, batch):
    async with conn.transaction():
        query = """
        INSERT INTO public.ratehawk_rooms (name, images, rg_ext, "hotelCode", bathroom, bedding_type, room_amenities)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (id) DO UPDATE 
        SET name = EXCLUDED.name,
            images = EXCLUDED.images,
            rg_ext = EXCLUDED.rg_ext,
            "hotelCode" = EXCLUDED."hotelCode",
            bathroom = EXCLUDED.bathroom,
            bedding_type = EXCLUDED.bedding_type,
            room_amenities = EXCLUDED.room_amenities;
        """
        await conn.executemany(query, batch)


async def process_and_insert(pool, file_path):
    """Processes JSON file and inserts/updates data in PostgreSQL"""
    async with pool.acquire() as conn:
        rooms_batch = []
        progress_bar = tqdm(desc="Processing", unit=" rows", position=0)
        async for row in stream_json(file_path):
            rooms_batch.extend(transform_room_data(row))
            if len(rooms_batch) >= BATCH_SIZE:
                await bulk_insert_rooms(conn, rooms_batch)
                rooms_batch.clear()
                progress_bar.update(BATCH_SIZE)

        if rooms_batch:
            await bulk_insert_rooms(conn, rooms_batch)
            progress_bar.update(len(rooms_batch))
        progress_bar.close()


async def main():
    """Manages async PostgreSQL connection pool."""
    async with asyncpg.create_pool(**DB_CONFIG, min_size=5, max_size=10) as pool:
        await process_and_insert(pool, RATEHAWK_DUMP)


if __name__ == "__main__":
    logger.info("Starting the ")
    start_time = time.time()
    # download_data()
    logger.info("Starting the Room Data Upload...")
    upload_start_time = time.time()
    asyncio.run(main())
    end_time = time.time()
    execution_time = end_time - upload_start_time

    logger.info(f"Rooms Data upload complete ✅ : {execution_time:.2f} seconds")
