SELECT 
actor_external_id,
consolidated_actor_id,
partner_family,
invoicing_model,
invoicing_scope,
billing_cycle
FROM fa_actor_fiscal_information
WHERE partner_family = 'BURGERKING'
AND invoicing_scope = 'CONSOLIDATED_ACTOR'
GROUP BY 1,2,3,4,5,6

