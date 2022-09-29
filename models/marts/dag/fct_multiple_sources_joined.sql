-- this model finds cases where a model references more than one source
with direct_source_relationships as (
    select distinct
        child,
        parent
    from {{ ref('int_all_dag_relationships') }}
    where distance = 1
    and parent_resource_type = 'source'
    -- we order the CTE so that listagg returns values correctly sorted for some warehouses
    order by 1, 2
),

multiple_sources_joined as (
    select
        child,
        {{ dbt.listagg(
            measure='parent', 
            delimiter_text="', '", 
            order_by_clause='order by parent' if target.type not in ['databricks','duckdb','spark']) 
        }} as source_parents
    from direct_source_relationships
    group by 1
    having count(*) > 1
)

select * from multiple_sources_joined

{{ filter_exceptions(this) }}