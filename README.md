# magenerator
Generate sample Magento store data

Repo Owner: Ben Garvey

Owned by Magento

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
npm install chance
npm install adj-noun
npm install random-date
```

# Running
```
coffee generate.coffee
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
  `created_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Created At',
  `updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Updated At',
  PRIMARY KEY (`entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8 COMMENT='Customer Entity';
```

```
CREATE TABLE `sales_flat_order` (
  `entity_id` int UNSIGNED NOT NULL auto_increment COMMENT 'Entity Id' ,
  `grand_total` decimal(12,4) NULL COMMENT 'Grand Total' ,
  `customer_id` int UNSIGNED NULL COMMENT 'Customer Id' ,
  `status` varchar(32) NULL COMMENT 'Status' ,
  `customer_email` varchar(255) NULL COMMENT 'Customer Email' ,
  `store_id` smallint UNSIGNED NULL COMMENT 'Store Id' ,
  `order_currency_code` varchar(255) NULL COMMENT 'Order Currency Code' ,
  `billing_address_id` int NULL COMMENT 'Billing Address Id' ,
  `shipping_address_id` int NULL COMMENT 'Shipping Address Id' ,
  `store_name` varchar(255) NULL COMMENT 'Store Name' ,
  `coupon_code` varchar(255) NULL COMMENT 'Coupon Code' ,
  `base_tax_amount` decimal(12,4) NULL COMMENT 'Base Tax Amount' ,
  `base_shipping_amount` decimal(12,4) NULL COMMENT 'Base Shipping Amount' ,
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
CREATE TABLE `sales_flat_order_item` (
`item_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Item Id',
`qty_ordered` decimal(12,4) DEFAULT '0.0000' COMMENT 'Qty Ordered',
`base_price` decimal(12,4) NOT NULL DEFAULT '0.0000' COMMENT 'Base Price',
`name` varchar(255) DEFAULT NULL COMMENT 'Name',
`order_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Order Id',
`sku` varchar(255) DEFAULT NULL COMMENT 'Sku',
`product_type` varchar(255) DEFAULT NULL COMMENT 'Product Type',
`product_id` int(10) unsigned DEFAULT NULL COMMENT 'Product Id',
`created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Created At',
`updated_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Updated At',
PRIMARY KEY (`item_id`),
KEY `IDX_SALES_FLAT_ORDER_ITEM_ORDER_ID` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Sales Flat Order Item';
```

```
CREATE TABLE `sales_flat_order_address` (
`entity_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Entity Id',
`city` varchar(255) DEFAULT NULL COMMENT 'City',
`state` varchar(255) DEFAULT NULL COMMENT 'State',
`country` varchar(255) DEFAULT NULL COMMENT 'Country',
PRIMARY KEY (`entity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Sales Flat Order Address';
```

Finally, import all csv file into the mysql tables by running the following commands:

```
LOAD DATA INFILE 'customer_entity.csv' into table magento.customer_entity FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'sales_flat_order.csv' into table magento.sales_flat_order FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'sales_flat_order_item.csv' into table magento.sales_flat_order_item FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
LOAD DATA INFILE 'sales_flat_order_address.csv' into table magento.sales_flat_order_address FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 LINES;
```
