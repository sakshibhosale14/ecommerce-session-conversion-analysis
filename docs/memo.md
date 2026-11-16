# Memo: Afternoon Visits Convert a Third Worse Than Morning Visits

**To:** E-commerce Growth / Product team
**From:** Sakshi Bhosale
**Re:** Session conversion by time of day, October-November 2019 (110M events)

## Bottom line

Sessions in the afternoon window (14-16 UTC) convert about **a third worse** than sessions in the morning window (5-9 UTC): 35% lower in October and 34% lower in November. The pattern is consistent, but its cause cannot be found in this data. I recommend diagnosing the cause before investing in a fix.

## What I found

- **Overall:** 7.47% of October sessions ended in a purchase (7.8M sessions, 3.0M users). Cleaned November was 5.90%.
- **Time of day:** October morning 9.16% vs afternoon 5.92%. November (excluding three abnormal days) morning 7.16% vs afternoon 4.74%. The gaps (35.4% and 33.8%) have narrow 95% confidence intervals (34.0-36.7% and 32.2-35.2%), and the afternoon was lower on every day of both months (58 of 58).
- **Volume and conversion peak at different times.** The busiest hour (15 UTC) converts at 5.89%, while hours 5-9 convert at about 9.2%.
- **Category matters.** Electronics (45% of sessions) converts at 9.6%; apparel at 3.2%.

## What I ruled out

| Explanation | Result |
|---|---|
| Afternoon visitors bounce more | No. They click more (6.0 vs 5.1 events per session), and fewer leave after one click (28.9% vs 30.9%) |
| Different product mix | No. Mix is nearly identical (electronics 46.3% vs 44.8%), and the gap appears in every major category |
| More first-time visitors | No. The new/returning mix is the same (38.6% vs 38.0%), and the gap appears in both groups |
| Weekday/weekend mix | No. The weekend share is similar (25.1% vs 26.4% in October), and the gap holds within weekdays and weekends |

## Opportunity (a scenario, not a forecast)

If targeted changes closed **25%** of the afternoon gap during 14-16 UTC, I estimate **about 2% more monthly revenue** in both months (roughly 4.5M in October). Closing 10% would add about 0.8%, and 50% about 3.9%. This assumes the extra purchases are worth the afternoon's usual average purchase.

## Recommendation

1. **Find the cause first.** This dataset has no traffic source, device or region. Check those by hour in your own analytics, and convert the UTC windows to the store's local time.
2. **Then test, don't assume.** If the gap persists within segments, A/B test one change aimed at the 14-16 window, with session conversion as the success metric and a sample size set in advance.
3. **Monitor purchase logging.** On Nov 15 the data shows 212,519 cart sessions and zero purchases, which suggests a tracking failure. An alert for "carts normal, purchases near zero" would catch this.

## Caveats

- The cause of the gap is unexplained; if it reflects who shops in the afternoon, no site change would close it.
- Nov 15-17 are excluded: Nov 15 looks like a purchase-logging gap, and Nov 16-17 had abnormal traffic and conversion for unknown reasons.
- I chose the time windows after viewing the hourly chart. Replication in November is the main safeguard.
- Revenue has no quantity or stated currency, and the file's timezone is not stated.

## Method

Sessions are built in SQL (DuckDB) with a 30-minute inactivity rule. The result holds under 15- and 60-minute rules (gap 35.5% and 35.7%). Confidence intervals come from bootstrap resampling of days. Details are in `definitions.md` and `findings.md`; the dashboard is in Power BI.
