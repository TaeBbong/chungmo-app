# Link parser eval — gemini-2.5-flash

- Run: 2026-09-15T21:16:38.733033 (100% run: year inference + csr json, image-only removed)
- Cases: 38 · errors: 0 · mean crawl 259 ms · mean model 6509 ms · prompt tokens 37087

## Overall

| core | groom | bride | datetime | location | accounts | thumbnail | groom (lenient) | bride (lenient) | account P / R |
|---|---|---|---|---|---|---|---|---|---|
| **100%** | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% / 100% |

`core` = groom, bride, datetime, location and the full account set all correct — the schedule saves without manual fixes.

## Crawl coverage (model-independent ceiling)

Whether the crawler's text contains each expected value verbatim; a field missing here is unreachable for any prompt or model.

| group | n | all | groom | bride | date | location | accounts |
|---|---|---|---|---|---|---|---|
| overall | 38 | **100%** | 100% | 100% | 100% | 100% | 100% |
| bootstrap-2019 | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| classic-jquery | 5 | 100% | 100% | 100% | 100% | 100% | 100% |
| csr-shell | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| english-intl | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| euckr-asp | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| iframe-embed | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| kakao-card | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| nextjs-ssr | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| notion-export | 1 | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-ssr | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| site-builder | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| styled-react | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| table-legacy | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| tailwind-semantic | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| wordpress-theme | 2 | 100% | 100% | 100% | 100% | 100% | 100% |

## By difficulty

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| easy | 15 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| hard | 9 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| medium | 14 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |

## By template

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| bootstrap-2019 | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| classic-jquery | 5 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| csr-shell | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| english-intl | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| euckr-asp | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| iframe-embed | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| kakao-card | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nextjs-ssr | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| notion-export | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-ssr | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| site-builder | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| styled-react | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| table-legacy | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| tailwind-semantic | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| wordpress-theme | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |

## By tag

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| bootstrap-2019 | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| calendar-grid | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| classic-jquery | 5 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| countdown | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| csr | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| csr-shell | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| css-modules | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| data-attrs | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| details-accordion | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| emoji-headings | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| english | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| english-intl | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| euc-kr | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| euckr-asp | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| extra-event-date | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| font-tags | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| gallery-captions | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| guestbook-distractors | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| hidden-accounts | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| iframe | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| iframe-embed | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| inline-js-korean | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| inline-styles | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| json-ld | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| kakao-card | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| kakaopay | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| lazy-src | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| map-iframe | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| mixed-language | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| modal-accounts | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nbsp | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| next-data | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nextjs-ssr | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| no-date | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| no-year | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| notion-export | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-data | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-ssr | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| og-only | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| picture-srcset | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| reception-distractor | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| rewrite-url | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| sc-classes | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| scoped-attrs | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| self-made | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| short-link | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| site-builder | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| span-split | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| split-numerals | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| styled-react | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| table-legacy | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| table-only | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| tailwind-semantic | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| time-element | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| wordpress-theme | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |

## Cases

| id | template | difficulty | G | B | D | L | A | T | chars | ms | mismatches |
|---|---|---|---|---|---|---|---|---|---|---|---|
| bs-01 | bootstrap-2019 | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1273 | 214+13889 |  |
| bs-02 | bootstrap-2019 | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1110 | 166+5368 |  |
| bs-03 | bootstrap-2019 | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1048 | 27+5979 |  |
| builder-01 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1048 | 175+9627 |  |
| builder-02 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 922 | 172+7407 |  |
| builder-03 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 869 | 175+4503 |  |
| euckr-01 | euckr-asp | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 725 | 228+6861 |  |
| euckr-02 | euckr-asp | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 567 | 608+5077 |  |
| frame-01 | iframe-embed | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1531 | 531+6102 |  |
| frame-02 | iframe-embed | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1452 | 464+5706 |  |
| hanul-01 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1808 | 210+7588 |  |
| hanul-02 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1321 | 198+6828 |  |
| hanul-03 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1270 | 557+7768 |  |
| hanul-04 | classic-jquery | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1234 | 119+5504 |  |
| hanul-05 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1173 | 187+4757 |  |
| intl-01 | english-intl | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 814 | 173+4222 |  |
| intl-02 | english-intl | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1004 | 210+6926 |  |
| kakao-01 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 850 | 188+6859 |  |
| kakao-02 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 644 | 275+6407 |  |
| kakao-03 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 562 | 239+4855 |  |
| nextcard-01 | nextjs-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 2244 | 166+9588 |  |
| nextcard-02 | nextjs-ssr | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1808 | 168+6767 |  |
| nextcard-03 | nextjs-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1654 | 272+6528 |  |
| nuxtcard-01 | nuxt-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1598 | 374+7426 |  |
| nuxtcard-02 | nuxt-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1368 | 186+7335 |  |
| sc-01 | styled-react | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 782 | 159+5163 |  |
| sc-02 | styled-react | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 898 | 237+8931 |  |
| self-01 | notion-export | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 816 | 160+6264 |  |
| spa-01 | csr-shell | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1252 | 510+2927 |  |
| spa-02 | csr-shell | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1763 | 445+6272 |  |
| spa-03 | csr-shell | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 971 | 680+4915 |  |
| table-01 | table-legacy | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 675 | 186+6948 |  |
| table-02 | table-legacy | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 605 | 156+4591 |  |
| tw-01 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1440 | 186+7609 |  |
| tw-02 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1251 | 192+4043 |  |
| tw-03 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1303 | 227+6493 |  |
| wp-01 | wordpress-theme | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1255 | 199+5474 |  |
| wp-02 | wordpress-theme | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1296 | 242+7864 |  |
