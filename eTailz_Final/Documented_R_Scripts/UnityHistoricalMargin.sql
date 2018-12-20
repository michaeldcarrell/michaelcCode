SELECT so.id SalesOrderId,
      soi.id SalesOrderItemId,
      p.id ProductId,
      m.id MarketplaceId,
      soi.wholesale_cost*soi.quantity COGS,
      soi.unit_price*soi.quantity TotalPrice,
      CASE
        WHEN asbi.AvgShippingPerItemByOrder=0 THEN p.estimated_shipping_cost*soi.quantity
        ELSE asbi.AvgShippingPerItemByOrder*soi.quantity
      END AvgShippingOnOrderTimeQty,
      soi.quantity,
      CASE
        WHEN m.id = 5 THEN af.commission_fee
        ELSE m.commission_fee_percentage
      END CommissionPercent,
      m.transaction_fee,
      (CASE
        WHEN m.id = 5 AND soi.unit_price * af.commission_fee < 1 THEN 1
        WHEN m.id = 5 AND soi.unit_price * af.commission_fee > 1 THEN soi.unit_price * af.commission_fee
        WHEN m.id != 5 THEN soi.unit_price * m.commission_fee_percentage
      END
       +m.transaction_fee)*soi.quantity Commission,
       (soi.unit_price - (soi.wholesale_cost +
        CASE
          WHEN asbi.AvgShippingPerItemByOrder = 0 THEN p.estimated_shipping_cost
          ELSE asbi.AvgShippingPerItemByOrder
        END +
        (CASE
          WHEN m.id = 5 AND soi.unit_price * af.commission_fee < 1 THEN 1
          WHEN m.id = 5 AND soi.unit_price * af.commission_fee > 1 THEN soi.unit_price * af.commission_fee
          WHEN m.id != 5 THEN soi.unit_price * m.commission_fee_percentage
        END +m.transaction_fee)))*soi.quantity Margin,
      (soi.unit_price - (soi.wholesale_cost +
        CASE
          WHEN asbi.AvgShippingPerItemByOrder = 0 THEN p.estimated_shipping_cost
          ELSE asbi.AvgShippingPerItemByOrder
        END +
        (CASE
          WHEN m.id = 5 AND soi.unit_price * af.commission_fee < 1 THEN 1
          WHEN m.id = 5 AND soi.unit_price * af.commission_fee > 1 THEN soi.unit_price * af.commission_fee
          WHEN m.id != 5 THEN soi.unit_price * m.commission_fee_percentage
        END +m.transaction_fee)))*soi.quantity/soi.unit_price MarginPercent,
      so.ca_created_at,
      concat(year(so.created_at),'-', month(so.created_at), '-', day(so.created_at)) DateBins,
      p.amazon_blocked,
      p.ca_is_blocked,
      v.is_active ActiveVendor,
      p.block_date,
      CASE
          WHEN po.shipping_cost IS NOT NULL OR so.shipping_cost IS NOT NULL THEN 'Closed'
          ELSE 'Open'
      END order_closed_status
FROM sales_order_items soi
JOIN sales_orders so ON so.id = soi.sales_order_id
JOIN products p ON p.id = soi.product_id
JOIN vendors v ON v.id = p.vendor_id
JOIN marketplaces m ON m.marketplace_name = so.ca_site_name
LEFT JOIN amazon_fees af ON af.id = p.amazon_category
JOIN purchase_orders po on so.id = po.sales_order_id
JOIN (SELECT so.id,
           CASE
               WHEN so.shipping_cost IS NOT NULL THEN COALESCE(so.shipping_cost/sum(soi.quantity), 0)
               WHEN po.shipping_cost IS NOT NULL THEN COALESCE(po.shipping_cost/sum(soi.quantity), 0)
               ELSE 0
           END AvgShippingPerItemByOrder
      FROM sales_order_items soi
      JOIN sales_orders so ON so.id = soi.sales_order_id
      JOIN purchase_orders po on so.id = po.sales_order_id
      JOIN purchase_order_items poi on po.id = poi.purchase_order_id
      GROUP BY so.id
) asbi ON asbi.id = so.id
ORDER BY so.created_at DESC