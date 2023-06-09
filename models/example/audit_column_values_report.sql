-- Old model query
{% set old_etl_relation_query %}
    select
	    id
        , amount
        , created_date
    from {{ ref('example_legacy_model') }}
{% endset %}

-- New model query
{% set new_etl_relation_query %}
    select
	    id
        , amount
        , created_date
    from {{ ref('example_refactored_model') }}
{% endset %}

-- Run audit macro
--> db_connection can be ['snowflake' or 'postgres']
{{ column_values_report(
    db_connection = 'postgres'
    , primary_key = 'id'
    , model_name = 'ExampleModel'
    , old_query = old_etl_relation_query
    , new_query = new_etl_relation_query
    , columns_to_compare = ['id', 'amount', 'created_date']
) }}
