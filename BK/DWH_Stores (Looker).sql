SELECT
    "partner_integration_store_addresses"."store_address_external_id" AS "store_addresses.external_id",
    "orders"."city_code" AS "orders.city_code",
    "stores"."id" AS "stores.id",
    "store_addresses"."id" AS "store_addresses.id",
    "store_addresses"."address" AS "store_addresses.address",
    "store_admin_users"."email" AS "store_admin_users.email",
    "company_details"."company_name" AS "company_details.company_name",
    "company_details"."tax_id" AS "company_details.tax_id"
FROM
    "public"."orders" AS "orders"
    LEFT JOIN "public"."store_addresses" AS "store_addresses" ON "orders"."store_address_id" = "store_addresses"."id"
    LEFT JOIN "public"."store_admin_users" AS "store_admin_users" ON "store_addresses"."store_admin_id" = "store_admin_users"."user_id"
    LEFT JOIN "public"."company_details" AS "company_details" ON "store_addresses"."company_detail_id" = "company_details"."id"
    LEFT JOIN "public"."stores" AS "stores" ON "store_addresses"."store_id" = "stores"."id"
    LEFT JOIN "public"."partner_integration_store_addresses" AS "partner_integration_store_addresses" ON "store_addresses"."id" = "partner_integration_store_addresses"."store_address_id"
WHERE ((( "orders"."activation_time_local" ) >= ((DATEADD(day,-25, DATE_TRUNC('day',GETDATE()) ))) AND ( "orders"."activation_time_local" ) < ((DATEADD(day,25, DATEADD(day,-25, DATE_TRUNC('day',GETDATE()) ) ))))) AND ("orders"."country_code" = 'ES' AND (NOT "orders"."mcd_partner" OR "orders"."mcd_partner" IS NULL)) AND ("orders"."partner_order" AND (((stores.enabled = '1')) AND "stores"."store_name" = 'Burger King'))
GROUP BY
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8
ORDER BY
    1