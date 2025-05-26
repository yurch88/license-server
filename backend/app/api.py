from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List
from datetime import datetime, timedelta
from jose import jwt

router = APIRouter()

SECRET = "supersecret"
ADMIN_LOGIN = "admin"
ADMIN_PASSWORD = "CFT^7ygvCFT^7ygv"

class License(BaseModel):
    id: int
    organization: str
    phone: str
    telegram: str
    key: str
    created_at: datetime
    expires_at: datetime
    status: str

db = {
    "users": [{"login": ADMIN_LOGIN, "password": ADMIN_PASSWORD}],
    "licenses": []
}

def create_license(org, phone, telegram, period_days):
    created = datetime.utcnow()
    expires = created + timedelta(days=period_days)
    payload = {"org": org, "phone": phone, "telegram": telegram, "exp": expires.timestamp()}
    key = jwt.encode(payload, SECRET, algorithm="HS256")
    lic = {
        "id": len(db["licenses"])+1,
        "organization": org,
        "phone": phone,
        "telegram": telegram,
        "key": key,
        "created_at": created,
        "expires_at": expires,
        "status": "active"
    }
    db["licenses"].append(lic)
    return lic

class LoginForm(BaseModel):
    login: str
    password: str

@router.post("/login")
def login(form: LoginForm):
    if form.login == ADMIN_LOGIN and form.password == ADMIN_PASSWORD:
        return {"token": jwt.encode({"login": ADMIN_LOGIN}, SECRET, algorithm="HS256")}
    raise HTTPException(status_code=401, detail="Invalid credentials")

def check_token(token: str):
    try:
        payload = jwt.decode(token, SECRET, algorithms=["HS256"])
        return payload
    except:
        raise HTTPException(status_code=401, detail="Invalid token")

class LicenseForm(BaseModel):
    organization: str
    phone: str
    telegram: str
    period: int

@router.get("/licenses")
def get_licenses(token: str):
    check_token(token)
    return db["licenses"]

@router.post("/licenses")
def add_license(form: LicenseForm, token: str = ""):
    check_token(token)
    lic = create_license(form.organization, form.phone, form.telegram, form.period)
    return lic
