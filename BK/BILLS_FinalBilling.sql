SELECT ii.serial_number,
       ba.external_id as store_address_id,
       ba.store_id as store_id,
       ba.store_address_external_id as store_address_external_id,
       ii.recipient_fiscal_info,
       upper(ifd.tax_id),
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
         join inv_fiscal_details ifd on ba.external_id = ifd.actor_external_id and ba.type= ifd.actor_type
where ba.partner_family = 'BURGERKING'
  and ba.country_code = 'ES'
  and bb.status not in ('VOID')
  and bb.closed_at > '2025-04-30'
  and ifd.actor_type IN ('PARTNER', 'CONSOLIDATED_PARTNER')
  

