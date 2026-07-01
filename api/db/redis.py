import json

import redis.asyncio as aioredis

from api.config import settings

_client: aioredis.Redis | None = None


def get_redis() -> aioredis.Redis:
    global _client
    if _client is None:
        _client = aioredis.from_url(settings.redis_url, decode_responses=True)
    return _client


_PREFS_TTL = 3600  # 1시간


def _prefs_key(user_id: int) -> str:
    return f"user:{user_id}:preferences"


async def get_cached_preferences(user_id: int) -> dict | None:
    r = get_redis()
    raw = await r.get(_prefs_key(user_id))
    if raw is None:
        return None
    return json.loads(raw)


async def set_cached_preferences(user_id: int, prefs: dict) -> None:
    r = get_redis()
    await r.set(_prefs_key(user_id), json.dumps(prefs), ex=_PREFS_TTL)


async def invalidate_preferences(user_id: int) -> None:
    r = get_redis()
    await r.delete(_prefs_key(user_id))
