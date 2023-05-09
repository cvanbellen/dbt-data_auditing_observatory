-- Table Structure Report
--> db_connection can be ['snowflake', 'postgres' or 'redshift']
{{ table_structure_report(
    old_db = 'metabase'
    , old_schema = 'dev'
    , old_table = 'example_legacy_model'
    , new_db = 'metabase'
    , new_schema = 'dev'
    , new_table = 'example_refactored_model'
    , db_connection = 'postgres'
    , date_column = 'created_date'
) }}
