SELECT bb.id as bill_id,
       ba.external_id as store_address_id,
       iii.concept,
       iii.base_amount/100 as base_amount,
       iii.tax_amount/100 as tax_amount,
       bb.status as bill_status,
       ii.state as invoice_status,
       bb.billing_cycle_start,
       bb.billing_cycle_end
from bls_bills bb
    join bls_actors ba on bb.actor_id = ba.id
    join inv_invoices ii on ii.bill_id = bb.id
    join inv_invoice_items iii on ii.id = iii.invoice_id
where ba.partner_family = 'BURGERKING'
and ba.country_code = 'ES'
and bb.closed_at > '2025-03-26'
and bb.status not in ('VOID')
