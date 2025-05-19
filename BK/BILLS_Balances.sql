SELECT ba.id,
       ba.external_id,
       coalesce(bab.exact_balance, bab.balance / 100) as real_balance,
       country_code,
       bab.currency
FROM bls_actor_balances AS bab
         LEFT JOIN bls_actors AS ba ON bab.actor_id = ba.id
WHERE country_code = 'ES'
  AND ba.type IN ('PARTNER', 'CONSOLIDATED_PARTNER')
  AND ba.partner_family in ('BURGERKING')
  AND billing_cycle = 'WEEKLY'
  -- AND external_id IN (594371)
  having  real_balance <> 0;