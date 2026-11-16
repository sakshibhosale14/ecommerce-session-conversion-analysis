# E-commerce Session Conversion Analysis

*When do online store visits turn into purchases? An analysis of 110M clickstream events (Oct-Nov 2019).*

**Tools:** SQL (DuckDB), Python, Power BI

## Summary

Using 110M clickstream events from an online store (Oct-Nov 2019), I built visit sessions in SQL and measured when visits turn into purchases. Afternoon visits (14-16 UTC) convert about 35% worse than morning visits (5-9 UTC): 5.9% vs 9.2% in October. The gap repeated in November (34%, after excluding three anomalous days), and 95% confidence intervals put it at roughly 34-37% and 32-35%. I tested four possible explanations (bounces, product mix, new vs returning visitors, weekday vs weekend) and found that none accounts for the gap. The cause can’t be identified from this data, so I recommend checking traffic source and device next, then A/B testing a fix. Closing a quarter of the gap would be worth an estimated 2% of monthly revenue, as a scenario, not a forecast.

!\[Dashboard](dashboard/dashboard.png)

## Key results

||October|November (excl. Nov 15-17)|
|-|-|-|
|Sessions|7,796,425|8,871,205|
|Users|3,022,290|3,453,220|
|Session conversion|7.47%|5.90%|
|Morning conversion (5-9 UTC)|9.16%|7.16%|
|Afternoon conversion (14-16 UTC)|5.92%|4.74%|
|**Afternoon lower by**|**35.4%**|**33.8%**|
|95% confidence interval for the gap|34.0% to 36.7%|32.2% to 35.2%|
|Days with afternoon lower|31 of 31|27 of 27|

October has 31 days and cleaned November has 27, so session and user totals are not directly comparable. Conversion rates are.

## Questions investigated

1. Where do sessions turn into purchases, and when?
2. Is the time-of-day difference real, or an artifact of bounces, category mix or visitor type?
3. Does the finding hold in a second month?
4. How much would closing part of the gap be worth?

## Approach

1. **Sessions.** Built in SQL with a 30-minute inactivity rule (`LAG` plus a running `SUM`). The dataset's own session ID follows no clean time rule and disagrees with mine for about a quarter of users, so I used my own definition. The gap is 35.5%, 35.4% and 35.7% under 15-, 30- and 60-minute rules.
2. **Primary metric.** Session conversion (sessions with a purchase / all sessions). About half of purchase sessions have no cart event in the data, which makes cart-based funnel steps unreliable.
3. **Alternative explanations.** Compared the gap within each segment (see below).
4. **Second month.** Replicated the gap in November after excluding three anomalous days.
5. **Statistics.** 95% bootstrap confidence intervals that resample whole days, not sessions, because sessions from the same day are not independent.
6. **Opportunity sizing.** Scenarios, not a forecast (see below).

## Explanations ruled out

|Explanation|What I checked|Result|
|-|-|-|
|Afternoon visitors bounce more|Single-click sessions and events per session, hour 8 vs hour 15|No: 28.9% vs 30.9% single-click, and 6.0 vs 5.1 events per session|
|Different product mix|Category share in each window, and the gap within each category|No: electronics is 46.3% of afternoon and 44.8% of morning sessions, and the gap appears in every major category|
|More first-time visitors|New vs returning share in each window|No: 38.6% vs 38.0%, and the gap holds in both groups|
|Weekday vs weekend mix|Weekend share in each window, and the gap within each day type|No: weekend share 25.1% vs 26.4% in October, and the gap is 35.5% (weekdays) and 35.2% (weekends)|

## Data quality

* **Nov 15:** 212,519 cart sessions and zero purchases, which looks like a purchase-logging gap.
* **Nov 16-17:** traffic and conversion far outside the normal range (Nov 17 converted at 18.2% against roughly 4-6% nearby), cause unknown.
* All three days are excluded from the November comparison, and results are shown with and without them.
* 31.8% of events have no category, so category findings cover about three-quarters of sessions.
* 68,673 zero-price rows (views and carts only) are kept for the funnel and excluded from revenue.

## Opportunity sizing (scenarios, not a forecast)

If targeted changes closed part of the afternoon gap during 14-16 UTC:

|Share of gap closed|Extra monthly revenue|
|-|-|
|10%|about 0.8%|
|25%|about 2.0%|
|50%|about 3.9%|

The result is nearly identical in both months. It assumes extra purchases are worth the afternoon's usual average purchase.

## Recommendation

Find the cause before investing in a fix: check traffic source, device and region by hour in the company's own analytics, then A/B test any change aimed at the 14-16 window. Add an alert for days with normal cart activity but near-zero purchases.

## Limitations

* The cause of the gap is unexplained. This dataset has no traffic source, device or region.
* I chose the time windows after viewing the hourly chart, so replication in a second month is the main safeguard.
* Intervals rest on only 27-31 days per month.
* The timezone, currency and purchase quantity are not stated in the data.
* Two months of one store from 2019. The cause of the Nov 16-17 spike is unknown.

## Skills demonstrated

* **SQL (DuckDB):** window functions, CTEs, sessionization, conditional aggregation, joins, `UNION ALL`, `CROSS JOIN` with `UNNEST`
* **Analysis:** defining metrics, ruling out alternative explanations, replication in a second month, sensitivity checks
* **Statistics:** bootstrap confidence intervals that respect dependence in the data
* **Data quality:** quantifying missing values, handling zero prices, detecting and excluding abnormal days
* **Communication:** a one-page memo and a Power BI dashboard

## Repository

|Folder|Contents|
|-|-|
|`sql/`|12 numbered queries|
|`python/`|bootstrap confidence interval|
|`docs/`|`definitions.md` (every decision with evidence), `findings.md` (full results), `memo.md` (one-page memo)|
|`exports/`|small CSVs used by the dashboard|
|`dashboard/`|Power BI file and screenshot|

## Reproduce

1. Download the dataset from Kaggle (search "eCommerce behavior data from multi category store") and put `2019-Oct.csv` and `2019-Nov.csv` in `data/raw/`. The data is not included because the files are several GB.
2. `pip install duckdb`
3. From the repo root, run `sql/01` to `sql/12` in order. Files 03, 05, 06 and 10 are heavy and can take several minutes.
4. `python python/gap\_confidence\_interval.py`

## Data credit

Dataset: [eCommerce behavior data from multi category store](https://www.kaggle.com/datasets/mkechinov/ecommerce-behavior-data-from-multi-category-store) on Kaggle (user mkechinov), collected by the Open CDP project. Kaggle lists the license as "Data files © Original Authors". The raw data is not included in this repository; download it from Kaggle. The files in `exports/` are small aggregated summary tables.

