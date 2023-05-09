{% macro column_values_report(old_query, new_query, primary_key, columns_to_compare, model_name, db_connection) -%}

with
    old_query as ({{ old_query }})

    , new_query as ({{ new_query }})

    {% for column in columns_to_compare %}

    , {{ column }}_old as (
        select
            '{{ column }}' as column_name
            {% if db_connection == 'postgres' or db_connection == 'redshift' %}
            , pg_typeof({{ column }}) as old_data_type
            {% endif %}
            {% if db_connection == 'snowflake' %}
            , typeof({{ column }}::variant) as old_data_type
            {% endif %}

        from old_query
    )

    , {{ column }}_new as (
        select
            '{{ column }}' as column_name
            {% if db_connection == 'postgres' or db_connection == 'redshift' %}
            , pg_typeof({{ column }}) as new_data_type
            {% endif %}
            {% if db_connection == 'snowflake' %}
            , typeof({{ column }}::variant) as new_data_type
            {% endif %}

        from new_query
    )

    , {{ column }}_old_agg as (
        select
            '{{ column }}' as column_name
            , count(distinct {{ column }}) as old_distinct_count
            , min({{ column }})::text as old_min_value
            , max({{ column }})::text as old_max_value
        from old_query
    )

    , {{ column }}_new_agg as (
        select
            '{{ column }}' as column_name
            , count(distinct {{ column }}) as new_distinct_count
            , min({{ column }})::text as new_min_value
            , max({{ column }})::text as new_max_value
        from new_query
    )

    , {{ column }}_old_null as (
        select
            '{{ column }}' as column_name
            , count(*) as old_null_entries
        from old_query
        where {{ column }} is null
    )

    , {{ column }}_new_null as (
        select
            '{{ column }}' as column_name
            , count(*) as new_null_entries
        from new_query
        where {{ column }} is null
    )

    , {{ column }}_joined as (
        select
            {{ column }}_old.column_name
            , {{ column }}_old.old_data_type
            , {{ column }}_new.new_data_type
            , {{ column }}_old_agg.old_distinct_count
            , {{ column }}_new_agg.new_distinct_count
            , {{ column }}_old_null.old_null_entries
            , {{ column }}_new_null.new_null_entries
            , {{ column }}_old_agg.old_min_value
            , {{ column }}_new_agg.new_min_value
            , {{ column }}_old_agg.old_max_value
            , {{ column }}_new_agg.new_max_value
        from {{ column }}_old
        left join {{ column }}_new on
            {{ column }}_old.column_name = {{ column }}_new.column_name
        left join {{ column }}_old_agg on
            {{ column }}_old.column_name = {{ column }}_old_agg.column_name
        left join {{ column }}_new_agg on
            {{ column }}_old.column_name = {{ column }}_new_agg.column_name
        left join {{ column }}_old_null on
            {{ column }}_old.column_name = {{ column }}_old_null.column_name
        left join {{ column }}_new_null on
            {{ column }}_old.column_name = {{ column }}_new_null.column_name
        where {{ column }}_old.old_data_type is not null
            and {{ column }}_new.new_data_type is not null
    )

    {% endfor %}

    , report_union as (
        select * from {{ columns_to_compare[0] }}_joined
        {% for column in columns_to_compare[1:] %}
        union
        select * from {{ column }}_joined
        {% endfor %}
    )

    , current_date_and_model_name as (
        select
            '{{ model_name }}' as model_name
            , current_date as run_date
            , *
        from report_union
    )

select * from current_date_and_model_name

{% endmacro %}
