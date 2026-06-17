from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from api.db.database import init_db
from api.routers import auth, cafes, condition, health, google_auth


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title="FocusSpot API",
    description="애플워치 건강 데이터 기반 카페 추천 서비스",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(google_auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(health.router, prefix="/api/health", tags=["health"])
app.include_router(condition.router, prefix="/api/condition", tags=["condition"])
app.include_router(cafes.router, prefix="/api/cafes", tags=["cafes"])


@app.get("/")
async def root():
    return {"status": "ok", "service": "FocusSpot API"}
