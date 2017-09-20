# magenerator
Generate sample Magento store data for use in our analytics demo

Contact: Ben Garvey bgarvey@magento.com

License: OSL 3.0

# Docker Setup
If you have docker installed
```
docker build -t magenerator .
docker run -v $(pwd)/data:/opt/app/data magenerator coffee generate.coffee
```

# Setup
If you don't have node, npm, or coffeescript installed
```
sudo apt-get update
sudo apt-get install nodejs
sudo apt-get install npm
sudo npm install -g coffee-script
```

Then in the magenerator directory
```
npm install
```

# Running
```
npm run-script generate
```

The data files are generated and placed in the data directory


# Importing to MySQL

First create a database called "magento", like this:

`CREATE DATABASE magento;`

Then copy all csv files to the proper mysql directory, like this:

`sudo cp data/*.csv /var/lib/mysql/magento/`

Create all the necessary tables:

```
CREATE TABLE `customer_entity` (
  `entity_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Entity Id',
  `email` varchar(255) DEFAULT NULL COMMENT 'Email',
  `group_id` smallint(5) unsigned NOT NULL DEFAULT 0 COMMENT 'Group Id',
  `store_id` smallint(5) unsigned DEFAULT NULL COMMENT 'Store Id',
  `created_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Created At',
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Updated At',
  PRIMARY KEY (`entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Customer Entity';
```

```
CREATE TABLE `sales_order` (
  `entity_id` int UNSIGNED NOT NULL auto_increment COMMENT 'Entity Id' ,
  `grand_total` decimal(12,4) NULL COMMENT 'Grand Total' ,
  `base_grand_total` decimal(12,4) NULL COMMENT 'Base Grand Total' ,
  `base_discount_amount` decimal(12,4) DEFAULT NULL COMMENT 'Base Discount Amount',
  `base_subtotal` decimal(12,4) DEFAULT NULL COMMENT 'Base Subtotal',
  `customer_id` int UNSIGNED NULL COMMENT 'Customer Id' ,
  `status` varchar(32) NULL COMMENT 'Status' ,
  `customer_email` varchar(255) NULL COMMENT 'Customer Email' ,
  `store_id` smallint UNSIGNED NULL COMMENT 'Store Id' ,
  `base_currency_code` varchar(255) NULL COMMENT 'Base Currency Code' ,
  `order_currency_code` varchar(255) NULL COMMENT 'Order Currency Code' ,
  `billing_address_id` int NULL COMMENT 'Billing Address Id' ,
  `shipping_address_id` int NULL COMMENT 'Shipping Address Id' ,
  `store_name` varchar(255) NULL COMMENT 'Store Name' ,
  `coupon_code` varchar(255) NULL COMMENT 'Coupon Code' ,
  `base_tax_amount` decimal(12,4) NULL COMMENT 'Base Tax Amount' ,
  `base_shipping_amount` decimal(12,4) NULL COMMENT 'Base Shipping Amount' ,
  `utm_source` varchar(255) NULL COMMENT 'UTM Source',
  `utm_medium` varchar(255) NULL COMMENT 'UTM Medium',
  `utm_campaign` varchar(255) NULL COMMENT 'UTM Campaign',
  `customer_group_id` smallint(6) NULL COMMENT 'Group Id',
  `created_at` timestamp NULL default NULL COMMENT 'Created At' ,
  `updated_at` timestamp NULL default NULL COMMENT 'Updated At' ,
  PRIMARY KEY (`entity_id`),
  INDEX `IDX_SALES_FLAT_ORDER_STATUS` (`status`),
  INDEX `IDX_SALES_FLAT_ORDER_STORE_ID` (`store_id`),
  INDEX `IDX_SALES_FLAT_ORDER_CREATED_AT` (`created_at`),
  INDEX `IDX_SALES_FLAT_ORDER_CUSTOMER_ID` (`customer_id`),
  INDEX `IDX_SALES_FLAT_ORDER_UPDATED_AT` (`updated_at`)
) COMMENT='Sales Flat Order' ENGINE=INNODB charset=utf8;
```

```
CREATE TABLE `sales_order_item` (
`item_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Item Id',
`qty_ordered` decimal(12,4) DEFAULT '0.0000' COMMENT 'Qty Ordered',
`base_price` decimal(12,4) NOT NULL DEFAULT '0.0000' COMMENT 'Base Price',
`name` varchar(255) DEFAULT NULL COMMENT 'Name',
`order_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Order Id',
`parent_item_id` int(10) unsigned DEFAULT NULL COMMENT 'Parent Item Id',
`sku` varchar(255) DEFAULT NULL COMMENT 'Sku',
`product_type` varchar(255) DEFAULT NULL COMMENT 'Product Type',
`product_id` int(10) unsigned DEFAULT NULL COMMENT 'Product Id',
`store_id` smallint(5) unsigned DEFAULT NULL COMMENT 'Store Id',
`created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Created At',
`updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Updated At',
PRIMARY KEY (`item_id`),
KEY `IDX_SALES_FLAT_ORDER_ITEM_ORDER_ID` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Sales Flat Order Item';
```

```
CREATE TABLE `sales_order_address` (
`entity_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Entity Id',
`city` varchar(255) DEFAULT NULL COMMENT 'City',
`region` varchar(255) DEFAULT NULL COMMENT 'Region',
`country_id` varchar(2) DEFAULT NULL COMMENT 'Country',
PRIMARY KEY (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Sales Flat Order Address';
```

```
CREATE TABLE `customer_group` (
`customer_group_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Group Id',
`customer_group_code` varchar(32) DEFAULT NULL COMMENT 'Customer Group Code',
`tax_class_id` int(10) DEFAULT 0 COMMENT 'Tax Class Id',
PRIMARY KEY (`customer_group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Customer Group';
```

```
CREATE TABLE `core_store` (
`store_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Store Id',
`name` varchar(255) DEFAULT NULL COMMENT 'Store Name',
PRIMARY KEY (`store_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Core Store';
```

```
CREATE TABLE `company` (
  `entity_id` int(10) UNSIGNED NOT NULL COMMENT 'Company ID',
  `status` smallint(5) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Status',
  `company_name` varchar(40) DEFAULT NULL COMMENT 'Company Name',
  `legal_name` varchar(80) DEFAULT NULL COMMENT 'Legal Name',
  `company_email` varchar(255) DEFAULT NULL COMMENT 'Company Email',
  `vat_tax_id` varchar(40) DEFAULT NULL COMMENT 'VAT Tax ID',
  `reseller_id` varchar(40) DEFAULT NULL COMMENT 'Reseller ID',
  `comment` text COMMENT 'Comment',
  `street` varchar(40) DEFAULT NULL COMMENT 'Street',
  `city` varchar(40) DEFAULT NULL COMMENT 'City',
  `country_id` varchar(2) DEFAULT NULL COMMENT 'Country ID',
  `region` varchar(40) DEFAULT NULL COMMENT 'Region',
  `region_id` int(10) UNSIGNED DEFAULT NULL COMMENT 'Region Id',
  `postcode` varchar(30) DEFAULT NULL COMMENT 'Postcode',
  `telephone` varchar(20) DEFAULT NULL COMMENT 'Telephone',
  `customer_group_id` int(10) UNSIGNED DEFAULT NULL COMMENT 'Customer Group ID',
  `sales_representative_id` int(10) UNSIGNED DEFAULT NULL COMMENT 'Sales Representative ID',
  `super_user_id` int(10) UNSIGNED DEFAULT NULL COMMENT 'Super User ID',
  `reject_reason` text COMMENT 'Reject Reason',
  `rejected_at` timestamp NULL DEFAULT NULL COMMENT 'Rejected At'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Company Table';
```

```
CREATE TABLE `quote` (
  `entity_id` int(10) UNSIGNED NOT NULL COMMENT 'Entity Id',
  `store_id` smallint(5) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Store Id',
  `created_at` timestamp NULL DEFAULT NULL COMMENT 'Created At',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `converted_at` timestamp NULL DEFAULT NULL COMMENT 'Converted At',
  `is_active` smallint(5) UNSIGNED DEFAULT '1' COMMENT 'Is Active',
  `is_virtual` smallint(5) UNSIGNED DEFAULT '0' COMMENT 'Is Virtual',
  `is_multi_shipping` smallint(5) UNSIGNED DEFAULT '0' COMMENT 'Is Multi Shipping',
  `items_count` int(10) UNSIGNED DEFAULT '0' COMMENT 'Items Count',
  `items_qty` decimal(12,4) DEFAULT '0.0000' COMMENT 'Items Qty',
  `grand_total` decimal(12,4) DEFAULT '0.0000' COMMENT 'Grand Total',
  `base_grand_total` decimal(12,4) DEFAULT '0.0000' COMMENT 'Base Grand Total',
  `checkout_method` varchar(255) DEFAULT NULL COMMENT 'Checkout Method',
  `customer_id` int(10) UNSIGNED DEFAULT NULL COMMENT 'Customer Id',
  `coupon_code` varchar(255) DEFAULT NULL COMMENT 'Coupon Code'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Sales Flat Quote';

```

```
CREATE TABLE `quote_item` (
  `item_id` int(10) UNSIGNED NOT NULL COMMENT 'Item Id',
  `quote_id` int(10) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Quote Id',
  `created_at` timestamp NULL DEFAULT NULL COMMENT 'Created At',
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP COMMENT 'Updated At',
  `product_id` int(10) UNSIGNED DEFAULT NULL COMMENT 'Product Id',
  `store_id` smallint(5) UNSIGNED DEFAULT NULL COMMENT 'Store Id',
  `is_virtual` smallint(5) UNSIGNED DEFAULT NULL COMMENT 'Is Virtual',
  `sku` varchar(255) DEFAULT NULL COMMENT 'Sku',
  `name` varchar(255) DEFAULT NULL COMMENT 'Name',
  `qty` decimal(12,4) NOT NULL DEFAULT '0.0000' COMMENT 'Qty',
  `price` decimal(12,4) NOT NULL DEFAULT '0.0000' COMMENT 'Price',
  `base_price` decimal(12,4) NOT NULL DEFAULT '0.0000' COMMENT 'Base Price',
  `product_type` varchar(255) DEFAULT NULL COMMENT 'Product Type'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Sales Flat Quote Item';
```



Finally, import all csv file into the mysql tables by running the following commands:

```
LOAD DATA INFILE 'customer_group.csv' into table magento.customer_group FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'customer_entity.csv' into table magento.customer_entity FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'core_store.csv' into table magento.core_store FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'sales_flat_order.csv' into table magento.sales_flat_order FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'sales_flat_order_item.csv' into table magento.sales_flat_order_item FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'sales_flat_order_address.csv' into table magento.sales_flat_order_address FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'company.csv' into table magento.company FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'quote.csv' into table magento.quote FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'quote_item.csv' into table magento.quote_item FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
```

If you need to load the data into a remote db from a local csv file, use this command

```
mysql -h {{HOSTNAME}} -P 3306 -u {{USERNAME}}} -p {{DATABASE_NAME}} --local-infile -e "LOAD DATA LOCAL INFILE 'data/sales_flat_order_address.csv' into table {{DATABASE_NAME}}.sales_flat_order_address FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES;";
```
