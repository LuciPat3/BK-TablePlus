 SELECT
    ioi.order_code                                                                                                           AS "Glovo Code",
    bbi.source_id as order_id,
    bb.status,
    ba.external_id as store_address_id,
    0.0                                                                                                                  AS "MCD Code",
	CASE WHEN (ba.city_time_zone <> 'UTC') THEN
	DATE_FORMAT(convert_tz(ioi.pricing_time, 'UTC', ba.city_time_zone), '%Y-%d-%m %H:%i')
	ELSE
    DATE_FORMAT(ioi.pricing_time, '%Y-%d-%m %H:%i') END                                                           AS "Pricing Time",
	CASE WHEN (ba.city_time_zone <> 'UTC') THEN
	DATE_FORMAT(convert_tz(ioi.dispatching_time, 'UTC', ba.city_time_zone), '%Y-%d-%m %H:%i')
	ELSE
    DATE_FORMAT(ioi.dispatching_time, '%Y-%d-%m %H:%i') END                                                           AS "Notification Partner Time",
	CASE WHEN (ba.city_time_zone <> 'UTC') THEN
	DATE_FORMAT(convert_tz(ioi.delivered_time, 'UTC', ba.city_time_zone), '%Y-%d-%m %H:%i')
	ELSE
    DATE_FORMAT(ioi.delivered_time, '%Y-%d-%m %H:%i') END                                                           AS "Delivered Time",
    ioi.description AS "Description",
    ROUND(SUM(IF(bbi.type = 'ORDER', bbi.amount, 0)) / 100.0,2)                                                              AS "Price of Products",
    ROUND(SUM(IF(bbi.type = 'DELIVERY_FEE', bbi.amount, 0)) / 100.0,2)                                       AS "Delivery fee",
    ROUND(SUM(IF(bbi.type = 'SURCHARGE', bbi.amount, 0)) / 100.0,2)                                       AS "Surcharge",
    ROUND(SUM(IF(bbi.type = 'PROMOTION', bbi.amount, 0)) / 100.0,2)                                       AS "Promotion",
    ROUND(SUM(IF(bbi.type = 'PROMOTION_ON_DELIVERY', bbi.amount, 0)) / 100.0,2)                                       AS "Promotion on delivery",
    ROUND(SUM(IF(bbi.type = 'GLOVO_COMMISSION_PARTNER_INCIDENT', bbi.amount, 0)) / 100.0,2)               AS "Commission Partner Incident",
    ROUND(SUM(IF(bbi.type = 'GLOVO_ORDER_PARTNER_INCIDENT', bbi.amount, 0)) / 100.0,2)                   AS "Products_partner_Incident",
    ROUND(SUM(IF(bbi.type IN ('DELIVERY_FEE', 'SURCHARGE', 'MINIMUM_BASKET_SURCHARGE'), bbi.amount, 0)) / 100.0,2)                                       AS "Minimun basket surcharge",
    ROUND(SUM(IF(bbi.type = 'ORDER', bbi.amount, 0) +
        IF(bbi.type IN ('DELIVERY_FEE', 'SURCHARGE', 'MINIMUM_BASKET_SURCHARGE'), bbi.amount, 0)) / 100.0,2)                                             AS "Total",
    ROUND(ABS(SUM(CASE WHEN bbi.type IN ('EFFECTIVE_COMMISSION','COST_PER_ORDER_ASSUMED','GLOVO_BALANCE_DISCOUNT', 'COMMISSION')
        THEN bbi.amount ELSE 0 END) / 100.0),2)                                                                              AS "Fee Type",
    ROUND(ABS(SUM(CASE WHEN bbi.type IN ('EFFECTIVE_COMMISSION','COST_PER_ORDER_ASSUMED','GLOVO_BALANCE_DISCOUNT', 'COMMISSION')
        THEN bbi.amount ELSE 0 END) / 100.0),2)                                                                              AS "Charged to MCD",
    ba.address                                              AS "Store Name",
    ba.store_address_external_id                                                                                             AS "Store Code",
    ioi.payment_method                                                                                                       AS "Payment Method",
    ROUND(SUM(CASE WHEN bbi.type = 'PRODUCTS_PAID_IN_CASH' THEN bbi.amount ELSE 0 END) / 100.0,2)                            AS "Products paid in Cash",
    0.0                                                                                                                      AS "Delivery paid in Cash", -- we do not have a bill item for it as far as I know
    ROUND(ABS(SUM(CASE WHEN bbi.type = 'COST_PER_ORDER_ASSUMED' THEN bbi.amount ELSE 0 END) / 100.0),2)                      AS "Courier delivery service access fee",
    ROUND(ABS(SUM(CASE WHEN bbi.type = 'EFFECTIVE_COMMISSION' or bbi.type = 'COMMISSION' THEN bbi.amount ELSE 0 END) / 100.0),2) AS "Glovo platform fee",
    ROUND(ABS(SUM(CASE WHEN bbi.type = 'GLOVO_BALANCE_DISCOUNT' THEN bbi.amount ELSE 0 END) / 100.0),2)                      AS "Glovo platform discount",
    ROUND(ABS(SUM(CASE WHEN bbi.type = 'PRODUCTS_TO_PAY_PARTNER' THEN bbi.amount ELSE 0 END) / 100.0),2)                     AS "Products to pay partners",
    ROUND(ABS(SUM(CASE WHEN bbi.type = 'REFUND' THEN bbi.amount ELSE 0 END) / 100.0),2)                                      AS "Refund",
    ROUND(ABS(SUM(CASE WHEN bbi.type = 'DELIVERY_FEE_TO_CHARGE_PARTNER' THEN bbi.amount ELSE 0 END) / 100.0),2)              AS "Delivery fee to charge partner"
FROM
    bls_bill_items      bbi
        JOIN bls_bills  bb ON bbi.bill_id = bb.id
		JOIN inv_order_information ioi ON bbi.source_id = ioi.order_id
        JOIN bls_actors ba ON bb.actor_id = ba.id
        JOIN inv_fiscal_details ifd ON ifd.actor_external_id = ba.external_id and ifd.actor_type = 'PARTNER'
WHERE
date(bb.creation_time) BETWEEN '2025-04-28' AND '2025-05-01'
and ba.partner_family = 'BURGERKING'
AND ba.billing_cycle = 'WEEKLY'
AND ba.type = 'PARTNER'
AND ba.country_code = 'ES'
-- AND bbi.source_id in (100912160465)
-- AND bb.status = 'PROCESSING'
-- and ba.store_address_external_id is not null
GROUP BY 1,2;