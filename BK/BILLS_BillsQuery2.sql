SELECT bb.id as bill_id,
       ba.external_id as store_address_id,
       iii.concept,
       CAST(iii.base_amount / 100.0 AS DECIMAL(15, 2)) AS base_amount,
       CAST(iii.tax_amount / 100.0 AS DECIMAL(15, 2)) AS tax_amount
from bls_bills bb
    join bls_actors ba on bb.actor_id = ba.id
    join inv_invoices ii on ii.bill_id = bb.id
    join inv_invoice_items iii on ii.id = iii.invoice_id
where ba.partner_family = 'BURGERKING'
and ba.billing_cycle = 'WEEKLY'
and ba.country_code = 'ES'
AND ba.type IN ('PARTNER','CONSOLIDATED_PARTNER')
-- and bb.id in (324645137)
and bb.billing_cycle_start = '2024-08-26'
and bb.billing_cycle_end = '2024-09-01'

-----

SELECT bb.id as bill_id,
       ba.external_id as store_address_id,
       iii.concept,
       CAST(iii.base_amount / 100.0 AS DECIMAL(15, 2)) AS base_amount,
       CAST(iii.tax_amount / 100.0 AS DECIMAL(15, 2)) AS tax_amount
from bls_bills bb
    join bls_actors ba on bb.actor_id = ba.id
    join inv_invoices ii on ii.bill_id = bb.id
    join inv_invoice_items iii on ii.id = iii.invoice_id
where ba.partner_family = 'BURGERKING'
-- and ba.billing_cycle = 'WEEKLY"
and ba.country_code = 'ES'
-- and bb.id in (324645137)
and bb.billing_cycle_start = '2024-08-26'
and bb.billing_cycle_end = '2024-08-31'
-- and ba.external_id in (31768)
and bb.status not in ('VOID')