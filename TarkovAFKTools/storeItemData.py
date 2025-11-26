import json
import os
import re
from bs4 import BeautifulSoup

# ========== 1. 读取本地 HTML 文件 ==========
html_path = os.path.join(os.getcwd(), "img.html")
if not os.path.exists(html_path):
    raise FileNotFoundError(f"未找到本地文件: {html_path}")

with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")

# ========== 2. 解析食物与饮品分区 ==========
# BeautifulSoup 读取 dasha-tabs 的内容时，HTML 里的 {tabs-pane label="xxx"} 会作为纯文本出现
# 这里保持与下载图片脚本一致的分割逻辑
blocks = re.split(r'\{tabs-pane label="(食物|饮品)"\}', html)

items = []

for i in range(1, len(blocks), 2):
    label = blocks[i]          # "食物" 或 "饮品"
    section_html = blocks[i + 1]

    part_soup = BeautifulSoup(section_html, "html.parser")
    lis = part_soup.find_all("li", class_=re.compile("newMainLi"))

    for li in lis:
        title_tag = li.find("a", class_="title")
        name = title_tag.get_text(strip=True) if title_tag else None
        if not name:
            continue

        meta_li = li.find("div", class_="meta")
        stat_text = meta_li.get_text(strip=True) if meta_li else ""

        hydration_match = re.search(r"水分：\s*([-+]?\d+)", stat_text)
        energy_match = re.search(r"能量：\s*([-+]?\d+)", stat_text)

        hydration = int(hydration_match.group(1)) if hydration_match else None
        energy = int(energy_match.group(1)) if energy_match else None

        items.append({
            "name": name,
            "type": "food" if label == "食物" else "drink",
            "hydration": hydration,
            "energy": energy,
        })

# ========== 3. 输出 JSON 文件 ==========
output_path = os.path.join(os.getcwd(), "item_data.json")

with open(output_path, "w", encoding="utf-8") as f:
    json.dump(items, f, ensure_ascii=False, indent=2)

print(f"已写入 {len(items)} 条物品数据 -> {output_path}")
