SELECT bbi.bill_id,
       bbi.source_id                                                                      AS order_id,
       -- boi.order_code                                                                     AS order_code,
       ba.external_id                                                                     AS parent_store_address_id,
       ioi.actual_store_address_id                                                        AS child_store_address_id,
       -- bbi.creation_time as dd,
       ba.city_code,
       ba.country_code,
       ABS(SUM(IF(bbi.type = 'EFFECTIVE_COMMISSION', bbi.amount, 0)) / 100.0)             AS Effective_commission,
       SUM(IF(bbi.type = 'ORDER', bbi.amount, 0)) / 100.0                                 AS Products,
       SUM(IF (bbi.type = 'ADJUSTMENT', bbi.amount, 0)) / 100.0  					AS adjustment,
       SUM(IF(bbi.type = 'PRODUCTS_PAID_IN_CASH', bbi.amount, 0)) / 100.0                 AS Products_paid_in_cash,
       SUM(IF(bbi.type = 'REFUND', bbi.amount, 0)) / 100.0                                AS Refund,
       SUM(IF(bbi.type = 'PROMOTION', bbi.amount, 0)) / 100.0                             AS Promo_product,
       SUM(IF(bbi.type = 'PROMOTION_ON_DELIVERY', bbi.amount, 0)) / 100.0                 AS Promo_df,
       SUM(IF(bbi.type = 'GLOVO_PROMOTION_ON_DELIVERY_TAXABLE_BASE', bbi.amount, 0)) / 100.0            AS Promo_df_taxable,
       CAST(SUM(CASE WHEN bbi.type = 'DELIVERY_FEE' THEN bbi.amount ELSE 0 END) / 100.0 AS DECIMAL(15, 2))                     AS DF,
       SUM(IF(bbi.type = 'PRODUCTS_TO_PAY_PARTNER', bbi.amount, 0)) / 100.0                 AS Products_to_pay_partner,
       SUM(IF (bbi.type = 'GLOVO_ORDER_PARTNER_INCIDENT', bbi.amount, 0)) / 100.0       AS GLOVO_ORDER_PARTNER_INCIDENT,
       SUM(IF (bbi.type = 'GLOVO_COMMISSION_PARTNER_INCIDENT', bbi.amount, 0)) / 100.0   AS GLOVO_COMMISSION_PARTNER_INCIDENT,
        CAST(SUM(CASE WHEN bbi.type = 'PRODUCTS_EDENRED' THEN bbi.amount ELSE 0 END) / 100.0 AS DECIMAL(15, 2))     AS Buoni_pasto,
       CAST(SUM(CASE WHEN bbi.type = 'GLOVO_COMMISSION_DISCOUNT_MEAL_VOUCHER' THEN bbi.amount ELSE 0 END) / 100.0 AS DECIMAL(15, 2))           AS Edenred_comm_Discount,
       SUM(IF(bbi.type = 'GLOVO_MKT_GMO', bbi.amount, 0)) / 100.0                  AS Marketing_promotion,
    SUM(IF(bbi.type = 'GLOVO_MKT_GMO_CREDIT', bbi.amount, 0)) / 100.0                  AS Discount_Marketing_promotion,
              SUM(IF(bbi.type in ( 'MINIMUM_BASKET_SURCHARGE', 'SURCHARGE'), bbi.amount, 0)) / 100.0              AS Surcharge,
       CAST(SUM(CASE WHEN bbi.type = 'PLATFORM_FEE' THEN bbi.amount ELSE 0 END) / 100.0 AS DECIMAL(15, 2))     AS PLATFORM_FEE,
CAST(SUM(CASE WHEN bbi.type = 'PARTNER_WAIT_TIME_FEE' THEN bbi.amount ELSE 0 END) / 100.0 AS DECIMAL(15, 2))                        AS Wait_time_fees,
CAST(SUM(CASE WHEN bbi.type = 'PARTNER_WAIT_TIME_FEE_TAXABLE_BASE' THEN bbi.amount ELSE 0 END) / 100.0 AS DECIMAL(15, 2))                        AS Wait_time_fees_PORTUGAL,
CAST(SUM(CASE WHEN bbi.type = 'SALES_FEE' THEN bbi.amount ELSE 0 END) / 100.0 AS DECIMAL(15, 2))                        AS SALES_FEE,
 CAST(SUM(CASE WHEN bbi.type = 'INSTANT_PAYOUT_FEE' THEN bbi.amount ELSE 0 END) / 100.0 AS DECIMAL(15, 2))                  AS Payout_commission,
CAST(SUM(CASE WHEN bbi.type = 'EARLY_PAYOUT_DISCOUNT' THEN bbi.amount ELSE 0 END) / 100.0 AS DECIMAL(15, 2))                  AS Payout_deducted,
SUM(IF(bbi.type = 'SANCTION', bbi.amount, 0)) / 100.0                                 AS Sanction,
SUM(IF(bbi.type = 'GLOVO_BALANCE_DISCOUNT', bbi.amount, 0)) / 100.0          AS Glovo_balance_discount,
            ABS(SUM(IF(bbi.type IN ('COST_PER_ORDER_ASSUMED','EFFECTIVE_COMMISSION', 'GLOVO_BALANCE_DISCOUNT'),
                  bbi.amount, 0))) / 100.0                AS Partner_Commission
FROM
    bls_bill_items    bbi
        JOIN bls_bills bb ON bbi.bill_id = bb.id
        JOIN bls_actors ba ON bb.actor_id = ba.id
        LEFT JOIN inv_order_information ioi on bbi.source_id = ioi.order_id
WHERE
        ba.partner_family = 'BURGERKING'
        and billing_cycle in ('WEEKLY')
-- AND ba.external_id in (269235)
  and ba.country_code = 'ES'
  and date(bb.processing_date) = '2025-05-11'
GROUP BY 1,2,3,4,5;