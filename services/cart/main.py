import os
import stripe
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()
app = FastAPI()

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

class Item(BaseModel):
    product_id: str
    name: str
    price: int  # in cents (e.g., 50000 for £500)

@app.post("/create-checkout-session")
async def create_checkout():
    try:
        # For the demo, we're hardcoding a "Consultancy Fee"
        session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[{
                'price_data': {
                    'currency': 'gbp',
                    'product_data': {'name': 'AWS Strategy Session'},
                    'unit_amount': 50000, 
                },
                'quantity': 1,
            }],
            mode='payment',
            success_url='http://localhost:3000/success',
            cancel_url='http://localhost:3000/cancel',
        )
        return {"url": session.url}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))