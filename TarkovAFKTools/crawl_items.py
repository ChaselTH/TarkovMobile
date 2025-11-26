"""
Crawler for EFTarkov item pages.

Iterates through https://www.eftarkov.com/news/{NUM}.html pages,
filters out quest/news posts by detecting item size blocks, and writes
per-type JSON files (e.g., bullet.json) with captured attributes.

Standard library only; safe to run without extra dependencies.
"""
from __future__ import annotations

import argparse
import json
import logging
import re
import time
from html import unescape
from pathlib import Path
from typing import Dict, List, Optional
from urllib import error, request

BASE_URL = "https://www.eftarkov.com/news/{id}.html"
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0 Safari/537.36"
)

SIZE_PATTERN = re.compile(
    r'id="width">\s*(\d+)\s*</span>\s*X\s*<span id="height">\s*(\d+)',
    re.IGNORECASE | re.DOTALL,
)
TABLE_ROW_PATTERN = re.compile(
    r"<tr[^>]*>\s*<td[^>]*>(.*?)</td>\s*<td[^>]*>(.*?)</td>\s*</tr>",
    re.DOTALL,
)
TAG_PATTERN = re.compile(r"<[^>]+>")
TYPE_KEYWORDS = {
    "子弹": "bullet",
    "弹药": "bullet",
    "弹匣": "magazine",
    "武器": "weapon",
    "背包": "backpack",
    "背心": "rig",
    "战术背心": "rig",
    "护甲": "armor",
    "头盔": "helmet",
    "医疗": "meds",
    "食物": "food",
    "饮料": "drink",
    "子弹箱": "ammo_case",
    "附件": "attachment",
    "手雷": "grenade",
    "钥匙": "key",
}


def fetch_html(url: str, timeout: int = 10) -> Optional[str]:
    req = request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with request.urlopen(req, timeout=timeout) as resp:
            if resp.status != 200:
                logging.warning("Non-200 status %s for %s", resp.status, url)
                return None
            return resp.read().decode("utf-8", "ignore")
    except error.URLError as exc:  # pragma: no cover - network dependent
        logging.warning("Request failed for %s: %s", url, exc)
        return None


def strip_tags(text: str) -> str:
    return unescape(TAG_PATTERN.sub("", text)).strip()


def parse_item(html: str, url: str) -> Optional[Dict[str, object]]:
    if "占用格数" not in html:
        return None

    size_match = SIZE_PATTERN.search(html)
    if not size_match:
        return None

    width, height = int(size_match.group(1)), int(size_match.group(2))

    table_data: Dict[str, str] = {}
    for key_html, value_html in TABLE_ROW_PATTERN.findall(html):
        key = strip_tags(key_html).replace("：", "").replace(":", "").strip()
        value = strip_tags(value_html)
        if not key:
            continue
        table_data[key] = value

    name_match = re.search(r"<h1[^>]*>(.*?)</h1>", html, re.DOTALL)
    if not name_match:
        name_match = re.search(r"<title>(.*?)</title>", html, re.DOTALL)
    name = strip_tags(name_match.group(1)) if name_match else "未知物品"

    item: Dict[str, object] = {
        "名称": name,
        "宽": width,
        "高": height,
        "来源": url,
    }
    item.update(table_data)
    item_type = determine_type(table_data)
    item["类型标识"] = item_type

    return item


def determine_type(table_data: Dict[str, str]) -> str:
    candidate = table_data.get("类型") or table_data.get("类别") or table_data.get("分类") or ""
    for keyword, slug in TYPE_KEYWORDS.items():
        if keyword in candidate:
            return slug
    return "other"


def write_json(output_dir: Path, items_by_type: Dict[str, List[Dict[str, object]]]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for item_type, entries in items_by_type.items():
        path = output_dir / f"{item_type}.json"
        with path.open("w", encoding="utf-8") as f:
            json.dump(entries, f, ensure_ascii=False, indent=2)
        logging.info("Wrote %s items to %s", len(entries), path)


def crawl(start: int, end: int, delay: float, output_dir: Path) -> None:
    items_by_type: Dict[str, List[Dict[str, object]]] = {}
    for item_id in range(start, end + 1):
        url = BASE_URL.format(id=item_id)
        html = fetch_html(url)
        if not html:
            continue
        item = parse_item(html, url)
        if not item:
            continue
        item_type = item.get("类型标识", "other")
        items_by_type.setdefault(item_type, []).append(item)
        logging.info(
            "Captured item %s (%s) at %s", item.get("名称"), item_type, url
        )
        if delay:
            time.sleep(delay)

    if items_by_type:
        write_json(output_dir, items_by_type)
    else:
        logging.warning("No items captured in range %s-%s", start, end)


def main() -> None:
    parser = argparse.ArgumentParser(description="Crawl EFTarkov item pages")
    parser.add_argument("--start", type=int, default=1, help="Starting NUM value")
    parser.add_argument("--end", type=int, default=5000, help="Ending NUM value")
    parser.add_argument(
        "--delay",
        type=float,
        default=0.2,
        help="Delay in seconds between requests to avoid hammering the site",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).parent / "item_json",
        help="Folder to write per-type JSON files",
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    crawl(args.start, args.end, args.delay, args.output_dir)


if __name__ == "__main__":
    main()
