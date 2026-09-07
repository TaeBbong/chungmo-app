#!/usr/bin/env python3
"""Generate the hosted invitation fixtures and the eval dataset.

Every case is a fictional wedding rendered in the *technical* style of a
kind of Korean mobile-invitation vendor page: jQuery-era PHP/ASP markup
(UTF-8 and EUC-KR), table layouts, site-builder output, Next.js/Nuxt SSR
with embedded JSON, client-rendered SPA shells, semantic HTML with JSON-LD,
WordPress-like themes with guestbook distractors, image-only pages, iframe
embeds, short-link redirects, English invitations and no-date invitations.

The ground truth lives in this file once; the templates render it and the
same values become `eval/dataset.json`, so the expectations can never drift
from the pages.

Usage (from the repository root):

    python3 eval/generate_fixtures.py

Outputs:
    hosting/public/eval/<id>/...   the fixture pages and their assets
    hosting/public/eval/index.html a human-readable catalogue
    eval/dataset.json              expected values, tags and notes per case
    eval/hosting_rules.json        redirects/rewrites/headers merged into firebase.json
"""

from __future__ import annotations

import base64
import html
import json
import random
import shutil
from datetime import datetime, timedelta, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "hosting" / "public" / "eval"
BASE_URL = "https://chung-mo.web.app"
KST = timezone(timedelta(hours=9))

# ---------------------------------------------------------------------------
# Ground truth pools
# ---------------------------------------------------------------------------

SURNAMES = ["김", "이", "박", "최", "정", "강", "조", "윤", "장", "임", "한", "오",
            "서", "신", "권", "황", "안", "송", "전", "홍", "유", "고", "문", "양",
            "손", "배", "백", "허", "남", "심"]
GROOM_GIVEN = ["민준", "서준", "도윤", "예준", "시우", "하준", "주원", "지호", "지훈",
               "준서", "건우", "현우", "우진", "선우", "서진", "연우", "정우", "승현",
               "유찬", "승민", "재원", "태양", "동현", "성민", "영훈", "준혁", "진우",
               "상우", "명호", "경수", "재현", "민석", "성훈", "형준", "규민", "찬영",
               "태호", "원준", "지환", "수호"]
BRIDE_GIVEN = ["서연", "서윤", "지우", "서현", "하은", "하윤", "민서", "지유", "윤서",
               "채원", "수아", "지민", "지아", "다은", "은서", "예은", "수빈", "소율",
               "예린", "지원", "유진", "가은", "혜원", "나연", "보람", "세영", "현지",
               "미소", "주하", "아름", "다혜", "혜진", "지수", "유나", "소희", "민지",
               "예지", "수연", "가영", "하람"]
FATHER_GIVEN = ["영수", "성호", "재호", "종수", "병철", "상철", "정호", "동수", "기태",
                "철수", "명수", "광수", "진호", "경식", "석민", "태영", "형식", "용호",
                "승철", "인수"]
MOTHER_GIVEN = ["정희", "미경", "영숙", "순자", "경자", "명자", "선희", "은희", "미숙",
                "정자", "옥자", "영미", "혜숙", "미영", "경희", "숙희", "지영", "현숙",
                "은정", "명희"]

VENUES = [
    ("라온컨벤션", "3층 그랜드홀", "서울특별시 강남구 테헤란로 123", "02-555-0101"),
    ("메종드블랑", "2층 로즈홀", "서울특별시 서초구 반포대로 45", "02-534-0202"),
    ("더채플앳한강", "5층 채플홀", "서울특별시 영등포구 여의대로 88", "02-780-0303"),
    ("루체스타 웨딩홀", "6층 스텔라홀", "경기도 성남시 분당구 판교역로 210", "031-702-0404"),
    ("아펠가모 광화문", "4층 라포레홀", "서울특별시 종로구 종로1길 50", "02-730-0505"),
    ("그랜드힐 컨벤션", "3층 다이아몬드홀", "서울특별시 송파구 올림픽로 300", "02-410-0606"),
    ("노블레스 웨딩", "7층 노블홀", "부산광역시 해운대구 센텀중앙로 55", "051-740-0707"),
    ("빌라드지디 수서", "1층 가든홀", "서울특별시 강남구 광평로 281", "02-459-0808"),
    ("호텔 라비앙", "2층 크리스탈볼룸", "대구광역시 수성구 동대구로 111", "053-760-0909"),
    ("더컨벤션 목동", "8층 그레이스홀", "서울특별시 양천구 목동동로 233", "02-2643-1010"),
    ("스칼라티움 강남", "4층 아트홀", "서울특별시 강남구 논현로 508", "02-3452-1111"),
    ("W웨딩홀 대전", "3층 파티오홀", "대전광역시 유성구 대덕대로 512", "042-861-1212"),
    ("헤리움 아트홀", "5층 오페라홀", "인천광역시 연수구 센트럴로 194", "032-830-1313"),
    ("포레스트 가든", "야외 가든홀", "경기도 고양시 일산동구 호수로 596", "031-901-1414"),
    ("루미에르 웨딩", "2층 루미에르홀", "광주광역시 서구 상무중앙로 66", "062-383-1515"),
    ("엘리시안 컨벤션", "6층 사파이어홀", "경기도 수원시 영통구 광교중앙로 140", "031-215-1616"),
    ("더파티움 안양", "9층 파티움홀", "경기도 안양시 동안구 시민대로 180", "031-380-1717"),
    ("제주 오션블루 리조트", "1층 오션홀", "제주특별자치도 서귀포시 중문관광로 72", "064-735-1818"),
    ("세인트메리 성당", "대성전", "서울특별시 중구 명동길 74", "02-774-1919"),
    ("울산 로얄호텔", "3층 그랜드볼룸", "울산광역시 남구 삼산로 300", "052-256-2020"),
]

BANKS = ["국민은행", "신한은행", "우리은행", "하나은행", "농협은행", "기업은행",
         "카카오뱅크", "토스뱅크", "새마을금고", "우체국", "케이뱅크", "부산은행",
         "SC제일은행", "대구은행", "수협은행", "신협"]


def account_number(rng: random.Random, bank: str) -> str:
    """Bank-specific-looking account number shapes."""
    if bank == "카카오뱅크":
        return f"3333-{rng.randint(10, 99):02d}-{rng.randint(1000000, 9999999)}"
    if bank == "토스뱅크":
        return f"1000-{rng.randint(1000, 9999)}-{rng.randint(1000, 9999)}"
    if bank == "케이뱅크":
        return f"100-{rng.randint(100, 999)}-{rng.randint(100000, 999999)}"
    if bank == "우체국":
        return f"{rng.randint(10000, 99999)}-{rng.randint(10, 99):02d}-{rng.randint(100000, 999999)}"
    if bank == "농협은행":
        return f"{rng.randint(301, 356)}-{rng.randint(1000, 9999)}-{rng.randint(1000, 9999)}-{rng.randint(10, 99)}"
    if bank == "신한은행":
        return f"110-{rng.randint(100, 999)}-{rng.randint(100000, 999999)}"
    return f"{rng.randint(100000, 999999)}-{rng.randint(10, 99):02d}-{rng.randint(100000, 999999)}"


# ---------------------------------------------------------------------------
# Case table: id, template, options
# ---------------------------------------------------------------------------
# accounts: none | groom | bride | couple | parents | full | mixed
# date_style: see DATE_STYLES

CASES = [
    # jQuery-era PHP vendor (UTF-8)
    ("hanul-01", "classic-jquery", dict(date_style="kor_full", accounts="full", quirks=["calendar-grid", "inline-js-korean"])),
    ("hanul-02", "classic-jquery", dict(date_style="kor_dot", accounts="couple", quirks=["calendar-grid", "gallery-captions"])),
    ("hanul-03", "classic-jquery", dict(date_style="kor_hour", accounts="parents", quirks=["short-link"])),
    ("hanul-04", "classic-jquery", dict(date_style="kor_short_noyear", accounts="mixed", quirks=["no-year", "countdown"])),
    ("hanul-05", "classic-jquery", dict(date_style="none", accounts="couple", quirks=["no-date"])),
    # ASP-era EUC-KR pages
    ("euckr-01", "euckr-asp", dict(date_style="kor_full", accounts="full", quirks=["euc-kr", "font-tags"])),
    ("euckr-02", "euckr-asp", dict(date_style="kor_dot", accounts="groom", quirks=["euc-kr", "nbsp"])),
    # Pure table layout (UTF-8)
    ("table-01", "table-legacy", dict(date_style="kor_full", accounts="couple", quirks=["table-only"])),
    ("table-02", "table-legacy", dict(date_style="iso_dash", accounts="none", quirks=["table-only"])),
    # Next.js SSR with __NEXT_DATA__
    ("nextcard-01", "nextjs-ssr", dict(date_style="kor_full", accounts="full", quirks=["next-data", "css-modules"])),
    ("nextcard-02", "nextjs-ssr", dict(date_style="kor_dot", accounts="couple", quirks=["next-data", "css-modules", "extra-event-date"])),
    ("nextcard-03", "nextjs-ssr", dict(date_style="en_long", accounts="bride", quirks=["next-data", "css-modules"])),
    # Client-rendered SPA shell (only meta + empty root in the HTML)
    ("spa-01", "csr-shell", dict(date_style="kor_full", accounts="couple", quirks=["csr", "og-only"])),
    ("spa-02", "csr-shell", dict(date_style="kor_dot", accounts="full", quirks=["csr", "og-only"])),
    ("spa-03", "csr-shell", dict(date_style="kor_hour", accounts="none", quirks=["csr", "og-only"])),
    # Nuxt SSR with window.__NUXT__
    ("nuxtcard-01", "nuxt-ssr", dict(date_style="kor_slash", accounts="parents", quirks=["nuxt-data", "scoped-attrs"])),
    ("nuxtcard-02", "nuxt-ssr", dict(date_style="kor_full", accounts="couple", quirks=["nuxt-data", "scoped-attrs"])),
    # Site-builder output (deep nesting, inline styles, span-split text, lazy images)
    ("builder-01", "site-builder", dict(date_style="kor_full", accounts="full", quirks=["lazy-src", "span-split", "inline-styles"])),
    ("builder-02", "site-builder", dict(date_style="kor_year2", accounts="couple", quirks=["lazy-src", "span-split"])),
    ("builder-03", "site-builder", dict(date_style="kor_dot", accounts="none", quirks=["lazy-src", "span-split"])),
    # Tailwind + semantic HTML + JSON-LD
    ("tw-01", "tailwind-semantic", dict(date_style="kor_full", accounts="full", quirks=["json-ld", "details-accordion", "picture-srcset", "kakaopay"])),
    ("tw-02", "tailwind-semantic", dict(date_style="iso_dash", accounts="couple", quirks=["json-ld", "details-accordion"])),
    ("tw-03", "tailwind-semantic", dict(date_style="none", accounts="parents", quirks=["no-date", "json-ld"])),
    # styled-components React SSR
    ("sc-01", "styled-react", dict(date_style="split_numerals", accounts="couple", quirks=["sc-classes", "split-numerals"])),
    ("sc-02", "styled-react", dict(date_style="kor_full", accounts="full", quirks=["sc-classes", "split-numerals"])),
    # WordPress-like theme with a guestbook
    ("wp-01", "wordpress-theme", dict(date_style="kor_full", accounts="couple", quirks=["guestbook-distractors", "time-element"])),
    ("wp-02", "wordpress-theme", dict(date_style="kor_dot", accounts="parents", quirks=["guestbook-distractors", "time-element"])),
    # Bootstrap 4 + jQuery, accounts in a modal
    ("bs-01", "bootstrap-2019", dict(date_style="kor_full", accounts="full", quirks=["modal-accounts", "map-iframe", "reception-distractor"])),
    ("bs-02", "bootstrap-2019", dict(date_style="kor_hour", accounts="couple", quirks=["modal-accounts", "map-iframe"])),
    ("bs-03", "bootstrap-2019", dict(date_style="kor_short_noyear", accounts="groom", quirks=["modal-accounts", "no-year", "rewrite-url"])),
    # Outer shell + iframe content
    ("frame-01", "iframe-embed", dict(date_style="kor_full", accounts="couple", quirks=["iframe"])),
    ("frame-02", "iframe-embed", dict(date_style="kor_dot", accounts="none", quirks=["iframe"])),
    # Image-only invitations
    ("img-01", "image-only", dict(date_style="kor_full", accounts="couple", quirks=["image-only"])),
    ("img-02", "image-only", dict(date_style="kor_dot", accounts="none", quirks=["image-only"])),
    # Messenger-style share card, accounts in hidden DOM
    ("kakao-01", "kakao-card", dict(date_style="kor_full", accounts="full", quirks=["hidden-accounts", "data-attrs"])),
    ("kakao-02", "kakao-card", dict(date_style="kor_dot", accounts="couple", quirks=["hidden-accounts", "short-link"])),
    ("kakao-03", "kakao-card", dict(date_style="kor_hour", accounts="none", quirks=["hidden-accounts"])),
    # English invitations
    ("intl-01", "english-intl", dict(date_style="en_long", accounts="none", quirks=["english"])),
    ("intl-02", "english-intl", dict(date_style="en_long", accounts="couple", quirks=["english", "mixed-language"])),
    # Self-made Notion-export page
    ("self-01", "notion-export", dict(date_style="kor_full", accounts="couple", quirks=["self-made", "emoji-headings"])),
]

TEMPLATE_VENDOR = {
    "classic-jquery": "하늘카드",
    "euckr-asp": "예그린카드",
    "table-legacy": "행복한청첩장",
    "nextjs-ssr": "넥스트카드",
    "csr-shell": "모먼트",
    "nuxt-ssr": "다봄",
    "site-builder": "메이커스",
    "tailwind-semantic": "온카드",
    "styled-react": "블룸",
    "wordpress-theme": "우리결혼",
    "bootstrap-2019": "라온초대장",
    "iframe-embed": "디어카드",
    "image-only": "포토청첩장",
    "kakao-card": "톡초대",
    "english-intl": "Ever After",
    "notion-export": "셀프제작",
}

# The crawler-facing expectation of each quirk, used for tagging only.
HARD_QUIRKS = {"csr", "iframe", "image-only", "euc-kr", "table-only"}

# ---------------------------------------------------------------------------
# Date rendering
# ---------------------------------------------------------------------------

KOR_WEEKDAY = ["월요일", "화요일", "수요일", "목요일", "금요일", "토요일", "일요일"]
KOR_WEEKDAY_SHORT = ["월", "화", "수", "목", "금", "토", "일"]
EN_WEEKDAY = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
EN_MONTH = ["January", "February", "March", "April", "May", "June", "July", "August",
            "September", "October", "November", "December"]


def kor_time(dt: datetime) -> str:
    h, m = dt.hour, dt.minute
    if h == 12 and m == 0:
        return "낮 12시"
    if h < 12:
        base = f"오전 {h}시"
    elif h == 12:
        base = "오후 12시"
    else:
        base = f"오후 {h - 12}시"
    if m == 30:
        return base + " 30분"
    if m:
        return base + f" {m}분"
    return base


DATE_STYLES = {
    "kor_full": lambda dt: f"{dt.year}년 {dt.month}월 {dt.day}일 {KOR_WEEKDAY[dt.weekday()]} {kor_time(dt)}",
    "kor_dot": lambda dt: f"{dt.year}.{dt.month:02d}.{dt.day:02d} ({KOR_WEEKDAY_SHORT[dt.weekday()]}) {dt.hour:02d}:{dt.minute:02d}",
    "kor_hour": lambda dt: f"{dt.year}년 {dt.month}월 {dt.day}일 {KOR_WEEKDAY[dt.weekday()]} {kor_time(dt)}",
    "kor_short_noyear": lambda dt: f"{dt.month}월 {dt.day}일 {KOR_WEEKDAY[dt.weekday()]} {kor_time(dt)}",
    "iso_dash": lambda dt: f"{dt.year}-{dt.month:02d}-{dt.day:02d} {dt.hour:02d}:{dt.minute:02d}",
    "en_long": lambda dt: f"{EN_WEEKDAY[dt.weekday()]}, {EN_MONTH[dt.month - 1]} {dt.day}, {dt.year} at {dt.strftime('%-I:%M %p')}",
    "kor_slash": lambda dt: f"{dt.year}/{dt.month:02d}/{dt.day:02d} {KOR_WEEKDAY[dt.weekday()]} {dt.hour}시 {dt.minute:02d}분",
    "kor_year2": lambda dt: f"{dt.year % 100:02d}.{dt.month:02d}.{dt.day:02d} {EN_WEEKDAY[dt.weekday()][:3].upper()} {dt.strftime('%p %-I:%M')}",
    "split_numerals": lambda dt: f"{dt.year} / {dt.month:02d} / {dt.day:02d}",
    "none": lambda dt: "",
}

# Wedding dates: weekends (plus one holiday weekday) from late 2026 through
# mid 2027, so the fixtures stay in the future for a while and never expire.
TIMES = [(11, 0), (11, 30), (12, 0), (12, 30), (13, 0), (13, 30), (14, 0),
         (15, 0), (16, 0), (17, 30), (18, 0), (12, 30), (13, 30), (11, 0)]


def wedding_dates(n: int, rng: random.Random) -> list[datetime]:
    start = datetime(2026, 10, 3, tzinfo=KST)
    weekend_days = []
    d = start
    while len(weekend_days) < 80:
        if d.weekday() in (5, 6):
            weekend_days.append(d)
        d += timedelta(days=1)
    rng.shuffle(weekend_days)
    picked = sorted(weekend_days[: n - 1])
    picked.append(datetime(2026, 10, 9, tzinfo=KST))  # 한글날, a Friday
    out = []
    for i, day in enumerate(picked):
        h, m = TIMES[i % len(TIMES)]
        out.append(day.replace(hour=h, minute=m))
    return out


# ---------------------------------------------------------------------------
# Case model
# ---------------------------------------------------------------------------


def build_cases() -> list[dict]:
    rng = random.Random(20261017)
    dates = wedding_dates(len(CASES), rng)
    venues = VENUES[:]
    rng.shuffle(venues)
    groom_given = GROOM_GIVEN[:]
    bride_given = BRIDE_GIVEN[:]
    rng.shuffle(groom_given)
    rng.shuffle(bride_given)
    cases = []
    for i, (cid, template, opts) in enumerate(CASES):
        g_sur, b_sur = rng.sample(SURNAMES, 2)
        groom = {
            "name": g_sur + groom_given[i],
            "father": g_sur + rng.choice(FATHER_GIVEN),
            "mother": rng.choice(SURNAMES) + rng.choice(MOTHER_GIVEN),
            "order": rng.choice(["장남", "차남", "아들", "장남"]),
        }
        bride = {
            "name": b_sur + bride_given[i],
            "father": b_sur + rng.choice(FATHER_GIVEN),
            "mother": rng.choice(SURNAMES) + rng.choice(MOTHER_GIVEN),
            "order": rng.choice(["장녀", "차녀", "딸", "장녀"]),
        }
        venue_name, hall, address, tel = venues[i % len(venues)]
        accounts = make_accounts(rng, opts["accounts"], groom, bride)
        has_date = opts["date_style"] != "none"
        cases.append({
            "id": cid,
            "template": template,
            "vendor": TEMPLATE_VENDOR[template],
            "groom": groom,
            "bride": bride,
            "dt": dates[i] if has_date else None,
            "date_style": opts["date_style"],
            "venue": {"name": venue_name, "hall": hall, "address": address, "tel": tel},
            "accounts": accounts,
            "quirks": opts["quirks"],
            "seq": i,
        })
    return cases


def make_accounts(rng: random.Random, mode: str, groom: dict, bride: dict) -> dict:
    def acc(holder, relation):
        bank = rng.choice(BANKS)
        return {"bank": bank, "number": account_number(rng, bank), "holder": holder, "relation": relation}

    g, b = [], []
    if mode in ("groom", "couple", "full", "mixed"):
        g.append(acc(groom["name"], "신랑"))
    if mode in ("bride", "couple", "full"):
        b.append(acc(bride["name"], "신부"))
    if mode in ("parents", "full"):
        g.append(acc(groom["father"], "아버지"))
        g.append(acc(groom["mother"], "어머니"))
        b.append(acc(bride["father"], "아버지"))
        b.append(acc(bride["mother"], "어머니"))
    if mode == "mixed":
        b.append(acc(bride["mother"], "어머니"))
    return {"groom": g, "bride": b}


# ---------------------------------------------------------------------------
# Helpers shared by templates
# ---------------------------------------------------------------------------


def e(s: str) -> str:
    return html.escape(s, quote=True)


def date_text(c: dict) -> str:
    if not c["dt"]:
        return ""
    return DATE_STYLES[c["date_style"]](c["dt"])


def url_of(c: dict) -> str:
    return f"{BASE_URL}/eval/{c['id']}/"


def og_meta(c: dict, title: str | None = None, description: str | None = None, image: str = "main.svg") -> str:
    title = title or f"{c['groom']['name']} ♥ {c['bride']['name']} 결혼합니다"
    if description is None:
        description = f"{date_text(c)} {c['venue']['name']} {c['venue']['hall']}".strip()
    return "\n".join([
        f'<meta property="og:title" content="{e(title)}">',
        f'<meta property="og:description" content="{e(description)}">',
        f'<meta property="og:image" content="{url_of(c)}{image}">',
        f'<meta property="og:url" content="{url_of(c)}">',
        '<meta property="og:type" content="website">',
    ])


def calendar_grid(dt: datetime, cell_tag: str = "div", cls: str = "day") -> str:
    """A month grid: every day number is a distractor for the model."""
    first = dt.replace(day=1)
    days = (first.replace(month=first.month % 12 + 1, year=first.year + (first.month == 12)) - first).days
    cells = [f'<{cell_tag} class="{cls} empty"></{cell_tag}>'] * ((first.weekday() + 1) % 7)
    for d in range(1, days + 1):
        mark = " today" if d == dt.day else ""
        cells.append(f'<{cell_tag} class="{cls}{mark}">{d}</{cell_tag}>')
    return "".join(cells)


def account_lines(accs: list[dict], fmt: str) -> list[str]:
    out = []
    for a in accs:
        bank_short = a["bank"].replace("은행", "")
        if fmt == "classic":
            out.append(f'{a["bank"]} {a["number"]} (예금주: {a["holder"]})')
        elif fmt == "short":
            out.append(f'{bank_short} {a["number"]} {a["holder"]}')
        elif fmt == "pipe":
            out.append(f'{a["bank"]} | {a["number"]} | {a["holder"]}')
        elif fmt == "nohyphen":
            out.append(f'{a["bank"]} {a["number"].replace("-", "")} 예금주 {a["holder"]}')
        elif fmt == "relation":
            rel = {"신랑": "신랑", "신부": "신부", "아버지": "아버지", "어머니": "어머니"}[a["relation"]]
            out.append(f'{rel} {a["holder"]} · {a["bank"]} {a["number"]}')
        else:
            out.append(f'{a["bank"]} {a["number"]} {a["holder"]}')
    return out


def photo_svg(c: dict, label: str, w: int = 720, h: int = 960, seed: int = 0) -> str:
    rng = random.Random(c["seq"] * 31 + seed)
    hue = rng.randint(0, 360)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
<stop offset="0" stop-color="hsl({hue},45%,78%)"/><stop offset="1" stop-color="hsl({(hue + 60) % 360},40%,55%)"/></linearGradient></defs>
<rect width="{w}" height="{h}" fill="url(#g)"/>
<circle cx="{w * 0.38:.0f}" cy="{h * 0.42:.0f}" r="{w * 0.12:.0f}" fill="rgba(255,255,255,0.55)"/>
<circle cx="{w * 0.62:.0f}" cy="{h * 0.42:.0f}" r="{w * 0.12:.0f}" fill="rgba(255,255,255,0.55)"/>
<text x="50%" y="{h * 0.72:.0f}" text-anchor="middle" font-family="sans-serif" font-size="{w * 0.06:.0f}" fill="#fff">{e(label)}</text>
</svg>
'''


def text_svg(lines: list[str], w: int = 720) -> str:
    """An image whose *content* is text — what image-only vendors ship."""
    lh = 44
    h = 80 + lh * len(lines)
    body = "".join(
        f'<text x="50%" y="{60 + i * lh}" text-anchor="middle" font-family="serif" font-size="{26 if i else 34}" fill="#333">{e(t)}</text>'
        for i, t in enumerate(lines))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><rect width="{w}" height="{h}" fill="#fbf7f2"/>{body}</svg>\n'


ROMANIZE = {"김": "Kim", "이": "Lee", "박": "Park", "최": "Choi", "정": "Jung", "강": "Kang", "조": "Cho", "윤": "Yoon", "장": "Jang", "임": "Lim", "한": "Han", "오": "Oh", "서": "Seo", "신": "Shin", "권": "Kwon", "황": "Hwang", "안": "Ahn", "송": "Song", "전": "Jeon", "홍": "Hong", "유": "Yoo", "고": "Ko", "문": "Moon", "양": "Yang", "손": "Son", "배": "Bae", "백": "Baek", "허": "Heo", "남": "Nam", "심": "Shim"}
GIVEN_ROMAN = {"민준": "Minjun", "서준": "Seojun", "도윤": "Doyun", "예준": "Yejun", "시우": "Siwoo", "하준": "Hajun", "주원": "Juwon", "지호": "Jiho", "지훈": "Jihoon", "준서": "Junseo", "건우": "Gunwoo", "현우": "Hyunwoo", "우진": "Woojin", "선우": "Sunwoo", "서진": "Seojin", "연우": "Yeonwoo", "정우": "Jungwoo", "승현": "Seunghyun", "유찬": "Yuchan", "승민": "Seungmin", "재원": "Jaewon", "태양": "Taeyang", "동현": "Donghyun", "성민": "Sungmin", "영훈": "Younghoon", "준혁": "Junhyuk", "진우": "Jinwoo", "상우": "Sangwoo", "명호": "Myungho", "경수": "Kyungsoo", "재현": "Jaehyun", "민석": "Minseok", "성훈": "Sunghoon", "형준": "Hyungjun", "규민": "Kyumin", "찬영": "Chanyoung", "태호": "Taeho", "원준": "Wonjun", "지환": "Jihwan", "수호": "Suho",
               "서연": "Seoyeon", "서윤": "Seoyun", "지우": "Jiwoo", "서현": "Seohyun", "하은": "Haeun", "하윤": "Hayun", "민서": "Minseo", "지유": "Jiyu", "윤서": "Yunseo", "채원": "Chaewon", "수아": "Sua", "지민": "Jimin", "지아": "Jia", "다은": "Daeun", "은서": "Eunseo", "예은": "Yeeun", "수빈": "Subin", "소율": "Soyul", "예린": "Yerin", "지원": "Jiwon", "유진": "Yujin", "가은": "Gaeun", "혜원": "Hyewon", "나연": "Nayeon", "보람": "Boram", "세영": "Seyoung", "현지": "Hyunji", "미소": "Miso", "주하": "Juha", "아름": "Areum", "다혜": "Dahye", "혜진": "Hyejin", "지수": "Jisoo", "유나": "Yuna", "소희": "Sohee", "민지": "Minji", "예지": "Yeji", "수연": "Suyeon", "가영": "Gayoung", "하람": "Haram"}


def romanized(name: str) -> str:
    """'김민준' -> 'Minjun Kim', the form English invitations print."""
    return f"{GIVEN_ROMAN.get(name[1:], name[1:])} {ROMANIZE.get(name[0], name[0])}"


def parents_line(side: dict, child_label: str) -> str:
    return f'{side["father"]} · {side["mother"]}의 {side["order"]} {side["name"][1:]}'


GA_SNIPPET = '''<script async src="https://www.googletagmanager.com/gtag/js?id=G-EVALFIXTURE"></script>
<script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag('js',new Date());gtag('config','G-EVALFIXTURE');</script>'''

LAZY_PIXEL = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"


# ---------------------------------------------------------------------------
# Templates: each returns {relative path: str | bytes}
# ---------------------------------------------------------------------------


def t_classic_jquery(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    quirks = c["quirks"]
    cal = f'<div class="calendar"><div class="cal_head">{c["dt"].year}년 {c["dt"].month}월</div><div class="cal_body">{calendar_grid(c["dt"])}</div></div>' if c["dt"] and "calendar-grid" in quirks else ""
    countdown = f'<div class="dday"><span id="dday_num">D-41</span> <span>{g["name"][1:]} ♥ {b["name"][1:]}의 결혼식이 41일 남았습니다</span></div>' if "countdown" in quirks else ""
    date_block = f'<p class="date_txt">{e(dtxt)}</p>' if dtxt else '<p class="date_txt">예식 일정은 추후 안내드리겠습니다</p>'
    gallery = "".join(f'<li><img src="../_assets/gallery-{k}.svg" alt=""><span class="cap">{cap}</span></li>' for k, cap in zip((1, 2, 3), ("2024.05.12 첫 여행", "2025.08.03 프러포즈", "2026.02.14 촬영"))) if "gallery-captions" in quirks else "".join(f'<li><img src="../_assets/gallery-{k}.svg" alt=""></li>' for k in (1, 2, 3))
    acc_html = ""
    if c["accounts"]["groom"] or c["accounts"]["bride"]:
        acc_html = '<div class="section account_sec"><h3 class="tit">마음 전하실 곳</h3>'
        for side, label in (("groom", "신랑측"), ("bride", "신부측")):
            if c["accounts"][side]:
                acc_html += f'<div class="acc_box"><p class="acc_side">{label}</p><ul>' + "".join(f'<li>{e(l)} <button type="button" onclick="copyAcc(\'{a["number"]}\')">복사</button></li>' for l, a in zip(account_lines(c["accounts"][side], "classic"), c["accounts"][side])) + '</ul></div>'
        acc_html += "</div>"
    js_korean = '''<script>
function copyAcc(n){var t=document.createElement('textarea');t.value=n;document.body.appendChild(t);t.select();document.execCommand('copy');document.body.removeChild(t);alert('계좌번호가 복사되었습니다.');}
function shareKakao(){alert('카카오톡 공유는 모바일에서만 가능합니다.');}
$(function(){$('.gallery_list').slick({dots:true,arrows:false});$('.acc_side').on('click',function(){$(this).next('ul').slideToggle();});});
</script>''' if "inline-js-korean" in quirks else "<script>$(function(){$('.gallery_list').slick({dots:true});});</script>"
    page = f'''<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<title>{e(g["name"])} ♥ {e(b["name"])} 모바일 청첩장 - {e(c["vendor"])}</title>
{og_meta(c)}
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/slick-carousel/1.8.1/slick.min.css">
<link rel="stylesheet" href="./style.css">
<script src="https://code.jquery.com/jquery-1.12.4.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/slick-carousel/1.8.1/slick.min.js"></script>
{GA_SNIPPET}
</head>
<body>
<div id="wrap">
  <div class="section main_sec">
    <p class="top_txt">WEDDING INVITATION</p>
    <img src="./main.svg" class="main_img" alt="">
    <p class="names">{e(g["name"])} <span class="heart">♥</span> {e(b["name"])}</p>
    {date_block}
    <p class="place_txt">{e(v["name"])} {e(v["hall"])}</p>
  </div>
  <div class="section invite_sec">
    <h3 class="tit">초대합니다</h3>
    <p class="invite_txt">서로가 마주보며 다져온 사랑을<br>이제 함께 한 곳을 바라보며 걸어갈 수 있는<br>큰 사랑으로 키우고자 합니다.<br>저희 두 사람이 사랑의 이름으로 지켜나갈 수 있게<br>앞날을 축복해 주시면 감사하겠습니다.</p>
    <p class="parents">{e(parents_line(g, "아들"))}<br>{e(parents_line(b, "딸"))}</p>
    <div class="contact"><a href="tel:010-0000-{1000 + c["seq"]:04d}" class="btn_call">신랑에게 연락하기</a><a href="tel:010-0000-{2000 + c["seq"]:04d}" class="btn_call">신부에게 연락하기</a></div>
  </div>
  {countdown}
  {cal}
  <div class="section gallery_sec">
    <h3 class="tit">갤러리</h3>
    <ul class="gallery_list">{gallery}</ul>
  </div>
  <div class="section location_sec">
    <h3 class="tit">오시는 길</h3>
    <p class="place_name">{e(v["name"])} {e(v["hall"])}</p>
    <p class="addr">{e(v["address"])}</p>
    <p class="tel">Tel. {e(v["tel"])}</p>
    <div id="map" style="width:100%;height:240px;background:#eee"></div>
    <div class="map_btns"><a href="https://map.kakao.com/link/search/{e(v["name"])}" target="_blank">카카오맵</a><a href="https://map.naver.com/v5/search/{e(v["name"])}" target="_blank">네이버지도</a><a href="tmap://search?name={e(v["name"])}">티맵</a></div>
    <p class="guide">지하철: 2호선 역삼역 3번 출구 도보 5분<br>버스: 146, 341, 360 (테헤란로 정류장 하차)<br>주차: 건물 지하 주차장 2시간 무료</p>
  </div>
  {acc_html}
  <div class="section share_sec">
    <a href="javascript:shareKakao()" class="btn_share">카카오톡으로 공유하기</a>
    <a href="javascript:copyUrl()" class="btn_share">청첩장 주소 복사하기</a>
  </div>
  <div class="footer">Copyright © {e(c["vendor"])}. All rights reserved.</div>
</div>
{js_korean}
</body>
</html>
'''
    css = '''body{margin:0;font-family:"Nanum Myeongjo",serif;color:#333;background:#fff}#wrap{max-width:480px;margin:0 auto}.section{padding:40px 20px;text-align:center}.tit{font-size:14px;letter-spacing:4px;color:#b58a6c}.main_img{width:100%}.names{font-size:24px}.heart{color:#e86}.calendar{padding:0 20px 30px}.cal_body{display:grid;grid-template-columns:repeat(7,1fr);gap:4px}.day{padding:8px 0}.day.today{background:#e86;color:#fff;border-radius:50%}.acc_box ul{list-style:none;padding:0}.footer{font-size:11px;color:#999;padding:20px}'''
    return {"index.html": page, "style.css": css, "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_euckr_asp(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    nb = "&nbsp;&nbsp;" if "nbsp" in c["quirks"] else " "
    acc_rows = ""
    for side, label in (("groom", "신랑측 계좌"), ("bride", "신부측 계좌")):
        for l in account_lines(c["accounts"][side], "short"):
            acc_rows += f'<div class="acc"><font size="2"><b>{label}</b>{nb}{e(l)}</font></div>'
    page = f'''<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=euc-kr">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(g["name"])}♥{e(b["name"])} 결혼합니다</title>
<meta property="og:title" content="{e(g["name"])}♥{e(b["name"])} 결혼합니다">
<meta property="og:image" content="{url_of(c)}main.jpg.svg">
<script language="javascript" src="/js/common.js"></script>
<style type="text/css">
body{{margin:0;font-family:굴림,Gulim,sans-serif;font-size:13px}}
#Wrapper{{width:100%;max-width:420px;margin:0 auto}}
.tit{{color:#c0392b;font-weight:bold;padding:20px 0 10px}}
.acc{{padding:4px 0}}
</style>
</head>
<body bgcolor="#ffffff" leftmargin="0" topmargin="0">
<div id="Wrapper">
<div align="center"><img src="./main.jpg.svg" width="100%" border="0"></div>
<div align="center" class="tit"><font size="4" color="#c0392b">{e(g["name"])}{nb}♥{nb}{e(b["name"])}</font></div>
<div align="center"><font size="2">{e(dtxt)}<br>{e(v["name"])}{nb}{e(v["hall"])}</font></div>
<div class="tit" align="center"><font size="3">초 대 합 니 다</font></div>
<div align="center"><font size="2" color="#555">두 사람이 사랑으로 하나 되어<br>새로운 가정을 이루려 합니다.<br>바쁘시더라도 오셔서 축복해 주시면<br>더없는 기쁨으로 간직하겠습니다.</font></div>
<div align="center" style="padding-top:12px"><font size="2">{e(g["father"])}{nb}·{nb}{e(g["mother"])}의 {e(g["order"])}{nb}{e(g["name"][1:])}<br>{e(b["father"])}{nb}·{nb}{e(b["mother"])}의 {e(b["order"])}{nb}{e(b["name"][1:])}</font></div>
<div class="tit" align="center"><font size="3">오시는 길</font></div>
<div align="center"><font size="2"><b>{e(v["name"])}{nb}{e(v["hall"])}</b><br>{e(v["address"])}<br>TEL. {e(v["tel"])}</font></div>
<div align="center" style="padding:8px 0"><a href="http://map.daum.net/?q={e(v["name"])}"><font size="2">다음지도 보기</font></a>{nb}|{nb}<a href="http://map.naver.com/?query={e(v["name"])}"><font size="2">네이버지도 보기</font></a></div>
<div class="tit" align="center"><font size="3">마음 전하실 곳</font></div>
<div align="center">{acc_rows or '<font size="2">화환은 정중히 사양합니다.</font>'}</div>
<div align="center" style="padding:30px 0 10px"><font size="1" color="#999">Copyright(c) {e(c["vendor"])} All rights reserved.</font></div>
</div>
</body>
</html>
'''
    return {"index.html": page.encode("euc-kr"), "main.jpg.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_table_legacy(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    acc = ""
    for side, label in (("groom", "신랑측"), ("bride", "신부측")):
        for a in c["accounts"][side]:
            acc += f'<tr><td class="lb">{label}</td><td>{e(a["bank"])}</td><td>{e(a["number"])}</td><td>{e(a["holder"])}</td></tr>'
    acc_table = f'<table class="acc" width="100%" cellpadding="6" cellspacing="0"><tr><th colspan="4">축의금 계좌 안내</th></tr>{acc}</table>' if acc else ""
    page = f'''<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>{e(g["name"])} · {e(b["name"])} 결혼식에 초대합니다</title>
{og_meta(c)}
<style type="text/css">
body {{ margin:0; background:#f5efe6; font-family:"Nanum Gothic",sans-serif; font-size:14px; color:#444; }}
table.card {{ width:100%; max-width:440px; margin:0 auto; background:#fff; border-collapse:collapse; }}
td.center {{ text-align:center; padding:14px 18px; }}
td.lb {{ color:#999; }}
th {{ background:#eee; font-weight:normal; padding:8px; }}
</style>
</head>
<body>
<table class="card" cellpadding="0" cellspacing="0">
  <tr><td class="center"><img src="./main.svg" width="100%" alt="" /></td></tr>
  <tr><td class="center" style="font-size:22px;letter-spacing:2px">{e(g["name"])} &amp; {e(b["name"])}</td></tr>
  <tr><td class="center">{e(dtxt) if dtxt else "예식 일정은 개별 연락드립니다"}</td></tr>
  <tr><td class="center"><b>{e(v["name"])}</b> {e(v["hall"])}</td></tr>
  <tr><td class="center" style="line-height:1.9">저희 두 사람의 작은 만남이<br />사랑의 결실을 이루어<br />소중한 결혼식을 올리게 되었습니다.<br />평생 서로 귀하게 여기며 첫 마음 그대로<br />존중하고 배려하며 살겠습니다.</td></tr>
  <tr><td class="center">
    <table width="100%" cellpadding="4"><tr><td class="lb" width="40%" align="right">신랑측 혼주</td><td>{e(g["father"])} · {e(g["mother"])}</td></tr><tr><td class="lb" align="right">신부측 혼주</td><td>{e(b["father"])} · {e(b["mother"])}</td></tr></table>
  </td></tr>
  <tr><td class="center"><table width="100%" cellpadding="4"><tr><th colspan="2">오시는 길</th></tr><tr><td class="lb" width="30%">예식장</td><td>{e(v["name"])} {e(v["hall"])}</td></tr><tr><td class="lb">주소</td><td>{e(v["address"])}</td></tr><tr><td class="lb">전화</td><td>{e(v["tel"])}</td></tr><tr><td class="lb">교통</td><td>지하철 2호선 · 버스 145, 360</td></tr></table></td></tr>
  <tr><td class="center">{acc_table}</td></tr>
  <tr><td class="center"><a href="https://map.kakao.com/link/search/{e(v["name"])}"><img src="../_assets/btn-map.svg" width="120" alt="" /></a></td></tr>
  <tr><td class="center" style="font-size:11px;color:#aaa">{e(c["vendor"])} 모바일청첩장</td></tr>
</table>
</body>
</html>
'''
    return {"index.html": page, "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_nextjs_ssr(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    quirks = c["quirks"]
    props = {
        "props": {"pageProps": {"invitation": {
            "id": c["id"], "groom": {"name": g["name"], "father": g["father"], "mother": g["mother"]},
            "bride": {"name": b["name"], "father": b["father"], "mother": b["mother"]},
            "date": c["dt"].isoformat() if c["dt"] else None,
            "venue": {"name": v["name"], "hall": v["hall"], "address": v["address"], "tel": v["tel"], "lat": 37.5, "lng": 127.03},
            "accounts": [dict(a, side="groom") for a in c["accounts"]["groom"]] + [dict(a, side="bride") for a in c["accounts"]["bride"]],
            "theme": "minimal", "bgm": "/static/bgm/03.mp3",
        }}, "__N_SSG": True},
        "page": "/card/[id]", "query": {"id": c["id"]}, "buildId": "x9Kd2pQ1sT0v", "isFallback": False, "gsp": True,
    }
    extra = f'<section class="Section_wrap__1kZ2a"><h2 class="Section_title__c9Jd3">청첩장 모임</h2><p class="Section_body__aQ8x2">결혼식 한 달 전, {(c["dt"] - timedelta(days=28)).strftime("%m월 %d일")} 저녁 7시 신촌에서 청첩장 모임을 가집니다. 편하게 와주세요!</p></section>' if "extra-event-date" in quirks and c["dt"] else ""
    accs = ""
    for side, label in (("groom", "신랑측"), ("bride", "신부측")):
        if c["accounts"][side]:
            accs += f'<div class="Account_group__Zk3d1"><p class="Account_side__9fL0p">{label}</p>' + "".join(
                f'<div class="Account_row__T2bqa"><span class="Account_bank__u1Pd0">{e(a["bank"])}</span><span class="Account_number__M4nqz">{e(a["number"])}</span><span class="Account_holder__Rr7cy">{e(a["holder"])}</span><button class="Account_copy__d3Wq1" data-clipboard-text="{e(a["number"])}">복사</button></div>'
                for a in c["accounts"][side]) + "</div>"
    page = f'''<!DOCTYPE html><html lang="ko"><head><meta charSet="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/><title>{e(g["name"])} ♥ {e(b["name"])} | {e(c["vendor"])}</title>{og_meta(c)}<meta name="next-head-count" content="8"/><link rel="preload" href="/_next/static/css/2f1a9b6c.css" as="style"/><link rel="stylesheet" href="./styles.css"/><noscript data-n-css=""></noscript><script defer="" nomodule="" src="/_next/static/chunks/polyfills-c67a75d1b6f99dc8.js"></script><script src="/_next/static/chunks/webpack-8fa1640cc84ba8fe.js" defer=""></script><script src="/_next/static/chunks/main-0ecb2f5a7f9d3f2c.js" defer=""></script><script src="/_next/static/chunks/pages/_app-3b0c2e4f7d1a9c8e.js" defer=""></script></head>
<body><div id="__next"><main class="Card_main__x9Fh2">
<header class="Hero_hero__7gT1k"><p class="Hero_eyebrow__Kd2m1">We're getting married</p><img alt="" src="./main.svg" class="Hero_image__p0Wz3" decoding="async"/><h1 class="Hero_names__r4Bn8">{e(g["name"])}<span class="Hero_amp__mZ2q0">and</span>{e(b["name"])}</h1><p class="Hero_date__4Lk9c">{e(dtxt)}</p><p class="Hero_venue__Q8sd1">{e(v["name"])} {e(v["hall"])}</p></header>
<section class="Section_wrap__1kZ2a"><h2 class="Section_title__c9Jd3">Invitation</h2><p class="Section_body__aQ8x2">오랜 기다림 속에서 저희 두 사람, 한 마음 되어 참된 사랑의 결실을 맺고자 합니다.<br/>귀한 걸음 하시어 축복해 주시면 감사하겠습니다.</p><p class="Section_parents__vN1x9"><span>{e(g["father"])} · {e(g["mother"])}의 {e(g["order"])} {e(g["name"][1:])}</span><span>{e(b["father"])} · {e(b["mother"])}의 {e(b["order"])} {e(b["name"][1:])}</span></p></section>
{extra}
<section class="Section_wrap__1kZ2a"><h2 class="Section_title__c9Jd3">Gallery</h2><div class="Gallery_grid__Hs4e2"><img alt="" src="../_assets/gallery-1.svg" loading="lazy"/><img alt="" src="../_assets/gallery-2.svg" loading="lazy"/><img alt="" src="../_assets/gallery-3.svg" loading="lazy"/></div></section>
<section class="Section_wrap__1kZ2a"><h2 class="Section_title__c9Jd3">Location</h2><p class="Location_name__A1sd9">{e(v["name"])} {e(v["hall"])}</p><p class="Location_addr__Bz7e2">{e(v["address"])}</p><p class="Location_tel__Cc8r4"><a href="tel:{e(v["tel"])}">{e(v["tel"])}</a></p><div class="Location_map__Dm3t5" id="map"></div><div class="Location_links__E0f1g"><a href="https://map.kakao.com/link/to/{e(v["name"])},37.5,127.03">카카오내비</a><a href="https://map.naver.com/v5/search/{e(v["name"])}">네이버지도</a><a href="https://tmap.life/{c["id"]}">티맵</a></div></section>
<section class="Section_wrap__1kZ2a"><h2 class="Section_title__c9Jd3">마음 전하실 곳</h2>{accs or '<p class="Section_body__aQ8x2">참석하여 축하해 주시는 것만으로 충분합니다.</p>'}</section>
<footer class="Footer_footer__u7Yt3"><button class="Footer_share__z2Xa9">카카오톡 공유하기</button><p class="Footer_copy__k3Lm0">© {e(c["vendor"])}</p></footer>
</main></div>
<script id="__NEXT_DATA__" type="application/json">{json.dumps(props, ensure_ascii=False)}</script>
<script src="https://developers.kakao.com/sdk/js/kakao.min.js"></script>
</body></html>
'''
    css = '.Card_main__x9Fh2{max-width:480px;margin:0 auto;font-family:Pretendard,sans-serif;color:#222}.Hero_hero__7gT1k{text-align:center;padding:32px 20px}.Hero_image__p0Wz3{width:100%;border-radius:12px}.Section_wrap__1kZ2a{padding:28px 20px;text-align:center}.Section_title__c9Jd3{font-size:13px;letter-spacing:3px;color:#a88}.Account_row__T2bqa{display:flex;gap:8px;justify-content:center;padding:6px 0}.Location_map__Dm3t5{height:220px;background:#eee}'
    return {"index.html": page, "styles.css": css, "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_csr_shell(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    data = {
        "couple": {"groom": g, "bride": b},
        "datetime": c["dt"].isoformat() if c["dt"] else None,
        "dateText": date_text(c),
        "venue": v,
        "accounts": c["accounts"],
        "greeting": "저희 두 사람이 사랑과 믿음으로 한 가정을 이루게 되었습니다. 귀한 걸음으로 축복해 주시면 감사하겠습니다.",
        "gallery": ["../_assets/gallery-1.svg", "../_assets/gallery-2.svg", "../_assets/gallery-3.svg"],
    }
    page = f'''<!doctype html>
<html lang="ko">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>{e(g["name"])} ♥ {e(b["name"])} 결혼합니다</title>
{og_meta(c)}
<link rel="icon" type="image/svg+xml" href="/vite.svg" />
<link rel="stylesheet" href="./app.css">
<script type="module" crossorigin src="./app.js"></script>
</head>
<body>
<div id="root"></div>
<noscript>이 청첩장은 JavaScript가 필요합니다.</noscript>
</body>
</html>
'''
    app_js = '''// Client-rendered invitation: the HTML above is an empty shell, everything
// comes from data.json at runtime (what a Vite/CRA SPA vendor ships).
const root = document.getElementById('root');
fetch('./data.json').then(r => r.json()).then(d => {
  const g = d.couple.groom, b = d.couple.bride, v = d.venue;
  const accs = ['groom', 'bride'].map(side => d.accounts[side].map(a =>
    `<li>${a.bank} ${a.number} (${a.holder})</li>`).join('')).join('');
  root.innerHTML = `
    <main class="card">
      <img src="./main.svg" alt="">
      <h1>${g.name} <small>&amp;</small> ${b.name}</h1>
      <p class="date">${d.dateText || '일정 추후 공지'}</p>
      <p class="venue">${v.name} ${v.hall}</p>
      <p class="greeting">${d.greeting}</p>
      <p class="parents">${g.father} · ${g.mother}의 ${g.order} ${g.name.slice(1)}<br>${b.father} · ${b.mother}의 ${b.order} ${b.name.slice(1)}</p>
      <section><h2>오시는 길</h2><p>${v.address}</p><p>${v.tel}</p></section>
      <section><h2>마음 전하실 곳</h2><ul>${accs || '<li>축하의 마음만으로 충분합니다</li>'}</ul></section>
      <div class="gallery">${d.gallery.map(s => `<img src="${s}" alt="">`).join('')}</div>
    </main>`;
});
'''
    return {"index.html": page, "app.js": app_js, "app.css": ".card{max-width:480px;margin:0 auto;text-align:center;font-family:sans-serif}.card img{width:100%}",
            "data.json": json.dumps(data, ensure_ascii=False, indent=2), "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_nuxt_ssr(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    state = {"layout": "default", "data": [{"card": {
        "groomName": g["name"], "brideName": b["name"], "groomParents": [g["father"], g["mother"]], "brideParents": [b["father"], b["mother"]],
        "weddingAt": c["dt"].isoformat() if c["dt"] else None, "hall": f'{v["name"]} {v["hall"]}', "address": v["address"], "tel": v["tel"],
        "accounts": c["accounts"]}}], "fetch": {}, "error": None, "state": {"theme": "ivory"}, "serverRendered": True, "routePath": f"/w/{c['id']}", "config": {"_app": {"basePath": "/", "assetsPath": "/_nuxt/"}}}
    sid = "data-v-4f2a91c3"
    accs = ""
    for side, label in (("groom", "신랑 측"), ("bride", "신부 측")):
        if c["accounts"][side]:
            accs += f'<div {sid} class="acc-group"><h4 {sid}>{label}</h4><ul {sid}>' + "".join(f'<li {sid}>{e(l)}</li>' for l in account_lines(c["accounts"][side], "relation")) + "</ul></div>"
    page = f'''<!doctype html>
<html data-n-head-ssr lang="ko" data-n-head="%7B%22lang%22:%7B%22ssr%22:%22ko%22%7D%7D">
<head><title>{e(g["name"])} ♡ {e(b["name"])} · {e(c["vendor"])}</title><meta data-n-head="ssr" charset="utf-8"><meta data-n-head="ssr" name="viewport" content="width=device-width,initial-scale=1">{og_meta(c)}<link rel="preload" href="/_nuxt/8d3f1a2.js" as="script"><link rel="preload" href="/_nuxt/pages/w/_id.4b1c0e9.js" as="script"><style data-vue-ssr-id="6c2b9a1e:0">.card[{sid}]{{max-width:480px;margin:0 auto;font-family:"Noto Serif KR",serif;color:#3a3a3a}}.hero[{sid}]{{text-align:center;padding:40px 20px}}.section[{sid}]{{padding:28px 20px;text-align:center}}.acc-group ul[{sid}]{{list-style:none;padding:0}}</style></head>
<body>
<div data-server-rendered="true" id="__nuxt"><div id="__layout"><div {sid} class="card">
<header {sid} class="hero"><img {sid} src="./main.svg" alt="" class="hero-img"><h1 {sid} class="names">{e(g["name"])} <i {sid}>♡</i> {e(b["name"])}</h1><p {sid} class="when">{e(dtxt)}</p><p {sid} class="where">{e(v["name"])} {e(v["hall"])}</p></header>
<section {sid} class="section"><h3 {sid}>모시는 글</h3><p {sid}>따스한 봄날, 저희 두 사람이 하나의 이름으로 새 출발을 합니다.<br {sid}>귀한 시간 내어 함께해 주시면 큰 기쁨이겠습니다.</p><p {sid} class="parents">{e(g["father"])} · {e(g["mother"])}의 {e(g["order"])} <b {sid}>{e(g["name"][1:])}</b><br {sid}>{e(b["father"])} · {e(b["mother"])}의 {e(b["order"])} <b {sid}>{e(b["name"][1:])}</b></p></section>
<section {sid} class="section"><h3 {sid}>예식 안내</h3><p {sid}>{e(dtxt)}</p><p {sid}>{e(v["name"])} {e(v["hall"])}</p><p {sid}>{e(v["address"])}</p><p {sid}>{e(v["tel"])}</p><div {sid} class="map-btns"><a {sid} href="https://map.kakao.com/link/search/{e(v["name"])}">카카오맵</a> <a {sid} href="nmap://search?query={e(v["name"])}">네이버지도</a></div></section>
<section {sid} class="section"><h3 {sid}>축의금 안내</h3>{accs or f'<p {sid}>축하해 주시는 마음만 감사히 받겠습니다.</p>'}</section>
<footer {sid} class="section"><small {sid}>Made with {e(c["vendor"])}</small></footer>
</div></div></div>
<script>window.__NUXT__={json.dumps(state, ensure_ascii=False)};</script>
<script src="/_nuxt/8d3f1a2.js" defer></script><script src="/_nuxt/pages/w/_id.4b1c0e9.js" defer></script>
</body></html>
'''
    return {"index.html": page, "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_site_builder(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    lazy = "lazy-src" in c["quirks"]

    def img(src, cls="lazy"):
        return f'<img class="{cls}" src="{LAZY_PIXEL}" data-src="{src}" alt="">' if lazy else f'<img src="{src}" alt="">'

    def spans(text: str, style="font-size:15px;color:#333"):
        return "".join(f'<span style="{style}">{e(w)}</span> ' for w in text.split(" "))

    accs = ""
    for side, label in (("groom", "신랑측"), ("bride", "신부측")):
        for a in c["accounts"][side]:
            accs += f'<div class="inline-blocked"><div class="fr-view"><p><span style="font-size:13px;color:#888">{label}</span> <span style="font-size:14px">{e(a["bank"])}</span> <span style="font-size:14px;font-weight:bold">{e(a["number"])}</span> <span style="font-size:14px">{e(a["holder"])}</span></p></div></div>'
    page = f'''<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no">
<meta name="generator" content="SiteBuilder 3.14">
<title>{e(g["name"])} ♥ {e(b["name"])} WEDDING</title>
{og_meta(c)}
<link href="https://fonts.googleapis.com/css2?family=Noto+Serif+KR:wght@300;500&family=Nanum+Myeongjo&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/resource/css/site.min.css?v=20260901">
<script src="/resource/js/jquery-3.6.0.min.js"></script>
<script src="/resource/js/lazyload.min.js"></script>
<style>
#site_wrap{{max-width:480px;margin:0 auto;font-family:"Noto Serif KR",serif}}.section_row{{padding:30px 20px;text-align:center}}._hidden{{display:none}}
</style>
</head>
<body class="body-container">
<div id="site_wrap" class="site_wrap">
<div class="section_row" style="background-color:#fbf8f3">
  <div class="inline-blocked" style="width:100%"><div class="fr-view">{img("./main.svg")}</div></div>
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center"><span style="font-size:12px;letter-spacing:6px;color:#b08968">INVITATION</span></p></div></div>
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center"><span style="font-size:24px">{e(g["name"])}</span> <span style="font-size:16px;color:#b08968">&amp;</span> <span style="font-size:24px">{e(b["name"])}</span></p></div></div>
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center">{spans(dtxt) if dtxt else spans("일정은 추후 안내드립니다")}</p></div></div>
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center">{spans(f'{v["name"]} {v["hall"]}', "font-size:14px;color:#666")}</p></div></div>
</div>
<div class="section_row">
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center"><span style="font-size:18px">모시는 글</span></p><p style="text-align:center"><span style="font-size:15px;line-height:2">평생을 같이하고 싶은 사람을 만났습니다.</span><br><span style="font-size:15px;line-height:2">서로 아껴주고 이해하며 사랑 베풀며 살고 싶습니다.</span><br><span style="font-size:15px;line-height:2">저희의 하나 됨을 지켜보아 주시고 격려해 주시면 더없는 기쁨이겠습니다.</span></p></div></div>
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center"><span style="font-size:14px">{e(g["father"])}</span><span style="font-size:14px"> · </span><span style="font-size:14px">{e(g["mother"])}</span><span style="font-size:13px;color:#888">의 {e(g["order"])}</span> <span style="font-size:15px">{e(g["name"][1:])}</span></p><p style="text-align:center"><span style="font-size:14px">{e(b["father"])}</span><span style="font-size:14px"> · </span><span style="font-size:14px">{e(b["mother"])}</span><span style="font-size:13px;color:#888">의 {e(b["order"])}</span> <span style="font-size:15px">{e(b["name"][1:])}</span></p></div></div>
</div>
<div class="section_row">
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center"><span style="font-size:18px">갤러리</span></p></div></div>
  <div class="gallery_wrap">{img("../_assets/gallery-1.svg")}{img("../_assets/gallery-2.svg")}{img("../_assets/gallery-3.svg")}</div>
</div>
<div class="section_row">
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center"><span style="font-size:18px">오시는 길</span></p><p style="text-align:center"><span style="font-size:16px;font-weight:bold">{e(v["name"])}</span> <span style="font-size:15px">{e(v["hall"])}</span></p><p style="text-align:center"><span style="font-size:14px;color:#666">{e(v["address"])}</span></p><p style="text-align:center"><span style="font-size:14px;color:#666">Tel {e(v["tel"])}</span></p></div></div>
  <div class="inline-blocked map_area"><div class="fr-view"><div class="map_placeholder" style="height:220px;background:#eee"></div></div></div>
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center"><a href="https://map.kakao.com/link/search/{e(v["name"])}" target="_blank"><span style="font-size:13px">카카오맵</span></a> <a href="https://map.naver.com/v5/search/{e(v["name"])}" target="_blank"><span style="font-size:13px">네이버지도</span></a></p></div></div>
</div>
<div class="section_row" style="background-color:#fbf8f3">
  <div class="inline-blocked"><div class="fr-view"><p style="text-align:center"><span style="font-size:18px">마음 전하실 곳</span></p></div></div>
  {accs or '<div class="inline-blocked"><div class="fr-view"><p style="text-align:center"><span style="font-size:14px">축하의 마음은 직접 전해주세요.</span></p></div></div>'}
</div>
<div class="section_row _hidden"><div class="fr-view"><p><span>이 페이지는 {e(c["vendor"])}로 제작되었습니다.</span></p></div></div>
</div>
<script>$(function(){{ new LazyLoad({{elements_selector:'.lazy'}}); }});</script>
</body>
</html>
'''
    return {"index.html": page, "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_tailwind_semantic(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    quirks = c["quirks"]
    ld = {"@context": "https://schema.org", "@type": "Event", "name": f'{g["name"]} & {b["name"]} Wedding',
          "startDate": c["dt"].isoformat() if c["dt"] else None,
          "location": {"@type": "Place", "name": v["name"], "address": v["address"]},
          "image": f'{url_of(c)}main.svg'}
    hero_img = '<picture><source srcset="./main.svg" type="image/svg+xml"><img src="./main.svg" alt="" class="w-full rounded-2xl"></picture>' if "picture-srcset" in quirks else '<img src="./main.svg" alt="" class="w-full rounded-2xl">'
    kakaopay = ' <a class="text-xs text-yellow-600 underline" href="https://qr.kakaopay.com/Ej8abc123">카카오페이 송금</a>' if "kakaopay" in quirks else ""
    accs = ""
    for side, label in (("groom", "신랑측 계좌"), ("bride", "신부측 계좌")):
        if c["accounts"][side]:
            rows = "".join(f'<li class="flex justify-between py-1"><span>{e(a["bank"])} {e(a["number"])}</span><span class="text-gray-500">{e(a["holder"])} ({e(a["relation"])}){kakaopay if a["relation"] in ("신랑", "신부") else ""}</span></li>' for a in c["accounts"][side])
            accs += f'<details class="rounded-xl bg-white p-4 shadow-sm"><summary class="cursor-pointer font-medium">{label}</summary><ul class="mt-2 text-sm">{rows}</ul></details>'
    date_block = f'<time datetime="{c["dt"].isoformat()}" class="text-gray-600">{e(dtxt)}</time>' if c["dt"] else '<p class="text-gray-600">예식 날짜는 확정되는 대로 다시 안내드릴게요 (2027년 봄 예정)</p>'
    page = f'''<!DOCTYPE html>
<html lang="ko" class="scroll-smooth">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{e(g["name"])} & {e(b["name"])} — 결혼합니다</title>
{og_meta(c)}
<script type="application/ld+json">{json.dumps(ld, ensure_ascii=False)}</script>
<link rel="stylesheet" href="./tailwind.css">
</head>
<body class="bg-stone-50 text-stone-800 antialiased">
<main class="mx-auto max-w-md px-5 py-10 space-y-12">
  <header class="text-center space-y-3">
    <p class="text-xs tracking-[0.3em] text-stone-400">WEDDING INVITATION</p>
    {hero_img}
    <h1 class="text-2xl font-semibold">{e(g["name"])} <span class="text-rose-400">&amp;</span> {e(b["name"])}</h1>
    {date_block}
    <p class="text-sm text-stone-500">{e(v["name"])} {e(v["hall"])}</p>
  </header>
  <section aria-labelledby="greeting" class="text-center space-y-4">
    <h2 id="greeting" class="text-sm tracking-widest text-rose-400">INVITATION</h2>
    <p class="leading-8">서로 다른 길을 걸어온 두 사람이<br>이제 같은 길을 함께 걸어가려 합니다.<br>그 첫걸음에 소중한 분들을 모십니다.</p>
    <dl class="text-sm text-stone-600"><div><dt class="inline">{e(g["father"])} · {e(g["mother"])}의 {e(g["order"])}</dt> <dd class="inline font-medium">{e(g["name"][1:])}</dd></div><div><dt class="inline">{e(b["father"])} · {e(b["mother"])}의 {e(b["order"])}</dt> <dd class="inline font-medium">{e(b["name"][1:])}</dd></div></dl>
  </section>
  <section aria-labelledby="where" class="space-y-3 text-center">
    <h2 id="where" class="text-sm tracking-widest text-rose-400">LOCATION</h2>
    <address class="not-italic"><strong>{e(v["name"])}</strong> {e(v["hall"])}<br><span class="text-sm text-stone-500">{e(v["address"])}</span><br><a href="tel:{e(v["tel"])}" class="text-sm underline">{e(v["tel"])}</a></address>
    <div class="h-56 rounded-xl bg-stone-200" role="img" aria-label="지도"></div>
    <nav class="flex justify-center gap-3 text-sm"><a class="rounded-full border px-4 py-1" href="https://map.kakao.com/link/search/{e(v["name"])}">카카오맵</a><a class="rounded-full border px-4 py-1" href="https://map.naver.com/v5/search/{e(v["name"])}">네이버지도</a><a class="rounded-full border px-4 py-1" href="https://apis.openapi.sk.com/tmap/app/routes?name={e(v["name"])}">티맵</a></nav>
  </section>
  <section aria-labelledby="gift" class="space-y-3">
    <h2 id="gift" class="text-center text-sm tracking-widest text-rose-400">마음 전하실 곳</h2>
    {accs or '<p class="text-center text-sm text-stone-500">축하의 마음은 오셔서 직접 전해주시면 감사하겠습니다.</p>'}
  </section>
  <section class="grid grid-cols-3 gap-2"><img src="../_assets/gallery-1.svg" alt="" class="rounded-lg"><img src="../_assets/gallery-2.svg" alt="" class="rounded-lg"><img src="../_assets/gallery-3.svg" alt="" class="rounded-lg"></section>
  <footer class="text-center text-xs text-stone-400">Powered by {e(c["vendor"])}</footer>
</main>
</body>
</html>
'''
    return {"index.html": page, "tailwind.css": "/* compiled tailwind subset */.mx-auto{margin:0 auto}.max-w-md{max-width:28rem}.text-center{text-align:center}.w-full{width:100%}",
            "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_styled_react(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dt = c["dt"]
    accs = ""
    for side, label in (("groom", "GROOM"), ("bride", "BRIDE")):
        for a in c["accounts"][side]:
            accs += f'<div class="sc-eCImPb kVYzXn"><span class="sc-jrQzAO dWQypH">{label}</span><span class="sc-gKclnd bJhcEE">{e(a["bank"])}</span><span class="sc-iBkjds hFMeGl">{e(a["number"])}</span><span class="sc-ftTHYK cOhGwo">{e(a["holder"])}</span></div>'
    # Big numerals with CSS-inserted separators: the crawler sees "20261017".
    numerals = f'<div class="sc-hKwDye eXfHqt"><span class="sc-bqiRlB jkyNZa">{dt.year}</span><span class="sc-bqiRlB jkyNZa">{dt.month:02d}</span><span class="sc-bqiRlB jkyNZa">{dt.day:02d}</span></div><p class="sc-dkPtRN gNvWpQ">{EN_WEEKDAY[dt.weekday()][:3].upper()} {dt.strftime("%-I:%M %p")}</p>'
    body_date = DATE_STYLES["kor_full"](dt)
    page = f'''<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/><title>{e(g["name"])} ♥ {e(b["name"])}</title>{og_meta(c)}<style data-styled="true" data-styled-version="5.3.11">.kVYzXn{{display:flex;gap:8px;justify-content:center;font-size:14px;padding:4px 0}}.eXfHqt{{display:flex;justify-content:center;gap:0;font-size:40px;font-weight:300}}.jkyNZa+.jkyNZa::before{{content:"/";padding:0 10px;color:#ccc}}.fZxmqp{{max-width:480px;margin:0 auto;font-family:Pretendard,sans-serif;text-align:center;color:#2b2b2b}}.hFMeGl{{font-variant-numeric:tabular-nums}}</style></head>
<body><div id="root"><div class="sc-bdvvtL fZxmqp">
<div class="sc-gsDKAQ bhVvXn"><img src="./main.svg" alt="" class="sc-hKFxyN kjaYJh"/><h1 class="sc-eCImPb cPQFdX">{e(g["name"])}<em class="sc-jrQzAO eYUbRL">&amp;</em>{e(b["name"])}</h1>{numerals}<p class="sc-dkPtRN gNvWpQ">{e(v["name"])} {e(v["hall"])}</p></div>
<div class="sc-hKwDye ipHVzc"><h2 class="sc-jSFjdj jEOffB">INVITATION</h2><p class="sc-gKclnd cXnFla">평생 함께할 사람을 만났습니다.<br/>{e(body_date)}에<br/>저희 두 사람 결혼합니다.</p><p class="sc-iBkjds kjmQXm">{e(g["father"])} · {e(g["mother"])}의 {e(g["order"])} {e(g["name"][1:])}<br/>{e(b["father"])} · {e(b["mother"])}의 {e(b["order"])} {e(b["name"][1:])}</p></div>
<div class="sc-hKwDye ipHVzc"><h2 class="sc-jSFjdj jEOffB">LOCATION</h2><p class="sc-gKclnd cXnFla"><b>{e(v["name"])}</b> {e(v["hall"])}<br/>{e(v["address"])}<br/>{e(v["tel"])}</p><div class="sc-ftTHYK jqEmtB" style="height:220px;background:#f0f0f0"></div><div class="sc-papXJ kzqoRk"><a href="https://map.kakao.com/link/search/{e(v["name"])}">카카오맵</a><a href="https://map.naver.com/v5/search/{e(v["name"])}">네이버지도</a></div></div>
<div class="sc-hKwDye ipHVzc"><h2 class="sc-jSFjdj jEOffB">ACCOUNT</h2>{accs}</div>
<div class="sc-hKwDye ipHVzc"><img src="../_assets/gallery-1.svg" alt=""/><img src="../_assets/gallery-2.svg" alt=""/></div>
<footer class="sc-crXcEl fgFgfj">{e(c["vendor"])} · made with love</footer>
</div></div>
<script src="/static/js/main.7b2c1f3e.js"></script></body></html>
'''
    return {"index.html": page, "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_wordpress_theme(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dt = c["dt"]
    dtxt = date_text(c)
    rng = random.Random(c["seq"])
    accs = ""
    for side, label in (("groom", "신랑측"), ("bride", "신부측")):
        if c["accounts"][side]:
            accs += f'<h4>{label}</h4><ul class="wp-block-list">' + "".join(f'<li>{e(l)}</li>' for l in account_lines(c["accounts"][side], "pipe")) + "</ul>"
    comments = [
        (f'{rng.choice(SURNAMES)}수진', f'{(dt - timedelta(days=14)).strftime("%m월 %d일")}에 청첩장 모임 때 봐요! 결혼 축하해 ♥', "2026-08-30"),
        ("동기 일동", f'{g["name"][1:]}아 축하한다! 우리 {(dt + timedelta(days=1)).strftime("%m월 %d일")} 저녁 7시에 뒤풀이 하자', "2026-09-01"),
        (f'{rng.choice(SURNAMES)}지훈', "신부 화장 잘 받길~ 근데 저 그날 오후 3시 다른 결혼식 있어서 늦을 듯", "2026-09-02"),
        (f'{rng.choice(SURNAMES)}서연', "너무 예쁘다 청첩장 ㅠㅠ 우리 결혼식 11월 21일이었는데 그때 기억난다", "2026-09-03"),
    ]
    guestbook = "".join(f'<li class="comment"><article><footer class="comment-meta"><b class="fn">{e(n)}</b> <time datetime="{d}">{d}</time></footer><div class="comment-content"><p>{e(t)}</p></div></article></li>' for n, t, d in comments)
    page = f'''<!DOCTYPE html>
<html lang="ko-KR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(g["name"])} &amp; {e(b["name"])} – {e(c["vendor"])}</title>
{og_meta(c)}
<meta name="generator" content="WordPress 6.5.2">
<link rel="stylesheet" id="wp-block-library-css" href="/wp-includes/css/dist/block-library/style.min.css?ver=6.5.2" media="all">
<link rel="stylesheet" id="theme-style-css" href="/wp-content/themes/wedding-story/style.css?ver=1.8" media="all">
<script src="/wp-includes/js/jquery/jquery.min.js?ver=3.7.1" id="jquery-core-js"></script>
</head>
<body class="post-template-default single single-post postid-{100 + c["seq"]} wp-embed-responsive">
<div id="page" class="site">
<header id="masthead" class="site-header"><p class="site-title"><a href="/">{e(c["vendor"])}</a></p></header>
<main id="primary" class="site-main">
<article id="post-{100 + c["seq"]}" class="post-{100 + c["seq"]} post type-post status-publish format-standard has-post-thumbnail hentry category-invitation">
<header class="entry-header"><h1 class="entry-title">{e(g["name"])} &amp; {e(b["name"])}</h1><div class="entry-meta"><span class="posted-on">Posted on <time class="entry-date published" datetime="2026-08-20T10:00:00+09:00">2026년 8월 20일</time></span></div></header>
<figure class="wp-block-image size-large"><img src="./main.svg" alt="" class="wp-image-{200 + c["seq"]}"><figcaption class="wp-element-caption">2026년 4월, 제주에서</figcaption></figure>
<div class="entry-content">
<p class="has-text-align-center">우리 결혼합니다.</p>
<p class="has-text-align-center"><strong><time datetime="{dt.isoformat()}">{e(dtxt)}</time></strong><br>{e(v["name"])} {e(v["hall"])}</p>
<h2 class="wp-block-heading">초대합니다</h2>
<p>바쁘신 와중에도 저희의 시작을 함께해 주신다면 큰 힘이 되겠습니다.<br>{e(g["father"])} · {e(g["mother"])}의 {e(g["order"])} {e(g["name"][1:])}<br>{e(b["father"])} · {e(b["mother"])}의 {e(b["order"])} {e(b["name"][1:])}</p>
<h2 class="wp-block-heading">오시는 길</h2>
<p><strong>{e(v["name"])} {e(v["hall"])}</strong><br>{e(v["address"])}<br>전화 {e(v["tel"])}</p>
<figure class="wp-block-embed"><div class="wp-block-embed__wrapper"><iframe src="https://map.kakao.com/link/map/{e(v["name"])},37.5,127.0" width="100%" height="240" loading="lazy" title="지도"></iframe></div></figure>
<h2 class="wp-block-heading">마음 전하실 곳</h2>
{accs or "<p>축하의 마음만 감사히 받겠습니다.</p>"}
<div class="wp-block-gallery has-nested-images columns-3 is-cropped wp-block-gallery-1 is-layout-flex"><figure class="wp-block-image"><img src="../_assets/gallery-1.svg" alt=""></figure><figure class="wp-block-image"><img src="../_assets/gallery-2.svg" alt=""></figure><figure class="wp-block-image"><img src="../_assets/gallery-3.svg" alt=""></figure></div>
</div>
<footer class="entry-footer"><span class="cat-links">Posted in <a href="/category/invitation/" rel="category tag">청첩장</a></span></footer>
</article>
<section id="comments" class="comments-area">
<h2 class="comments-title">방명록 ({len(comments)})</h2>
<ol class="comment-list">{guestbook}</ol>
<div id="respond" class="comment-respond"><h3 id="reply-title" class="comment-reply-title">축하 메시지 남기기</h3><form action="/wp-comments-post.php" method="post" id="commentform"><p class="comment-form-comment"><textarea id="comment" name="comment" rows="4"></textarea></p><p class="form-submit"><input name="submit" type="submit" id="submit" class="submit" value="남기기"></p></form></div>
</section>
</main>
<footer id="colophon" class="site-footer"><div class="site-info">Proudly powered by WordPress · {e(c["vendor"])}</div></footer>
</div>
</body>
</html>
'''
    return {"index.html": page, "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_bootstrap_2019(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    quirks = c["quirks"]
    # A page served through a rewrite lives at a URL that is not its
    # directory, so (like real vendors behind a router) it must reference
    # its assets absolutely.
    base = f"/eval/{c['id']}/" if "rewrite-url" in quirks else "./"
    shared = f"/eval/_assets/" if "rewrite-url" in quirks else "../_assets/"
    reception = f'<div class="card mb-3"><div class="card-body"><h5 class="card-title"><i class="fa fa-glass"></i> 피로연 안내</h5><p class="card-text">예식 후 피로연은 {(c["dt"] + timedelta(days=7)).strftime("%m월 %d일")} 오후 6시 <b>한옥마을 별채</b>(서울시 종로구 북촌로 32)에서 따로 진행됩니다.</p></div></div>' if "reception-distractor" in quirks else ""
    modal_rows = ""
    for side, label in (("groom", "신랑측"), ("bride", "신부측")):
        for l in account_lines(c["accounts"][side], "nohyphen"):
            modal_rows += f'<li class="list-group-item d-flex justify-content-between"><span>{label}</span><span>{e(l)}</span></li>'
    page = f'''<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<title>{e(g["name"])} ♥ {e(b["name"])} 결혼식에 초대합니다 | {e(c["vendor"])}</title>
{og_meta(c)}
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css">
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">
<link rel="stylesheet" href="{base}custom.css">
</head>
<body>
<div class="container px-0" style="max-width:480px">
  <div class="jumbotron text-center mb-0 rounded-0">
    <img src="{base}main.svg" class="img-fluid rounded" alt="">
    <h2 class="mt-3">{e(g["name"])} <i class="fa fa-heart text-danger"></i> {e(b["name"])}</h2>
    <p class="lead"><i class="fa fa-calendar"></i> {e(dtxt)}</p>
    <p><i class="fa fa-map-marker"></i> {e(v["name"])} {e(v["hall"])}</p>
  </div>
  <div class="row no-gutters">
    <div class="col-12 p-4 text-center">
      <h5 class="text-muted">INVITATION</h5>
      <p>저희 두 사람이 사랑과 믿음으로<br>한 가정을 이루게 되었습니다.<br>바쁘시더라도 오셔서 축복해 주시면<br>감사하겠습니다.</p>
      <p class="small">{e(g["father"])} · {e(g["mother"])}의 {e(g["order"])} {e(g["name"][1:])}<br>{e(b["father"])} · {e(b["mother"])}의 {e(b["order"])} {e(b["name"][1:])}</p>
      <a href="tel:010-0000-{3000 + c["seq"]:04d}" class="btn btn-outline-secondary btn-sm"><i class="fa fa-phone"></i> 신랑</a>
      <a href="tel:010-0000-{4000 + c["seq"]:04d}" class="btn btn-outline-secondary btn-sm"><i class="fa fa-phone"></i> 신부</a>
    </div>
    <div class="col-12 p-4">
      <div class="card mb-3"><div class="card-body"><h5 class="card-title"><i class="fa fa-map-o"></i> 오시는 길</h5><p class="card-text"><b>{e(v["name"])} {e(v["hall"])}</b><br>{e(v["address"])}<br><i class="fa fa-phone"></i> {e(v["tel"])}</p><div class="embed-responsive embed-responsive-16by9"><iframe class="embed-responsive-item" src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3164.9!2d127.03!3d37.5" allowfullscreen></iframe></div><div class="btn-group btn-group-sm mt-2 w-100"><a class="btn btn-light" href="https://map.kakao.com/link/search/{e(v["name"])}">카카오맵</a><a class="btn btn-light" href="https://map.naver.com/v5/search/{e(v["name"])}">네이버지도</a><a class="btn btn-light" href="https://www.google.com/maps/search/{e(v["name"])}">구글지도</a></div></div></div>
      {reception}
      <div class="card mb-3"><div class="card-body text-center"><h5 class="card-title"><i class="fa fa-gift"></i> 마음 전하실 곳</h5><button type="button" class="btn btn-primary btn-sm" data-toggle="modal" data-target="#accountModal">계좌번호 보기</button></div></div>
    </div>
  </div>
  <div class="row no-gutters"><div class="col-4"><img src="{shared}gallery-1.svg" class="img-fluid" alt=""></div><div class="col-4"><img src="{shared}gallery-2.svg" class="img-fluid" alt=""></div><div class="col-4"><img src="{shared}gallery-3.svg" class="img-fluid" alt=""></div></div>
  <footer class="text-center text-muted small py-4">© 2026 {e(c["vendor"])}</footer>
</div>
<div class="modal fade" id="accountModal" tabindex="-1" role="dialog" aria-hidden="true"><div class="modal-dialog" role="document"><div class="modal-content"><div class="modal-header"><h5 class="modal-title">축의금 계좌</h5><button type="button" class="close" data-dismiss="modal"><span>&times;</span></button></div><div class="modal-body p-0"><ul class="list-group list-group-flush">{modal_rows or '<li class="list-group-item">계좌 안내는 개별 연락 드리겠습니다.</li>'}</ul></div></div></div></div>
<script src="https://code.jquery.com/jquery-3.3.1.slim.min.js"></script>
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.bundle.min.js"></script>
</body>
</html>
'''
    return {"index.html": page, "custom.css": ".jumbotron{background:#fff8f3}", "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_iframe_embed(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    inner_files = t_classic_jquery(dict(c, quirks=[]))
    outer = f'''<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(g["name"])} ♥ {e(b["name"])} 청첩장 - {e(c["vendor"])}</title>
{og_meta(c, description="모바일 청첩장")}
<style>html,body{{margin:0;height:100%;background:#f3f3f3}}#viewer{{max-width:480px;height:100%;margin:0 auto;border:0;display:block;background:#fff}}.bar{{position:fixed;bottom:0;left:0;right:0;background:#fff;border-top:1px solid #ddd;text-align:center;padding:8px;font:12px sans-serif}}</style>
</head>
<body>
<iframe id="viewer" src="./content.html" title="청첩장"></iframe>
<div class="bar"><a href="javascript:void(0)" onclick="Kakao.Link.sendDefault()">카카오톡 공유</a></div>
<script src="https://developers.kakao.com/sdk/js/kakao.min.js"></script>
</body>
</html>
'''
    return {"index.html": outer, "content.html": inner_files["index.html"], "style.css": inner_files["style.css"], "main.svg": inner_files["main.svg"]}


def t_image_only(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    info_lines = [f'{g["name"]} ♥ {b["name"]}', dtxt, f'{v["name"]} {v["hall"]}', v["address"]]
    acc_lines = ["마음 전하실 곳"] + [f'신랑측 {l}' for l in account_lines(c["accounts"]["groom"], "short")] + [f'신부측 {l}' for l in account_lines(c["accounts"]["bride"], "short")]
    files = {
        "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}'),
        "section-info.svg": text_svg(info_lines),
        "section-greeting.svg": text_svg(["초대합니다", "저희 두 사람이 사랑으로 하나 되는 날", "귀한 걸음으로 축복해 주세요", f'{g["father"]} · {g["mother"]}의 {g["order"]} {g["name"][1:]}', f'{b["father"]} · {b["mother"]}의 {b["order"]} {b["name"][1:]}']),
        "section-account.svg": text_svg(acc_lines if len(acc_lines) > 1 else ["마음 전하실 곳", "축하의 마음만으로 충분합니다"]),
    }
    page = f'''<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(g["name"])}♥{e(b["name"])} 청첩장</title>
{og_meta(c, description="모바일 청첩장이 도착했습니다")}
<style>body{{margin:0;background:#fbf7f2}}.card{{max-width:480px;margin:0 auto}}.card img{{display:block;width:100%}}</style>
</head>
<body>
<div class="card">
<img src="./main.svg" alt="">
<img src="./section-info.svg" alt="예식 안내">
<img src="./section-greeting.svg" alt="인사말">
<img src="../_assets/gallery-1.svg" alt="">
<img src="../_assets/gallery-2.svg" alt="">
<img src="./section-account.svg" alt="계좌 안내">
<img src="../_assets/map.svg" alt="약도">
</div>
<script>document.querySelectorAll('img').forEach(function(i){{i.oncontextmenu=function(){{return false}}}});</script>
</body>
</html>
'''
    files["index.html"] = page
    return files


def t_kakao_card(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    hidden = ""
    btns = ""
    for side, label in (("groom", "신랑측"), ("bride", "신부측")):
        for i, a in enumerate(c["accounts"][side]):
            aid = f"{side}{i}"
            btns += f'<button class="acc_btn" data-side="{side}" data-bank="{e(a["bank"])}" data-account="{e(a["number"])}" data-holder="{e(a["holder"])}" onclick="showAcc(\'{aid}\')">{label} {e(a["relation"])} 계좌 보기</button>'
            hidden += f'<div id="acc_{aid}" class="acc_detail" style="display:none"><p>{label} · {e(a["relation"])}</p><p>{e(a["bank"])} {e(a["number"])}</p><p>예금주 {e(a["holder"])}</p></div>'
    page = f'''<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{e(g["name"])}·{e(b["name"])} 결혼식 초대</title>
{og_meta(c, title=f'{g["name"]}·{b["name"]} 결혼식에 초대합니다', description=f'{dtxt} · {v["name"]} {v["hall"]}'.strip(" ·"))}
<meta name="apple-mobile-web-app-capable" content="yes">
<style>
body{{margin:0;background:#9bbbd4;font-family:-apple-system,"Apple SD Gothic Neo",sans-serif}}
.bubble{{max-width:360px;margin:24px auto;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.15)}}
.bubble img{{width:100%;display:block}}
.body{{padding:16px}} .row{{display:flex;gap:8px;padding:6px 0;font-size:14px}} .row .k{{width:52px;color:#888}}
.acc_btn{{display:block;width:100%;margin:6px 0;padding:10px;border:1px solid #ddd;background:#fafafa;border-radius:8px}}
.acc_detail{{padding:8px 12px;background:#fff8e1;border-radius:8px;margin:6px 0;font-size:13px}}
</style>
</head>
<body>
<div class="bubble">
  <img src="./main.svg" alt="">
  <div class="body">
    <h1 style="font-size:18px;margin:0 0 8px">{e(g["name"])} · {e(b["name"])} 결혼합니다</h1>
    <div class="row"><span class="k">일시</span><span>{e(dtxt) if dtxt else "추후 안내"}</span></div>
    <div class="row"><span class="k">장소</span><span>{e(v["name"])} {e(v["hall"])}</span></div>
    <div class="row"><span class="k">주소</span><span>{e(v["address"])}</span></div>
    <div class="row"><span class="k">연락</span><span><a href="tel:{e(v["tel"])}">{e(v["tel"])}</a></span></div>
    <p style="font-size:14px;line-height:1.7;color:#444">{e(g["father"])}·{e(g["mother"])}의 {e(g["order"])} {e(g["name"][1:])}<br>{e(b["father"])}·{e(b["mother"])}의 {e(b["order"])} {e(b["name"][1:])}<br>두 사람의 새로운 시작을 함께해 주세요.</p>
    <a href="https://map.kakao.com/link/map/{e(v["name"])},37.5,127.0" style="display:block;text-align:center;padding:10px;background:#fee500;border-radius:8px;color:#191919;text-decoration:none;font-size:14px">카카오맵으로 길찾기</a>
    <div class="accounts" style="margin-top:12px">{btns or '<p style="font-size:13px;color:#888;text-align:center">축의금은 정중히 사양합니다</p>'}{hidden}</div>
  </div>
</div>
<script>
function showAcc(id){{var el=document.getElementById('acc_'+id);el.style.display=el.style.display==='none'?'block':'none';}}
</script>
</body>
</html>
'''
    return {"index.html": page, "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


def t_english_intl(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    mixed = "mixed-language" in c["quirks"]
    g_en = romanized(g["name"])
    b_en = romanized(b["name"])
    accs = ""
    if c["accounts"]["groom"] or c["accounts"]["bride"]:
        accs = '<section class="block"><h2>Gift</h2><p>For those who wish to send a gift (축의금):</p><ul>' + "".join(f'<li>{"Groom" if side == "groom" else "Bride"} — {e(a["bank"])} {e(a["number"])} ({e(a["holder"])})</li>' for side in ("groom", "bride") for a in c["accounts"][side]) + "</ul></section>"
    kor_block = f'<section class="block"><h2>한국어 안내</h2><p>{e(g["name"])} · {e(b["name"])}<br>{e(DATE_STYLES["kor_full"](c["dt"]))}<br>{e(v["name"])} {e(v["hall"])}<br>{e(v["address"])}</p></section>' if mixed else ""
    page = f'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{e(g_en)} &amp; {e(b_en)} — Wedding</title>
{og_meta(c, title=f"{g_en} & {b_en} are getting married", description=f"{dtxt} · {v['name']}")}
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;1,400&display=swap" rel="stylesheet">
<style>body{{margin:0;font-family:"Cormorant Garamond",Georgia,serif;color:#333;background:#fffdf9}}.page{{max-width:520px;margin:0 auto;padding:40px 24px;text-align:center}}.block{{padding:24px 0}}h1{{font-weight:400;font-size:34px;letter-spacing:1px}}h2{{font-size:13px;letter-spacing:4px;text-transform:uppercase;color:#a99}}img{{width:100%}}ul{{list-style:none;padding:0}}</style>
</head>
<body>
<div class="page">
  <img src="./main.svg" alt="">
  <p style="letter-spacing:4px;font-size:12px;color:#a99">TOGETHER WITH THEIR FAMILIES</p>
  <h1>{e(g_en)} <em>&amp;</em> {e(b_en)}</h1>
  <p>request the pleasure of your company<br>at the celebration of their marriage</p>
  <section class="block"><h2>When</h2><p>{e(dtxt)}</p></section>
  <section class="block"><h2>Where</h2><p><strong>{e(v["name"])}</strong>, {e(v["hall"])}<br>{e(v["address"])}<br>{e(v["tel"])}</p><p><a href="https://maps.google.com/?q={e(v["name"])}">Open in Google Maps</a> · <a href="https://map.kakao.com/link/search/{e(v["name"])}">Kakao Map</a></p></section>
  <section class="block"><h2>Parents</h2><p>{e(g["father"])} &amp; {e(g["mother"])}<br>{e(b["father"])} &amp; {e(b["mother"])}</p></section>
  {kor_block}
  {accs}
  <section class="block"><h2>RSVP</h2><p>Kindly reply by {(c["dt"] - timedelta(days=21)).strftime("%B %-d, %Y")}</p><a href="https://forms.gle/EvalFixtureRSVP">RSVP form</a></section>
  <p style="font-size:12px;color:#bbb">{e(c["vendor"])}</p>
</div>
</body>
</html>
'''
    return {"index.html": page, "main.svg": photo_svg(c, f'{g_en} & {b_en}')}


def t_notion_export(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    dtxt = date_text(c)
    accs = "".join(f'<li>{e(l)}</li>' for side in ("groom", "bride") for l in account_lines(c["accounts"][side], "relation"))
    page = f'''<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"/><title>💒 {e(g["name"])} ♥ {e(b["name"])} 결혼합니다</title>{og_meta(c)}<style>
body {{ line-height: 1.5; white-space: pre-wrap; font-family: ui-sans-serif, -apple-system, "Apple SD Gothic Neo", sans-serif; }}
.page-body {{ max-width: 600px; margin: 0 auto; padding: 24px; }}
h1 {{ font-size: 1.875rem; margin-top: 1.875rem; }} h2 {{ font-size: 1.5rem; margin-top: 1.5rem; }}
.callout {{ border-radius: 3px; padding: 1rem; background: rgb(241, 241, 239); }}
img {{ max-width: 100%; }} figure {{ margin: 1.25em 0; }}
</style></head>
<body><article id="2a1b3c4d-eval-{c["seq"]:04d}" class="page sans"><header><div class="page-header-icon"><span class="icon">💒</span></div><h1 class="page-title">{e(g["name"])} ♥ {e(b["name"])} 결혼합니다</h1></header><div class="page-body">
<figure id="f1" class="image"><a href="./main.svg"><img src="./main.svg"/></a></figure>
<h2 id="h1" class="">📅 언제</h2>
<p id="p1" class="">{e(dtxt)}</p>
<h2 id="h2" class="">📍 어디서</h2>
<p id="p2" class=""><strong>{e(v["name"])} {e(v["hall"])}</strong></p>
<p id="p3" class="">{e(v["address"])} (☎ {e(v["tel"])})</p>
<p id="p4" class=""><a href="https://map.naver.com/v5/search/{e(v["name"])}">네이버지도</a> · <a href="https://map.kakao.com/link/search/{e(v["name"])}">카카오맵</a></p>
<h2 id="h3" class="">💌 인사말</h2>
<div class="callout"><div style="font-size:1.5em"><span class="icon">🌿</span></div><div style="width:100%">저희 둘이 직접 만든 청첩장이에요. 예쁘게 봐주세요 :)<br/>{e(g["father"])} · {e(g["mother"])}의 {e(g["order"])} {e(g["name"][1:])}<br/>{e(b["father"])} · {e(b["mother"])}의 {e(b["order"])} {e(b["name"][1:])}</div></div>
<h2 id="h4" class="">💐 마음 전하실 곳</h2>
<ul id="l1" class="bulleted-list">{accs or "<li>축하해 주시는 마음이면 충분해요</li>"}</ul>
<h2 id="h5" class="">📸 사진</h2>
<figure class="image"><img src="../_assets/gallery-1.svg"/></figure><figure class="image"><img src="../_assets/gallery-2.svg"/></figure>
<p id="p9" class=""><em>주차는 건물 지하 2·3층, 2시간 무료예요.</em></p>
</div></article></body></html>
'''
    return {"index.html": page, "main.svg": photo_svg(c, f'{g["name"]} & {b["name"]}')}


TEMPLATES = {
    "classic-jquery": t_classic_jquery,
    "euckr-asp": t_euckr_asp,
    "table-legacy": t_table_legacy,
    "nextjs-ssr": t_nextjs_ssr,
    "csr-shell": t_csr_shell,
    "nuxt-ssr": t_nuxt_ssr,
    "site-builder": t_site_builder,
    "tailwind-semantic": t_tailwind_semantic,
    "styled-react": t_styled_react,
    "wordpress-theme": t_wordpress_theme,
    "bootstrap-2019": t_bootstrap_2019,
    "iframe-embed": t_iframe_embed,
    "image-only": t_image_only,
    "kakao-card": t_kakao_card,
    "english-intl": t_english_intl,
    "notion-export": t_notion_export,
}

TEMPLATE_NOTES = {
    "classic-jquery": "jQuery/slick PHP-era vendor page: div soup, <br>-heavy text, inline onclick handlers, Korean strings inside inline scripts, a month calendar grid full of distractor numbers.",
    "euckr-asp": "ASP-era page encoded in EUC-KR and served with charset=euc-kr; <font> tags, align attributes, &nbsp; padding.",
    "table-legacy": "XHTML transitional page laid out entirely with <table>/<td>; no <div> or <p> wrappers around the text.",
    "nextjs-ssr": "Next.js SSR: hashed CSS-module class names and a __NEXT_DATA__ JSON blob duplicating the content (with an ISO datetime).",
    "csr-shell": "Vite/CRA-style SPA: the HTML is an empty #root plus OpenGraph meta; content is fetched from data.json at runtime.",
    "nuxt-ssr": "Nuxt 2 SSR: data-v-* scoped attributes on every element and a window.__NUXT__ state script.",
    "site-builder": "Site-builder export: deep .inline-blocked/.fr-view nesting, inline styles, every word in its own <span>, lazy images with a data: pixel in src and the real URL in data-src.",
    "tailwind-semantic": "Modern semantic HTML with Tailwind utilities, JSON-LD Event, <time datetime>, <details> accordions for accounts, KakaoPay links.",
    "styled-react": "React SSR with styled-components hashes; the date is rendered as three bare numerals whose separators are CSS ::before content.",
    "wordpress-theme": "WordPress single-post markup with a guestbook whose comments mention other dates and names.",
    "bootstrap-2019": "Bootstrap 4 + jQuery: FontAwesome icons, Google Maps iframe, accounts inside a hidden modal, account numbers without hyphens, a reception on a different date/venue as a distractor.",
    "iframe-embed": "Outer shell page whose only content is an <iframe> pointing at content.html.",
    "image-only": "Every section (date, venue, accounts) is an image; the HTML carries only <img> tags and OpenGraph meta.",
    "kakao-card": "Messenger-style share card: key/value rows, accounts held in data-* attributes and display:none blocks toggled by a button.",
    "english-intl": "English-language invitation (romanised names, 'Saturday, October 17, 2026 at 1:30 PM'), optionally with a Korean summary block.",
    "notion-export": "Self-made Notion HTML export: emoji headings, callout blocks, <figure> images.",
}

# ---------------------------------------------------------------------------
# Dataset (expected values)
# ---------------------------------------------------------------------------


def expected_of(c: dict) -> dict:
    g, b, v = c["groom"], c["bride"], c["venue"]
    quirks = c["quirks"]
    url = url_of(c)
    if "short-link" in quirks:
        url = f"{BASE_URL}/eval/s/{short_code(c)}"
    elif "rewrite-url" in quirks:
        url = f"{BASE_URL}/eval/w/{short_code(c)}"
    thumb_file = "main.jpg.svg" if c["template"] == "euckr-asp" else "main.svg"
    tags = sorted(set(quirks) | {c["template"]})
    difficulty = "hard" if HARD_QUIRKS & set(quirks) else ("medium" if {"no-year", "split-numerals", "lazy-src", "guestbook-distractors", "reception-distractor", "extra-event-date", "hidden-accounts"} & set(quirks) else "easy")
    english_only = c["template"] == "english-intl" and "mixed-language" not in quirks
    groom_name = romanized(g["name"]) if english_only else g["name"]
    bride_name = romanized(b["name"]) if english_only else b["name"]
    aliases = [romanized(g["name"]), romanized(b["name"])] if (c["template"] == "english-intl" and not english_only) else []
    date_text_expected = DATE_STYLES["kor_full"](c["dt"]) if c["date_style"] == "split_numerals" else date_text(c)
    return {
        "id": c["id"],
        "url": url,
        "template": c["template"],
        "vendor": c["vendor"],
        "tags": tags,
        "difficulty": difficulty,
        "notes": TEMPLATE_NOTES[c["template"]],
        "expected": {
            "groom": groom_name,
            "bride": bride_name,
            "groomAliases": aliases[:1],
            "brideAliases": aliases[1:],
            "datetime": c["dt"].isoformat() if c["dt"] else None,
            "dateText": date_text_expected,
            "location": f'{v["name"]} {v["hall"]}',
            "locationKeywords": [v["name"]],
            "address": v["address"],
            "groomAccounts": c["accounts"]["groom"],
            "brideAccounts": c["accounts"]["bride"],
            "thumbnails": [f"{url_of(c)}{thumb_file}"],
        },
    }


def short_code(c: dict) -> str:
    return base64.urlsafe_b64encode(c["id"].encode()).decode().rstrip("=").lower()[:8]


# ---------------------------------------------------------------------------
# Shared assets and catalogue
# ---------------------------------------------------------------------------


def shared_assets() -> dict:
    files = {}
    for k in (1, 2, 3):
        rng = random.Random(k)
        hue = rng.randint(0, 360)
        files[f"gallery-{k}.svg"] = f'<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400"><rect width="600" height="400" fill="hsl({hue},35%,70%)"/><text x="50%" y="55%" text-anchor="middle" font-family="sans-serif" font-size="28" fill="#fff">gallery {k}</text></svg>\n'
    files["map.svg"] = '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="360"><rect width="600" height="360" fill="#e9eef2"/><path d="M0 200 L600 120" stroke="#fff" stroke-width="18"/><path d="M250 0 L320 360" stroke="#fff" stroke-width="14"/><circle cx="300" cy="170" r="14" fill="#e33"/><text x="320" y="176" font-family="sans-serif" font-size="20" fill="#333">예식장</text></svg>\n'
    files["btn-map.svg"] = '<svg xmlns="http://www.w3.org/2000/svg" width="240" height="64"><rect width="240" height="64" rx="8" fill="#fee500"/><text x="50%" y="58%" text-anchor="middle" font-family="sans-serif" font-size="22" fill="#191919">지도 보기</text></svg>\n'
    return files


def catalogue(dataset: list[dict]) -> str:
    rows = "".join(
        f'<tr><td><a href="{d["url"]}">{d["id"]}</a></td><td>{e(d["template"])}</td><td>{e(d["difficulty"])}</td><td>{e(", ".join(d["tags"]))}</td><td>{e(d["expected"]["groom"])} · {e(d["expected"]["bride"])}</td><td>{e(d["expected"]["dateText"] or "—")}</td></tr>'
        for d in dataset)
    return f'''<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>청모 파싱 평가 픽스처</title>
<meta name="robots" content="noindex">
<link rel="stylesheet" href="/assets/site.css">
<style>table{{border-collapse:collapse;width:100%;font-size:13px}}th,td{{border-bottom:1px solid var(--line);padding:6px 8px;text-align:left;vertical-align:top}}.wrap{{max-width:1100px}}</style>
</head>
<body>
<div class="wrap">
  <header class="topbar"><img src="/assets/icon.png" alt=""><a class="brand" href="/">청모</a><nav><a href="https://github.com/TaeBbong/chungmo-app">GitHub</a></nav></header>
  <h1>파싱 평가 픽스처</h1>
  <p class="meta">{len(dataset)}개의 가상 모바일 청첩장. 모든 인물·장소·계좌는 허구이며, 청모의 링크 파서 정확도를 측정하기 위해 다양한 벤더 페이지 구조를 흉내 냈습니다.</p>
  <div style="overflow-x:auto"><table><thead><tr><th>id</th><th>template</th><th>난이도</th><th>tags</th><th>신랑 · 신부</th><th>일시</th></tr></thead><tbody>{rows}</tbody></table></div>
  <p class="note">정답 데이터: <a href="https://github.com/TaeBbong/chungmo-app/blob/main/eval/dataset.json">eval/dataset.json</a> · 생성기: <code>eval/generate_fixtures.py</code></p>
</div>
</body>
</html>
'''


def hosting_rules(cases: list[dict]) -> dict:
    redirects, rewrites = [], []
    for c in cases:
        if "short-link" in c["quirks"]:
            redirects.append({"source": f"/eval/s/{short_code(c)}", "destination": f"/eval/{c['id']}/", "type": 301})
        if "rewrite-url" in c["quirks"]:
            rewrites.append({"source": f"/eval/w/{short_code(c)}", "destination": f"/eval/{c['id']}/index.html"})
    # Firebase matches the glob against the request path, so the bare and
    # the directory form of the URL both need the charset header — but only
    # the HTML, or the SVG next to it would be served as text/html too.
    headers = [{"source": src, "headers": [{"key": "Content-Type", "value": "text/html; charset=euc-kr"}]}
               for src in ("/eval/euckr-*", "/eval/euckr-*/", "/eval/euckr-*/index.html")]
    return {"redirects": redirects, "rewrites": rewrites, "headers": headers}


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    cases = build_cases()
    if OUT.exists():
        shutil.rmtree(OUT)
    (OUT / "_assets").mkdir(parents=True)
    for name, content in shared_assets().items():
        (OUT / "_assets" / name).write_text(content, encoding="utf-8")

    dataset = []
    for c in cases:
        files = TEMPLATES[c["template"]](c)
        d = OUT / c["id"]
        d.mkdir()
        for name, content in files.items():
            if isinstance(content, bytes):
                (d / name).write_bytes(content)
            else:
                (d / name).write_text(content, encoding="utf-8")
        dataset.append(expected_of(c))

    (OUT / "index.html").write_text(catalogue(dataset), encoding="utf-8")
    (ROOT / "eval" / "dataset.json").write_text(
        json.dumps({"version": 1, "baseUrl": BASE_URL, "generatedBy": "eval/generate_fixtures.py", "cases": dataset}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    (ROOT / "eval" / "hosting_rules.json").write_text(json.dumps(hosting_rules(cases), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"generated {len(dataset)} fixtures under {OUT}")


if __name__ == "__main__":
    main()
