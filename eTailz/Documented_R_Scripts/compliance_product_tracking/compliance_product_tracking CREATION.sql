CREATE DATABASE compliance_product_tracking;

USE compliance_product_tracking;

CREATE TABLE crude_sku_status (
	status_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  status NVARCHAR(255) NOT NULL,

  INDEX (status_id)
);

CREATE TABLE listings (
  listing_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
  asin VARCHAR(255) NOT NULL,
  status_id INT NOT NULL,
  
  FOREIGN KEY (status_id)
		REFERENCES crude_sku_status(status_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE crude_skus (
	crude_sku_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	crude_sku VARCHAR(255) NOT NULL,
    listing_id INT NOT NULL,
    current_file_path VARCHAR(255),
	
	FOREIGN KEY (listing_id)
		REFERENCES listings(listing_id)
		ON UPDATE CASCADE ON DELETE RESTRICT
);