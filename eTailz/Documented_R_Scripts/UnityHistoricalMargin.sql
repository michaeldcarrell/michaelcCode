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
      so.ca_created_at, concat(year(so.created_at),'-', month(so.created_at), '-', day(so.created_at)) DateBins
FROM sales_order_items soi
JOIN sales_orders so ON so.id = soi.sales_order_id
JOIN products p ON p.id = soi.product_id
JOIN vendors v ON v.id = p.vendor_id
JOIN marketplaces m ON m.id = so.marketplace_id
LEFT JOIN amazon_fees af ON af.id = p.amazon_category
JOIN (SELECT so.id, Coalesce(so.shipping_cost/sum(soi.quantity),0) AvgShippingPerItemByOrder FROM sales_order_items soi
      JOIN sales_orders so ON so.id = soi.sales_order_id
      GROUP BY so.id
) asbi ON asbi.id = so.id
ORDER BY so.id DESC