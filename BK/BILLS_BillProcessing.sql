SELECT
    bbi.bill_id,
    bbi.source_id                                                                       AS order_id,
    -- boi.order_code                                                                      AS order_code,
    ba.external_id                                                                      AS store_address_id,
    ba.city_code,
    ba.country_code,
    SUM(IF(bbi.type = 'ORDER', bbi.amount, 0)) / 100.0                                  AS Products,
    SUM(IF(bbi.type = 'DELIVERY_FEE', bbi.amount, 0)) / 100.0                                  AS DF,
    SUM(IF(bbi.type = 'PROMOTION', bbi.amount, 0)) / 100.0                              AS Promotion,
    ABS(SUM(IF(bbi.type = 'COST_PER_ORDER_ASSUMED', bbi.amount, 0)) / 100.0)            AS CPO,
    SUM(IF(bbi.type = 'EFFECTIVE_COMMISSION', bbi.amount, 0) / 100.0)              AS Effective_commission,
    SUM(IF(bbi.type = 'COMMISSION_PARTNER_INCIDENT', bbi.amount, 0) / 100.0)              AS COMMISSION_PARTNER_INCIDENT,
    ABS(SUM(IF(bbi.type = 'GLOVO_BALANCE_DISCOUNT', bbi.amount, 0)) / 100.0)            AS Glovo_balance_discount,
    SUM(IF(bbi.type = 'PROMOTION_ON_DELIVERY', bbi.amount, 0)) / 100.0                  AS Promotion_on_delivery,
    SUM(IF(bbi.type = 'REFUND', bbi.amount, 0)) / 100.0                                 AS Refund,
    SUM(IF(bbi.type = 'PLATFORM_FEE', bbi.amount, 0)) / 100.0                  AS Platform_fee,
    SUM(IF(bbi.type in ( 'MINIMUM_BASKET_SURCHARGE', 'SURCHARGE'), bbi.amount, 0)) / 100.0                              AS Surcharge,
    SUM(IF(bbi.type = 'PRODUCTS_PAID_IN_CASH', bbi.amount, 0)) / 100.0                  AS Products_paid_in_cash,
     SUM(IF(bbi.type = 'PRODUCTS_PARTNERS_INCIDENT', bbi.amount, 0)) / 100.0                  AS Products_partner_Incident,
     SUM(IF(bbi.type = 'ADJUSTMENT', bbi.amount, 0)) / 100.0                                 AS Adjustment,
 SUM(IF(bbi.type = 'PRODUCTS_TO_PAY_PARTNER', bbi.amount, 0)) / 100.0                  AS Products_to_pay_partner,
    ABS(SUM(IF(bbi.type IN ('COST_PER_ORDER_ASSUMED','EFFECTIVE_COMMISSION', 'GLOVO_BALANCE_DISCOUNT', 'COMMISSION'),
        bbi.amount, 0))) / 100.0                                                       AS Partner_Commission
FROM
    bls_bill_items     bbi
        JOIN bls_bills bb ON bbi.bill_id = bb.id
        JOIN bls_actors ba ON bb.actor_id = ba.id
WHERE
ba.partner_family = 'BURGERKING'
-- and bb.status = 'Processing'
-- and bbi.source_id in (101305072887)
and bbi.bill_id in (709982596)
-- and date (bbi.creation_time) BETWEEN '2023-01-01' and '2022-12-31'
GROUP BY 1,2,3,4,5;