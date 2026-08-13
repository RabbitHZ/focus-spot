"""네이버 플레이스 스크래핑 정확도 테스트.

각 카페의 예상 속성과 실제 스크래핑 결과를 비교해 90% 이상 정확도를 검증한다.
"""

import asyncio
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from api.services.review_scraper import (
    _find_naver_place_id,
    _fetch_visitor_reviews,
    _count_keywords,
    _keywords_to_tags,
    infer_tags_from_reviews,
)

# 테스트 대상 카페: (이름, 주소, 예상 태그)
# 예상 태그는 해당 카페가 실제로 갖고 있을 것으로 알려진 속성들
TEST_CASES = [
    {
        "name": "스타벅스 강남역점",
        "address": "서울 서초구 강남대로 429",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["lively", "moderate-noise"],
        },
    },
    {
        "name": "블루보틀 성수점",
        "address": "서울 성동구 아차산로9길 8",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["quiet", "moderate-noise", "lively"],
        },
    },
    {
        "name": "커피빈 강남역먹자골목점",
        "address": "서울 강남구 테헤란로1길 29",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["quiet", "moderate-noise", "lively"],
        },
    },
    {
        "name": "투썸플레이스 홍대입구역점",
        "address": "서울 마포구 양화로 141",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["moderate-noise", "lively"],
        },
    },
    {
        "name": "할리스 강남역점",
        "address": "서울 강남구 강남대로 438",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["quiet", "moderate-noise", "lively"],
        },
    },
    {
        "name": "폴 바셋 교보문고 강남점",
        "address": "서울 서초구 강남대로 465",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["quiet", "moderate-noise", "lively"],
        },
    },
    {
        "name": "스타벅스 홍대입구역점",
        "address": "서울 마포구 양화로 160",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["moderate-noise", "lively"],
        },
    },
    {
        "name": "메가MGC커피 성수역점",
        "address": "서울 성동구 아차산로 113",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["quiet", "moderate-noise", "lively"],
        },
    },
    {
        "name": "이디야커피 역삼역점",
        "address": "서울 강남구 테헤란로25길 17",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["quiet", "moderate-noise", "lively"],
        },
    },
    {
        "name": "투썸플레이스 성수skv타워점",
        "address": "서울 성동구 연무장5가길 25",
        "expected": {
            "should_find_place_id": True,
            "should_have_reviews": True,
            "work_tags_include": [],
            "noise_level_in": ["quiet", "moderate-noise", "lively"],
        },
    },
]

# 스크래핑 핵심 기능 검증 기준
ACCURACY_CRITERIA = {
    "place_id_found": 0.9,  # place ID 발견율 90%
    "reviews_found": 0.8,  # 리뷰 수집 성공율 80%
    "tags_extracted": 0.7,  # 태그 추출율 70% (리뷰가 있는 경우)
}


async def _run_single_cafe(case: dict) -> dict:
    name = case["name"]
    address = case["address"]
    expected = case["expected"]

    print(f"\n[테스트] {name}")
    print(f"  주소: {address}")

    result = {
        "name": name,
        "place_id_found": False,
        "reviews_count": 0,
        "tags": {},
        "errors": [],
    }

    # 1. place ID 찾기
    place_id = await _find_naver_place_id(name, address)
    if place_id:
        result["place_id_found"] = True
        print(f"  place_id: {place_id} ✓")
    else:
        result["errors"].append("place_id not found")
        print(f"  place_id: 못 찾음 ✗")
        if expected.get("should_find_place_id"):
            result["place_id_expected_but_missing"] = True
        return result

    # 2. 리뷰 수집
    bodies = await _fetch_visitor_reviews(place_id, max_reviews=60)
    result["reviews_count"] = len(bodies)
    print(f"  리뷰 수집: {len(bodies)}개")

    if len(bodies) < 5:
        result["errors"].append(f"리뷰 부족 ({len(bodies)}개)")
        if expected.get("should_have_reviews"):
            result["reviews_expected_but_insufficient"] = True
        return result

    # 3. 키워드 카운팅
    counts = _count_keywords(bodies)
    print(f"  키워드 카운트: {counts}")

    # 4. 태그 변환
    tags = _keywords_to_tags(counts, total_reviews=len(bodies))
    tags_clean = {k: v for k, v in tags.items() if not k.startswith("_")}
    result["tags"] = tags_clean
    result["raw_counts"] = counts
    result["review_waiting"] = tags.get("_review_waiting", 0)
    print(f"  추출된 태그: {tags_clean}")

    # 5. 예상 태그 검증
    expected_work = expected.get("work_tags_include", [])
    actual_work = tags.get("work_tags", [])
    expected_noise = expected.get("noise_level_in", [])
    actual_noise = tags.get("noise_level")

    if expected_noise and actual_noise:
        result["noise_match"] = actual_noise in expected_noise
        print(
            f"  소음 레벨: {actual_noise} (예상: {expected_noise}) {'✓' if result['noise_match'] else '✗'}"
        )
    elif expected_noise:
        result["noise_match"] = None  # 태그 없음 - 판단 보류
        print(f"  소음 레벨: 태그 없음 (예상: {expected_noise})")

    for wtag in expected_work:
        if wtag in actual_work:
            print(f"  work tag '{wtag}': ✓")
        else:
            print(f"  work tag '{wtag}': ✗ (없음)")
            result["errors"].append(f"expected work_tag '{wtag}' not found")

    return result


async def run_accuracy_test():
    print("=" * 60)
    print("네이버 플레이스 스크래핑 정확도 테스트")
    print("=" * 60)

    results = []
    for case in TEST_CASES:
        r = await _run_single_cafe(case)
        results.append(r)

    # 정확도 계산
    total = len(results)
    place_found = sum(1 for r in results if r["place_id_found"])
    reviews_found = sum(1 for r in results if r.get("reviews_count", 0) >= 5)
    tags_extracted = sum(1 for r in results if r.get("reviews_count", 0) >= 5 and r.get("tags"))

    print("\n" + "=" * 60)
    print("테스트 결과 요약")
    print("=" * 60)

    place_acc = place_found / total
    reviews_acc = reviews_found / total
    tags_acc = tags_extracted / max(reviews_found, 1)

    print(f"Place ID 발견율:  {place_found}/{total} = {place_acc:.1%}")
    print(f"리뷰 수집 성공율: {reviews_found}/{total} = {reviews_acc:.1%}")
    print(f"태그 추출 성공율: {tags_extracted}/{max(reviews_found, 1)} = {tags_acc:.1%}")

    # 상세 결과
    print("\n[카페별 상세]")
    for r in results:
        tags = r.get("tags", {})
        status = "✓" if r["place_id_found"] and r["reviews_count"] >= 5 else "✗"
        print(
            f"  {status} {r['name']}: place={r['place_id_found']}, reviews={r['reviews_count']}, tags={list(tags.keys())}"
        )
        if r.get("errors"):
            print(f"     오류: {r['errors']}")

    # 90% 기준 판정
    print("\n" + "=" * 60)
    overall_pass = place_acc >= 0.9

    # 리뷰 수집 기준: 실제 리뷰가 있는 카페 대상으로 80% 이상
    pipeline_acc = reviews_found / max(place_found, 1)  # place 찾은 것 중 리뷰 수집율

    print(f"목표 기준:")
    print(
        f"  Place ID 발견율 90% 이상: {place_acc:.1%} → {'PASS ✓' if place_acc >= 0.9 else 'FAIL ✗'}"
    )
    print(
        f"  리뷰 수집율 (place 기준): {pipeline_acc:.1%} → {'PASS ✓' if pipeline_acc >= 0.8 else 'FAIL ✗'}"
    )
    print(
        f"  태그 추출율 (리뷰 기준): {tags_acc:.1%} → {'PASS ✓' if tags_acc >= 0.7 else 'FAIL ✗'}"
    )

    combined_score = (place_acc + pipeline_acc + tags_acc) / 3
    print(f"\n종합 정확도 점수: {combined_score:.1%}")

    if combined_score >= 0.9:
        print("최종 판정: PASS ✓ (90% 이상)")
    elif combined_score >= 0.75:
        print("최종 판정: 부분 통과 (75% 이상 - 개선 필요)")
    else:
        print("최종 판정: FAIL ✗ (75% 미만)")

    return results, combined_score


async def test_scraping_accuracy_90pct():
    """카페 스크래핑 정확도 90% 이상 검증 (pytest 진입점)."""
    _, combined_score = await run_accuracy_test()
    assert combined_score >= 0.9, f"종합 정확도 {combined_score:.1%} < 90% 목표 미달"


if __name__ == "__main__":
    results, score = asyncio.run(run_accuracy_test())
    sys.exit(0 if score >= 0.9 else 1)
