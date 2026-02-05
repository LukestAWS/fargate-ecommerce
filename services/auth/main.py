from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel
from datetime import datetime, timedelta, timezone
import jwt

app = FastAPI(title="LukestAWS Auth Service")

SECRET_KEY = "your-secret-key-change-this-in-prod"  # Change in real use!
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

class UserLogin(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

# Dummy user DB (for demo only)
FAKE_USERS = {
    "testuser": {"username": "testuser", "password": "testpass"}
}

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

@app.post("/auth/login", response_model=Token)
async def login(user: UserLogin = Body(...)):
    if user.username not in FAKE_USERS or FAKE_USERS[user.username]["password"] != user.password:
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}