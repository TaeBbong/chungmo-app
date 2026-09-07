<!-- docs/FIREBASE_HOSTING.md -->

# Static Pages on Firebase Hosting: Policies and Fixtures

How chungmo serves its privacy policy, terms of service and the parsing
evaluation fixtures from `https://chung-mo.web.app`, using the Firebase
project the app already depends on. Written as a working reference: each
section is concept → the actual configuration in this repo → why it is
shaped that way.

---

## 1. The problem: URLs we do not control

Until this change the app's "이용 약관" and "개인정보 처리방침" rows opened two
public Notion pages. That worked, but it tied a store-listing requirement to
a third-party workspace: the URL shape is Notion's, the page needs
JavaScript to render (a plain `curl` returns only "JavaScript must be
enabled"), and nothing in the repository recorded the wording that users
were actually shown.

The parsing evaluation (see `docs/PARSING_EVAL.md`) had the same problem in
a sharper form. Real invitation links expire after the wedding, so a
benchmark built on them silently rots; the fixtures must live on a host we
own, at addresses that stay stable for years.

Firebase Hosting fits both needs because the project already exists
(`chung-mo`, the same one behind Firebase AI Logic, Analytics and App Check),
the CLI is already authenticated, and static hosting is free at this scale.

---

## 2. What Firebase Hosting is

Firebase Hosting is a static CDN with a small routing layer:

- A **site** (`chung-mo`) has a default domain `<site>.web.app`. One project
  can own several sites; we use the default one.
- A **deploy** uploads a local directory (the `public` root) as an
  immutable **version** and then **releases** it. Rollback is a matter of
  releasing an earlier version from the console.
- Routing is declarative in `firebase.json`: clean URLs, trailing-slash
  policy, redirects, rewrites and per-path response headers. There is no
  server code involved for any of this.

The mental model is "an S3 bucket with a good `.htaccess`". Anything that
needs computation belongs in Cloud Functions, which this site does not use.

---

## 3. The configuration in this repo

`firebase.json` already carried the FlutterFire section that `flutterfire
configure` maintains. Hosting is a sibling key:

```json
"hosting": {
  "site": "chung-mo",
  "public": "hosting/public",
  "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
  "cleanUrls": true,
  "trailingSlash": false,
  "headers": [
    { "source": "/assets/**",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=604800" }] },
    { "source": "**/*.html",
      "headers": [{ "key": "Cache-Control", "value": "public, max-age=300" }] }
  ]
}
```

Line by line:

- `public: hosting/public` — the deploy root. It is deliberately not the
  Flutter `web/` directory: that one is the Flutter Web scaffold, and mixing
  a hand-written site into it would make `flutter build web` and the
  hosting deploy fight over the same files.
- `cleanUrls: true` — `privacy.html` is served at `/privacy`, and a request
  for `/privacy.html` is redirected to the clean form. The app's constants
  therefore point at extension-less URLs that will survive a later move to
  a different generator.
- `trailingSlash: false` — `/privacy/` redirects (301) to `/privacy`.
  Without an explicit policy Firebase returned 404 for the slash form, which
  is exactly the kind of link a store reviewer might type by hand.
- `headers` — assets (icon, stylesheet) cache for a week, HTML for five
  minutes. Policy pages change rarely but must propagate quickly when they
  do; the CDN honours these values.

The site itself is three hand-written pages plus a stylesheet:

```
hosting/public/
├── index.html      # landing: store badges, feature summary, policy links
├── privacy.html    # 개인정보처리방침, wording carried over verbatim
├── terms.html      # 이용약관, wording carried over verbatim
├── 404.html        # Firebase serves this for unknown paths automatically
└── assets/
    ├── site.css    # shared styles, light/dark via prefers-color-scheme
    └── icon.png    # 192px app icon, also used as favicon
```

The pages are plain HTML on purpose. There is no build step, so the deploy
is reproducible from a clean checkout with nothing but the Firebase CLI, and
a reviewer can read the policy text in the diff.

The app side is a two-line change in `lib/core/utils/constants.dart`:

```dart
static const String privacyUrl = "https://chung-mo.web.app/privacy";
static const String termsUrl = "https://chung-mo.web.app/terms";
```

`AboutPage` already opened these constants through `url_launcher`, so no
presentation code moved.

---

## 4. Deploying

```bash
firebase deploy --only hosting --project chung-mo
```

`--only hosting` matters: the same `firebase.json` describes the FlutterFire
apps, and a bare `firebase deploy` would try to touch every configured
product. The command uploads only files whose hash changed, finalizes a
version and releases it; the whole round trip is a few seconds.

A quick post-deploy check that covers the routing rules:

```bash
for p in / /privacy /terms /privacy/ /missing; do
  printf "%s -> " "$p"
  curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" "https://chung-mo.web.app$p"
done
# /         -> 200
# /privacy  -> 200
# /terms    -> 200
# /privacy/ -> 301 https://chung-mo.web.app/privacy
# /missing  -> 404
```

There is also a local emulator (`firebase emulators:start --only hosting`)
that applies the same `firebase.json` rules on `localhost:5000`; it is the
right place to test new redirects or headers before they go live.

---

## 5. How the policy text was migrated

Notion renders its public pages client-side, so the text had to be
extracted from a rendered DOM rather than from the HTML response. Headless
Chrome does this in one command:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new --disable-gpu --virtual-time-budget=20000 \
  --dump-dom "https://wegange.notion.site/<page-id>" > page.html
```

`--virtual-time-budget` lets the page's scripts run to completion before the
DOM is dumped. Notion marks every block with a `notion-<type>-block` class
(`notion-sub_header-block`, `notion-numbered_list-block`, ...), so a small
parser that walks those classes in document order yields a clean list of
headings, paragraphs and list items to transcribe into semantic HTML.

Two things were normalised while transcribing, without changing wording:

- The privacy page kept its last six sections inside a single Notion *code*
  block (a formatting accident). They are now ordinary `<h2>` sections.
- The terms page's numbered items are real `<ol>` lists, so screen readers
  and copy/paste see the numbering.

The wording itself is unchanged and still dated 2025-03-10. It predates image
and text parsing (which upload the invitation to Gemini via Firebase AI
Logic) and the Analytics/Crashlytics integration, so the content is due for
a legal review; that is tracked separately from this hosting work.

---

## 6. Why not the alternatives

| Option | Why not |
|---|---|
| Keep Notion | JS-only rendering, URL owned by a third party, wording not versioned with the app. |
| GitHub Pages | A second deployment identity and DNS story for a project that already lives in one Firebase project. |
| In-app WebView with bundled HTML | Store listings need an HTTPS URL; a bundled page cannot be linked from Play Console or App Store Connect. |
| Flutter Web build of the app | Megabytes of runtime to show two pages of text, and the eval fixtures need raw HTML anyway. |

---

## 7. Checklist for adding a page

1. Add `hosting/public/<name>.html`; link `/assets/site.css` and reuse the
   `topbar`/`footer` markup so the pages stay consistent.
2. If the page needs a redirect or a special header, add it under
   `hosting.redirects` / `hosting.headers` in `firebase.json`.
3. `firebase emulators:start --only hosting` and open `localhost:5000/<name>`.
4. `firebase deploy --only hosting --project chung-mo`.
5. Reference the page from the app through a constant in
   `lib/core/utils/constants.dart`, never as a string literal in a widget.
