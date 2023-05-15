{% macro column_match_report(old_query, new_query, primary_key, columns_to_compare, model_name) -%}

with
    old_query as ({{ old_query }})

    , new_query as ({{ new_query }})

    {% for column in columns_to_compare %}

    , {{ column }}_joined as (
        select
            coalesce(old_query.{{ primary_key }}, new_query.{{ primary_key }}) as {{ primary_key }}
            , old_query.{{ column }} as old_query_value
            , new_query.{{ column }} as new_query_value
            , case
                when old_query.{{ column }} = new_query.{{ column }} then 'perfect_match'
                when old_query.{{ column }} is null and new_query.{{ column }} is null then 'both_are_null'
                when old_query.{{ primary_key }} is null then 'missing_from_old'
                when new_query.{{ primary_key }} is null then 'missing_from_new'
                when old_query.{{ column }} is null then 'null_in_old_only'
                when new_query.{{ column }} is null then 'null_in_new_only'
                when old_query.{{ column }} != new_query.{{ column }} then 'values_do_not_match'
            end as match_status
        from old_query
        full outer join new_query on
            old_query.{{ primary_key }} = new_query.{{ primary_key }}
    )

    , {{ column }}_aggregated as (
        select
            '{{ column }}' as column_name
            , match_status
            , count(*) as count_records
        from {{ column }}_joined
        group by column_name, match_status
    )

    , {{ column }}_cte as (
        select
            column_name
            , match_status
            , count_records
            , round(100.0 * count_records / sum(count_records) over (), 2) as percent_of_total
        from {{ column }}_aggregated
    )

    {% endfor %}

    , report_union as (
        select * from {{ columns_to_compare[0] }}_cte
        {% for column in columns_to_compare[1:] %}
        union all
        select * from {{ column }}_cte
        {% endfor %}
    )

    , pivoted_report as (
        select
            column_name
            , case
                when match_status = 'perfect_match'
                    then percent_of_total
                else 0
            end as perfect_match_pct
            , case
                when match_status = 'perfect_match'
                    then count_records
                else 0
            end as perfect_match_count
            , case
                when match_status = 'both_are_null'
                    then percent_of_total
                else 0
            end as both_are_null_pct
            , case
                when match_status = 'both_are_null'
                    then count_records
                else 0
            end as both_are_null_count
            , case
                when match_status = 'missing_from_old'
                    then percent_of_total
                else 0
            end as missing_from_old_pct
            , case
                when match_status = 'missing_from_old'
                    then count_records
                else 0
            end as missing_from_old_count
            , case
                when match_status = 'missing_from_new'
                    then percent_of_total
                else 0
            end as missing_from_new_pct
            , case
                when match_status = 'missing_from_new'
                    then count_records
                else 0
            end as missing_from_new_count
            , case
                when match_status = 'null_in_old_only'
                    then percent_of_total
                else 0
            end as null_in_old_pct
            , case
                when match_status = 'null_in_old_only'
                    then count_records
                else 0
            end as null_in_old_count
            , case
                when match_status = 'null_in_new_only'
                    then percent_of_total
                else 0
            end as null_in_new_pct
            , case
                when match_status = 'null_in_new_only'
                    then count_records
                else 0
            end as null_in_new_count
            , case
                when match_status = 'values_do_not_match'
                    then percent_of_total
                else 0
            end as values_dont_match_pct
            , case
                when match_status = 'values_do_not_match'
                    then count_records
                else 0
            end as values_dont_match_count
        from report_union
    )

    , agg_values as (
        select
            column_name
            , sum(perfect_match_pct) + sum(both_are_null_pct) as total_match_ratio
            , sum(perfect_match_pct) as perfect_match
            , sum(both_are_null_pct) as both_are_null
            , sum(missing_from_old_pct) as missing_from_old
            , sum(missing_from_new_pct) as missing_from_new
            , sum(null_in_old_pct) as null_in_old_only
            , sum(null_in_new_pct) as null_in_new_only
            , sum(values_dont_match_pct) as values_do_not_match
        from pivoted_report
        group by column_name
    )

    , current_date_and_model_name as (
        select
            '{{ model_name }}' as model_name
            , current_date as run_date
            , *
        from agg_values
    )

select * from current_date_and_model_name

{% endmacro %}
