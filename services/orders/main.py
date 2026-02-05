from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel
from typing import Dict, List
from datetime import datetime

app = FastAPI(title="LukestAWS Orders Service")

class OrderItem(BaseModel):
    product_id: int
    quantity: int

class OrderCreate(BaseModel):
    items: List[OrderItem]
    total: float

class Order(BaseModel):
    order_id: int
    items: List[OrderItem]
    total: float
    status: str = "pending"
    created_at: datetime

# In-memory orders (demo only)
orders_db: Dict[int, Order] = {}
order_counter = 1

@app.post("/orders/create", response_model=Order)
async def create_order(order_data: OrderCreate = Body(...)):
    global order_counter
    if not order_data.items:
        raise HTTPException(status_code=400, detail="Order must have at least one item")
    if order_data.total <= 0:
        raise HTTPException(status_code=400, detail="Total must be positive")

    order = Order(
        order_id=order_counter,
        items=order_data.items,
        total=order_data.total,
        status="pending",
        created_at=datetime.utcnow()
    )
    orders_db[order_counter] = order
    order_counter += 1
    return order

@app.get("/orders/{order_id}", response_model=Order)
async def get_order(order_id: int):
    if order_id not in orders_db:
        raise HTTPException(status_code=404, detail="Order not found")
    return orders_db[order_id]

@app.get("/health")
async def health_check():
    return {"status": "healthy"}