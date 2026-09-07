# Link parser eval — gemini-2.5-flash

- Run: 2026-09-07T21:54:30.630011 (baseline crawler, 58edbf9)
- Cases: 40 · errors: 0 · mean crawl 29 ms · mean model 5172 ms · prompt tokens 39711

## Overall

| core | groom | bride | datetime | location | accounts | thumbnail | groom (lenient) | bride (lenient) | account P / R |
|---|---|---|---|---|---|---|---|---|---|
| **63%** | 90% | 90% | 68% | 83% | 83% | 73% | 95% | 95% | 83% / 83% |

`core` = groom, bride, datetime, location and the full account set all correct — the schedule saves without manual fixes.

## Crawl coverage (model-independent ceiling)

Whether the crawler's text contains each expected value verbatim; a field missing here is unreachable for any prompt or model.

| group | n | all | groom | bride | date | location | accounts |
|---|---|---|---|---|---|---|---|
| overall | 40 | **68%** | 95% | 95% | 68% | 78% | 83% |
| bootstrap-2019 | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| classic-jquery | 5 | 100% | 100% | 100% | 100% | 100% | 100% |
| csr-shell | 3 | 0% | 100% | 100% | 0% | 0% | 33% |
| english-intl | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| euckr-asp | 2 | 0% | 0% | 0% | 0% | 0% | 0% |
| iframe-embed | 2 | 0% | 100% | 100% | 0% | 0% | 50% |
| image-only | 2 | 0% | 100% | 100% | 0% | 0% | 50% |
| kakao-card | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| nextjs-ssr | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| notion-export | 1 | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-ssr | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| site-builder | 3 | 100% | 100% | 100% | 100% | 100% | 100% |
| styled-react | 2 | 100% | 100% | 100% | 100% | 100% | 100% |
| table-legacy | 2 | 0% | 100% | 100% | 0% | 100% | 50% |
| tailwind-semantic | 3 | 33% | 100% | 100% | 33% | 100% | 100% |
| wordpress-theme | 2 | 100% | 100% | 100% | 100% | 100% | 100% |

## By difficulty

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| easy | 15 | 93% | 93% | 93% | 100% | 100% | 100% | 87% |
| hard | 11 | 0% | 82% | 82% | 0% | 36% | 36% | 45% |
| medium | 14 | 79% | 93% | 93% | 86% | 100% | 100% | 79% |

## By template

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| bootstrap-2019 | 3 | 33% | 67% | 67% | 67% | 100% | 100% | 100% |
| classic-jquery | 5 | 80% | 100% | 100% | 80% | 100% | 100% | 100% |
| csr-shell | 3 | 0% | 100% | 100% | 0% | 0% | 33% | 0% |
| english-intl | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 50% |
| euckr-asp | 2 | 0% | 0% | 0% | 0% | 100% | 0% | 100% |
| iframe-embed | 2 | 0% | 100% | 100% | 0% | 0% | 50% | 0% |
| image-only | 2 | 0% | 100% | 100% | 0% | 0% | 50% | 50% |
| kakao-card | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nextjs-ssr | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 67% |
| notion-export | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-ssr | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| site-builder | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 0% |
| styled-react | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| table-legacy | 2 | 0% | 100% | 100% | 0% | 100% | 50% | 100% |
| tailwind-semantic | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| wordpress-theme | 2 | 50% | 50% | 50% | 100% | 100% | 100% | 100% |

## By tag

| group | n | core | groom | bride | datetime | location | accounts | thumbnail |
|---|---|---|---|---|---|---|---|---|
| bootstrap-2019 | 3 | 33% | 67% | 67% | 67% | 100% | 100% | 100% |
| calendar-grid | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| classic-jquery | 5 | 80% | 100% | 100% | 80% | 100% | 100% | 100% |
| countdown | 1 | 0% | 100% | 100% | 0% | 100% | 100% | 100% |
| csr | 3 | 0% | 100% | 100% | 0% | 0% | 33% | 0% |
| csr-shell | 3 | 0% | 100% | 100% | 0% | 0% | 33% | 0% |
| css-modules | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 67% |
| data-attrs | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| details-accordion | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| emoji-headings | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| english | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 50% |
| english-intl | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 50% |
| euc-kr | 2 | 0% | 0% | 0% | 0% | 100% | 0% | 100% |
| euckr-asp | 2 | 0% | 0% | 0% | 0% | 100% | 0% | 100% |
| extra-event-date | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| font-tags | 1 | 0% | 0% | 0% | 0% | 100% | 0% | 100% |
| gallery-captions | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| guestbook-distractors | 2 | 50% | 50% | 50% | 100% | 100% | 100% | 100% |
| hidden-accounts | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| iframe | 2 | 0% | 100% | 100% | 0% | 0% | 50% | 0% |
| iframe-embed | 2 | 0% | 100% | 100% | 0% | 0% | 50% | 0% |
| image-only | 2 | 0% | 100% | 100% | 0% | 0% | 50% | 50% |
| inline-js-korean | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| inline-styles | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 0% |
| json-ld | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| kakao-card | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| kakaopay | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| lazy-src | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 0% |
| map-iframe | 2 | 50% | 50% | 50% | 100% | 100% | 100% | 100% |
| mixed-language | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 0% |
| modal-accounts | 3 | 33% | 67% | 67% | 67% | 100% | 100% | 100% |
| nbsp | 1 | 0% | 0% | 0% | 0% | 100% | 0% | 100% |
| next-data | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 67% |
| nextjs-ssr | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 67% |
| no-date | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| no-year | 2 | 0% | 100% | 100% | 0% | 100% | 100% | 100% |
| notion-export | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-data | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| nuxt-ssr | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| og-only | 3 | 0% | 100% | 100% | 0% | 0% | 33% | 0% |
| picture-srcset | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| reception-distractor | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| rewrite-url | 1 | 0% | 100% | 100% | 0% | 100% | 100% | 100% |
| sc-classes | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| scoped-attrs | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| self-made | 1 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| short-link | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| site-builder | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 0% |
| span-split | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 0% |
| split-numerals | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| styled-react | 2 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| table-legacy | 2 | 0% | 100% | 100% | 0% | 100% | 50% | 100% |
| table-only | 2 | 0% | 100% | 100% | 0% | 100% | 50% | 100% |
| tailwind-semantic | 3 | 100% | 100% | 100% | 100% | 100% | 100% | 100% |
| time-element | 2 | 50% | 50% | 50% | 100% | 100% | 100% | 100% |
| wordpress-theme | 2 | 50% | 50% | 50% | 100% | 100% | 100% | 100% |

## Cases

| id | template | difficulty | G | B | D | L | A | T | chars | ms | mismatches |
|---|---|---|---|---|---|---|---|---|---|---|---|
| bs-01 | bootstrap-2019 | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 2442 | 26+9489 |  |
| bs-02 | bootstrap-2019 | easy | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | 1822 | 22+7891 | groom: expected "허주원", got "주원"; bride: expected "황아름", got "아름" |
| bs-03 | bootstrap-2019 | medium | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | 1624 | 23+14917 | datetime: expected "2027-04-04T11:30:00+09:00", got "" |
| builder-01 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | 1790 | 20+6864 | thumbnail: expected one of {https://chung-mo.web.app/eval/builder-01/main.svg}, got "" |
| builder-02 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | 1418 | 27+5051 | thumbnail: expected one of {https://chung-mo.web.app/eval/builder-02/main.svg}, got "" |
| builder-03 | site-builder | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | 1288 | 23+3636 | thumbnail: expected one of {https://chung-mo.web.app/eval/builder-03/main.svg}, got "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" |
| euckr-01 | euckr-asp | hard | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ | 153 | 26+3162 | groom: expected "송태양", got ""; bride: expected "서유나", got ""; datetime: expected "2026-11-01T13:30:00+09:00", got ""; accounts: missing [groom\|수협\|16973090290061, groom\|하나\|42228871329236, groom\|신협\|64631545984245, bride\|대구\|86642650570721, bride\|신협\|75615679770931, bride\|신한\|110949645285], extra [] |
| euckr-02 | euckr-asp | hard | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ | 153 | 37+3513 | groom: expected "이재현", got ""; bride: expected "전세영", got ""; datetime: expected "2026-11-14T14:00:00+09:00", got ""; accounts: missing [groom\|하나\|86033657991073], extra [] |
| frame-01 | iframe-embed | hard | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | 66 | 24+1997 | datetime: expected "2027-04-10T12:00:00+09:00", got ""; location: expected keywords [라온컨벤션], got ""; accounts: missing [groom\|대구\|35080829886683, bride\|농협\|3421583169884], extra []; thumbnail: expected one of {https://chung-mo.web.app/eval/frame-01/main.svg}, got "" |
| frame-02 | iframe-embed | hard | ✓ | ✓ | ✗ | ✗ | ✓ | ✗ | 66 | 23+2043 | datetime: expected "2027-04-11T12:30:00+09:00", got ""; location: expected keywords [울산 로얄호텔], got ""; thumbnail: expected one of {https://chung-mo.web.app/eval/frame-02/main.svg}, got "" |
| hanul-01 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 3267 | 56+8134 |  |
| hanul-02 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 2458 | 44+5294 |  |
| hanul-03 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 2470 | 74+8671 |  |
| hanul-04 | classic-jquery | medium | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | 2247 | 30+9478 | datetime: expected "2026-10-24T12:30:00+09:00", got "" |
| hanul-05 | classic-jquery | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 2168 | 21+4736 |  |
| img-01 | image-only | hard | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | 211 | 24+3755 | datetime: expected "2027-04-25T13:00:00+09:00", got ""; location: expected keywords [빌라드지디 수서], got ""; accounts: missing [groom\|토스뱅크\|100048224645, bride\|케이뱅크\|100623762698], extra []; thumbnail: expected one of {https://chung-mo.web.app/eval/img-01/main.svg}, got "" |
| img-02 | image-only | hard | ✓ | ✓ | ✗ | ✗ | ✓ | ✓ | 211 | 21+2400 | datetime: expected "2027-05-01T13:30:00+09:00", got ""; location: expected keywords [엘리시안 컨벤션], got "" |
| intl-01 | english-intl | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 613 | 21+3130 |  |
| intl-02 | english-intl | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | 995 | 21+5578 | thumbnail: expected one of {https://chung-mo.web.app/eval/intl-02/main.svg}, got "" |
| kakao-01 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1519 | 125+5868 |  |
| kakao-02 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 822 | 36+4523 |  |
| kakao-03 | kakao-card | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 508 | 24+3038 |  |
| nextcard-01 | nextjs-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 2432 | 23+6473 |  |
| nextcard-02 | nextjs-ssr | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1865 | 21+6569 |  |
| nextcard-03 | nextjs-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | 1549 | 26+5112 | thumbnail: expected one of {https://chung-mo.web.app/eval/nextcard-03/main.svg}, got "" |
| nuxtcard-01 | nuxt-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1823 | 26+6242 |  |
| nuxtcard-02 | nuxt-ssr | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1466 | 27+5263 |  |
| sc-01 | styled-react | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1002 | 26+4217 |  |
| sc-02 | styled-react | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1325 | 25+6474 |  |
| self-01 | notion-export | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 876 | 21+4971 |  |
| spa-01 | csr-shell | hard | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | 15 | 16+2005 | datetime: expected "2026-12-27T13:30:00+09:00", got ""; location: expected keywords [빌라드지디 수서], got ""; accounts: missing [groom\|부산\|27106841392679, bride\|수협\|54107582985324], extra []; thumbnail: expected one of {https://chung-mo.web.app/eval/spa-01/main.svg}, got "" |
| spa-02 | csr-shell | hard | ✓ | ✓ | ✗ | ✗ | ✗ | ✗ | 15 | 18+1823 | datetime: expected "2027-01-02T11:00:00+09:00", got ""; location: expected keywords [엘리시안 컨벤션], got ""; accounts: missing [groom\|우리\|94442488455348, groom\|신한\|110244815862, groom\|카카오뱅크\|3333214389560, bride\|하나\|91755377119108, bride\|카카오뱅크\|3333745988127, bride\|신한\|110965185509], extra []; thumbnail: expected one of {https://chung-mo.web.app/eval/spa-02/main.svg}, got "" |
| spa-03 | csr-shell | hard | ✓ | ✓ | ✗ | ✗ | ✓ | ✗ | 15 | 23+1672 | datetime: expected "2027-01-03T11:00:00+09:00", got ""; location: expected keywords [메종드블랑], got ""; thumbnail: expected one of {https://chung-mo.web.app/eval/spa-03/main.svg}, got "" |
| table-01 | table-legacy | hard | ✓ | ✓ | ✗ | ✓ | ✗ | ✓ | 121 | 31+2150 | datetime: expected "2026-11-15T15:00:00+09:00", got ""; accounts: missing [groom\|우체국\|4878731795505, bride\|새마을금고\|20523780949506], extra [] |
| table-02 | table-legacy | hard | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | 125 | 22+3351 | datetime: expected "2026-11-21T16:00:00+09:00", got "" |
| tw-01 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1008 | 22+6088 |  |
| tw-02 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 814 | 21+4035 |  |
| tw-03 | tailwind-semantic | easy | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 898 | 28+5254 |  |
| wp-01 | wordpress-theme | medium | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | 1757 | 27+5249 |  |
| wp-02 | wordpress-theme | medium | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | 1897 | 19+6796 | groom: expected "이민석", got "민석"; bride: expected "김지원", got "지원" |
