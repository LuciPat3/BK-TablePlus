SELECT
    ba.external_id as store_address_id,
    ii.serial_number,
    ba.store_address_external_id as store,
    ii.recipient_fiscal_info as recipient_fiscal_info,
    upper(ifd.tax_id),
    -- bb.closed_at,
    -- bb.billing_cycle_start,
    --- bb.billing_cycle_end,
    SUM( DISTINCT(CASE WHEN iii.concept = 'ACCUMULATED_DEBT' THEN iii.base_amount/100 END)) AS ACCUMULATED_DEBT,
    SUM( DISTINCT(CASE WHEN iii.concept = 'COMMISSION_PARTNER_INCIDENT' THEN iii.base_amount/100 END)) AS COMMISSION_PARTNER_INCIDENT,
    SUM( DISTINCT(CASE WHEN iii.concept = 'COST_OF_INCIDENTS' THEN iii.base_amount/100 END)) AS COST_OF_INCIDENTS,
    SUM( DISTINCT(CASE WHEN iii.concept = 'COURIER_ACCESS_FEE' THEN iii.base_amount/100 END)) AS COURIER_ACCESS_FEE,
    SUM( DISTINCT(CASE WHEN iii.concept = 'DELIVERY_FEE_PROMOTION_ASSUMED' THEN iii.base_amount/100 END)) AS DELIVERY_FEE_PROMOTION_ASSUMED,
    SUM( DISTINCT(CASE WHEN iii.concept = 'DELIVERY_FEE_TO_CHARGE_PARTNER' THEN iii.base_amount/100 END)) AS DELIVERY_FEE_TO_CHARGE_PARTNER,
    SUM( DISTINCT(CASE WHEN iii.concept = 'DISCOUNT' THEN iii.base_amount/100 END)) AS DISCOUNT,
    SUM( DISTINCT(CASE WHEN iii.concept = 'GLOVO_ALREADY_PAID' THEN iii.base_amount/100 END)) AS GLOVO_ALREADY_PAID,
    SUM( DISTINCT(CASE WHEN iii.concept = 'INVOICE_BALANCE' THEN iii.base_amount/100 END)) AS INVOICE_BALANCE,
    SUM( DISTINCT(CASE WHEN iii.concept = 'PARTNER_INVOICE_DELIVERY_FEES' THEN iii.base_amount/100 END)) AS PARTNER_INVOICE_DELIVERY_FEES,
    SUM( DISTINCT(CASE WHEN iii.concept = 'PARTNERSHIP_FEE' THEN iii.base_amount/100 END)) AS PARTNERSHIP_FEE,
    SUM( DISTINCT(CASE WHEN iii.concept = 'PLATFORM_FEE' THEN iii.base_amount/100 END)) AS PLATFORM_FEE,
    SUM( DISTINCT(CASE WHEN iii.concept = 'PRODUCTS' THEN iii.base_amount/100 END)) AS PRODUCTS,
    SUM( DISTINCT(CASE WHEN iii.concept = 'PRODUCTS_PARTNER_INCIDENT' THEN iii.base_amount/100 END)) AS PRODUCTS_PARTNER_INCIDENT,
    SUM( DISTINCT(CASE WHEN iii.concept = 'PRODUCTS_TO_PAY_FOR_INCIDENTS' THEN iii.base_amount/100 END)) AS PRODUCTS_TO_PAY_FOR_INCIDENTS,
    SUM( DISTINCT(CASE WHEN iii.concept = 'PROMOTION_ASSUMED_BY_PARTNER' THEN iii.base_amount/100 END)) AS PROMOTION_ASSUMED_BY_PARTNER,
    SUM( DISTINCT(CASE WHEN iii.concept = 'SANCTIONS' THEN iii.base_amount/100 END)) AS SANCTIONS,
    SUM( DISTINCT(CASE WHEN iii.concept = 'TAX' THEN iii.tax_amount/100 END)) AS TAX_AMOUNT,
    SUM( DISTINCT(CASE WHEN iii.concept = 'TAXABLE_BASE' THEN iii.base_amount/100 END)) AS TAXABLE_BASE,
    SUM( DISTINCT(CASE WHEN iii.concept = 'TOTAL_INVOICE' THEN iii.base_amount/100 END)) AS TOTAL_INVOICE,
    SUM( DISTINCT(CASE WHEN iii.concept = 'TOTAL_PAYABLE' THEN iii.base_amount/100 END)) AS PAYABLE
FROM bls_bills bb
    JOIN bls_actors ba ON bb.actor_id = ba.id
    JOIN inv_invoices ii ON ii.bill_id = bb.id
    JOIN inv_invoice_items iii ON ii.id = iii.invoice_id
    JOIN inv_fiscal_details ifd ON ba.external_id = ifd.actor_external_id
WHERE ba.partner_family = 'BURGERKING'
     AND ifd.actor_type IN ('PARTNER', 'CONSOLIDATED_PARTNER')
    AND ba.country_code = 'ES'
    AND bb.status NOT IN ('VOID')
    AND bb.closed_at > '2025-04-03'
GROUP BY 1,2,3