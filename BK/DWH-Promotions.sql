WITH promotion_values AS (


    SELECT g.country_code                                                   AS country_code,
           o.city_code                                                      AS city_code,
      ppu.order_id,
           o.code                                                           AS order_code,
           (CASE
                WHEN opc.cancellation_strategy = 'PAY_PRODUCTS'
                    THEN 'Yes'
                ELSE 'No' END)                                              AS order_paid_to_partner,
           sa.id                                                            AS store_address_id,
           s.id                                                             AS store_id,
           s.store_name                                                     AS store_name,
           cd.company_name                                                  AS company_name,
           cd.tax_id                                                        AS company_tax_id, --10
           ppu.partner_promotion_id                                        AS partner_promotion_id,
           pp.start_date                                                    AS promotion_start_date,
           pp.end_date                                                      AS promotion_end_date,
           pp.name                                                          AS promotion_name,
           pp.percentage                                                    AS percentage_discount,
           (CASE
                WHEN LOWER(pp.name) ILIKE 'mkt\\_%' OR LOWER(pp.name) ILIKE 'mktg\\_%' OR LOWER(pp.name) ILIKE 'mtk\\_%'
                    THEN 'MKT'
                WHEN LOWER(pp.name) ILIKE 'nb\\_%' OR LOWER(pp.name) ILIKE 'nbs\\_%'
                    THEN 'NB'
                WHEN LOWER(pp.name) ILIKE 'gr\\_%' OR LOWER(pp.name) ILIKE 'grc\\_%' OR LOWER(pp.name) ILIKE 'grs\\_%'
                    THEN 'GR'
                WHEN LOWER(pp.name) ILIKE 'pop\\_%' OR LOWER(pp.name) ILIKE 'pops\\_%'
                    THEN 'POPS'
                ELSE '??' END)                                              AS budget_owner,   --20
           o.activation_time_local                                          AS order_activation_time_local,
           dpo.dispatching_time_local                                       AS order_dispatching_time_local,
           o.partner_order                                                  AS partner_order,
           (CASE ---All Delivered Orders
                WHEN o.final_status = 'DeliveredStatus'
                    THEN (CASE
                              WHEN (tg.entity_tags ILIKE '%Qcommerce%')
                                  THEN 'GROCERIES'
                              WHEN o.vertical = 'COURIER'
                                  THEN 'COURIER'
                              WHEN o.vertical = 'QUIERO'
                                  THEN 'QUIERO'
                              WHEN o.is_food
                                  THEN 'FOOD'
                              ELSE 'OTHER'
                    END) END)                                               AS order_type,
           o.mcd_partner                                                    AS mcdo_order,
           o.is_marketplace                                                 AS marketplace,
           g.customer_tax                                                   AS tax_rate,
           (CASE WHEN LOWER(pp.name) ILIKE '%%notauto%%' THEN TRUE ELSE FALSE END) AS promotion_manual_invoicing,
           pp.type                                                    AS promotion_type,
           o.final_status                                                   AS order_final_status,
           COALESCE(opppc.commission_on_discounted_price, FALSE)            AS order_with_commission_on_discounted_price,
           --ppu.amount,
           --ppu.partner_promotion_sponsor_id,
         ppu.strategy as payment_strategy,
           SUM((CASE when
                    pp.type IN
                         ('PERCENTAGE_DISCOUNT', 'TWO_FOR_ONE') and amount_partner >0
               then
               CAST(amount_partner/ POWER(10, cu.digits)  AS DECIMAL(15, 2))
                    ELSE 0 END))                                            AS product_balance_partner,
               SUM((CASE when
                    pp.type IN
                         ('PERCENTAGE_DISCOUNT', 'TWO_FOR_ONE') and amount_glovo >0
               then
               CAST(amount_glovo/ POWER(10, cu.digits)  AS DECIMAL(15, 2))
                    ELSE 0 END))                                            AS product_balance_glovo
           ,
           SUM((CASE
                    WHEN pp.type = 'FREE_DELIVERY' and amount_glovo >0 then
                        CAST(amount_glovo / POWER(10, cu.digits) AS DECIMAL(15, 2))
                    ELSE 0 END))                                            AS free_delivery_balance_glovo,
             SUM((CASE
                    WHEN pp.type = 'FREE_DELIVERY' and amount_partner >0  then
                        CAST(amount_partner/ POWER(10, cu.digits) AS DECIMAL(15, 2))
                    ELSE 0 END))                                            AS free_delivery_balance_partner,
            SUM((CASE
                    WHEN pp.type = 'FLAT_DELIVERY' and amount_glovo >0 then
                           CAST(amount_glovo/ POWER(10, cu.digits) AS DECIMAL(15, 2))
                    ELSE 0 END))                                            AS flat_delivery_balance_glovo,
           SUM((CASE
                    WHEN pp.type = 'FLAT_DELIVERY' and amount_partner >0 then
                           CAST(amount_partner/ POWER(10, cu.digits) AS DECIMAL(15, 2))
                    ELSE 0 END))                                            AS flat_delivery_balance_partner,
           SUM(CAST((CASE
                         WHEN pp.type IN
                              ('FLAT_DELIVERY', 'FREE_DELIVERY') then case
                                      WHEN o.final_status = 'DeliveredStatus'
                                          THEN
                                          op.weather_surcharge
                                      ELSE op.effective_weather_surcharge END
                         ELSE 0 END) / POWER(10, cu.digits) AS DECIMAL(15, 2)))
                                                                            AS weather_surcharge_balance,
           SUM((CASE
                    WHEN pp.type IN
                         ('FLAT_DELIVERY', 'FREE_DELIVERY')
                        THEN CAST(op.service_fee / POWER(10, cu.digits) AS DECIMAL(15, 2))
                    ELSE 0 END))                                            AS service_fee_balance

    FROM
       /* Partner_promotion_uses table has 2 lines(or more per order), so to avoid duplicates in the data, especially for Co-Financed promotions, we use two subqueries to separte what is paid by Glovo or Partner.
                         and then have one line per order, with the sum of what is covered by Glovo and what is covered by Partner(using a full outer join of the two subqueries).
                                                                                   The rows in PPU that have the amount set to 0 are filtered out as we dont need that info
                                                                                   */
   (select coalesce(glo.order_id, pa.order_id) as order_id, amount_glovo, amount_partner,
           case when amount_glovo is null then pa.partner_promotion_id when amount_partner is null then glo.partner_promotion_id else glo.partner_promotion_id end as partner_promotion_id,
              CASE WHEN (glo.order_id is not null and pa.order_id is not null) then 'CO-FINANCED'
               when glo.order_id  then 'ASSUMED_BY_GLOVO'
                   when pa.order_id  then 'ASSUMED_BY_PARTNER'
                       else 'UNDEFINED' end as strategy from
(select order_id,partner_promotion_sponsor_id,partner_promotion_id, sum(amount) as amount_glovo from partner_promotion_uses where partner_promotion_sponsor_id =1 and deleted is false group by 1,2,3 having amount_glovo >0 ) glo
full outer join
(select order_id,partner_promotion_sponsor_id,partner_promotion_id, sum(amount) as amount_partner from  partner_promotion_uses where partner_promotion_sponsor_id =2 and deleted is false group by 1,2,3 having amount_partner >0) pa
    on pa.order_id = glo.order_id and pa.partner_promotion_id = glo.partner_promotion_id) ppu

              join     orders                                      o on o.id = ppu.order_id

        JOIN      order_pricings                              op ON op.order_id = o.id
        LEFT JOIN dispatched_partner_orders                   dpo ON dpo.order_id = o.id
        JOIN      geography                                   g ON g.code = o.city_code
        LEFT JOIN store_addresses                             sa ON sa.id = o.store_address_id
        LEFT JOIN stores                                      s ON s.id = sa.store_id
        LEFT JOIN company_details                             cd ON cd.id = sa.company_detail_id
        LEFT JOIN partner_promotions                          pp ON pp.id = ppu.partner_promotion_id
        JOIN      currency                                    cu ON cu.code = o.currency
        LEFT JOIN tagged_stores                               tg ON sa.store_id = tg.store_id
        LEFT JOIN order_partner_compensations                 opc ON opc.order_id = o.id
        LEFT JOIN order_pricing_partner_promotion_commissions opppc ON opppc.order_id = op.order_id
    WHERE ppu.partner_promotion_id IS NOT NULL
      AND o.deleted IS FALSE
      AND o.activation_time IS NOT NULL
      AND o.final_status IN ('DeliveredStatus', 'CanceledStatus')
        /* Substitute the dates with the correct invoicing period */
      AND dpo.dispatching_time_local BETWEEN '2024-03-25 00:00:00' AND '2024-03-31 23:59:59'
      AND o.country_code = 'ES'
      AND o.store_address_id IN (178594,161117,164428,190067,190081,190049,165557,163952,164223,164232,165359,161694,161844,152145,152146,165314,161705,161690,161704,156087,154889,156092,191815,165317,165287,161702,161718,156095,156106,156117,156121,156128,156140,164924,165002,165009,165019,164812,164840,164957,164968,164981,164987,164992,165014,165020,161109,163967,161586,161594,156177,164718,156180,158765,165558,156080,234785,165309,165312,161111,165280,165282,165286,165288,178252,165266,165244,165265,164499,165274,165247,165255,165260,164542,164573,164587,164595,158753,164603,164792,164810,164847,164900,165313,165291,182880,165425,165306,165621,165577,165578,173497,158735,158736,164619,158752,234769,165612,165330,164581,161120,161123,165447,165328,150122,165618,152144,162033,164545,165262,185055,165264,165261,164553,165259,165263,164638,150106,164651,152163,165617,158708,165564,178264,163970,164756,163977,162423,161895,161134,161606,156281,336752,158750,161739,173344,162271,162001,164652,164467,156711,161735,165620,152150,336686,176232,165327,161837,161892,161142,163998,164672,164492,164556,173454,156285,161621,161126,283869,161754,161077,158729,176221,161693,336703,161774,158743,156287,158747,158748,189767,156288,190083,165302,152176,173485,158761,158760,161848,161918,173502,164613,176177,535146,161963,313457,161118,178285,165574,164005,234738,178290,164826,394672,164011,165358,547062,152165,150113,156297,165516,161936,176209,181029,234771,185172,178305,165579,161828,161778,191802,158763,152158,161711,161732,161741,173494,156315,161136,178307,158813,178062,173506,178310,161127,176187,161681,173474,257008,611324,161841,156328,234781,161559,173492,156697,164715,161886,176215,161107,161939,173472,161133,178312,173348,456069,181032,156680,162429,180080,162404,165331,605314,170153,161764,206928,164684,165326,556462,173480,176191,425283,175114,161793,165271,156440,187196,234766,161977,165454,161775,161137,160929,161856,158762,178313,178319,161948,331199,165322,176184,161100,158744,161651,152149,158757,163679,150126,161834,704790,144306,493453,172934,158758,165583,165296,173484,156441,161105,234793,152156,156444,156445,178322,178547,611987,165536,643117,165587,162314,150124,176164,152159,178325,165360,164416,152168,165367,161657,256796,152139,326608,161669,161899,185104,161831,161631,199516,173463,178330,454990,178335,161767,173504,161143,187227,164706,178528,162045,176262,178338,161737,248417,176260,161905,161885,187514,183545,158759,161609,161583,694006,178870,190093,181050,164228,165278,161888,162014,173481,181038,164748,162406,161850,161838,162342,185401,158619,156446,157215,157217,158623,178344,176234,336706,180076,186563,178350,161822,182897,175566,171235,186066,186554,185963,198054,165406,199745,199832,195704,179366,174760,184745,180072,180064,144308,180067,181275,185185,185096,185092,182560,182556,182552,181010,219428,191806,216320,185953,187204,195721,184748,186037,185976,184793,198059,198065,185389,190121,190090,163750,223271,215317,215531,223580,195693,190125,178073,587975,329704,204693,195694,219074,220637,424160,158755,204687,165357,208353,215847,215549,215862,161071,219710,223166,223113,223171,223149,220725,249149,164536,249502,223263,223184,244863,556455,239500,260844,305258,239518,611989,239454,238698,238690,238700,249117,239377,238692,589841,253684,249422,267303,253669,303161,302227,249439,239507,249431,372698,267108,267113,273962,327776,274547,273557,273947,277332,165622,165279,275172,445521,275255,283866,164534,296766,298307,329054,301707,163765,313377,336750,306381,306367,319503,156689,363289,337692,338567,314068,173486,407275,371399,327582,346959,447914,362222,362199,369862,369811,369841,369830,369797,366744,362224,369852,440668,447340,163820,372806,372830,388476,388465,499709,410360,499652,406928,396946,372763,372783,406666,161813,405043,179368,440654,164439,440735,447738,352525,447928,164685,406664,161113,404998,620339,404996,419325,426652,434076,429818,445911,436020,161115,438577,438625,439055,435426,497454,497454,480541,448636,440618,440696,165555,448721,474381,466395,464163,556456,178058,163896,537960,493889,494022,185084,537577,549001,537336,161542,165337,520493,537723,610880,537718,566396,198076,549457,537716,562565,566400,165364,581831,321654,596512,589864,566489,607145,566410,566363,601978,609097,595269,607510,594371,607149,585013,178093,165433,589859,590578,590568,596203,566393,598892,605455,601466,165362,601948,611269,616015,616007,614293,616011,615961,614941,165386,618531,616354,624752,633176,628938,628965,642262,625026,616018,628931,628879,633187,628861,634804,641257,641176,643176,164658,643183,643174,655849,656333,647959,657935,596167,165300,189785,165602,185202,178234)
    --AND o.id IN (231365639)

    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28
    ),


cost_allocation  AS (
         SELECT pv.*,
                ROUND((CASE
                           WHEN (free_delivery_balance_partner > 0 OR flat_delivery_balance_partner > 0)
                               THEN flat_delivery_balance_partner + free_delivery_balance_partner
                           ELSE 0 END), 2) AS delivery_promotion_assumed_by_partner_with_vat,
                ROUND(CAST(delivery_promotion_assumed_by_partner_with_vat / (1 + tax_rate) AS DECIMAL(15, 4)),

                      2)                   AS delivery_promotion_assumed_by_partner_without_vat,

                ROUND(CASE
                          WHEN (free_delivery_balance_glovo > 0 OR flat_delivery_balance_glovo > 0)
                              THEN flat_delivery_balance_glovo + free_delivery_balance_glovo +
                                                service_fee_balance +
                                                weather_surcharge_balance
                          ELSE 0 END,
                      2)                   AS delivery_promotion_assumed_by_glovo,
                ROUND(CASE WHEN product_balance_partner > 0
                              THEN product_balance_partner
                          ELSE 0 END,
                      2)                   AS product_promotion_assumed_by_partner,
                ROUND(CASE
                          WHEN product_balance_glovo > 0
                              THEN product_balance_glovo
                          ELSE 0 END,
                      2)                   AS product_promotion_assumed_by_glovo
         FROM
             promotion_values pv
     )

SELECT store_address_id,order_id, SUM(product_promotion_assumed_by_partner) as total_product_promotion_assumed_by_partner,
       SUM(delivery_promotion_assumed_by_partner_with_vat) as total_delivery_promotion_assumed_by_partner_with_vat,
       SUM(delivery_promotion_assumed_by_partner_without_vat) as total_delivery_promotion_assumed_by_partner_without_vat,
       SUM(product_promotion_assumed_by_glovo) as total_product_promotion_assumed_by_glovo,
       sum(delivery_promotion_assumed_by_glovo) as total_delivery_promotion_assumed_by_glovo
       from cost_allocation
group by 1,2
