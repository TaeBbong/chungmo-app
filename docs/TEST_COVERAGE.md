<!-- docs/TEST_COVERAGE.md -->

# Test Coverage

How coverage is measured in this project, why the obvious command gives the
wrong number, and where the thin spots currently are.

---

## 1. Running it

```bash
fvm dart run tool/coverage.dart            # measure and report
fvm dart run tool/coverage.dart --html     # also render coverage/html (needs `brew install lcov`)
fvm dart run tool/coverage.dart --no-run   # re-report an existing coverage/lcov.info
fvm dart run tool/coverage.dart --min=60   # exit non-zero below a threshold, for CI
```

The report lands in `coverage/lcov.info`, which is gitignored. The
**Coverage Gutters** extension reads it directly and paints covered and
uncovered lines in the editor margin — the most useful way to read it while
writing a test.

---

## 2. Why not just `flutter test --coverage`

Because the number it prints is too high, and wrong in the direction that
matters.

`flutter test --coverage` records coverage for the libraries the test run
actually **loaded**. A file that no test imports is never loaded, so it does
not appear in `lcov.info` at all — it is missing from the report rather than
scored zero. The files with no tests are exactly the files that disappear,
so they leave the denominator and the percentage climbs.

Measured on this repository the day the tooling was added:

| | Lines | Coverage |
| --- | --- | --- |
| `flutter test --coverage`, as-is | 1774 / 2457 | **72.2%** |
| Every library loaded, generated code excluded | 1737 / 3213 | **54.1%** |

(Those are the figures from the day this was set up. The current total is
57.9%; run the tool for today's.)

29 of 109 files were absent from the first report, among them `main.dart`,
`detail_page.dart`, `stats_page.dart`, both theme files and most use cases.

There is no flag that fixes this. `--coverage-package` filters by *package*
name, which is a different question. The established workaround is to
generate a test that imports every library, which is what the
[`full_coverage`](https://pub.dev/packages/full_coverage) package exists to
do; `tool/coverage.dart` does it inline so the repository takes no extra
dependency for it.

Two details that script handles:

- **`part` files cannot be imported.** `*.g.dart` and `*.freezed.dart` are
  `part of` their library, and importing one is a compile error. They are
  skipped, and covered through the library that owns them.
- **The helper is deleted after the run.** Committed, it would go stale the
  moment a file is added — and a stale helper under-reports silently, which
  is the problem it exists to solve.

---

## 3. What is excluded

Generated code: `*.g.dart`, `*.freezed.dart`, `*.config.dart`, `*.mocks.dart`
and `firebase_options.dart`. Counting it measures freezed and injectable, not
our tests. The filtered set is written back to `coverage/lcov.info`, so the
editor gutters and `genhtml` show the same files these numbers describe.

Here the difference is small (54.5% → 54.1%) because the generated files are
mostly data classes whose covered share resembles the rest. It is kept
because the number should mean one thing.

---

## 4. Where it stands

57.9% overall, by area:

| Area | Coverage |
| --- | --- |
| `core/navigation`, `data/mapper`, `data/models` | 100% |
| `core/utils` | 90.5% |
| `presentation/bloc` | 88.6% |
| `data/repositories` | 87.7% |
| `presentation/widgets` | 80.5% |
| `domain/entities` | 76.9% |
| `data/sources` | 76.6% |
| `core/services` | 72.6% |
| `presentation/pages` | 33.0% |
| `domain/usecases` | 10.0% |
| `core/analytics` | 7.4% |
| `presentation/theme` | 6.5% |
| `main.dart`, `core/env.dart` | 0% |

Low is not automatically bad. `presentation/theme` (0/142) and `main.dart`
(0/55) are declarations and bootstrap: there is no behaviour to assert, and
testing them would pin down formatting rather than conduct. The nine
`domain/usecases` files are three lines each and do nothing but forward to a
repository that is tested at 87.7%.

The four gaps this doc first named are closed (#66). Writing those tests
turned up three defects that no amount of reading had: a notification rule
that could never fire for a wedding tomorrow and a branch that could never
run at all (#67), and a preference write that only worked because `main`
happened to read one first.

What is left, in the order it is worth doing:

| File | Uncovered | Why it matters |
| --- | --- | --- |
| `presentation/pages` | 773 lines | The largest remaining block. `create_page.dart` alone carries the share-intent handling, the clipboard peek and the coach-mark tour. |
| `core/analytics/firebase_analytics_service.dart` | 18 lines | Thin over the SDK; worth it only if the event names start carrying logic. |
| `data/sources/remote/cloud_function_impl.dart` | 16 lines | The legacy GPT backend, which `main` never selects. Not worth a test while that is true. |

---

## 5. What the number is for

To find the next test to write, not to hit a target. A percentage says
nothing about whether the assertions are any good — this repository has had
two tests that passed against the behaviour they were supposed to forbid, and
both counted as coverage until they were rewritten to actually discriminate.

Read the per-area table and the no-coverage list; ignore the headline.
