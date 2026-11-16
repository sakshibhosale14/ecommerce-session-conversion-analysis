# Findings: E-commerce Session Conversion Analysis

## Headline

**Afternoon sessions (14-16 UTC) convert about a third worse than morning sessions (5-9 UTC), in both October and November 2019.** The gap is not explained by bounces, product category mix, new-vs-returning visitors, or weekday-vs-weekend mix. Its cause cannot be determined from this dataset.

## Key numbers

| | October | November (excl. Nov 15-17) |
|---|---|---|
| Days | 31 | 27 |
| Sessions | 7,796,425 | 8,871,205 |
| Users | 3,022,290 | 3,453,220 |
| Session conversion | 7.47% | 5.90% |
| Revenue | 229,957,502 | 193,969,781 |
| Revenue per purchase | 394.76 | 370.75 |

Totals are not directly comparable because of the different month lengths. Conversion and revenue per purchase are. Definitions and exclusions are in `definitions.md`.

## Finding 1: volume and conversion peak at different times

- The busiest hour is 15 UTC (506,440 sessions in October) and converts at 5.89%.
- Hours 5-9 UTC convert at about 9.1-9.2%.
- October: morning 9.16% vs afternoon 5.92%, so the afternoon is **35.4% lower**.

## Finding 2: it replicated in November

| | Morning | Afternoon | Afternoon lower by |
|---|---|---|---|
| October | 9.16% | 5.92% | 35.4% |
| November, excluding Nov 15-17 | 7.16% | 4.74% | 33.8% |
| November, all days (distorted) | 7.54% | 5.83% | 22.7% |

The all-days November figure is distorted by three abnormal days (see Finding 6). The gap is stable under 15-, 30- and 60-minute session rules (35.5%, 35.4%, 35.7%).

**Confidence intervals** (bootstrap, resampling days): October 35.4%, 95% CI 34.0% to 36.7%; November (excl. Nov 15-17) 33.8%, 95% CI 32.2% to 35.2%. The afternoon converted worse than the morning on **every day**: 31 of 31 in October and 27 of 27 in clean November. Each month has only 27-31 days, so the intervals are rough.

## Finding 3: four explanations ruled out

**Bounces.** Afternoon visitors are not leaving faster. Hour 8 vs hour 15: single-click sessions 30.9% vs 28.9%; average events per session 5.1 vs 6.0.

**Category mix.** The mix is almost the same in both periods (electronics 44.8% of morning sessions, 46.3% of afternoon), and the gap appears inside every major category:

| Category | Morning | Afternoon |
|---|---|---|
| electronics | 11.84% | 7.25% |
| appliances | 9.22% | 6.55% |
| computers | 7.35% | 4.66% |
| unknown | 6.89% | 4.55% |
| apparel | 3.41% | 3.04% |

**New vs returning.** First-seen-in-October sessions are 38.0% of morning and 38.6% of afternoon sessions, and the gap holds in both groups:

| | Morning | Afternoon |
|---|---|---|
| First seen in October | 6.73% | 4.54% |
| Later sessions | 10.64% | 6.78% |

**Weekday vs weekend.** The weekend share is about the same in both windows (26.4% vs 25.1% in October; 24.1% vs 22.9% in November), and the gap holds within weekdays and weekends: October 35.5% and 35.2%, November 32.6% and 37.2%.

## Finding 4: conversion depends heavily on category

Electronics is 45.2% of sessions and converts at 9.56%. Apparel converts at 3.19% and furniture at 3.73%. About a quarter of sessions (25.6%) have no category, so category findings cover roughly three-quarters of traffic.

## Finding 5: returning visitors convert better

In the morning window, later sessions converted at 10.64% against 6.73% for first-seen sessions. "First seen in October" does not mean a new customer.

## Finding 6: data problems found and handled

- **Nov 15:** 593,416 sessions and 212,519 with a cart, but **zero purchases**. This looks like a purchase-logging gap (an inference).
- **Nov 16-17:** traffic and conversion far above normal (Nov 17: 18.17% conversion against roughly 4-6% on nearby days). Cause unknown.
- **Cart events:** 52% of purchase sessions have no cart event in the same session, and only 7.3% of those had an earlier cart for the same product. Session conversion is therefore the primary metric.

## Opportunity sizing (scenario, not forecast)

If targeted changes closed a share of the afternoon gap during hours 14-16 UTC:

| Share of gap closed | October extra revenue | % of month | November (clean) extra revenue | % of month |
|---|---|---|---|---|
| 10% | 1,805,510 | 0.79% | 1,512,978 | 0.78% |
| 25% | 4,513,776 | 1.96% | 3,782,444 | 1.95% |
| 50% | 9,027,552 | 3.93% | 7,564,888 | 3.90% |

Assumptions: extra purchases are worth the afternoon's usual average purchase; revenue is one price per purchase event; only hours 14-16 are included. The scenarios scale linearly by construction, so they are one finding expressed three ways, not three findings.

## Recommendation

Do not invest in a fix yet. The data cannot say whether the gap comes from the site experience or from who shops in the afternoon, and no site change would close a gap that comes from audience mix. First look for the cause in data this file does not contain (traffic source, device, region), then A/B test any targeted change before rolling it out. A 25% improvement in the 14-16 window would be worth about 2% of monthly revenue, so the upside is real but modest.

## Limitations

- The cause of the afternoon gap is unexplained.
- Confidence intervals rest on only 27-31 days per month.
- The morning and afternoon windows were chosen after viewing the hourly chart. November replication is the main safeguard.
- The timezone is not stated, so no local-time story (lunchtime, after work) can be told.
- Two months of data from one store in 2019. November conversion is lower than October's for unknown reasons.
- Revenue has no quantity column and no stated currency.
- Nov 16-17 are excluded without a known cause.
