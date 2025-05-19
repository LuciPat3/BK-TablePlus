select ba.type as actor_type,
		bb.id,
		bbi.creation_time,
       ba.external_id as actor_external_id,
       bbi.description as description,
       bbi.currency as currency,
       bbi.amount / 100 as amount,
       bbi.tax / 100 as tax_amount,
       bbi.type as type,
       bbi.source_type,
       bbi.source_id
       -- boi.dispatching_time
from bls_bill_items bbi
    join bls_bills bb on bbi.bill_id = bb.id
    join bls_actors ba on bb.actor_id = ba.id
    -- join bls_orders_information boi on boi.order_id = bbi.source_id -- and bbi.source_type = 'ORDER'
where ba.type = 'PARTNER'
and ba.partner_family = 'BURGERKING'
and ba.billing_cycle = 'WEEKLY'
and ba.country_code = 'ES'
-- and bbi.bill_item_import_id is null
and date(bbi.creation_time) = '2022-11-28' AND '2022-11-30'




SELECT
    bbi.bill_id,
    bbi.source_id                                                                       AS order_id,
    -- boi.order_code                                                                      AS order_code,
    ba.external_id                                                                      AS store_address_id,
    bbi.creation_time AS time,
    ba.city_code,
    ba.country_code,
    SUM(IF(bbi.type = 'ORDER', bbi.amount, 0)) / 100.0                                  AS Products,
    SUM(IF(bbi.type = 'DELIVERY_FEE', bbi.amount, 0)) / 100.0                                  AS DF,
    SUM(IF(bbi.type = 'PROMOTION', bbi.amount, 0)) / 100.0                              AS Promotion,
    ABS(SUM(IF(bbi.type = 'COST_PER_ORDER_ASSUMED', bbi.amount, 0)) / 100.0)            AS CPO,
    ABS(SUM(IF(bbi.type = 'EFFECTIVE_COMMISSION', bbi.amount, 0)) / 100.0)              AS Effective_commission,
    ABS(SUM(IF(bbi.type = 'GLOVO_BALANCE_DISCOUNT', bbi.amount, 0)) / 100.0)            AS Glovo_balance_discount,
    SUM(IF(bbi.type = 'PROMOTION_ON_DELIVERY', bbi.amount, 0)) / 100.0                  AS Promotion_on_delivery,
    SUM(IF(bbi.type = 'REFUND', bbi.amount, 0)) / 100.0                                 AS Refund,
    SUM(IF(bbi.type in ( 'MINIMUM_BASKET_SURCHARGE', 'SURCHARGE'), bbi.amount, 0)) / 100.0                              AS Surcharge,
    SUM(IF(bbi.type = 'PRODUCTS_PAID_IN_CASH', bbi.amount, 0)) / 100.0                  AS Products_paid_in_cash,
 SUM(IF(bbi.type = 'PRODUCTS_TO_PAY_PARTNER', bbi.amount, 0)) / 100.0                  AS Products_to_pay_partner,
    ABS(SUM(IF(bbi.type IN ('COST_PER_ORDER_ASSUMED','EFFECTIVE_COMMISSION', 'GLOVO_BALANCE_DISCOUNT'),
        bbi.amount, 0))) / 100.0                                                       AS Partner_Commission
FROM
    bls_bill_items     bbi
        JOIN bls_bills bb ON bbi.bill_id = bb.id
        JOIN bls_actors ba ON bb.actor_id = ba.id
WHERE
ba.partner_family = 'BURGERKING'
and ba.country_code = 'ES'
and date(bb.processing_date) = '2023-06-04' 
GROUP BY 1,2,3,4,5,6;