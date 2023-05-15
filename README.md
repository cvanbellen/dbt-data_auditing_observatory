# Package: dbt-data_auditing_observatory

![Untitled](https://user-images.githubusercontent.com/117457905/236837634-111ca85d-967e-44e8-962e-e0c873730304.png)

# Motivation

The **dbt-data_audit_observatory** package, created by Indicium, helps delivering **************************observability************************** and ********************automation******************** to the process of data auditing between tables, specially when implementing data stack transition. With 3 specialized macros that approach several aspects of data validation in a data stack transitioning context, this package is used to compare the “old” (legacy) model with the “new” (refactored) model, quantifying and summarizing important information, such as table structure comparison and column-level compatibility overview.

# Overview

Each of these macros play an important role in creating a Data Quality Assurance layer in dbt, and providing Data teams with a huge observability increase in the data auditing process, especially when implementing data stack transition. With the complementary characteristic of the macros, we provide below a quick use-guide to the package, so the AE can jump right in into data auditing!

![image](https://user-images.githubusercontent.com/117457905/236840212-a32d859d-d7c3-44d2-b908-33f00f3f43fc.png)

# Table Refactoring Example

To better understand how the macros work, we provide an example of a work-in-progress refactoring process, in the shape of 2 tables that should match eachother. In the middle of a journey to refactor a single model or a complete data workflow in dbt, important differences between legacy and refactored models will inevitably appear, and the purpose of these macros is to enable the quick identification of the incompatibilities between the data, making the life easier for the Analytics Engineer in charge of the process.
Below we can see an example of a legacy table, and its work-in-progress refactored counterpart:

* __Example of a legacy table:__

![image](https://github.com/cvanbellen/dbt-data_auditing_observatory/assets/117457905/28fd004c-f858-4dc9-b47c-0f0df4ee2552)

* __Example of a work-in-progress refactored table:__

![image](https://github.com/cvanbellen/dbt-data_auditing_observatory/assets/117457905/01741113-1c02-4e0f-8c76-48d9b62d21fa)

Let's see if the macros can help us spot what is wrong with the refactored model.

# Macros

## 1. table_structure_report():

### 1.1 Usage

The most straightforward macro, it consists in a dimensional comparison between legacy and refactored table structures, featuring the following metrics:

- row count;
- number of columns;
- missing columns in comparison with its counterpart;
- oldest date of a date column (optional);
- newest date of a date column (optional).

The row count and the number of columns comparison subsidize a dimensional analysis of the table by the AE,  clearly informing about possible missing data between the two tables. The optional date reference column, usually a *‘date_synced’* type column, can bring further detail to a missing data issue, allowing to quickly identify if  different time intervals are being used between the tables.

### 1.2 Code

Below is the code used to run the ********************************************table_structure_report******************************************** macro.

To run the macro, simply paste the following in a **.sql** file inside your dbt project, and replace the variables with the correspondent paths to your models and a date column:

```sql
-- Table Structure Report
--> db_connection can be ['snowflake' or 'postgres']
{{ table_structure_report(
    db_connection = 'postgres'
    , old_db = 'your_legacy_database'
    , old_schema = 'your_legacy_schema'
    , old_table = 'example_old_model'
    , new_db = 'your_refactored_database'
    , new_schema = 'your_refactored_schema'
    , new_table = 'example_refactored_model'
    , date_column = 'created_date'
) }}
```

Note that the **date_column** variable is optional, and can be safely deleted if there is none to be compared.

### 1.3 Output

Below we have the 2 possible outputs.

The first possible output, when a date column is used within the comparison, shows up like this:

![image](https://github.com/cvanbellen/dbt-data_auditing_observatory/assets/117457905/d5f237bc-4604-4573-baf2-077578bfaeb7)

And the second one, when the analysis does not involve a date column:

![image](https://github.com/cvanbellen/dbt-data_auditing_observatory/assets/117457905/22242bcd-9f70-4e2f-9250-11a328f2dd87)

We can see that this first macro quickly points out to a crucial structural difference between the both tables: the 'end_date' column from the legacy model is not represented in the refactored model, and this should be further investigated. Also, we are informed that the number of rows is coherent between both models, and the time interval analysis of the 'created_date' column indicates that we have data correspondent to the same time period in both cases.

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

![image](https://github.com/cvanbellen/dbt-data_auditing_observatory/assets/117457905/1024a6f8-035b-4422-bfbe-dd3576d6508b)

![image](https://github.com/cvanbellen/dbt-data_auditing_observatory/assets/117457905/b2af9ac2-3976-4dfb-8e79-cd18e1e7ca81)

This second macro helps us to identify a compatibility issue within the 'amount' column: in 33,33% of the rows, the values do not match between the models! In this example, we know that this difference is due to different amount attributed to id = '003', but in a much larger model, with thousands or even millions of rows, each incompatibility issue should be further investigated. This macro enables the quantification of data compatibility between tables, but in order to really solve this problem, we will have to take a look at the actual data. That's what macro number 3 is for...

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
--> db_connection can be ['snowflake' or 'postgres']
{{ column_values_report(
    db_connection = 'postgres'
    , primary_key = 'id'
    , model_name = 'ExampleModel'
    , old_query = old_etl_relation_query
    , new_query = new_etl_relation_query
    , columns_to_compare = column_variables

) }}
```

### 3.3 Output

Below is the example output, split into two screenshots. Note how this EDA approach facilitates troubleshooting compatibility issues between the tables, making the AE’s life easier.

![image](https://github.com/cvanbellen/dbt-data_auditing_observatory/assets/117457905/cf452948-9fc4-422a-ae85-7c055fd681bb)

![image](https://github.com/cvanbellen/dbt-data_auditing_observatory/assets/117457905/216f2fe1-400c-488f-8a77-7626b8902d9d)

With this macro, we can take a more detailed look at the data at column level, and possibly spot any issues regarding data types used, null entries, duplicated entries, or differences between minimum and maximum amounts for each column. Here, we can see clearly that minumum values for the 'amount' column aren't consistent between the tables, and that may help us identify within the data workflow what can be causing this 33,33% incompatibility rate!
