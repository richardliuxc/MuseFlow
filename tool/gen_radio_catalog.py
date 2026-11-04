#!/usr/bin/env python3
"""Build a compact, curated radio catalogue from the RadioHub SQLite database.

The app ships a small JSON snapshot so it can browse stations offline without
shipping the 58 MB source database. Regenerate with:

    python3 tool/gen_radio_catalog.py --db /path/to/radiohub.db
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path

import sqlite3

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "data" / "radio_stations.json"

COUNTRY_ZH = {
    "CN": "中国", "TW": "中国台湾", "HK": "中国香港", "MO": "中国澳门",
    "US": "美国", "GB": "英国", "JP": "日本", "KR": "韩国", "FR": "法国",
    "DE": "德国", "CA": "加拿大", "AU": "澳大利亚", "SG": "新加坡",
    "MY": "马来西亚", "IT": "意大利", "ES": "西班牙", "NL": "荷兰",
    "RU": "俄罗斯", "BR": "巴西", "MX": "墨西哥", "IN": "印度",
    "TH": "泰国", "VN": "越南", "PH": "菲律宾", "ID": "印度尼西亚",
    "TR": "土耳其", "AE": "阿联酋", "CH": "瑞士", "SE": "瑞典",
    "NO": "挪威", "DK": "丹麦", "FI": "芬兰", "PL": "波兰",
    "PT": "葡萄牙", "GR": "希腊", "IE": "爱尔兰", "NZ": "新西兰",
    "AR": "阿根廷", "CL": "智利", "CO": "哥伦比亚", "PE": "秘鲁",
    "ZA": "南非", "EG": "埃及", "SA": "沙特阿拉伯",
}

ASIA = {"JP", "KR", "SG", "MY", "TH", "VN", "PH", "ID", "IN"}
CHINESE = {"CN", "TW", "HK", "MO"}

GENRE_RULES = [
    ("新闻", ("news", "新闻", "资讯", "current affairs", "information", "cctv", "电视伴音")),
    ("谈话", ("talk", "谈话", "脱口秀", "crosstalk", "相声", "interview", "故事")),
    ("体育", ("sport", "体育", "足球", "篮球")),
    ("爵士", ("jazz", "blues", "soul", "swing")),
    ("古典", ("classical", "opera", "symphony", "orchestral", "hymn")),
    ("摇滚", ("rock", "metal", "punk", "alternative")),
    ("电子", ("electronic", "dance", "techno", "house", "trance", "edm", "club", "ambient", "chillout")),
    ("怀旧", ("oldies", "retro", "old time", "80s", "90s", "classic hits", "怀旧", "经典")),
    ("文化", ("culture", "文化", "history", "education", "arts", "literature", "documentary")),
    ("生活", ("lifestyle", "health", "travel", "cooking", "relax", "生活", "情感")),
    ("流行", ("pop", "top 40", "hits", "chart", "流行", "华语")),
    ("音乐", ("music", "音乐", "songs", "golden")),
]


def region_for(code: str) -> str:
    if code in CHINESE:
        return "华语"
    if code in ASIA:
        return "日韩"
    if code in {"US", "CA", "MX", "BR", "AR", "CL", "CO", "PE"}:
        return "欧美"
    if code in {"GB", "IE", "FR", "DE", "IT", "ES", "NL", "PT", "GR", "CH", "SE", "NO", "DK", "FI", "PL", "RU", "AU", "NZ"}:
        return "欧美"
    return "世界"


def genre_for(tags: str, name: str, language: str) -> str:
    haystack = " ".join((tags or "", name or "", language or "")).lower()
    for genre, keywords in GENRE_RULES:
        if any(word in haystack for word in keywords):
            return genre
    return "综合"


def clean(text: str) -> str:
    return re.sub(r"\s+", " ", (text or "").replace("\u200b", " ")).strip()


def is_usable_url(url: str) -> bool:
    u = (url or "").strip().lower()
    if not u.startswith(("http://", "https://")):
        return False
    if any(bad in u for bad in ("youtube.com", "facebook.com", "instagram.com", "tiktok.com", "embed", ".html")):
        return False
    return True


def row_to_station(row) -> dict:
    (uuid, name, resolved, original, homepage, favicon, tags, country,
     code, language, votes, codec, bitrate, hls) = row
    url = clean(resolved or original)
    tags_list = [clean(t) for t in (tags or "").split(",") if clean(t)]
    country_code = (code or "").upper()
    return {
        "id": uuid,
        "name": clean(name),
        "url": url,
        "homepage": clean(homepage),
        "favicon": clean(favicon),
        "tags": tags_list[:6],
        "country": COUNTRY_ZH.get(country_code, clean(country) or country_code),
        "countryCode": country_code,
        "language": clean(language),
        "region": region_for(country_code),
        "genre": genre_for(tags or "", name or "", language or ""),
        "votes": int(votes or 0),
        "codec": clean(codec),
        "bitrate": int(bitrate or 0),
        "hls": 1 if hls else 0,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--db", required=True, help="Path to radiohub.db")
    parser.add_argument("--out", default=str(OUT))
    args = parser.parse_args()

    source = Path(args.db)
    if not source.exists():
        raise SystemExit(f"database not found: {source}")

    connection = sqlite3.connect(source)
    connection.row_factory = sqlite3.Row
    base = """
        SELECT stationuuid, name, url_resolved, url, homepage, favicon, tags,
               country, countrycode, language, votes, codec, bitrate, hls
        FROM stations
        WHERE lastcheckok = 1
          AND url_resolved IS NOT NULL
          AND url_resolved LIKE 'http%'
    """
    chinese = connection.execute(
        base + " AND countrycode IN ('CN','TW','HK','MO') ORDER BY votes DESC LIMIT 280"
    ).fetchall()
    international = connection.execute(
        base + """
          AND countrycode IN ('US','GB','CA','AU','FR','DE','JP','KR','SG','MY','TH','IT','ES','NL','RU','BR','MX')
          AND (lower(tags) LIKE '%music%' OR lower(tags) LIKE '%news%'
               OR lower(tags) LIKE '%jazz%' OR lower(tags) LIKE '%classical%'
               OR lower(tags) LIKE '%talk%' OR lower(tags) LIKE '%culture%')
          ORDER BY votes DESC LIMIT 280
        """
    ).fetchall()
    global_rows = connection.execute(base + " ORDER BY votes DESC LIMIT 120").fetchall()
    connection.close()

    seen_urls: set[str] = set()
    seen_names: set[str] = set()
    stations: list[dict] = []
    for row in list(chinese) + list(international) + list(global_rows):
        station = row_to_station(row)
        if not station["name"] or not is_usable_url(station["url"]):
            continue
        key_url = station["url"].split("?")[0].rstrip("/").lower()
        key_name = station["name"].lower() + "|" + station["countryCode"]
        if key_url in seen_urls or key_name in seen_names:
            continue
        seen_urls.add(key_url)
        seen_names.add(key_name)
        stations.append(station)
        if len(stations) >= 520:
            break

    # Hosted order: Chinese first, then international, then the rest.
    stations.sort(key=lambda s: (0 if s["region"] == "华语" else 1, -s["votes"]))

    # Curated picks for the home page / radio hero. Prefer stations whose
    # streams were manually verified, then fill with regional highlights.
    preferred_names = [
        "怀集音乐之声",
        "AsiaFM高清音乐台",
        "清晨音乐台",
        "上海流行音乐广播 动感101 FM101.7",
        "北京音乐广播",
        "Classic FM UK",
        "MANGORADIO",
        "上海经典音乐广播 FM94.7",
    ]
    featured_ids: list[str] = []
    by_name = {s["name"]: s["id"] for s in stations}
    for name in preferred_names:
        station_id = by_name.get(name)
        if station_id and station_id not in featured_ids:
            featured_ids.append(station_id)

    def pick(predicate) -> None:
        if len(featured_ids) >= 8:
            return
        for station in stations:
            if station["id"] in featured_ids:
                continue
            if predicate(station):
                featured_ids.append(station["id"])
                return

    pick(lambda s: s["region"] == "华语" and s["genre"] == "音乐" and s["hls"] == 0)
    pick(lambda s: s["region"] == "华语" and s["genre"] == "新闻")
    pick(lambda s: s["region"] == "日韩" and s["genre"] in ("音乐", "流行"))
    pick(lambda s: s["region"] == "欧美" and s["genre"] == "爵士")

    for station in stations:
        station["featured"] = station["id"] in featured_ids

    payload = {
        "schema": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "source": "RadioHub / Radio Browser",
        "count": len(stations),
        "regions": ["华语", "欧美", "日韩", "世界"],
        "genres": ["音乐", "新闻", "谈话", "流行", "摇滚", "电子", "爵士", "古典", "怀旧", "文化", "生活", "体育", "综合"],
        "featuredIds": featured_ids,
        "stations": stations,
    }

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"wrote {len(stations)} stations ({out.stat().st_size / 1024:.0f} KB) -> {out}")
    print("featured:", [next(s["name"] for s in stations if s["id"] == i) for i in featured_ids])


if __name__ == "__main__":
    main()
