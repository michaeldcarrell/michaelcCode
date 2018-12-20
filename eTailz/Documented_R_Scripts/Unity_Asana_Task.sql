SELECT p.ca_sku "Inventory Number",
       p.asin ASIN,
       RIGHT(p.ca_sku, LENGTH(p.ca_sku)- POSITION('-' IN p.ca_sku)) MPN,
       LPAD(p.upc, 13, '0') EAN,
       LPAD(p.upc, 12,  '0') UPC,
       p.ca_title "Auction Title",
       LENGTH(p.ca_title) "Length_Auction Title",
       'eBay Title' Attribute1_Name,
       CASE
           WHEN LENGTH(p.ca_title) > 120 THEN p.ca_title
       END Attribute1_Value,
       CASE
           WHEN LENGTH(p.ca_title) > 120 THEN LENGTH(p.ca_title)
       END "Length_eBay Title",
       'eBay, Walmart, Sears, Pricefalls, Shop.com, Overstock' Labels,
       'Walmart Price' Attribute7_Name,
       mp.price Attribute7_Value,
       'Jet Price' Attribute8_Name,
       mp.price Attribute8_Value,
       'Sears Price' Attribute9_Name,
       mp.price Attribute9_Value,
       mp.price "Buy It Now Price",
       'eBay Key Features' Attribute10_Name,
       'Wish Price' Attribute11_Name,
       mp.price Attribute11_Value,
       'SHOP Price' Attribute12_Name,
       mp.price Attribute12_Value,
       'Overstock Price' Attribute13_Name,
       mp.price Attribute13_Value,
       'Pricefalls Price' Attribute14_Name,
       mp.price Attribute14_Value,
       'DS' Classification,
       v.id VendorId,
       'Dropship' VendorType,
       v.supplier_id||'-'||RIGHT(p.ca_sku, LENGTH(p.ca_sku)-POSITION('-' IN p.ca_sku)) CompositeSku
FROM etailz_unity.products p
JOIN etailz_unity.vendors v on p.vendor_id = v.id
JOIN etailz_unity.marketplace_product mp on p.id = mp.product_id
WHERE p.ca_is_blocked = 0
AND p.amazon_blocked = 0
AND mp.marketplace_id = 5
AND v.is_active = 1
AND v.id NOT IN (45)
ORDER BY p.id