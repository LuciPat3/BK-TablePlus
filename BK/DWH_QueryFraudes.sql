WITH   tmp_ori AS -- CTE to get refunds filtered by gen1 attributable reasons and charge nothing (same that above, but from another source because I noticed some orders were missing..)
    (SELECT
                                        ori.order_id,
                                        ori.creation_time as creation,
                                        ori.reason AS reason_chosen,
                                        ori.partner_resolution,
                                        o.activation_time as activation,
                                         DATEDIFF(minute,activation,creation) AS difference_ori,
                                        ori.update_time AS date_chosen,
                                        ROUND(ori.refunded_to_customer,2) AS refunded_to_customer
                        FROM public.order_refund_incidents ori 
                        LEFT JOIN orders o ON o.id=ori.order_id 
						WHERE date_chosen > '2023-01-01 00:00:00'
						AND o.country_code='ES'
                        AND ori.refunded_to_customer > 0
                        AND ori.partner_resolution = 'CHARGE_NOTHING'
                        AND (o.is_marketplace = TRUE OR o.handling_strategy_type = 'PICKUP')
                        AND ((reason_chosen LIKE '%CANCELED_OR_UNDELIVERED%' AND o.payment_method <> 'CASH' AND difference_ori>=90 and o.handling_strategy_type = 'DELIVERY') OR (reason_chosen LIKE '%CANCELED_OR_UNDELIVERED%' AND o.handling_strategy_type='PICKUP')  OR (reason_chosen LIKE '%DELAY_OR_COLD%' OR reason_chosen LIKE '%MISSING_PRODUCTS%' OR reason_chosen LIKE '%MISSING_PRODUCTS%' OR reason_chosen LIKE '%BAD_QUALITY_FOOD%' OR reason_chosen LIKE '%MISTAKE_PRODUCT%' OR reason_chosen LIKE '%WRONG_PRODUCTS%' OR reason_chosen LIKE '%PRODUCTS_MISTREATED%'))
                        AND (o.final_status  = 'DeliveredStatus' OR o.cancel_reason  IN ('DELIVERY_TAKING_TOO_LONG','PARTNER_NOT_ACCEPTED_ROBOCALL','PARTNER_PRINTER_ISSUE','STORE_CAN_NOT_DELIVER','TEMPORARY_STORE_CLOSURE','PRODUCTS_NOT_AVAILABLE','STORE_CLOSED'))),
                
             
tmp_undelivered_orders AS --CTE to join the two previous ones and get the incidents from Gen 1. We include certain scenarios (promotions) that will impact the amount that'll be chargedto the partner
         (SELECT                  
                    ori.order_id AS order_id,
                    ko.order_started_at,
                    o.country_code,
                    MAX(ROUND(ori.refunded_to_customer,2))        AS        refunded_customer,
                    SUM(CASE WHEN kopd.promocode IS NOT NULL THEN 0 ELSE round(COALESCE(kopd.product_discounts_assumed_by_glovo_currlocal,0),2) END)        AS glovo_assumes_product_discount,
                    SUM(CASE WHEN kopd.promocode IS NOT NULL THEN 0 ELSE round(COALESCE(kopd.delivery_discounts_assumed_by_glovo_currlocal,0),2) END)        AS glovo_assumes_delivery_discount,
                    SUM(ROUND(COALESCE(delivery_discounts_assumed_by_glovo_currlocal,0),2)) AS delivery_discounts_assumed_by_glovo_currlocal,
                    
                    SUM(CASE WHEN kopd.order_discount_origin='PROMOTION_FREE_DELIVERY' AND kopd.delivery_discounts_assumed_by_partner_currlocal>0
                    THEN kopd.delivery_discounts_assumed_by_partner_currlocal*-1 ELSE 0 END) AS delivery_surcharge,
                    
                    MAX(CASE WHEN COALESCE(kopd.order_discount_is_free_delivery,FALSE)=TRUE THEN 0 ELSE ROUND(coalesce(o.delivery_fee,0),2) END) AS client_paid_DF,
                    MAX(CASE WHEN COALESCE(kopd.order_discount_is_free_delivery,FALSE)=TRUE THEN 0 ELSE ROUND(COALESCE(kopd.delivery_discounts_assumed_by_glovo_currlocal,0),2) END) AS flat_df_discount,
                    MAX(ROUND(COALESCE(ko.order_total_purchase_currlocal,0),2)) AS order_total_purchase_currlocal,
                    SUM(ROUND(COALESCE(kopd.product_discounts_assumed_by_partner_currlocal,0),2)) AS product_discounts_assumed_by_partner_currlocal,
                    MAX(round(coalesce(o.delivery_fee,0),2))						AS  delivery_fee,
                    MAX(round(coalesce(o.service_fee,0),2))						AS  service_fee,
                    MAX(round(coalesce(o.basket_surcharge,0),2))							AS basket_surcharge,
                    MAX(round(coalesce(ko.order_weather_revenue_without_tax_currlocal,0),2)) AS order_weather_revenue_without_tax_currlocal,
                    MAX(ko.order_tax_rate) AS order_tax_rate
                    
                    
 
  
                 FROM tmp_ori ori
                          LEFT JOIN bi_kpis.kpi_order_pricing_discounts kopd ON kopd.order_id=ori.order_id
                          LEFT JOIN orders o ON o.id=ori.order_id
                          LEFT JOIN bi_kpis.kpi_orders ko ON ko.order_id=ori.order_id
                          GROUP BY 1,2,3),
                  

                  



Table_Order AS (SELECT 
       o.country_code                                           AS country_code,
       o.id                                                   AS order_id_to,
       CONCAT('P', o.store_address_id)                          AS store_address_id,
       s.id                                                     AS store_id,
       DATE_TRUNC('month', o.creation_time_local)                                 as month_date,
       o.partner_commission_percentage                          AS percentage_commission,
       s.store_name AS store_name,
       tuo.order_id,
       ori.reason AS reason,
       o.cancel_reason AS cancel,
       o.final_status as status,
       MAX(CASE WHEN tuo.order_id IS NOT NULL AND(ROUND(COALESCE(tuo.refunded_customer,0),1) <= (ROUND(COALESCE(tuo.order_total_purchase_currlocal,0),1)-ROUND(COALESCE(tuo.glovo_assumes_product_discount,0),1)-ROUND(COALESCE(tuo.product_discounts_assumed_by_partner_currlocal,0),1)))
       THEN COALESCE(tuo.refunded_customer,0)
       			WHEN tuo.order_id IS NOT NULL AND o.is_prime = FALSE AND(ROUND(COALESCE(tuo.refunded_customer,0),1) > (ROUND(COALESCE(tuo.order_total_purchase_currlocal,0),1)-ROUND(COALESCE(tuo.glovo_assumes_product_discount,0),1)-ROUND(COALESCE(tuo.product_discounts_assumed_by_partner_currlocal,0),1)))
       THEN (COALESCE(tuo.refunded_customer,0)+COALESCE(tuo.glovo_assumes_product_discount,0)-COALESCE(tuo.service_fee,0)-COALESCE(tuo.basket_surcharge,0)-COALESCE(tuo.client_paid_DF,0)-COALESCE(tuo.order_weather_revenue_without_tax_currlocal,0)/(1+coalesce(tuo.order_tax_rate,0)))
    
      			WHEN tuo.order_id IS NOT NULL AND o.is_prime = TRUE AND (ROUND(COALESCE(tuo.refunded_customer,0),1) > (ROUND(COALESCE(tuo.order_total_purchase_currlocal,0),1)-ROUND(COALESCE(tuo.glovo_assumes_product_discount,0),1)-ROUND(COALESCE(tuo.product_discounts_assumed_by_partner_currlocal,0),1))) THEN (coalesce(tuo.refunded_customer,0)+COALESCE(tuo.glovo_assumes_product_discount,0)-coalesce(tuo.service_fee,0)-coalesce(tuo.basket_surcharge,0)-coalesce(tuo.order_weather_revenue_without_tax_currlocal,0)/(1+tuo.order_tax_rate)) 
       ELSE ROUND(ori.charged_to_partner)*1 END)  AS products,
       
       MAX(CASE WHEN tuo.order_id IS NOT NULL AND(ROUND(COALESCE(tuo.refunded_customer,0),1) > (ROUND(COALESCE(tuo.order_total_purchase_currlocal,0),1)-ROUND(COALESCE(tuo.glovo_assumes_product_discount,0),1)-ROUND(COALESCE(tuo.product_discounts_assumed_by_partner_currlocal,0),1))) THEN (ROUND(COALESCE(tuo.basket_surcharge,0),2)+ROUND(COALESCE(tuo.delivery_fee,0),2)+ROUND(COALESCE(tuo.delivery_surcharge,0),2)
       +COALESCE(tuo.flat_df_discount,0)+COALESCE(tuo.order_weather_revenue_without_tax_currlocal/(1+tuo.order_tax_rate),0))
       ELSE COALESCE(tuo.delivery_discounts_assumed_by_glovo_currlocal,0) END)        AS Gen1_DF_MBS_Weather

            
       FROM
    order_refund_incidents ori
    JOIN orders            o ON o.id = ori.order_id
    JOIN store_addresses   sa ON sa.id = o.store_address_id
    JOIN stores            s ON s.id = sa.store_id
    LEFT JOIN tmp_undelivered_orders tuo ON ori.order_id=tuo.order_id
    LEFT JOIN bi_kpis.kpi_orders ko ON ko.order_id=o.id
    LEFT JOIN bi_kpis.kpi_order_pricing_discounts kopd ON kopd.order_id=o.id
WHERE ori.update_time_local BETWEEN '2024-03-25 00:00:00'
    AND '2024-03-31 23:59:59' -- Put invoicing period. For example for 1Q sept '2020-09-01 00:00:00' AND '2020-09-15 23:59:59'
    AND o.creation_time_local BETWEEN '2024-02-12 00:00:00'
    AND '2024-03-31 23:59:59' -- Put month and a half taking the last day of the invoicing period as reference. For example for 1Q sept '2020-08-01 00:00:00' AND '2020-09-15 23:59:59'
    AND sa.company_detail_id IS NOT NULL
    AND  tuo.order_id IS NOT NULL
    AND ko.order_is_mcdonalds = FALSE
    AND o.country_code IN ('ES')
    --AND s.store_name = 'Burger King'





GROUP BY 1, 2, 3, 4,5,6,7,8,9,10,11
ORDER BY products ASC)

SELECT
order_id,
country_code,
store_address_id,
store_id,
store_name,
percentage_commission,
SUM(products) AS productss,
SUM(Gen1_DF_MBS_Weather) AS surcharges
FROM Table_order xx
GROUP BY 1,2,3,4,5,6