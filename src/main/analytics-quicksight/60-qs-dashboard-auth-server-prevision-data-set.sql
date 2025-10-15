----------------------------------------------------------------------------------------
-- - This query computes the calls by day 90° percentile for every client and use the 
--   120% of it as the maximum expected calls limit. The percentile is computed 
--   separately for every day of the week (Saturday, Sunday, Monday, ...).
-- - This query also guarantee a "dense" result set: a result set without missing 
--   row, return a row with value (calls_by_day) 0 instead of no row for a day 
--   without call.
-- - Computes the expected limits on all the data history but returns number of calls, 
--   expected limit and violations only for today and last 60 days before today.
----------------------------------------------------------------------------------------
with 
  -- Sum the calls received in a day by each client.
  sum_by_day as (
    select 
      cast( minute_slot as date) as date_slot,
      date_part(dayofweek, cast( minute_slot as date) ) as day_of_week,
      maudc.consumer_name,
      maudc.client_name,
      sum( maudc.calls_quantity ) as calls_by_day
    from
      views.mv_00_auth_usage__data__calls maudc 
    group by
      date_slot,
      consumer_name,
      client_name
  ),
  -- Use number of calls summarized by date ("sum_by_day" CTE) to compute maximum 
  -- call expected limit as the 120% of 90° percentile of calls made by a client 
  -- in the past.
  computed_limit as (
    select
      consumer_name,
      client_name,
      day_of_week,
      1.2 * (PERCENTILE_cont(0.9) WITHIN GROUP (ORDER BY calls_by_day)) as max_limit
    from
      sum_by_day
    group by
      consumer_name, 
      client_name, 
      day_of_week
    order by
      consumer_name,
      client_name,
      day_of_week
  ),
  -- We want a record for every client for every day to have an easier integration 
  -- with QuickSight Visuals.
  -- This table compute all the consumers and clients name's
  all_consumer_client_name as (
    select
      consumer_name,
      client_name
    from 
      views.mv_00_auth_usage__data__calls
    group by
      consumer_name,
      client_name
  ),
  -- We need a limit for every day of the week and every client, we set that 
  -- limit, by default, to 0.
  all_needed_limits as (
    select
      n.consumer_name,
      n.client_name,
      d.num as day_of_week,
      0 as max_limit
    from
      all_consumer_client_name n,
      ( select 0 as num union all select 1 as num union all select 2 as num union all select 3 as num union all select 4 as num union all select 5 as num union all select 6 as num ) d
  ),
  -- Put together computed limit and a row for every limit we need to know 
  all_limits_union as (
    select consumer_name, client_name, day_of_week, max_limit from all_needed_limits
    union all
    select consumer_name, client_name, day_of_week, max_limit from computed_limit
  ),
  -- Compute a table with a row for each client+consumer pair and for every day of the week.
  -- max_limit column get its value from "computed_limit" table if the client+consumer+day_of_week
  -- triple exist in that table; otherwise get 0.
  all_limits as (
    select 
      consumer_name, 
      client_name, 
      day_of_week,
      max( max_limit ) as max_limit
    from 
      all_limits_union
    group by
      consumer_name, 
      client_name, 
      day_of_week
  ),
  -- Used to compute "Last N days" with N minor than 999
  digits AS (
    SELECT 0 AS d UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
    SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
  ),
  -- Define a result set of two column: 
  -- - "generated_date" that is today and 60 days before;
  -- - "day_of_week" the day of the week ( 0 to 6 )
  last_period as (
    SELECT
      (GETDATE() - seq.i)::DATE AS generated_date,
      date_part(dayofweek, (GETDATE() - seq.i)::DATE) as day_of_week
    FROM ( -- Compute all the numbers formed by 3 decimal digit
      SELECT 100 * d1.d + 10 * d2.d + d3.d AS i
      FROM digits d1, digits d2, digits d3
      where i <= 60
    ) AS seq
    ORDER BY
      generated_date DESC
  ),
  -- Define the number of rows that will be returned from the query.
  -- One row for every last 61 days (60 plus today) and for each consumer+client couple 
  --  present in the data history.
  all_consumer_client_name_last_period as (
    select
      n.consumer_name,
      n.client_name,
      p.generated_date as date_slot,
      p.day_of_week 
    from
      all_consumer_client_name n,
      last_period p
  ),
  -- Extract the data for each row computed in "all_consumer_client_name_last_period" CTE,
  -- join each row with its expected limit ( "all_limits" CTE ) and
  -- join with actual calls by day. If no calls are registered for that client in that date
  -- the result got 0 calls_by_day in reason of "left join" and "coalesce".
  sum_by_day_with_limits as (
    select
      ad.date_slot,
      ad.day_of_week,
      ad.consumer_name,
      ad.client_name,
      coalesce( d.calls_by_day, 0) as calls_by_day,
      l.max_limit
    from
      all_consumer_client_name_last_period ad
      join all_limits l on l.consumer_name = ad.consumer_name  
                       and l.client_name = ad.client_name 
                       and l.day_of_week = ad.day_of_week
      left join sum_by_day d on d.consumer_name = ad.consumer_name  
                            and d.client_name = ad.client_name 
                            and d.date_slot = ad.date_slot 
  ),
  -- Enrich the prepared result set ("sum_by_day_with_limits" CTE) with columns that point out
  -- the presence of some limit violations. So the result set is easier to visualize.
  calls_and_limits_and_violations as (
    select
      *,
      (
        case
          when calls_by_day > max_limit then 'UPPER'
          else 'OK'
        end
      )
       as status,
      (
        case
          when calls_by_day > max_limit then 2
          else 0
        end
      )
       as status_severity
    from
      sum_by_day_with_limits
  )
-- The global query, guarantee column ordering and add another column for easier visualization.
-- - "today_severity": repeat for each date the value of the today's "status_severity" column;
--                     useful for feature like "show me the history of the clients that have 
--                      issues now".
select
  max( 
    case 
	    when CURRENT_DATE = date_slot then status_severity 
	    else -1 
	end 
  ) over ( partition by consumer_name, client_name ) as today_severity,
  consumer_name,
  client_name,
  date_slot,
  max_limit,
  calls_by_day,
  status,
  status_severity
from 
  calls_and_limits_and_violations
order by 
  consumer_name,
  client_name,
  date_slot
