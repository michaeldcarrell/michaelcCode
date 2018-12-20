UPDATE crude_sku_asins SET
  crude_sku_status = CASE
    (WHEN crude_sku_id = 1 AND asin = 'asin') THEN 1
  END,
  current_file_path = CASE
    (WHEN crude_sku_id = 1 AND asin = 'asin') THEN 'FilePath'
  END
