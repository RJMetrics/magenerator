fs = require "fs"
randomDate = require "random-date"
Chance = require "chance"
chance = new Chance()
adjNoun = require "adj-noun"
csvString = require "csv-string"
async = require "async"

TOTAL_CUSTOMERS = 10
TOTAL_ADDRESSES = 10
TOTAL_PRODUCTS = 1000
TOTAL_ORDERS = 1000
ITEMS_MIN = 1
ITEMS_MAX = 5
CUSTOMER_FILE = 'data/customer_entity.csv'
ORDER_FILE = 'data/sales_flat_order.csv'
ORDER_ITEM_FILE = 'data/sales_flat_order_item.csv'
ADDRESS_FILE = 'data/sales_flat_order_address.csv'
PRODUCT_FILE = 'data/products.csv'
CURRENCY = "$"
STORE_NAME = "MageMart"

DATE_BIAS = 10 # [0..100] where 0 = today
DATE_WINDOW = 365 # Days to extend data into the past

products = []

go = (callback) ->

  console.log "Products = ", products.length

  # Generate list of customers
  customers = generateCustomers(TOTAL_CUSTOMERS)

  # Generate a list of addresses where they want to ship stuff (1-3 places per customer) and add them to the customers
  addresses = generateAddresses(TOTAL_ADDRESSES)

  # Generate a list of products
  #products= generateProducts(TOTAL_PRODUCTS)
  #products = getLumaProducts()

  # Make customers buy the things and ship them to locations
  orders = generateOrders(TOTAL_ORDERS, customers, addresses, products)

  # Export all the data to CSV
  exportCustomerData(customers)
  exportOrderData(orders, products, customers, addresses)
  callback null, 'done'

generateCustomers = (total) ->
  console.log "Generating customers..."
  customers = []
  createdAt = getRandomDate()
  for index in [0..total]
    customer =
      entity_id: index
      email: getRandomEmail()
      created_at: createdAt
      updated_at: createdAt
    customers.push(customer)
  return customers

generateAddresses = (total) ->
  console.log "Generating addresses..."
  addresses = []
  for index in [0..total]
    address =
      entity_id: index
      city: chance.city()
      state: chance.state()
      country: chance.country({full:true})
    addresses.push(address)
  return addresses

generateProducts = (total) ->
  console.log "Generating products..."
  products = []
  for index in [0..total]
    product =
      entity_id: index
      name: adjNoun().join('-')
      sku: "s#{index}"
      price: getRandomDec(0, 10)
    products.push(product)
  return products

generateOrders = (total, customers, addresses, products) ->
  console.log "Generating orders..."
  orders = []
  for index in [0..total]
    customer = getRandomItem(customers)
    address = getRandomItem(addresses)
    items = getItems(products, ITEMS_MIN, ITEMS_MAX)
    createdAt = getRandomDate()
    order =
      entity_id: index
      items: items
      grand_total: getCartValue(items)
      customer_id: customer.entity_id
      status: getOrderStatus()
      customer_email: customer.email
      store_id: 1
      other_currency_code: CURRENCY
      billing_address_id: address.entity_id
      shipping_address_id: address.entity_id
      store_name: STORE_NAME
      updated_at: createdAt
      created_at: createdAt
    orders.push(order)
  return orders

getRandomEmailDomain = () ->
  list = ['gmail', 'yahoo', 'magento', 'hotmail', 'aol']
  getRandomItem(list)

getRandomEmail = () ->
  "#{chance.first()}.#{chance.last()}@#{getRandomEmailDomain()}.com"

getRandomItem = (list) ->
  index = getRandomInt(0, list.length)
  return list[index]

getRandomInt = (min, max) ->
  r = Math.floor(getRandomFloat(min, max))
  return r

getRandomFloat = (min, max) ->
  (Math.random() * (max - min)) + min

getRandomDec = (min, max) ->
  dec = (Math.random() * (max - min)) + min
  dec.toFixed(2)

getItems = (products, min, max) ->
  totalItems = getRandomInt(min,max)
  items = []
  for index in [0..totalItems]
    item = getRandomItem(products)
    item.qty_ordered = getRandomInt(1,5)
    items.push(item)
  return items

getCartValue = (items) ->
  total = 0
  for item in items
    total += (item.price * item.qty_ordered)
  return total.toFixed(2)

getOrderStatus = () ->
  return "complete"

exportCustomerData = (customers) ->
  console.log "Exporting customer list... "
  csvData = convertArrayToCsv(customers)
  writeCsv(CUSTOMER_FILE, csvData)

exportAddressData = (addresses) ->
  console.log "Exporting addresses... "
  csvData = convertArrayToCsv(addresses)
  writeCsv(ADDRESS_FILE, csvData)

exportOrderData = (orders, products, customers, addresses) ->
  console.log "Exporting orders... "
  csvData = convertArrayToCsv(orders)
  writeCsv(ORDER_FILE, csvData)
  exportOrderItems(orders)
  exportAddressData(addresses)

exportOrderItems = (orders) ->
  csv = ''
  itemId = 0
  orderItems = []
  for order in orders
    for item in order.items
      createdAt = getRandomDate()
      orderItem =
        item_id: itemId++
        qty_ordered: getRandomInt(1,5)
        base_price: item.price
        name: item.name
        order_id: order.entity_id
        sku: item.sku
        product_type: 'tools'
        product_id: item.entity_id
        created_at: createdAt
        updated_at: createdAt
    orderItems.push(orderItem)
  csv = convertArrayToCsv(orderItems)
  writeCsv(ORDER_ITEM_FILE, csv)

getRandomDate = (start, end) ->
  min = 0
  max = DATE_WINDOW
  bias = DATE_BIAS
  influence = 1

  rand = Math.random() * (max - min) + min
  mix = Math.random() * influence
  value = rand * (1 - mix) + (bias * mix)
  date = new Date()
  date.setDate(date.getDate() - value)
  date.toISOString().slice(0, 19).replace('T', ' ');

getProducts = (callback) ->
  fs.readFile PRODUCT_FILE, 'utf-8', (err, data) ->
    console.log "Loaded product data..."
    products = convertCsvToObjectList(data)
    callback null, products

escapeQuotesForCsv = (str) ->
  if typeof str is 'string'
    str.replace('"','""')
  else
    str

convertCsvToArray = (str) ->
  return csvString.parse(str)

# Assumes a header row for attribute names
convertArrayToObjectList = (arr) ->
  header = arr[0]
  list = []
  for index in [1..TOTAL_PRODUCTS]
    ob = {}
    for headerIndex in [0..header.length-1]
      ob[header[headerIndex]] = arr[index][headerIndex]
    list.push ob
  return list

convertCsvToObjectList = (str) ->
  arr = convertCsvToArray(str)
  list = convertArrayToObjectList(arr)
  return list

convertArrayToCsv = (arr, subTableFile) ->
  csv = "#{getCsvHeader(arr[0])}\n"
  for item in arr
    csv += "#{convertToCsv(item)}\n"
  return csv.slice(0,-1)

getCsvHeader = (object) ->
  header = ''
  for key, value of object when not Array.isArray(value)
    header += "\"#{escapeQuotesForCsv(key)}\","
  return header.slice(0,-1)

convertToCsv = (object) ->
  csv = ''
  for key, value of object when not Array.isArray(value)
    csv += "\"#{escapeQuotesForCsv(value)}\","
  return csv.slice(0,-1)

writeCsv = (file, csv) ->
  fs.writeFile(file, csv, (err) ->
    if err
      return console.log err
    else
      console.log "Done."
  )

async.series([
  getProducts
  go
  ],
  (err, result) ->
    console.log "Error", err
    console.log "Complete!"
)

