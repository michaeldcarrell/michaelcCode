SELECT so.id||'-'||po.id||'-'||soi.id AS composite_key,
       po.id po_id,
       'http://unity.etailz.com/salesOrders/'||so.id AS unity,
       CASE
         WHEN so.marketplace_id != 5 THEN
           'https://complete.channeladvisor.com/Orders/OrderDetail.mvc/Edit?apid=12016759&invoiceID='||so.ca_id
         ELSE
           'https://sellercentral.amazon.com/hz/orders/details?_encoding=UTF8&orderId='||so.ca_site_order_id
       END
       AS site_order_url,
       p.ca_sku etailz_sku,
       RIGHT(p.ca_sku, LENGTH(p.ca_sku)-POSITION('-' IN p.ca_sku)) vendor_sku,
       po.created_at po_submitted_at,
       v.name vendor,
       '' weekdays_since_placed,
       '' status,
       '' notes
FROM etailz_unity.sales_orders so
JOIN etailz_unity.purchase_orders po ON so.id = po.sales_order_id
JOIN etailz_unity.sales_order_items soi ON so.id = soi.sales_order_id
JOIN etailz_unity.products p ON soi.product_id = p.id
JOIN etailz_unity.vendors v ON v.id = p.vendor_id
JOIN (SELECT soi.id soi_id, MAX(pois.label)
       FROM etailz_unity.sales_order_items soi
       JOIN etailz_unity.purchase_order_items poi ON poi.sales_order_item_id = soi.id
       JOIN etailz_unity.purchase_order_item_status pois ON pois.id = poi.status_id
       JOIN etailz_unity.purchase_orders po ON po.id = poi.purchase_order_id
       WHERE pois.label in ('Placed', 'Confirmed', 'Shipped', 'Tracked')
       GROUP BY soi.id
) con ON con.soi_id = soi.id
WHERE EXTRACT(HOURS FROM (current_timestamp - po.created_at)) > 48
AND so.ca_shipping_status NOT IN ('Canceled', 'Refunded', 'Cannot Ship')
AND po.deleted_at IS NULL
ORDER BY po.created_at DESC
