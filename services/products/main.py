from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
import os
import asyncpg
from contextlib import asynccontextmanager
import asyncio

app = FastAPI(title="LukestAWS Products Service")

class Product(BaseModel):
    id: int
    name: str
    description: str
    price: float

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@db:5432/productsdb")

pool = None

@app.post("/products", response_model=Product)
async def create_product(product: Product):
    if pool is None:
        # Fallback for demo purposes if DB is down
        DUMMY_PRODUCTS.append(product)
        return product
    
    async with pool.acquire() as conn:
        new_id = await conn.fetchval(
            "INSERT INTO products (name, description, price) VALUES ($1, $2, $3) RETURNING id",
            product.name, product.description, product.price
        )
        return {**product.dict(), "id": new_id}

@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool
    for attempt in range(10):  # Retry up to 10 times
        try:
            pool = await asyncpg.create_pool(DATABASE_URL, timeout=5)
            async with pool.acquire() as conn:
                await conn.execute('''
                    CREATE TABLE IF NOT EXISTS products (
                        id SERIAL PRIMARY KEY,
                        name TEXT NOT NULL,
                        description TEXT,
                        price DECIMAL NOT NULL
                    )
                ''')
                count = await conn.fetchval("SELECT COUNT(*) FROM products")
                if count == 0:
                    await conn.executemany('''
                        INSERT INTO products (name, description, price) VALUES ($1, $2, $3)
                    ''', [
                        ("AWS Reserved Instance Guide", "Save 30-60% on compute", 0.0),
                        ("EC2 Right-Sizing Report", "Find idle instances – cut 50% waste", 0.0),
                        ("S3 Cost Optimisation Checklist", "Move to Intelligent-Tiering", 0.0),
                    ])
            print("DB pool created & initialized successfully")
            break
        except Exception as e:
            print(f"DB connection attempt {attempt+1} failed: {e}")
            await asyncio.sleep(2)  # Wait before retry
    else:
        print("All DB connection attempts failed – using dummy data fallback")

    yield
    if pool:
        await pool.close()

app.router.lifespan_context = lifespan

DUMMY_PRODUCTS = [
    Product(id=1, name="AWS Reserved Instance Guide", description="Save 30-60% on compute", price=0.0),
    Product(id=2, name="EC2 Right-Sizing Report", description="Find idle instances – cut 50% waste", price=0.0),
    Product(id=3, name="S3 Cost Optimisation Checklist", description="Move to Intelligent-Tiering", price=0.0),
]

@app.get("/products", response_model=List[Product])
async def get_products():
    if pool is None:
        print("Using dummy products – DB not connected")
        return DUMMY_PRODUCTS

    try:
        async with pool.acquire() as conn:
            rows = await conn.fetch("SELECT * FROM products ORDER BY id")
            return [dict(row) for row in rows]
    except Exception as e:
        print(f"Query failed: {e} – falling back to dummy")
        return DUMMY_PRODUCTS

@app.get("/health")
async def health_check():
    return {"status": "healthy"}