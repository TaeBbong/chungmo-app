# Link parser eval — gemini-2.5-flash

- Run: 2026-09-14T20:05:06.867909 (pre-submission rerun)
- Cases: 40 · errors: 0 · mean crawl 252 ms · mean model 5946 ms · prompt tokens 32740

## Overall

| core | groom | bride | datetime | location | accounts | thumbnail | groom (lenient) | bride (lenient) | account P / R |
|---|---|---|---|---|---|---|---|---|---|
| **85%** | 100% | 100% | 90% | 95% | 93% | 100% | 100% | 100% | 93% / 93% |

`core` = groom, bride, datetime, location and the full account set all correct — the schedule saves without manual fixes.

## Crawl coverage (model-independent ceiling)

Whether the crawler's text contains each expected value verbatim; a field missing here is unreachable for any prompt or model.

| group | n | all | groom | bride | date | location | accounts |
|---|---|---|---|---|---|---|---|
| overall | 40 | **90%** | 100% | 100% | 95% | 95% | 93% |
| bootstrap-2019 | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| classic-jquery | 5 | 100% | 100% | 100% | 100% | 100% | 100% |
| csr-shell | 3 | 33% | 100% | 100% | 100% | 100% | 33% |
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

## By difficulty

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| easy | 15 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| hard | 11 | 64% | 100% | 100% | 82% | 82% | 73% | 100% |
| medium | 14 | 86% | 100% | 100% | 86% | 100% | 100% | 100% |

## By template

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| bootstrap-2019 | 3 | 67% | 100% | 100% | 67% | 100% | 100% | 100% |
| classic-jquery | 5 | 80% | 100% | 100% | 80% | 100% | 100% | 100% |
| csr-shell | 3 | 33% | 100% | 100% | 100% | 100% | 33% | 100% |
| english-intl | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| euckr-asp | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| iframe-embed | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| image-only | 2 | 0% | 100% | 100% | 0% | 0% | 50% | 100% |
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
| bootstrap-2019 | 3 | 67% | 100% | 100% | 67% | 100% | 100% | 100% |
| calendar-grid | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| classic-jquery | 5 | 80% | 100% | 100% | 80% | 100% | 100% | 100% |
| countdown | 1 | 0% | 100% | 100% | 0% | 100% | 100% | 100% |
| csr | 3 | 33% | 100% | 100% | 100% | 100% | 33% | 100% |
| csr-shell | 3 | 33% | 100% | 100% | 100% | 100% | 33% | 100% |
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
| image-only | 2 | 0% | 100% | 100% | 0% | 0% | 50% | 100% |
| inline-js-korean | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| inline-styles | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| json-ld | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| kakao-card | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| kakaopay | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| lazy-src | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| map-iframe | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| mixed-language | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| modal-accounts | 3 | 67% | 100% | 100% | 67% | 100% | 100% | 100% |
| nbsp | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| next-data | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nextjs-ssr | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| no-date | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| no-year | 2 | 0% | 100% | 100% | 0% | 100% | 100% | 100% |
| notion-export | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-data | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-ssr | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| og-only | 3 | 33% | 100% | 100% | 100% | 100% | 33% | 100% |
| picture-srcset | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| reception-distractor | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| rewrite-url | 1 | 0% | 100% | 100% | 0% | 100% | 100% | 100% |
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
| bs-01 | bootstrap-2019 | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1273 | 194+10199 |  |
| bs-02 | bootstrap-2019 | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1110 | 197+5907 |  |
| bs-03 | bootstrap-2019 | medium | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | 1048 | 220+8190 | datetime: expected "2027-04-04T11:30:00+09:00", got "" |
| builder-01 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1048 | 175+8872 |  |
| builder-02 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 922 | 167+7647 |  |
| builder-03 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 869 | 168+3737 |  |
| euckr-01 | euckr-asp | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 725 | 194+7320 |  |
| euckr-02 | euckr-asp | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 567 | 478+5125 |  |
| frame-01 | iframe-embed | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1531 | 940+5216 |  |
| frame-02 | iframe-embed | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1452 | 460+4027 |  |
| hanul-01 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1808 | 244+9452 |  |
| hanul-02 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1321 | 233+5650 |  |
| hanul-03 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1270 | 302+6666 |  |
| hanul-04 | classic-jquery | medium | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | 1234 | 190+7904 | datetime: expected "2026-10-24T12:30:00+09:00", got "" |
| hanul-05 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1173 | 191+6126 |  |
| img-01 | image-only | hard | ✓ | ✓ | ✗ | ✗ | ✗ | ✓ | 624 | 185+3339 | datetime: expected "2027-04-25T13:00:00+09:00", got ""; location: expected keywords [빌라드지디 수서], got ""; accounts: missing [groom\|토스뱅크\|100048224645, bride\|케이뱅크\|100623762698], extra [] |
| img-02 | image-only | hard | ✓ | ✓ | ✗ | ✗ | ✓ | ✓ | 624 | 163+2654 | datetime: expected "2027-05-01T13:30:00+09:00", got ""; location: expected keywords [엘리시안 컨벤션], got "" |
| intl-01 | english-intl | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 814 | 170+4055 |  |
| intl-02 | english-intl | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1004 | 186+5593 |  |
| kakao-01 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 850 | 195+7551 |  |
| kakao-02 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 644 | 782+5005 |  |
| kakao-03 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 562 | 499+3884 |  |
| nextcard-01 | nextjs-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 2244 | 174+9267 |  |
| nextcard-02 | nextjs-ssr | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1808 | 180+5554 |  |
| nextcard-03 | nextjs-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1654 | 218+7048 |  |
| nuxtcard-01 | nuxt-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1598 | 151+6191 |  |
| nuxtcard-02 | nuxt-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1368 | 413+5121 |  |
| sc-01 | styled-react | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 782 | 158+5192 |  |
| sc-02 | styled-react | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 898 | 205+7248 |  |
| self-01 | notion-export | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 816 | 187+5500 |  |
| spa-01 | csr-shell | hard | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | 235 | 167+3705 | accounts: missing [groom\|부산\|27106841392679, bride\|수협\|54107582985324], extra [] |
| spa-02 | csr-shell | hard | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | 230 | 155+3352 | accounts: missing [groom\|우리\|94442488455348, groom\|신한\|110244815862, groom\|카카오뱅크\|3333214389560, bride\|하나\|91755377119108, bride\|카카오뱅크\|3333745988127, bride\|신한\|110965185509], extra [] |
| spa-03 | csr-shell | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 227 | 165+3354 |  |
| table-01 | table-legacy | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 675 | 216+5454 |  |
| table-02 | table-legacy | hard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 605 | 148+3433 |  |
| tw-01 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1440 | 179+7316 |  |
| tw-02 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1251 | 213+6470 |  |
| tw-03 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1303 | 199+6572 |  |
| wp-01 | wordpress-theme | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1255 | 188+6145 |  |
| wp-02 | wordpress-theme | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1296 | 259+6824 |  |
