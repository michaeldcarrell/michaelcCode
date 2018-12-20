SELECT so.id sales_order_id,
      soi.id sales_order_item_id,
      p.id product_id,
      m.id marketplace_id,
      soi.wholesale_cost*soi.quantity cogs,
      soi.unit_price*soi.quantity total_price,
      CASE
        WHEN asbi.avg_shipping_per_item_by_order=0 THEN p.estimated_shipping_cost*soi.quantity
        ELSE asbi.avg_shipping_per_item_by_order*soi.quantity
      END avg_shipping_on_order_time_qty,
      soi.quantity,
      CASE
        WHEN m.id = 5 THEN af.commission_fee
        ELSE m.commission_fee_percentage
      END commission_percent,
      m.transaction_fee,
      (CASE
        WHEN m.id = 5 AND soi.unit_price * af.commission_fee < 1 THEN 1
        WHEN m.id = 5 AND soi.unit_price * af.commission_fee > 1 THEN soi.unit_price * af.commission_fee
        WHEN m.id != 5 THEN soi.unit_price * m.commission_fee_percentage
      END
      +m.transaction_fee)*soi.quantity commission,
     (soi.unit_price - (soi.wholesale_cost +
        CASE
          WHEN asbi.avg_shipping_per_item_by_order = 0 THEN p.estimated_shipping_cost
          ELSE asbi.avg_shipping_per_item_by_order
        END +
        (CASE
          WHEN m.id = 5 AND soi.unit_price * af.commission_fee < 1 THEN 1
          WHEN m.id = 5 AND soi.unit_price * af.commission_fee > 1 THEN soi.unit_price * af.commission_fee
          WHEN m.id != 5 THEN soi.unit_price * m.commission_fee_percentage
        END +m.transaction_fee)))*soi.quantity margin,
     CASE
       WHEN soi.unit_price = 0 THEN 0
       ELSE
        (soi.unit_price - (soi.wholesale_cost +
          CASE
            WHEN asbi.avg_shipping_per_item_by_order = 0 THEN p.estimated_shipping_cost
            ELSE asbi.avg_shipping_per_item_by_order
          END +
          (CASE
            WHEN m.id = 5 AND soi.unit_price * af.commission_fee < 1 THEN 1
            WHEN m.id = 5 AND soi.unit_price * af.commission_fee > 1 THEN soi.unit_price * af.commission_fee
            WHEN m.id != 5 THEN soi.unit_price * m.commission_fee_percentage
          END +m.transaction_fee)))*soi.quantity/soi.unit_price
     END margin_percent,
     DATE_PART(YEAR, so.ca_created_at)||'-'||
        DATE_PART(MONTH, so.ca_created_at)||'-'||
        DATE_PART(DAY, so.ca_created_at)||' '||
        DATE_PART(HOURS, so.ca_created_at)||':'||
        DATE_PART(MINUTES, so.ca_created_at)||':'||
        DATE_PART(SECONDS, so.ca_created_at) ca_created_at,
     DATE_PART(YEAR, so.created_at)||'-'||DATE_PART(MONTH, so.created_at)||'-'||DATE_PART(DAY, so.created_at) DateBins,
     p.amazon_blocked,
     p.ca_is_blocked,
     v.is_active active_vendor,
     p.block_date,
     CASE
        WHEN po.shipping_cost IS NOT NULL OR so.shipping_cost IS NOT NULL THEN 'Closed'
        ELSE 'Open'
     END order_closed_status
FROM etailz_unity.sales_order_items soi
JOIN etailz_unity.sales_orders so ON so.id = soi.sales_order_id
JOIN etailz_unity.products p ON p.id = soi.product_id
JOIN etailz_unity.vendors v ON v.id = p.vendor_id
JOIN etailz_unity.marketplaces m ON m.marketplace_name = so.ca_site_name
LEFT JOIN etailz_unity.amazon_fees af ON af.id = p.amazon_category
JOIN etailz_unity.purchase_orders po ON so.id = po.sales_order_id
JOIN (SELECT so.id,
           CASE
               WHEN so.shipping_cost IS NOT NULL THEN
                 CASE
                   WHEN SUM(soi.quantity)=0 THEN 0
                   ELSE so.shipping_cost/SUM(soi.quantity)
                 END
               WHEN po.shipping_cost IS NOT NULL THEN
                 CASE WHEN SUM(soi.quantity)=0 THEN 0
                 ELSE po.shipping_cost/SUM(soi.quantity)
               END
               ELSE 0
           END avg_shipping_per_item_by_order
      FROM etailz_unity.sales_order_items soi
      JOIN etailz_unity.sales_orders so ON so.id = soi.sales_order_id
      JOIN etailz_unity.purchase_orders po ON so.id = po.sales_order_id
      JOIN etailz_unity.purchase_order_items poi ON po.id = poi.purchase_order_id
      GROUP BY so.id, so.shipping_cost, po.shipping_cost
) asbi ON asbi.id = so.id
WHERE po.deleted_at IS NULL
ORDER BY so.created_at DESC