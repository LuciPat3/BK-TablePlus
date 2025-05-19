SELECT
    (DATE("order_refund_incidents"."creation_time")) AS "order_refund_incidents.creation_date",
    "order_refund_incidents"."order_id" AS "order_refund_incidents.order_id",
    "order_refund_incidents"."products_affected" AS "order_refund_incidents.products_affected",
    "order_refund_incidents"."reason" AS "order_refund_incidents.reason",
    "orders"."store_address_id" AS "orders.store_address_id",
    "store_addresses"."address" AS "store_addresses.address",
        (CASE WHEN "orders"."free_delivery" THEN 'Yes' ELSE 'No' END) AS "orders.free_delivery",
    "orders"."city_code" AS "orders.city_code",
    "order_refund_incidents"."additional_details" AS "order_refund_incidents.additional_details",
    "order_refund_incidents"."partner_resolution" AS "order_refund_incidents.partner_resolution",
    "orders"."code" AS "orders.code",
    "stores"."store_name" AS "stores.store_name",
    "orders"."country_code" AS "orders.country_code",
    COALESCE(CAST( ( SUM(DISTINCT (CAST(FLOOR(COALESCE( "order_refund_incidents"."charged_to_partner_eur" ,0)*(1000000*1.0)) AS DECIMAL(38,0))) + CAST(STRTOL(LEFT(MD5(CAST( order_refund_incidents.id   AS VARCHAR)),15),16) AS DECIMAL(38,0))* 1.0e8 + CAST(STRTOL(RIGHT(MD5(CAST( order_refund_incidents.id   AS VARCHAR)),15),16) AS DECIMAL(38,0)) ) - SUM(DISTINCT CAST(STRTOL(LEFT(MD5(CAST( order_refund_incidents.id   AS VARCHAR)),15),16) AS DECIMAL(38,0))* 1.0e8 + CAST(STRTOL(RIGHT(MD5(CAST( order_refund_incidents.id   AS VARCHAR)),15),16) AS DECIMAL(38,0))) )  AS DOUBLE PRECISION) / CAST((1000000*1.0) AS DOUBLE PRECISION), 0) AS "order_refund_incidents.total_charged_to_partner_eur",
    COALESCE(CAST( ( SUM(DISTINCT (CAST(FLOOR(COALESCE( "order_refund_incidents"."refunded_to_customer_eur" ,0)*(1000000*1.0)) AS DECIMAL(38,0))) + CAST(STRTOL(LEFT(MD5(CAST( order_refund_incidents.id   AS VARCHAR)),15),16) AS DECIMAL(38,0))* 1.0e8 + CAST(STRTOL(RIGHT(MD5(CAST( order_refund_incidents.id   AS VARCHAR)),15),16) AS DECIMAL(38,0)) ) - SUM(DISTINCT CAST(STRTOL(LEFT(MD5(CAST( order_refund_incidents.id   AS VARCHAR)),15),16) AS DECIMAL(38,0))* 1.0e8 + CAST(STRTOL(RIGHT(MD5(CAST( order_refund_incidents.id   AS VARCHAR)),15),16) AS DECIMAL(38,0))) )  AS DOUBLE PRECISION) / CAST((1000000*1.0) AS DOUBLE PRECISION), 0) AS "order_refund_incidents.total_refunded_to_customer_eur"
FROM
    "public"."orders" AS "orders"
    LEFT JOIN "public"."store_addresses" AS "store_addresses" ON "orders"."store_address_id" = "store_addresses"."id"
    LEFT JOIN "public"."stores" AS "stores" ON "store_addresses"."store_id" = "stores"."id"
    LEFT JOIN "public"."order_refund_incidents" AS "order_refund_incidents" ON "orders"."id" = "order_refund_incidents"."order_id"
WHERE ((( "orders"."activation_time_local" ) >= ((DATEADD(week,-1, DATE_TRUNC('week', DATE_TRUNC('day',GETDATE())) ))) AND ( "orders"."activation_time_local" ) < ((DATEADD(week,1, DATEADD(week,-1, DATE_TRUNC('week', DATE_TRUNC('day',GETDATE())) ) ))))) AND "orders"."country_code" = 'ES' AND "stores"."store_name" = 'Burger King' AND "order_refund_incidents"."order_id" IS NOT NULL
GROUP BY
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13
ORDER BY
    1 DESC
    

