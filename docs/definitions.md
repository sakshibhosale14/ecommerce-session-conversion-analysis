# Definitions and Decisions

Every metric definition and data-handling choice in this project, with the evidence behind it.

## Data

- **Source:** eCommerce behavior data from a multi-category online store (Kaggle, dataset by mkechinov), October and November 2019.
- **Size:** October 42,448,764 events; November 67,501,979 events.
- **Event types present:** `view`, `cart`, `purchase`. (There is no `remove_from_cart` in these files.)
- **Tools:** DuckDB (SQL on Parquet files), Power BI Desktop.
- **Timezone:** The file does not state one. Hours are labelled UTC and are not interpreted as local time.
- **Currency:** Not stated in the dataset, so revenue figures carry no currency symbol.

## 1. Session

A session is one visit: a user's events with no gap longer than **30 minutes**. A new session starts at a user's first event, or after a gap strictly greater than 30 minutes. A session is identified by `(user_id, session_num)`.

**Why not the dataset's own `user_session` column?** I compared the two:

| | Sessions (October) |
|---|---|
| My 30-minute rule | 7,796,425 |
| Dataset `user_session` | 9,244,421 |

- The two methods agree on the session count for 74.3% of users (2,245,475 of 3,022,290). The dataset has more sessions for 23.4% and fewer for 2.3%.
- The dataset's ID does not follow a time threshold. The share of consecutive click pairs where it changes rises gradually with the gap: 1.6% (under 1 min), 7.4% (1-5 min), 28.2% (5-10 min), 49.6% (10-20 min), 62.3% (20-30 min), 96.1% (over 30 min).
- Its rule is undocumented, so I used a transparent, reproducible definition instead.

**Sensitivity check (October):** the morning-vs-afternoon gap under different session rules.

| Gap rule | Sessions | Afternoon conversion lower than morning by |
|---|---|---|
| 15 min | 8,132,642 | 35.5% |
| 30 min | 7,797,354 | 35.4% |
| 60 min | 7,525,695 | 35.7% |

The finding does not depend on the 30-minute choice. The 30-minute row of this rebuild shows 7,797,354 sessions, 929 more than the main table (7,796,425, about 0.01%). I did not investigate the cause. Conversion and gap figures are unchanged at the precision reported.

## 2. Primary metric: session conversion

**Session conversion = sessions with at least one purchase / all sessions.** October: 582,524 / 7,796,425 = **7.47%**.

**Why not a cart-based funnel?**

- 303,200 of 582,524 purchase sessions (52%) contain no cart event in the same session.
- Only 22,044 of those (7.3%) had an earlier cart for the same product.
- That share rose through the month (3.8% in Oct 1-7 to 9.9% in Oct 22-31), so part of the gap comes from missing history before 1 October. At least part of it is still unexplained after the last week of October, so I can't say how many cart events the data simply does not record.

Cart-based step rates (view-to-cart, cart-to-purchase) are therefore **secondary, lower-confidence diagnostics**. For reference, same-session cart-to-purchase in October was 279,324 / 524,300, about 53.3%.

## 3. Funnel steps and sessions without a view

Steps: view, cart, purchase. 1,698 sessions (0.02%) have no view event. They are kept and ignored.

## 4. Missing category and brand

- `category_code` is missing on 13,515,609 events (31.8%); `brand` on 6,113,008 (14.4%).
- Rows are not removed. For category analysis, each session's **main category** is the most common first-level category among its events, or `unknown` if it has none. 25.6% of October sessions are `unknown`, so category findings cover about three-quarters of sessions.
- Very small categories (for example medicine, 3,360 sessions) are not interpreted.

## 5. Zero prices

68,673 rows have a price of 0: 68,523 views and 150 carts, and no purchases. They are kept for the funnel (a view without a price is still a view) and excluded from revenue.

## 6. Revenue

Revenue = the sum of `price` over purchase events with price > 0. The dataset has no quantity column, so each purchase event counts as one unit.

## 7. Excluded days in November (15-17)

| Date | Sessions | Sessions with a cart | Sessions with a purchase | Conversion |
|---|---|---|---|---|
| Nov 14 | 415,091 | 74,807 | 17,272 | 4.16% |
| **Nov 15** | 593,416 | 212,519 | **0** | 0.0% |
| Nov 16 | 757,013 | 191,223 | 50,687 | 6.7% |
| **Nov 17** | 738,121 | 195,522 | 134,102 | **18.17%** |
| Nov 18 | 401,781 | 45,819 | 22,204 | 5.53% |

- **Nov 15:** carts were recorded but no purchases. This looks like a purchase-logging gap. That is an inference, not something I confirmed.
- **Nov 16-17:** traffic and conversion far above neighbouring days. The cause is unknown.
- **Decision:** the "clean November" excludes Nov 15-17. Results are shown both ways.

| | Morning (5-9 UTC) | Afternoon (14-16 UTC) | Afternoon lower by |
|---|---|---|---|
| October | 9.16% | 5.92% | 35.4% |
| November, all days | 7.54% | 5.83% | 22.7% |
| November, excluding Nov 15-17 | 7.16% | 4.74% | 33.8% |

October has 31 days and clean November has 27, so session, user and revenue totals are not directly comparable. Conversion and revenue per purchase are.

## 8. Time windows

Morning = hours 5-9 UTC; afternoon = hours 14-16 UTC. **I chose these windows after looking at the hourly conversion chart**, so they are data-driven. Replication on November (a month not used to pick the windows) is the main protection against overfitting, but the exact window boundaries were not pre-specified.

## 9. "First in Oct"

`session_num = 1` means a user's first session seen in that month. It does not mean a new customer, because someone may have shopped in September.

## 10. Confidence intervals

95% bootstrap intervals for the afternoon-vs-morning gap (10,000 resamples, seed 42, `python/gap_confidence_interval.py`):

| | Gap | 95% CI | Days with afternoon lower |
|---|---|---|---|
| October | 35.4% | 34.0% to 36.7% | 31 of 31 |
| November, excluding Nov 15-17 | 33.8% | 32.2% to 35.2% | 27 of 27 |

Whole **days** are resampled, not sessions, because sessions from the same day and users are not independent. With only 27-31 days per month the intervals are rough, and they say nothing about the cause of the gap.

## Open questions

- Why afternoon conversion is lower is not explained. Bounces, category mix and new-vs-returning visitors were tested and ruled out.
- Why November conversion is lower than October's, and what happened on Nov 16-17, is unknown.
- The dataset's session rule is undocumented.
