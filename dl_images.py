import os
import re
import time
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

from curl_cffi import requests as cffi_requests

import truststore
truststore.inject_into_ssl()

# --- Configuration ---
HTML_FILE = "page.htm"
BASE_URL = "https://www.gtabase.com"
OUTPUT_DIR = "images"
DELAY = 0.3  # secondes entre chaque téléchargement

HEADERS = {
 "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                  "AppleWebKit/537.36 (KHTML, like Gecko) "
                  "Chrome/124.0 Safari/537.36",
    "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
    "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8",
    "Referer": "https://www.gtabase.com/gta-6/vehicles",
}

session = requests.Session()
session.headers.update(HEADERS)


def fix_image_path(path: str) -> str:
    """Retire le dossier 'resized' et le suffixe _WxH (ex: _320x180)."""
    path = path.replace("/resized/", "/")
    path = re.sub(r"_\d+x\d+(?=\.\w+$)", "", path)
    return path


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    with open(HTML_FILE, encoding="utf-8") as f:
        soup = BeautifulSoup(f, "html.parser")

    container = soup.find(id="cars_list")
    if container is None:
        print("Conteneur #cars_list introuvable.")
        return

    items = container.find_all("div", class_="product-item", recursive=False)
    print(f"{len(items)} éléments trouvés.")

    ok, skipped, errors = 0, 0, 0

    for item in items:
        meta = item.find("meta", attrs={"itemprop": "image"})
        if not meta or not meta.get("content"):
            continue

        image_path = fix_image_path(meta["content"])
        image_url = urljoin(BASE_URL, image_path)
        filename = os.path.basename(image_path)
        dest = os.path.join(OUTPUT_DIR, filename)

        if os.path.exists(dest):
            print(f"[skip] {filename} existe déjà")
            skipped += 1
            continue

        try:
            resp = cffi_requests.get(image_url, impersonate="chrome", headers={"Referer": "https://www.gtabase.com/"}, timeout=30)
            resp.raise_for_status()
            with open(dest, "wb") as out:
                out.write(resp.content)
            print(f"[ok]   {image_url}")
            ok += 1
        except requests.RequestException as e:
            print(f"[err]  {image_url} -> {e}")
            errors += 1

        time.sleep(DELAY)  # pause entre chaque requête

    print(f"\nTerminé : {ok} téléchargées, {skipped} ignorées, {errors} erreurs.")


if __name__ == "__main__":
    main()