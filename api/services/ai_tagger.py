"""Claude API로 카페 속성 태그 추론"""

import json
import re

import anthropic

from api.config import settings

_client: anthropic.AsyncAnthropic | None = None


def _get_client() -> anthropic.AsyncAnthropic:
    global _client
    if _client is None:
        _client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
    return _client


async def infer_cafe_tags(name: str, address: str) -> dict:
    """
    카페 이름과 주소만으로 속성 태그를 추론한다.
    Anthropic API 키가 없으면 기본값을 반환한다.
    """
    if not settings.anthropic_api_key:
        return _default_tags()

    prompt = f"""다음 카페의 분위기와 특성을 추론해서 JSON으로만 답해줘. 설명 없이 JSON만.

카페명: {name}
주소: {address}

다음 필드를 추론해:
- noise_level: "quiet" | "moderate-noise" | "lively"
- lighting: "bright" | "dim" | "natural-light"
- space_type: "spacious" | "cozy" | "private-booth" | "counter-seat"
- work_tags: 해당하는 것만 골라 배열로 → ["work-friendly", "fast-wifi", "power-outlet", "no-laptop", "easy-to-seat", "specialty-coffee", "decaf-available", "non-coffee"]

카페 이름에서 힌트를 최대한 활용해. 예: 스타벅스→work-friendly/fast-wifi, 스페셜티 카페→specialty-coffee, 감성 카페→cozy/dim"""

    try:
        client = _get_client()
        msg = await client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=300,
            messages=[{"role": "user", "content": prompt}],
        )
        text = msg.content[0].text.strip()
        # JSON 블록 추출
        match = re.search(r"\{.*\}", text, re.DOTALL)
        if match:
            return json.loads(match.group())
    except Exception:
        pass

    return _default_tags()


def _default_tags() -> dict:
    return {
        "noise_level": "moderate-noise",
        "lighting": "bright",
        "space_type": "cozy",
        "work_tags": ["work-friendly"],
    }
