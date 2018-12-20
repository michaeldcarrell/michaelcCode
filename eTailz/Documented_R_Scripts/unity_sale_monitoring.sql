SELECT so.id SalesOrderId,
      soi.id SalesOrderItemId,
      p.id ProductId,
      m.id MarketplaceId,
      soi.wholesale_cost*soi.quantity COGS,
      soi.unit_price*soi.quantity TotalPrice,
      so.ca_created_at,
      p.amazon_blocked,
      p.ca_is_blocked,
      CASE 
        WHEN v.is_active = 1 THEN 0
        ELSE 1
      END InactiveVendor,
      p.block_date
FROM sales_order_items soi
JOIN sales_orders so ON so.id = soi.sales_order_id
JOIN products p ON p.id = soi.product_id
JOIN marketplaces m on m.id = so.marketplace_id
JOIN vendors v on p.vendor_id = v.id
ORDER BY so.created_at DESC