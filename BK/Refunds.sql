select ba.type as actor_type,
		bb.id,
		bbi.creation_time,
       ba.external_id as actor_external_id,
       bbi.description as description,
       bbi.currency as currency,
       bbi.amount / 100 as amount,
       bbi.tax / 100 as tax_amount,
       bbi.type as type,
       bbi.source_type,
       bbi.source_id
       -- boi.dispatching_time
from bls_bill_items bbi
    join bls_bills bb on bbi.bill_id = bb.id
    join bls_actors ba on bb.actor_id = ba.id
    -- join bls_orders_information boi on boi.order_id = bbi.source_id -- and bbi.source_type = 'ORDER'
where ba.type in ('PARTNER', 'CONSOLIDATED_PARTNER')
-- and bbi.bill_item_import_id is null
-- and ba.external_id in (161609)
and bbi.source_id in (513832669,513882161,514080306,514120786,514140086,514141890,514669526,514695183,515371907,515661956,515663781,515716873,516018060,516198428,516227468,516283693,516288158,516402587,516574097,516702088,516801334,516883720,517000638,517025823,517031068,517049194,517088265,517357274,517363086,517370627,517416881,517446076,517514968,517531406,517533654,517762651,517802546,517806252,517809893)
and bbi.type = 'REFUND'
-- and bbi.bill_id in (136898516,136893999,136855749,136856163,136855749,136898516,136898516,136855749)
-- and date(bbi.creation_time) BETWEEN '2022-03-28' and '2022-03-31'