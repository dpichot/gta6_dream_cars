import os
import re
import time
from urllib.parse import urljoin, urlparse

from curl_cffi import requests as cffi_requests
from bs4 import BeautifulSoup

# --- Configuration ---
HTML_FILE = "page.htm"
BASE_URL = "https://www.gtabase.com"
OUTPUT_FILE = "cars.dart"
DELAY = 0.5
VERIFY_SSL = True  # passer à False si l'erreur "self-signed certificate" revient

# Pas de User-Agent ici : curl_cffi envoie ceux d'un vrai Chrome (impersonate)
HEADERS = {
    "Accept-Language": "fr-FR,fr;q=0.9,en;q=0.8",
    "Referer": "https://www.gtabase.com/gta-6/vehicles",
}

session = cffi_requests.Session(impersonate="chrome")


# ---------- Helpers ----------
def fetch(url: str) -> BeautifulSoup:
    resp = session.get(url, headers=HEADERS, timeout=30, verify=VERIFY_SSL)
    resp.raise_for_status()
    return BeautifulSoup(resp.text, "html.parser")


def clean(text):
    if text is None:
        return None
    text = re.sub(r"\s+", " ", text).strip()
    return text or None


def field_value(soup, selector):
    """Texte du .field-value du <li> qui correspond au sélecteur."""
    li = soup.select_one(selector)
    if not li:
        return None
    val = li.select_one(".field-value")
    return clean(val.get_text(" ", strip=True)) if val else None


def to_int(text):
    if text is None:
        return None
    m = re.search(r"\d+", text)
    return int(m.group()) if m else None


def to_float(text):
    if text is None:
        return None
    m = re.search(r"\d+(?:\.\d+)?", text)
    return float(m.group()) if m else None


def dart_str(value):
    if value is None:
        return "null"
    v = value.replace("\\", "\\\\").replace('"', '\\"').replace("$", "\\$")
    return f'"{v}"'


def dart_val(value):
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return dart_str(value)
    return str(value)


# ---------- Extraction ----------
def parse_car(soup, url):
    data = {"id": urlparse(url).path.rstrip("/").split("/")[-1]}

    # Nom et marque : premier mot = marque, reste = nom
    h1 = soup.select_one("div.page-header h1")
    full_name = clean(h1.get_text(" ", strip=True)) if h1 else None
    if full_name:
        parts = full_name.split(" ", 1)
        data["marque"] = parts[0]
        data["nom"] = parts[1] if len(parts) > 1 else None
    else:
        data["marque"] = data["nom"] = None

    data["categorie"] = field_value(soup, "li.vehicle-class")
    data["style"] = field_value(soup, "li.gta6-style")
    data["access"] = field_value(soup, "li.gta6-keyless")
    data["tracker"] = field_value(soup, "li.gta6-tracker")
    data["securite"] = (
        "advanced" in data["tracker"].lower() if data["tracker"] else None
    )
    data["nombrePlaces"] = to_int(field_value(soup, "li.seats"))

    # Classement route : li.rating-asphalt
    data["classementRoute"] = to_int(field_value(soup, "li.rating-asphalt"))

    # Classement terre : li.overall qui n'est PAS rating-asphalt
    data["classementTerre"] = None
    for li in soup.select("li.field-entry.overall"):
        if "rating-asphalt" in (li.get("class") or []):
            continue
        val = li.select_one(".field-value")
        if val:
            data["classementTerre"] = to_int(val.get_text())
            break

    # Modèle de base
    base_li = soup.select_one("li.converted-from")
    base_name = None
    if base_li:
        a = base_li.select_one("h3.contentheading a")
        base_name = clean(a.get_text()) if a else field_value(soup, "li.converted-from")
    data["modeleBase"] = base_name
    data["unique"] = base_name is not None

    # Stats
    stats = {
        "vitesse": to_float(field_value(soup, "li.field-entry.speed")),
        "acceleration": to_float(field_value(soup, "li.field-entry.acceleration")),
        "adherenceAsphalte": to_float(field_value(soup, "li.field-entry.asphalt-handling")),
        "adherenceTerre": to_float(field_value(soup, "li.field-entry.off-road-handling")),
        "robustesse": to_float(field_value(soup, "li.field-entry.strength")),
    }
    data["stats"] = stats if any(v is not None for v in stats.values()) else None
    return data


def to_dart(d):
    if d["stats"]:
        s = d["stats"]
        stats = "CarStats(" + ", ".join(f"{k}: {dart_val(v)}" for k, v in s.items()) + ")"
    else:
        stats = "null"

    comment = f" // base: {d['modeleBase']}" if d["modeleBase"] else ""
    lines = [
        "  Car(",
        f"    id: {dart_val(d['id'])},",
        f"    nom: {dart_val(d['nom'])},",
        f"    marque: {dart_val(d['marque'])},",
        "    possedee: false,",
        f"    categorie: {dart_val(d['categorie'])},",
        f"    style: {dart_val(d['style'])},",
        f"    securite: {dart_val(d['securite'])},",
        f"    access: {dart_val(d['access'])},",
        f"    tracker: {dart_val(d['tracker'])},",
        f"    nombrePlaces: {dart_val(d['nombrePlaces'])},",
        f"    classementRoute: {dart_val(d['classementRoute'])},",
        f"    classementTerre: {dart_val(d['classementTerre'])},",
        f"    stats: {stats},",
        f"    unique: {dart_val(d['unique'])},{comment}",
        "  ),",
    ]
    return "\n".join(lines)


# ---------- Main ----------
def main():
    with open(HTML_FILE, encoding="utf-8") as f:
        soup = BeautifulSoup(f, "html.parser")

    container = soup.find(id="cars_list")
    if container is None:
        print("Conteneur #cars_list introuvable.")
        return

    # Liens uniques (dédoublonnés, ordre conservé)
    urls = []
    for item in container.find_all("div", class_="product-item", recursive=False):
        link = item.find("link", attrs={"itemprop": "url"})
        if link and link.get("href"):
            url = urljoin(BASE_URL, link["href"])
            if url not in urls:
                urls.append(url)

    print(f"{len(urls)} voitures à traiter.")
    errors = []

    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        out.write("final cars = [\n")
        for i, url in enumerate(urls, 1):
            try:
                car = parse_car(fetch(url), url)
                out.write(to_dart(car) + "\n")
                out.flush()
                print(f"[{i}/{len(urls)}] ok  {car['marque']} {car['nom']}")
            except Exception as e:
                print(f"[{i}/{len(urls)}] ERR {url} -> {e}")
                errors.append(url)
            time.sleep(DELAY)
        out.write("];\n")

    print(f"\nTerminé : {len(urls) - len(errors)} ok, {len(errors)} erreurs.")
    for u in errors:
        print("  -", u)


if __name__ == "__main__":
    main()