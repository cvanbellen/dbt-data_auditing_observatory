with
    legacy_model as (
        select
            '001' as id
            , 250 as amount
            , date('2020-01-01') as created_date
        union
        select
            '002' as id
            , 375 as amount
            , date('2020-01-02') as created_date
        union
        select
            '003' as id
            , 125 as amount
            , date('2020-01-03') as created_date
    )

select * from legacy_model
