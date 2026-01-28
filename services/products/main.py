from fastapi import FastAPI
from pydantic import BaseModel
from typing import List

app = FastAPI(title="LukestAWS Products Service")

class Product(BaseModel):
    id: int
    name: str
    description: str
    price: float

# Dummy data (later replaced with RDS)
PRODUCTS = [
    Product(id=1, name="AWS Reserved Instance Guide", description="Save 30-60% on compute", price=0.0),
    Product(id=2, name="EC2 Right-Sizing Report", description="Find idle instances – cut 50% waste", price=0.0),
    Product(id=3, name="S3 Cost Optimisation Checklist", description="Move to Intelligent-Tiering", price=0.0),
]

@app.get("/products", response_model=List[Product])
async def get_products():
    return PRODUCTS

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)