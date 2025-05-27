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
    frozen_at: datetime = None
    freeze_time: int = 0
    revoked: bool = False

db = {
    "users": [{"login": ADMIN_LOGIN, "password": ADMIN_PASSWORD}],
    "licenses": []
}

def check_license_expiry(lic):
    now = datetime.utcnow()
    if lic["status"] == "active" and now > lic["expires_at"]:
        lic["status"] = "inactive"
    return lic

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
        "status": "active",
        "frozen_at": None,
        "freeze_time": 0,
        "revoked": False,
    }
    db["licenses"].insert(0, lic)
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
    for lic in db["licenses"]:
        check_license_expiry(lic)
    return [
        {k: v for k, v in lic.items() if k not in ['id', 'revoked', 'freeze_time']} for lic in db["licenses"]
    ]

@router.post("/licenses")
def add_license(form: LicenseForm, token: str = ""):
    check_token(token)
    lic = create_license(form.organization, form.phone, form.telegram, form.period)
    return {k: v for k, v in lic.items() if k not in ['id', 'revoked', 'freeze_time']}

@router.post("/licenses/freeze")
def freeze_license(key: str, token: str = ""):
    check_token(token)
    for lic in db["licenses"]:
        if lic["key"] == key and lic["status"] == "active":
            lic["status"] = "freeze"
            lic["frozen_at"] = datetime.utcnow()
            return {"result": "ok"}
    raise HTTPException(404, "License not found or not active")

@router.post("/licenses/unfreeze")
def unfreeze_license(key: str, token: str = ""):
    check_token(token)
    for lic in db["licenses"]:
        if lic["key"] == key and lic["status"] == "freeze" and lic["frozen_at"]:
            now = datetime.utcnow()
            frozen_seconds = int((now - lic["frozen_at"]).total_seconds())
            lic["expires_at"] += timedelta(seconds=frozen_seconds)
            lic["status"] = "active"
            lic["frozen_at"] = None
            lic["freeze_time"] += frozen_seconds
            return {"result": "ok"}
    raise HTTPException(404, "License not found or not frozen")

@router.post("/licenses/revoke")
def revoke_license(key: str, token: str = ""):
    check_token(token)
    for lic in db["licenses"]:
        if lic["key"] == key and not lic["revoked"]:
            lic["status"] = "inactive"
            lic["revoked"] = True
            return {"result": "ok"}
    raise HTTPException(404, "License not found")
