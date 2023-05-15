-- Table Structure Report
--> db_connection can be ['snowflake' or 'postgres']
{{ table_structure_report(
    db_connection = 'postgres'
    , old_db = 'your_legacy_db'
    , old_schema = 'your_legacy_schema'
    , old_table = 'example_legacy_model'
    , new_db = 'your_refactored_db'
    , new_schema = 'your_refactored_schema'
    , new_table = 'example_refactored_model'
    , date_column = 'created_date'
) }}
