# Package: dbt-data_auditing_observatory

![Untitled](https://user-images.githubusercontent.com/117457905/236837634-111ca85d-967e-44e8-962e-e0c873730304.png)

# Motivation

The **dbt-data_audit_observatory** package, created by Indicium, helps delivering **************************observability************************** and ********************automation******************** to the process of data auditing between tables, specially when implementing data stack transition. With 3 specialized macros that approach several aspects of data validation in a data stack transitioning context, this package is used to compare the “old” (legacy) model with the “new” (refactored) model, quantifying and summarizing important information, such as table structure comparison and column-level compatibility overview.

# Overview

Each of these macros play an important role in creating a Data Quality Assurance layer in dbt, and providing Data teams with a huge observability increase in the data auditing process, especially when implementing data stack transition. With the complementary characteristic of the macros, we provide below a quick use-guide to the package, so the AE can jump right in into data auditing!

![image](https://user-images.githubusercontent.com/117457905/236840212-a32d859d-d7c3-44d2-b908-33f00f3f43fc.png)

# Macros

## 1. table_structure_report():

### 1.1 Usage

The most straightforward macro, it consists in a dimensional comparison between legacy and refactored table structures, featuring the following metrics:

- row count;
- number of columns;
- oldest date of a date column (optional);
- newest date of a date column (optional).

The row count and the number of columns comparison subsidize a dimensional analysis of the table by the AE,  clearly informing about possible missing data between the two tables. The optional date reference column, usually a *‘date_synced’* type column, can bring further detail to a missing data issue, allowing to quickly identify if  different time intervals are being used between the tables.

### 1.2 Code

Below is the code used to run the ********************************************table_structure_report******************************************** macro.

To run the macro, simply paste the following in a **.sql** file inside your dbt project, and replace the variables with the correspondent paths to your models and a date column:

```sql
-- Table Structure Report
{{ table_structure_report(
    old_db = 'old_database'
    , old_schema = 'old_schema'
    , old_table = 'example_old_model'
    , new_db = 'new_database'
    , new_schema = 'new_schema'
    , new_table = 'example_refactored_model'
    , db_connection = 'postgres' --> Can be ['snowflake', 'postgres', or 'redshift']
    , date_column = 'created_date'
) }}
```

Note that the **date_column** variable is optional, and can be safely deleted if there is none to be compared.

### 1.3 Output

Below we have the 2 possible outputs.

The first possible output, when a date column is used within the comparison, shows up like this:

![Untitled 1](https://user-images.githubusercontent.com/117457905/236838016-2d7db463-6723-417b-af37-e3b0851aa3bc.png)

And the second one, when the analysis does not involve a date column:

![Untitled 2](https://user-images.githubusercontent.com/117457905/236838196-de682c9a-acd8-42fb-a4d7-57cb677e48da.png)

## 2. column_match_report():

### 2.1 Usage

The most powerful macro when it comes to data auditing processes and data quality assurance, this macro enables generating automated table compatibility reports in a column level, comparing each column from the refactored table with its correspondent pair from the legacy table. By declaring an effective **primary key**, it is possible to **fully join** both tables and compare their columns’ compatibility, which is measured thorugh these 7 basic metrics, relative to total row number resultant from the full join applied:

- Perfect match (%);
- Both values are null (%);
- Values do not match (%);
- Value null only in old (%);
- Value null only in new (%);
- Value missing from old (%);
- Value missing from new (%).

A **********************************total match ratio********************************** metric is generated by summing the “perfect match” and “both are null” metrics, and can be translated as a total column compatibility ratio.

### 2.2 Code

Below is the code used to run the ********************************************column_match_report******************************************** macro.

To run the macro, simply paste the following in a **.sql** file inside your dbt project, and replace the variables with the correspondent information related to your model.

It is important to explicitly declare all the columns that are going to be evaluated by the final report. Note that the query format allows for experimenting with SQL directly in this auditing model, such as, for example, applying business rules to check if the compatibility ratio goes up.

Also, the ********************model_name******************** variable allows the aggregation of several auditing reports together, that can be used to generate data auditing BI reports!

```sql
-- Declare audited column names
{% set column_variables = [
    'id'
    , 'amount'
    , 'created_date'
] %}

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
{{ column_match_report(
    primary_key = 'id'
    , model_name = 'ExampleModel'
    , old_query = old_etl_relation_query
    , new_query = new_etl_relation_query
    , columns_to_compare = column_variables
) }}
```

### 2.3 Output

Below is this example’s output, split into two screenshots. Note that the model name, associated with the run date information, can be used to generate automated data quality reports, warnings and Business Intelligence dashboards:

![Untitled 3](https://user-images.githubusercontent.com/117457905/236838291-e9a539af-bdc0-4d4b-84ef-656c9cf1e3d8.png)

![Untitled 4](https://user-images.githubusercontent.com/117457905/236838363-118bd6df-6eeb-4f65-9729-e08782b310a1.png)

## 3. column_values_report():

### 3.1 Usage

Using the same primary key based full join logic as the **column_match_report** macro, this ****************************************column_values_report**************************************** macro focuses much more on visualizing the actual differences between the tables, acting as an Exploratory Data Analysis (EDA) framwork for the AE to quickly spot what can possibly be going wrong within the data transformation steps, identifying patterns within the data. The report is also presented at column-level, and the column pairs are compared based on:

- Data types;
- Distinct values count;
- Null entries count;
- Min value;
- Max value.

### 3.2 Code

Below is the code used to run the ********************************************column_match_report******************************************** macro.

To run the macro, simply paste the following in a **.sql** file inside your dbt project, and replace the variables with the correspondent information related to your model.

Note that this macro follows the same shape as the previous one, the column_match_report macro:

```sql
-- Declare audited column names
{% set column_variables = [
    'id'
    , 'amount'
    , 'created_date'
] %}

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
{{ column_values_report(
    primary_key = 'id'
    , model_name = 'ExampleModel'
    , db_connection = 'postgres' --> Can be ['snowflake', 'postgres' or 'redshift']
    , old_query = old_etl_relation_query
    , new_query = new_etl_relation_query
    , columns_to_compare = column_variables

) }}
```

### 3.3 Output

Below is the example output, split into two screenshots. Note how this EDA approach facilitates troubleshooting compatibility issues between the tables, making the AE’s life easier.

![Untitled 5](https://user-images.githubusercontent.com/117457905/236838418-71b0c223-4aa7-4c5d-9f7c-1547f879da40.png)

![Untitled 6](https://user-images.githubusercontent.com/117457905/236838473-07d5655c-f1fd-41bc-adfe-60f5126751cf.png)
