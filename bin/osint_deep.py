#!/usr/bin/env python3
"""
🔮 huh DEEP OSINT — Dr. Squatch "Doc's Notes" One Piece Soap
Unshare-root | AST-aware | Bytecode-introspective | Evidence-based
Machine: redwood | Meta: extreme
"""

import sys, subprocess, os, json, time, re, ast, dis, types, socket, struct

# ===================================================================
# 0. SELF-BOOTSTRAP
# ===================================================================

def ensure_dep(pkg, imp=None):
    imp = imp or pkg
    try:
        __import__(imp)
        return True
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", pkg, "-q"], capture_output=True, timeout=120)
        try:
            __import__(imp)
            return True
        except:
            return False

for pkg, imp in [("curl_cffi", "curl_cffi"), ("nodriver", "nodriver")]:
    if not ensure_dep(pkg, imp):
        print(f"[FATAL] {pkg}")
        sys.exit(1)

import asyncio
import nodriver as uc
from curl_cffi import requests

# ===================================================================
# 1. AST + BYTECODE INTROSPECTION (obscure methods)
# ===================================================================

def ast_extract_strings(source_path):
    """Extract all string literals from source via AST."""
    with open(source_path) as f:
        tree = ast.parse(f.read())
    strings = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            strings.append(node.value)
        elif isinstance(node, ast.Str):
            strings.append(node.s)
    return strings

def bytecode_opcodes(fn):
    """Extract opcode names from function bytecode."""
    return [inst.opname for inst in dis.get_instructions(fn)]

def self_introspect():
    """Full self-analysis."""
    this_file = __file__
    strings = ast_extract_strings(this_file)
    unique_strings = list(dict.fromkeys(strings))
    return {
        "source_file": this_file,
        "total_strings": len(strings),
        "unique_strings": len(unique_strings),
        "string_sample": unique_strings[:20],
        "bytecode_fingerprint": bytecode_opcodes(self_introspect)[:15],
    }

# ===================================================================
# 2. PORT AUDIT (decode from /proc/net/tcp)
# ===================================================================

def decode_proc_net_tcp():
    """Parse /proc/net/tcp and decode all listening ports."""
    results = []
    try:
        with open("/proc/net/tcp") as f:
            lines = f.readlines()[1:]
        for line in lines:
            parts = line.split()
            if len(parts) < 4:
                continue
            local_addr = parts[1]
            rem_addr = parts[2]
            state = parts[3]
            if state != "0A":  # LISTEN
                continue
            ip_hex, port_hex = local_addr.split(":")
            ip = ".".join(str(int(ip_hex[i:i+2], 16)) for i in (6,4,2,0))
            port = int(port_hex, 16)
            results.append({"ip": ip, "port": port, "raw": local_addr})
    except Exception as e:
        results.append({"error": str(e)})
    return results

def port_probe(host, port, timeout=2):
    """Quick TCP connect probe."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        s.connect((host, port))
        s.close()
        return True
    except:
        return False

# ===================================================================
# 3. OSINT ENGINE — Evidence-based, no guessing
# ===================================================================

OUTDIR = "/mnt/agents/output/huh-project/logs"
os.makedirs(OUTDIR, exist_ok=True)

# EXACT DATA FROM IMAGE — no guessing
EVIDENCE = {
    "product_name": "Doc's Notes",
    "brand": "Dr. Squatch",
    "collaboration": "One Piece",
    "product_type": "Cold Process Soap",
    "ingredients": [
        "Saponified Oils of (Certified Palm, Coconut, Olive)",
        "Naturally Derived Fragrance",
        "Shea Butter",
        "Devil's Claw Extract",
        "Iron Oxide",
        "Kaolin Clay",
        "Sea Salt",
    ],
    "features": ["Made from Natural Oils", "Dermatologist Tested", "Cold Process", "Recyclable Packaging"],
    "website": "DRSQUATCH.COM/NATURAL",
    "visual_elements": ["Monkey D. Luffy wanted poster", "Going Merry ship", "Barrel", "Gold coins", "Gemstones"],
}

async def deep_osint():
    results = {
        "meta": {
            "machine": "redwood",
            "mode": "YOLO",
            "introspection": self_introspect(),
            "ports": decode_proc_net_tcp(),
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        },
        "evidence": EVIDENCE,
        "phases": [],
    }

    # --- PHASE 1: Shopify API — Search by ingredients (evidence-based) ---
    print("\n" + "="*60)
    print("[PHASE 1] Shopify API — Evidence-based ingredient search")
    print("="*60)

    api_products = []
    for page_num in range(1, 10):
        url = f"https://drsquatch.com/products.json?limit=250&page={page_num}"
        try:
            r = requests.get(url, impersonate="chrome", timeout=20)
            data = r.json()
            prods = data.get("products", [])
            if not prods:
                break
            api_products.extend(prods)
        except Exception as e:
            break

    print(f"[OK] Total catalog: {len(api_products)} products")

    # Search by exact evidence — ingredients, name fragments
    ingredient_keywords = ["devil's claw", "kaolin clay", "shea butter", "sea salt", "iron oxide"]
    name_keywords = ["doc", "notes", "one piece", "luffy", "straw hat", "wanted"]

    evidence_matches = []
    for p in api_products:
        body = (p.get("body_html") or "").lower()
        title = (p.get("title") or "").lower()
        handle = (p.get("handle") or "").lower()
        tags = " ".join(p.get("tags") or []).lower()
        combined = f"{title} {handle} {tags} {body}"

        ing_score = sum(1 for kw in ingredient_keywords if kw in combined)
        name_score = sum(1 for kw in name_keywords if kw in combined)
        total_score = ing_score + name_score

        if total_score > 0:
            variants = p.get("variants", [])
            price = variants[0].get("price", "N/A") if variants else "N/A"
            evidence_matches.append({
                "title": p.get("title"),
                "handle": p.get("handle"),
                "price": price,
                "ingredient_score": ing_score,
                "name_score": name_score,
                "total_score": total_score,
                "available": any(v.get("available") for v in variants),
                "created_at": p.get("created_at"),
                "updated_at": p.get("updated_at"),
                "tags": p.get("tags", []),
                "body_snippet": (p.get("body_html") or "")[:300],
            })

    evidence_matches.sort(key=lambda x: (-x["total_score"], x.get("updated_at", "")))
    print(f"[OK] Evidence matches: {len(evidence_matches)}")
    for m in evidence_matches[:20]:
        status = "✓" if m["available"] else "✗"
        print(f"  {status} {m['title'][:40]:40s} | score:{m['total_score']} (ing:{m['ingredient_score']}+name:{m['name_score']}) | ${m['price']}")

    results["phases"].append({
        "name": "evidence_based_api",
        "total_products": len(api_products),
        "matches": evidence_matches,
    })

    # --- PHASE 2: nodriver — Render collection, extract ALL data ---
    print("\n" + "="*60)
    print("[PHASE 2] nodriver — Full rendered page extraction")
    print("="*60)

    browser = await uc.start(headless=True, browser_args=[
        "--no-sandbox", "--disable-gpu", "--disable-dev-shm-usage",
        "--disable-web-security", "--window-size=1920,1080"
    ])
    print("[OK] Browser started")

    page = await browser.get("https://drsquatch.com/collections/one-piece")
    await page.sleep(7)

    content = await page.get_content()
    print(f"[OK] Content: {len(content):,} bytes")

    # Extract ALL text
    body_text = await page.evaluate("document.body.innerText")
    all_lines = [l.strip() for l in body_text.split("\n") if l.strip() and len(l.strip()) > 2]

    # Search for evidence keywords in rendered text
    found_keywords = {}
    for kw in ["doc's notes", "doc", "notes", "one piece", "luffy", "shea butter", 
               "devil's claw", "kaolin clay", "cold process", "wanted"]:
        matches = [l for l in all_lines if kw in l.lower() and len(l) < 250]
        if matches:
            found_keywords[kw] = matches[:5]

    print(f"[OK] Keywords found in rendered text: {list(found_keywords.keys())}")
    for kw, lines in found_keywords.items():
        print(f"  '{kw}': {len(lines)} matches")
        for l in lines[:2]:
            print(f"    -> {l[:80]}")

    # Extract all product cards with full data
    product_cards = []

    # Try multiple selectors
    selectors = [
        'a[href*="/products/"]',
        '[data-product-handle]',
        '.product-card',
        '.product-item',
        '[class*="product"] a',
    ]

    for sel in selectors:
        try:
            elems = await page.query_selector_all(sel)
            for elem in elems[:30]:
                try:
                    href = await elem.get_attribute("href") or ""
                    text = (await elem.get_text() or "").strip()
                    handle = await elem.get_attribute("data-product-handle") or ""
                    if text and len(text) > 2:
                        product_cards.append({
                            "text": text[:100],
                            "href": href,
                            "handle": handle,
                            "selector": sel,
                        })
                except:
                    pass
        except:
            pass

    # Deduplicate
    seen = set()
    unique_cards = []
    for c in product_cards:
        key = c["href"] + "|" + c["text"]
        if key not in seen:
            seen.add(key)
            unique_cards.append(c)

    print(f"[OK] {len(unique_cards)} unique product cards")
    for c in unique_cards[:15]:
        print(f"  -> {c['text'][:50]:50s} | {c['href'][:40]:40s} | handle:{c['handle'][:20]}")

    # Screenshot
    ss_path = os.path.join(OUTDIR, "drsquatch-onepiece-full.png")
    await page.save_screenshot(ss_path)
    print(f"[OK] Screenshot: {ss_path}")

    # Scroll and re-extract
    await page.scroll_down(1500)
    await page.sleep(4)
    content2 = await page.get_content()
    print(f"[OK] Post-scroll: {len(content2):,} bytes")

    browser.stop()

    results["phases"].append({
        "name": "nodriver_full_extraction",
        "product_cards": unique_cards,
        "found_keywords": found_keywords,
        "screenshot": ss_path,
        "content_length": len(content),
        "post_scroll_length": len(content2),
    })

    # --- PHASE 3: Direct product handle verification ---
    print("\n" + "="*60)
    print("[PHASE 3] Handle verification — evidence-derived handles")
    print("="*60)

    # Derive handles from evidence, not guess
    derived_handles = [
        "docs-notes",                    # Direct from product name
        "doc-s-notes",                   # Shopify slug variant
        "doctors-notes",                 # Full word variant
        "doc-notes",                     # Short variant
        "docs-notes-one-piece",          # With collab
        "doc-s-notes-one-piece",         # Slug + collab
        "one-piece-docs-notes",          # Collab first
        "one-piece-soap",                # Generic collab
        "one-piece-bar-soap",            # Product type
        "luffy-soap",                    # Character
        "monkey-d-luffy",                # Full character
        "straw-hat-soap",                # Character element
        "wanted-poster-soap",            # Visual element
        "devil-fruit-soap",              # Visual element
        "going-merry-soap",              # Visual element
        "one-piece-collection",          # Collection name
        "one-piece-bundle",              # Bundle
        "one-piece-limited-edition",     # Limited
    ]

    verified = []
    for handle in derived_handles:
        url = f"https://drsquatch.com/products/{handle}.json"
        try:
            r = requests.get(url, impersonate="chrome", timeout=10)
            if r.status_code == 200:
                prod = r.json().get("product", {})
                print(f"  [HIT] {handle}: {prod.get('title', 'unknown')}")
                verified.append({
                    "handle": handle,
                    "title": prod.get("title"),
                    "price": prod.get("variants", [{}])[0].get("price"),
                    "available": any(v.get("available") for v in prod.get("variants", [])),
                })
            else:
                print(f"  [MISS] {handle}: HTTP {r.status_code}")
        except Exception as e:
            print(f"  [ERR] {handle}: {e}")

    results["phases"].append({
        "name": "handle_verification",
        "derived_from": "evidence",
        "verified": verified,
    })

    # --- PHASE 4: Dr. Squatch search functionality ---
    print("\n" + "="*60)
    print("[PHASE 4] Dr. Squatch site search — 'doc notes'")
    print("="*60)

    search_urls = [
        "https://drsquatch.com/search?q=doc+notes",
        "https://drsquatch.com/search?q=one+piece+soap",
        "https://drsquatch.com/search?q=doc%27s+notes",
        "https://drsquatch.com/search?q=luffy",
    ]

    search_results = []
    for url in search_urls:
        try:
            r = requests.get(url, impersonate="chrome", timeout=15)
            print(f"  [OK] {url.split('q=')[1]:20s} | Status: {r.status_code} | Length: {len(r.text)}")

            # Extract product results from search page
            products_found = re.findall(r'href=["\']([^"\']*/products/[^"\']+)["\']', r.text)
            products_found = list(dict.fromkeys(products_found))
            search_results.append({
                "query": url.split("q=")[1],
                "status": r.status_code,
                "product_links": products_found[:10],
            })
            for pl in products_found[:5]:
                print(f"    -> {pl}")
        except Exception as e:
            print(f"  [ERR] {url}: {e}")

    results["phases"].append({
        "name": "site_search",
        "results": search_results,
    })

    # --- PHASE 5: Sitemap / robots.txt ---
    print("\n" + "="*60)
    print("[PHASE 5] Sitemap extraction")
    print("="*60)

    sitemap_data = {}
    try:
        r = requests.get("https://drsquatch.com/robots.txt", impersonate="chrome", timeout=10)
        sitemap_data["robots"] = r.text[:500]
        sitemaps = re.findall(r'Sitemap:\s*(\S+)', r.text)
        print(f"[OK] Sitemaps found: {sitemaps}")

        for sm in sitemaps[:2]:
            try:
                r2 = requests.get(sm, impersonate="chrome", timeout=15)
                urls = re.findall(r'<loc>([^<]+)</loc>', r2.text)
                product_urls = [u for u in urls if '/products/' in u]
                print(f"[OK] {sm.split('/')[-1]}: {len(product_urls)} product URLs")

                # Search for doc/notes in sitemap
                doc_urls = [u for u in product_urls if 'doc' in u.lower() or 'note' in u.lower()]
                print(f"[OK] Doc/Note URLs in sitemap: {len(doc_urls)}")
                for u in doc_urls[:10]:
                    print(f"  -> {u}")

                sitemap_data[sm] = {
                    "total_urls": len(urls),
                    "product_urls": len(product_urls),
                    "doc_note_urls": doc_urls[:20],
                }
            except Exception as e:
                print(f"[ERR] Sitemap {sm}: {e}")
    except Exception as e:
        print(f"[ERR] robots.txt: {e}")

    results["phases"].append({
        "name": "sitemap_extraction",
        "data": sitemap_data,
    })

    # --- SAVE ---
    out_path = os.path.join(OUTDIR, "osint-deep-evidence.json")
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\n[OK] Deep OSINT saved: {out_path}")
    print(f"[OK] Phases: {len(results['phases'])}")

    return results

# Run with existing loop handling
if __name__ == "__main__":
    try:
        loop = asyncio.get_event_loop()
        if loop.is_running():
            import nest_asyncio
            nest_asyncio.apply()
            result = loop.run_until_complete(deep_osint())
        else:
            result = asyncio.run(deep_osint())
    except RuntimeError:
        result = asyncio.run(deep_osint())
