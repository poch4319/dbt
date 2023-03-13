{{ config(materialized='view') }}

with tripdata as 
(
  select *,
    row_number() over(partition by affiliated_base_number, pickup_datetime) as rn
  from {{ source('staging','fhv_tripdata') }}
  where affiliated_base_number is not null 
)
select
    -- identifiers
    {{ dbt_utils.surrogate_key(['affiliated_base_number', 'pickup_datetime']) }} as tripid,
    cast(affiliated_base_number as string) as affiliated_base_number,
    cast(pulocationid as integer) as pickup_locationid,
    cast(dolocationid as integer) as dropoff_locationid,
    
    -- timestamps
    cast(pickup_datetime as timestamp) as pickup_datetime,
    cast(dropoff_datetime as timestamp) as dropoff_datetime,
    
    -- trip info
    cast(sr_flag as string) as sf_flag

from tripdata
where rn = 1


-- dbt build --m <model.sql> --var 'is_test_run: false'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}