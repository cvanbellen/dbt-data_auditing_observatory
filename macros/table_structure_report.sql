{% macro table_structure_report(full_path_to_old, full_path_to_new, date_column=None) -%}


{% set old_db = full_path_to_old.split('.')[0] %}
{% set old_schema = full_path_to_old.split('.')[1] %}
{% set old_table = full_path_to_old.split('.')[2] %}

{% set new_db = full_path_to_new.split('.')[0] %}
{% set new_schema = full_path_to_new.split('.')[1] %}
{% set new_table = full_path_to_new.split('.')[2] %}


with
    old_columns_query as (
        select distinct column_name
        from information_schema.columns
        where lower(table_catalog) like lower('{{ old_db }}')
            and lower(table_schema) like lower('{{ old_schema }}')
            and lower(table_name) like lower('{{ old_table }}')
    )

    , new_columns_query as (
        select distinct column_name
        from information_schema.columns
        where lower(table_catalog) like lower('{{ new_db }}')
            and lower(table_schema) like lower('{{ new_schema }}')
            and lower(table_name) like lower('{{ new_table }}')
    )

    , missing_from_old as (
        select
            'Old' as model
            , listagg(new_columns_query.column_name, '; ') as missing_columns
        from new_columns_query
        left join old_columns_query on
            new_columns_query.column_name = old_columns_query.column_name
        where old_columns_query.column_name is null
    )

    , missing_from_new as (
        select
            'New' as model
            , listagg(old_columns_query.column_name, '; ') as missing_columns
        from old_columns_query
        left join new_columns_query on
            old_columns_query.column_name = new_columns_query.column_name
        where new_columns_query.column_name is null
    )

    , old as (
        select
            'Old' as model
            , count(*) as row_count
            {% if date_column is not none %}
            , min({{ date_column }})::timestamp_tz as min_{{ date_column }}
            , max({{ date_column }})::timestamp_tz as max_{{ date_column }}
            {% endif %}
        from {{ ref(old_table)}}
    )

    , old_columns as (
        select
            'Old' as model
            , count(*) as number_of_columns
        from information_schema.columns
        where lower(table_catalog) like lower('{{ old_db }}')
            and lower(table_schema) like lower('{{ old_schema }}')
            and lower(table_name) like lower('{{ old_table }}')
    )

    , old_join as (
        select
            old.model
            , old.row_count
            , old_columns.number_of_columns
            {% if date_column is not none %}
            , old.min_{{ date_column }}
            , old.max_{{ date_column }}
            {% endif %}
            , missing_from_old.missing_columns
        from old
        left join old_columns on
            old.model = old_columns.model
        left join missing_from_old on
            old.model = missing_from_old.model
    )

    , new as (
        select
            'New' as model
            , count(*) as row_count
            {% if date_column is not none %}
            , min({{ date_column }})::timestamp_tz as min_{{ date_column }}
            , max({{ date_column }})::timestamp_tz as max_{{ date_column }}
            {% endif %}
        from {{ ref(new_table)}}
    )

    , new_columns as (
        select
            'New' as model
            , count(*) as number_of_columns
        from information_schema.columns
        where lower(table_catalog) like lower('{{ new_db }}')
            and lower(table_schema) like lower('{{ new_schema }}')
            and lower(table_name) like lower('{{ new_table }}')
    )

    , new_join as (
        select
            new.model
            , new.row_count
            , new_columns.number_of_columns
            {% if date_column is not none %}
            , new.min_{{ date_column }}
            , new.max_{{ date_column }}
            {% endif %}
            , missing_from_new.missing_columns
        from new
        left join new_columns on
            new.model = new_columns.model
        left join missing_from_new on
            new.model = missing_from_new.model
    )

    , cte_union as (
        select * from old_join
        union
        select * from new_join
    )

select * from cte_union

{% endmacro %}
