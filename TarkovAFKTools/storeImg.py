import os
import re
import requests
from bs4 import BeautifulSoup

# ========== 1. 读取本地 HTML 文件 ==========
html_path = os.path.join(os.getcwd(), "img.html")
with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

soup = BeautifulSoup(html, "html.parser")

# ========== 2. 输出目录 ==========
food_dir = os.path.join(os.getcwd(), "Img", "Food")
drink_dir = os.path.join(os.getcwd(), "Img", "Drink")
os.makedirs(food_dir, exist_ok=True)
os.makedirs(drink_dir, exist_ok=True)

# ========== 3. 清理非法字符 ==========
def clean_filename(name):
    return re.sub(r'[\\/:*?"<>|]', "_", name).strip()

# ========== 4. 下载图片 ==========
def download_img(url, filename, folder):
    save_path = os.path.join(folder, filename + ".webp")
    try:
        resp = requests.get(url, timeout=10)
        if resp.status_code == 200:
            with open(save_path, "wb") as f:
                f.write(resp.content)
            print("已保存:", save_path)
        else:
            print("下载失败:", url)
    except Exception as e:
        print("请求错误:", url, e)

# ========== 5. HTML 中的食物和饮品都在 dasha-tabs 内 ==========
# BeautifulSoup 读取 dasha-tabs 的内容时，HTML 里的 {tabs-pane label="xxx"} 会作为纯文本出现
# 所以我们按文本切割标签块

html_text = soup.get_text()

# 按照你的文件结构精确分割
blocks = re.split(r'\{tabs-pane label="(食物|饮品)"\}', html)

# blocks 结构：
# [前置垃圾, label1, 内容1, label2, 内容2, ...]

for i in range(1, len(blocks), 2):
    label = blocks[i]          # "食物" 或 "饮品"
    section_html = blocks[i+1] # 对应的 HTML 片段

    part_soup = BeautifulSoup(section_html, "html.parser")
    imgs = part_soup.find_all("img")

    target_dir = food_dir if label == "食物" else drink_dir

    for img in imgs:
        alt = img.get("alt", "").strip()
        if not alt:
            continue

        alt_clean = clean_filename(alt)
        url = img.get("data-src") or img.get("src")

        if url and url.endswith(".webp"):
            download_img(url, alt_clean, target_dir)

print("全部处理完成！")
