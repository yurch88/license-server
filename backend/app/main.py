from fastapi import FastAPI
from . import api
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.include_router(api.router)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)
