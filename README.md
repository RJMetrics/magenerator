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
  `base_discount_invoiced` decimal(12,4) DEFAULT NULL COMMENT 'Base Discount Invoiced',
  `base_discount_refunded` decimal(12,4) DEFAULT NULL COMMENT 'Base Discount Refunded',
  `base_subtotal` decimal(12,4) DEFAULT NULL COMMENT 'Base Subtotal',
  `increment_id` varchar(32) DEFAULT NULL COMMENT 'Increment Id',
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
`base_discount_amount` decimal(12,4) DEFAULT NULL COMMENT 'Base Discount Amount',
`base_discount_invoiced` decimal(12,4) DEFAULT NULL COMMENT 'Base Discount Invoiced',
`base_discount_refunded` decimal(12,4) DEFAULT NULL COMMENT 'Base Discount Refunded',
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
CREATE TABLE `shared_catalog` (
  `entity_id` int(10) UNSIGNED NOT NULL COMMENT 'Shared Catalog Entity Id',
  `name` varchar(255) DEFAULT NULL COMMENT 'Shared Catalog Name', 
  `description` text COMMENT 'Shared Catalog description',
  `customer_group_id` int(10) UNSIGNED NOT NULL COMMENT 'Customer Group Id',
  `type` smallint(5) UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Type: 0-custom, 1-public',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created At',
  `created_by` int(10) UNSIGNED DEFAULT NULL COMMENT 'Customer Id',
  `store_id` smallint(5) UNSIGNED DEFAULT NULL COMMENT 'Store ID'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Shared Catalog Table';
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
CREATE TABLE `store` (
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
  `coupon_code` varchar(255) DEFAULT NULL COMMENT 'Coupon Code',
  `reserved_order_id` varchar(64) DEFAULT NULL COMMENT 'Reserved Order Id'
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

```
CREATE TABLE `enterprise_rma` (
  `entity_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Entity Id',
  `date_requested` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Date Requested',
  `status` varchar(32) DEFAULT NULL COMMENT 'Status',
  `order_id` smallint(5) unsigned DEFAULT NULL COMMENT 'Order Id',
  `customer_id` smallint(5) unsigned DEFAULT NULL COMMENT 'Customer Id',
  PRIMARY KEY (`entity_id`),
  KEY `IDX_ENTERPRISE_RMA_ORDER_ID` (`order_id`),
  KEY `IDX_ENTERPRISE_RMA_CUSTOMER_ID` (`customer_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Enterprise Rma';
```

```
CREATE TABLE `enterprise_rma_item` (
  `entity_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Entity Id',
  `rma_entity_id` smallint(5) unsigned DEFAULT NULL COMMENT 'Rma Entity Id',
  `qty_returned` decimal(12,4) DEFAULT '0.0000' COMMENT 'Qty Returned',
  `order_item_id` int unsigned DEFAULT NULL COMMENT 'Order Item Id',
  `product_name` varchar(100) DEFAULT NULL COMMENT 'Product Id',
  `status` varchar(32) DEFAULT NULL COMMENT 'Status',
  PRIMARY KEY (`entity_id`),
  KEY `IDX_ENTERPRISE_RMA_ITEM_ORDER_ITEM_ID` (`order_item_id`),
  KEY `IDX_ENTERPRISE_RMA_ITEM_RMA_ENTITY_ID` (`rma_entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Enterprise Rma Item';
```

```
CREATE TABLE `catalog_product_entity` (
 `entity_id` int(10) UNSIGNED NOT NULL COMMENT 'Entity ID',
`sku` varchar(255) DEFAULT NULL COMMENT 'Sku',
`name` varchar(255) DEFAULT NULL COMMENT 'Name',
`created_at` timestamp NULL DEFAULT NULL COMMENT 'Created At',
`updated_at` timestamp NULL DEFAULT NULL COMMENT 'Updated At',
  PRIMARY KEY (`entity_id`),
  KEY `IDX_catalog_product_entity_ENTITY_ID` (`entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Catalog Product Entity';
```

```
CREATE TABLE `catalog_category_product` (
`category_id` int(10) unsigned NOT NULL COMMENT 'Category Id',
`product_id` int(10) unsigned NOT NULL COMMENT 'Product Id',
  PRIMARY KEY (`category_id`,`product_id`),
  KEY `IDX_catalog_category_entity_CATEGORY_ID_PRODUCT_ID` (`category_id`, `product_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Catalog Category Product';
```

```
CREATE TABLE `catalog_category_entity` (
`entity_id` int(10) unsigned NOT NULL COMMENT 'Entity Id',
`parent_id` int(10) unsigned DEFAULT NULL COMMENT 'Parent Id',
`level` int(5) unsigned DEFAULT NULL COMMENT 'Level',
`path` varchar(32) DEFAULT NULL COMMENT 'Path',
`created_at` timestamp NULL DEFAULT NULL COMMENT 'Created At',
`updated_at` timestamp NULL DEFAULT NULL COMMENT 'Updated At',
  PRIMARY KEY (`entity_id`),
  KEY `IDX_catalog_category_entity_ENTITY_ID` (`entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Catalog Category Entity';
```

```
CREATE TABLE `catalog_category_entity_varchar` (
`value_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Value Id',
`attribute_id` int(10) unsigned DEFAULT NULL COMMENT 'Attribute Id',
`entity_id` int(10) unsigned DEFAULT NULL COMMENT 'Entity Id',
`value` varchar(100) DEFAULT NULL COMMENT 'Value',
  PRIMARY KEY (`value_id`),
  KEY `IDX_catalog_category_entity_varchar_VALUE_ID` (`value_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Catalog Category Entity Varchar';
```

```
CREATE TABLE `negotiable_quote` (
  `quote_id` int(10) UNSIGNED NOT NULL COMMENT 'Quote ID',
  `is_regular_quote` smallint(5) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Is regular quote',
  `status` varchar(255) NOT NULL COMMENT 'Negotiable quote status',
  `quote_name` varchar(255) DEFAULT NULL COMMENT 'Negotiable quote name',
  `negotiated_price_type` smallint(5) UNSIGNED DEFAULT NULL COMMENT 'Negotiated price type',
  `negotiated_price_value` float DEFAULT NULL COMMENT 'Negotiable price value',
  `shipping_price` float DEFAULT NULL COMMENT 'Shipping price',
  `expiration_period` date DEFAULT NULL COMMENT 'Expiration period',
  `status_email_notification` smallint(5) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Status email notification',
  `snapshot` mediumtext COMMENT 'Snapshot',
  `has_unconfirmed_changes` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Has changes, not confirmed by merchant',
  `is_customer_price_changed` smallint(6) NOT NULL DEFAULT '0' COMMENT 'Is Customer Price Changed',
  `is_shipping_tax_changed` smallint(6) NOT NULL DEFAULT '0' COMMENT 'Is Shipping Tax Changed',
  `notifications` int(11) DEFAULT NULL COMMENT 'Notifications',
  `applied_rule_ids` varchar(255) DEFAULT NULL COMMENT 'Applied Rule Ids',
  `is_address_draft` smallint(6) NOT NULL DEFAULT '0' COMMENT 'Is address update from checkout',
  `deleted_sku` text COMMENT 'Deleted products SKU',
  `creator_type` smallint(6) NOT NULL DEFAULT '3' COMMENT 'Quote creator type',
  `creator_id` int(11) DEFAULT NULL COMMENT 'Quote creator id',
  `original_total_price` decimal(12,4) DEFAULT NULL COMMENT 'Original Total Price',
  `base_original_total_price` decimal(12,4) DEFAULT NULL COMMENT 'Base Original Total Price',
  `negotiated_total_price` decimal(12,4) DEFAULT NULL COMMENT 'Negotiated Total Price',
  `base_negotiated_total_price` decimal(12,4) DEFAULT NULL COMMENT 'Base Negotiated Total Price'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='negotiable_quote';
```

```
CREATE TABLE `negotiable_quote_history` (
  `history_id` int(10) UNSIGNED NOT NULL COMMENT 'History Id',
  `quote_id` int(10) UNSIGNED NOT NULL COMMENT 'Quote Id',
  `is_seller` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Is changes has made by seller',
  `author_id` int(10) UNSIGNED NOT NULL COMMENT 'Log author ID',
  `is_draft` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Is draft message',
  `status` varchar(255) NOT NULL DEFAULT 'created' COMMENT 'Log status',
  `log_data` text COMMENT 'Serialized log data',
  `snapshot_data` text COMMENT 'Serialized quote snapshot data',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created At'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Negotiable quote history log';
```

```
CREATE TABLE `negotiable_quote_comment` (
  `entity_id` int(10) UNSIGNED NOT NULL COMMENT 'Entity Id',
  `parent_id` int(10) UNSIGNED NOT NULL COMMENT 'Parent Id',
  `creator_type` smallint(5) UNSIGNED NOT NULL COMMENT 'Comment creator type',
  `is_decline` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Is quote was declined by seller',
  `is_draft` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Is draft message',
  `creator_id` int(10) UNSIGNED NOT NULL COMMENT 'Comment author ID',
  `comment` text COMMENT 'Comment',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created At'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Negotiable quote comments';
```

```
CREATE TABLE `company_payment` (
  `company_id` int(10) UNSIGNED NOT NULL COMMENT 'Company ID',
  `applicable_payment_method` smallint(5) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Applicable payment method',
  `available_payment_methods` text COMMENT 'Payment methods list',
  `use_config_settings` smallint(5) UNSIGNED NOT NULL DEFAULT '0' COMMENT 'Use config settings'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='company_payment';
```

```
CREATE TABLE `company_advanced_customer_entity` (
  `customer_id` int(10) UNSIGNED NOT NULL COMMENT 'Customer ID',
  `company_id` int(10) UNSIGNED NOT NULL COMMENT 'Company ID',
  `job_title` text COMMENT 'Job Title',
  `status` smallint(5) UNSIGNED NOT NULL DEFAULT '1' COMMENT 'Status',
  `telephone` varchar(255) DEFAULT NULL COMMENT 'Phone Number'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='company_advanced_customer_entity';
```

```
CREATE TABLE `company_credit` (
  `entity_id` int(10) UNSIGNED NOT NULL COMMENT 'Credit ID',
  `company_id` int(10) UNSIGNED NOT NULL COMMENT 'Company ID',
  `credit_limit` decimal(12,4) UNSIGNED DEFAULT NULL COMMENT 'Credit Limit',
  `balance` decimal(12,4) NOT NULL DEFAULT '0.0000' COMMENT 'Outstanding balance',
  `currency_code` varchar(3) NOT NULL DEFAULT '' COMMENT 'Currency Code',
  `exceed_limit` smallint(6) NOT NULL DEFAULT '0' COMMENT 'Exceed Limit'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Company Credit Table';
```

```
CREATE TABLE `admin_user` (
  `user_id` int(10) UNSIGNED NOT NULL COMMENT 'User ID',
  `email` varchar(128) DEFAULT NULL COMMENT 'User Email',
  `username` varchar(40) DEFAULT NULL COMMENT 'User Login',
  `is_active` smallint(6) NOT NULL DEFAULT '1' COMMENT 'User Is Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Admin User Table';
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
LOAD DATA INFILE 'enterprise_rma.csv' into table magento.enterprise_rma FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'enterprise_rma_item.csv' into table magento.enterprise_rma_item FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'catalog_product_entity.csv' into table magento.catalog_product_entity FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'catalog_category_product.csv' into table magento.catalog_category_product FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'catalog_category_entity.csv' into table magento.catalog_category_entity FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'catalog_category_entity_varchar.csv' into table magento.catalog_category_entity_varchar FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
```

If you need to load the data into a remote db from a local csv file, use this command

```
mysql -h {{HOSTNAME}} -P 3306 -u {{USERNAME}}} -p {{DATABASE_NAME}} --local-infile -e "LOAD DATA LOCAL INFILE 'data/sales_flat_order_address.csv' into table {{DATABASE_NAME}}.sales_flat_order_address FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 LINES;";
```
