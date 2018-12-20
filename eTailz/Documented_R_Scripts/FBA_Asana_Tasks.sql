SELECT s.sku 'Inventory Number',
       detail.asin ASIN,
       cost.item_number MPN,
       RIGHT(s.gtin, 13) EAN,
       RIGHT(s.gtin, 12) UPC,
       detail.title 'Auction Title',
       LENGTH(detail.title) 'Length_Auction Title',
       'eBay Title' Attribute1_Name,
       CASE
           WHEN LENGTH(detail.title) > 120 THEN detail.title
       END Attribute1_Value,
       CASE
           WHEN LENGTH(detail.title) > 120 THEN LENGTH(detail.title)
       END 'Length_eBay Title',
       'Jet, eBay, Walmart, Wish, Sears, Pricefalls, Shop.com, Overstock' Labels,
       'Walmart Price' Attribute7_Name,
       detail.listing_price Attribute7_Value,
       'Jet Price' Attribute8_Name,
       detail.listing_price Attribute8_Value,
       'Sears Price' Attribute9_Name,
       detail.listing_price Attribute9_Value,
       detail.listing_price 'Buy It Now Price',
       'eBay Key Features' Attribute10_Name,
       'Wish Price' Attribute11_Name,
       detail.listing_price Attribute11_Value,
       'SHOP Price' Attribute12_Name,
       detail.listing_price Attribute12_Value,
       'Overstock Price' Attribute13_Name,
       detail.listing_price Attribute13_Value,
       'Pricefalls Price' Attribute14_Name,
       detail.listing_price Attribute14_Value,
       'FBA' Classification,
       p.id VendorId,
       'FBA' VendorType
FROM skus s
JOIN sku_details detail on s.id = detail.sku_id
JOIN sku_costs cost on s.id = cost.sku_id
JOIN partners p on s.partner_id = p.id
JOIN system_list_items sli on p.account_status_id = sli.id
WHERE s.ignore_reorder_until_date < CURDATE()
AND p.prefix = '4741'
AND sli.id = 6
ORDER BY p.id