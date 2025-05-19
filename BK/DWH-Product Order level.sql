SELECT  b.store_address_id as store_address_id,
      order_id,
      SUM(b.supply_delayed),
  COUNT(order_code)
FROM (
        SELECT store_address_id,
               city,
               dispatching_time_local,
               order_id,
               order_code,
               round(amount, 4) AS supply_delayed,
               cancellation_strategy,
               order_status
        FROM (
                 SELECT o.store_address_id AS store_address_id,
                        o.dispatching_time_local,
                        o.id              AS order_id,
                        o.code            AS order_code,
                        g.code            AS city,
                        g.country_code,
                        CASE
                            WHEN o.mcd_partner
                                THEN o.purchases_estimated_price
                            WHEN g.country_code = 'KE' AND opc.cancellation_strategy = 'PAY_PRODUCTS'
                                THEN o.purchases_estimated_price
                            WHEN opc.cancellation_strategy = 'PAY_PRODUCTS'
                                THEN CASE
                                /* first check if we have a final cost */
                                         WHEN opc.declared_cost > 0
                                             /* convert minor to major currency units */
                                             THEN opc.declared_cost / power(10, c.digits)
                                /* otherwise consider the estimated */
                                         ELSE o.purchases_estimated_price END
                            ELSE 0 END    AS amount,
                        opc.cancellation_strategy,
                        s.type            AS order_status
                 FROM orders o
                          JOIN statuses s ON o.id = s.order_id
                          JOIN geography g ON g.code = o.city_code
                          JOIN currency c ON o.currency = c.code
                          LEFT JOIN order_partner_compensations opc
                                    ON opc.order_id = o.id -- we also care about mktplace partners
                          LEFT JOIN dispatched_partner_orders dpo ON dpo.order_id = o.id
               WHERE g.country_code = 'ES'
                   AND dpo.dispatching_time_local BETWEEN '2024-03-04 00:00:00' AND '2024-03-10 23:59:59'
                 AND  o.store_address_id IN (161767,173348,173454,176164,535146)
                   AND s.type IN ('DeliveredStatus', 'CanceledStatus')) a) b
GROUP BY 1,2;



---------


SELECT *
FROM orders WHERE id IN (100390288311,100349431150)

SELECT * FROM orders
WHERE code in ('PTAMZYMA','PL7GLBKM','P7ECSUPN','P4WSQN8M','PLCHKAMX','PAL19QPA','PH74PC2H','P5VM1WRW','PEFNQFSZ','PCR9UTFT','PULN3SVU','P8CBADL1','PBHTTR1M','PJANNX3P','PNFSTEM8','PRN16ZZL','PQSQ961R','PRXGHBNM','PJY1XS7D','PF11GM2M','PBNCFNUH','P1NN9XJ1','PLL7FX13','P5HGGCLX','PJDLCUNU','P1F5ALHG','PFLGP1JL')