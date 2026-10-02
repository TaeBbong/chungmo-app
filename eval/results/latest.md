# Link parser eval — gemini-2.5-flash

- Run: 2026-10-02T12:08:10.476883 (image fallback (#51), review fixes)
- Cases: 40 · errors: 0 · mean crawl 290 ms · mean model 5884 ms · prompt tokens 43063

## Overall

| core | groom | bride | datetime | location | venue | accounts | thumbnail | groom (lenient) | bride (lenient) | account P / R |
|---|---|---|---|---|---|---|---|---|---|---|
| **100%** | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% / 100% |

`core` = groom, bride, datetime, location and the full account set all correct — the schedule saves without manual fixes.

## Crawl coverage (model-independent ceiling)

Whether the crawler's text contains each expected value verbatim; a field missing here is unreachable for any prompt or model.

| group | n | all | groom | bride | date | location | accounts |
|---|---|---|---|---|---|---|---|
| overall | 40 | **95%** | 100% | 100% | 95% | 95% | 98% |
| bootstrap-2019 | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| classic-jquery | 5 | 100% | 100% | 100% | 100% | 100% | 100% |
| csr-shell | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| english-intl | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| euckr-asp | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| iframe-embed | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| image-only | 2 | 0% | 100% | 100% | 0% | 0% | 50% |
| kakao-card | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| nextjs-ssr | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| notion-export | 1 | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-ssr | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| site-builder | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| styled-react | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| table-legacy | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| tailwind-semantic | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| wordpress-theme | 2 | 100% | 100% | 100% | 100% | 100% | 100% |

## By tier

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| image | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| text | 38 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |

## By difficulty

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| easy | 15 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| hard | 11 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
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
| image-only | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
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
| image-only | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
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
| bs-01 | bootstrap-2019 | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1273 | 165+9756 |  |
| bs-02 | bootstrap-2019 | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1110 | 200+6767 |  |
| bs-03 | bootstrap-2019 | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1048 | 329+6488 |  |
| builder-01 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1048 | 175+7402 |  |
| builder-02 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 922 | 434+5541 |  |
| builder-03 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 869 | 191+2919 |  |
| euckr-01 | euckr-asp | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 725 | 178+5863 |  |
| euckr-02 | euckr-asp | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 567 | 427+4515 |  |
| frame-01 | iframe-embed | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1531 | 448+4831 |  |
| frame-02 | iframe-embed | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1452 | 505+5209 |  |
| hanul-01 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1808 | 204+9945 |  |
| hanul-02 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1321 | 193+4288 |  |
| hanul-03 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1270 | 280+6010 |  |
| hanul-04 | classic-jquery | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1234 | 361+6285 |  |
| hanul-05 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1173 | 334+5204 |  |
| img-01 | image-only | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 624 | 336+5987 |  |
| img-02 | image-only | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 624 | 146+6063 |  |
| intl-01 | english-intl | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 814 | 299+4192 |  |
| intl-02 | english-intl | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1004 | 189+4675 |  |
| kakao-01 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 850 | 206+6674 |  |
| kakao-02 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 644 | 502+3881 |  |
| kakao-03 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 562 | 163+4989 |  |
| nextcard-01 | nextjs-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 2244 | 214+8437 |  |
| nextcard-02 | nextjs-ssr | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1808 | 167+6501 |  |
| nextcard-03 | nextjs-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1654 | 192+6813 |  |
| nuxtcard-01 | nuxt-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1598 | 187+7138 |  |
| nuxtcard-02 | nuxt-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1368 | 318+6796 |  |
| sc-01 | styled-react | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 782 | 203+6539 |  |
| sc-02 | styled-react | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 898 | 125+8925 |  |
| self-01 | notion-export | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 816 | 372+3571 |  |
| spa-01 | csr-shell | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1252 | 544+3582 |  |
| spa-02 | csr-shell | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1763 | 1003+6657 |  |
| spa-03 | csr-shell | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 971 | 518+4100 |  |
| table-01 | table-legacy | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 675 | 184+4978 |  |
| table-02 | table-legacy | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 605 | 202+4403 |  |
| tw-01 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1440 | 189+6970 |  |
| tw-02 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1251 | 180+5523 |  |
| tw-03 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1303 | 178+5680 |  |
| wp-01 | wordpress-theme | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1255 | 387+4800 |  |
| wp-02 | wordpress-theme | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1296 | 183+6476 |  |
