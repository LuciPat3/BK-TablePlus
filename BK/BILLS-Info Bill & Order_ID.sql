select
    ba.type as actor_type,
    bb.id,
    bbi.creation_time,
    bb.closed_at,
    ba.external_id as actor_external_id,
    bbi.description as description,
    bbi.currency as currency,
    bbi.amount / 100 as amount,
    bbi.tax / 100 as tax_amount,
    bbi.type as type,
    bbi.source_type,
    bbi.source_id -- boi.dispatching_time
from
    bls_bill_items bbi
    join bls_bills bb on bbi.bill_id = bb.id
    join bls_actors ba on bb.actor_id = ba.id 
    -- join bls_orders_information boi on boi.order_id = bbi.source_id 
    -- and bbi.source_type = 'ORDER' query
where ba.type in ('PARTNER', 'CONSOLIDATED_PARTNER') 
    and bbi.bill_item_import_id is null 
    and bbi.type = 'ORDER'
    -- and bbi.type = 'PRODUCTS_PAID_IN_CASH' 
    -- and ba.external_id in (25)
    and bbi.source_id in (101305072887)
    -- and bbi.bill_id in (543708996) --
    -- and date(bbi.creation_time) BETWEEN '2023-02-05'
    -- and '2023-02-06' -- -- -- -- -