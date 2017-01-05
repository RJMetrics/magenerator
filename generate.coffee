fs = require "fs"
randomDate = require "random-date"
Chance = require "chance"
chance = new Chance()
csvParse = require "csv-parse"
async = require "async"
require "should"

TOTAL_CUSTOMERS = 10000
TOTAL_ADDRESSES = 10000
TOTAL_PRODUCTS = 200
TOTAL_ORDERS = 30000 #keep ratio of orders to customers at least 3:1 to allow interesting repeat ratios to form
ITEMS_MIN = 1
ITEMS_MAX = 20
CUSTOMER_GROUPS_FILE = 'data/customer_group.csv'
CUSTOMER_FILE = 'data/customer_entity.csv'
ORDER_FILE = 'data/sales_flat_order.csv'
ORDER_ITEM_FILE = 'data/sales_flat_order_item.csv'
ADDRESS_FILE = 'data/sales_flat_order_address.csv'
PRODUCT_FILE = 'data/products.csv'
CURRENCY = "$"
STORE_NAME = "MageMart"
COUPONS = chance.unique(chance.hash, 20, {casing: 'upper', length: 5})
CUSTOMER_GROUPS = [{id: 1, code: "NOT LOGGED IN"}
                   {id: 2, code: "General"}
                   {id: 3, code: "Wholesale"}
                   {id: 4, code: "Retailer"}
                   {id: 5, code: "US Resellers"}
                   {id: 6, code: "CA Resellers"}
                   {id: 7, code: "US High Frequency Purchasers"}
                   {id: 8, code: "CA High Frequency Purchasers"}
                   {id: 9, code: "Inactive"}
                   {id: 10, code: "B2b"}]

DATE_BIAS = 1 # [0..100] where 0 = today
DATE_WINDOW = 1095 # Days to extend data into the past

go = (products) ->
  # Generate customer groups
  customerGroups = generateCustomerGroups()

  # Generate list of customers
  customers = generateCustomers(TOTAL_CUSTOMERS)

  # Generate a list of addresses where they want to ship stuff (1-3 places per customer) and add them to the customers
  addresses = generateAddresses(TOTAL_ADDRESSES)

  # Make customers buy the things and ship them to locations
  orders = generateOrders(TOTAL_ORDERS, customers, addresses, products)

  # Export all the data to CSV
  exportCustomerGroups(customerGroups)
  exportCustomerData(customers)
  exportOrderData(orders, products, customers, addresses)
  console.log "Complete!"

generateCustomerGroups = () ->
  console.log "Generating customers groups..."
  customerGroups = []
  for group in CUSTOMER_GROUPS
    customerGroup =
      customer_group_id: group.id
      customer_group_code: group.code
      tax_class_id: 1
    customerGroups.push(customerGroup)
  return customerGroups

generateCustomers = (total) ->
  console.log "Generating customers..."
  customers = []
  for index in [1..total]
    createdAt = getRandomDate()
    customer =
      entity_id: index
      email: getRandomEmail()
      group_id: getRandomItem(CUSTOMER_GROUPS).id
      created_at: createdAt
      updated_at: createdAt
    customers.push(customer)
  return customers

generateAddresses = (total) ->
  console.log "Generating addresses..."
  addresses = []
  for index in [1..total]
    address =
      entity_id: index
      city: chance.city()
      region: chance.state({full: true})
      country_id: 'US'
    addresses.push(address)
  return addresses

generateOrders = (total, customers, addresses, products) ->
  console.log "Generating orders..."
  orders = []
  orderCounts = [] #a count of orders by customer_id
  for index in [1..total]
    address = getRandomItem(addresses)
    couponCode = if chance.bool({likelihood: 10}) then getRandomItem(COUPONS) else null
    items = getItems(products, ITEMS_MIN, ITEMS_MAX)
    grandTotal = getCartValue(items)
    shippingAmount = getRandomItem([1.99,3.99,6.99])
    discountAmount = getDiscountAmount(couponCode, grandTotal)
    createdAt = getRandomDate()
    customer = getCustomerToBuyFavoringRepeats(customers, orderCounts, createdAt)
    utmParameters = getUtmParameters()
    
    order =
      entity_id: index
      items: items
      grand_total: grandTotal
      base_grand_total: grandTotal
      customer_id: customer.entity_id
      status: getOrderStatus()
      customer_email: customer.email
      store_id: 1
      order_currency_code: CURRENCY
      billing_address_id: address.entity_id
      shipping_address_id: address.entity_id
      store_name: STORE_NAME
      coupon_code: couponCode
      base_tax_amount: (0.08 * grandTotal).toFixed(2)
      base_shipping_amount: shippingAmount
      base_discount_amount: discountAmount
      utm_source: utmParameters.utmSource
      utm_medium: utmParameters.utmMedium
      utm_campaign: utmParameters.utmCampaign
      created_at: createdAt
      updated_at: createdAt
    orders.push(order)
    orderCounts[customer.entity_id] = if orderCounts[customer.entity_id] then orderCounts[customer.entity_id] + 1 else 1
  return orders

getCustomerToBuyFavoringRepeats = (customers, orderCounts, orderCreatedAt) ->
  #rather than return a truly random customer, bias toward previous buyers
  cust = getRandomItem(customers)
  purchases = if orderCounts[cust.entity_id] then orderCounts[cust.entity_id] else 0;
  if purchases == 0
    return cust #make sure each customer gets one purchase to create a baseline

  #among repeat buyers, the more purchases you've made the more likely to be picked (exponentially)
  #this creates incrementally increasing repeat purchase probability values
  probability = Math.min(100, (purchases*purchases)) 
  if chance.bool({likelihood: probability})
    #we have a winner -- return cust, but first make sure their created_at date is at or before this purchase
    if cust.created_at > orderCreatedAt
      cust.created_at = orderCreatedAt #make sure customer created at or before first order placed
    return cust
  return getCustomerToBuyFavoringRepeats(customers, orderCounts) #recursively try another customer

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

getDiscountAmount = (couponCode, grandTotal) ->
  if couponCode
    discountPercent = getRandomItem([0.05,0.1,0.25])
    return -1*(discountPercent*grandTotal).toFixed(2)
  return 0.00

getUtmParameters = () ->
  #set UTM parameters, whose values are dependent upon each other
  utmParameters = {}
  utmParameters.utmCampaign = 'not set'
  utmParameters.utmMedium = 'none'
  if chance.bool({likelihood: 35})
    utmParameters.utmSource = 'Google'
    if chance.bool({likelihood: 20})
      utmParameters.utmMedium = 'cpc'
      utmParameters.utmCampaign = getRandomItem(['Sale Item Ads','Competitor Keywords','Long Tail Keywords'])
    else
      utmParameters.utmMedium = 'organic'
  else if chance.bool({likelihood: 50})  
    utmParameters.utmSource = getRandomItem(['Facebook','Twitter'])
    utmParameters.utmMedium = 'socialmedia'
  else if chance.bool({likelihood: 20})  
    utmParameters.utmSource = 'Newsletter'
    utmParameters.utmMedium = 'email'
    utmParameters.utmCampaign = getRandomItem(['Holiday Newsletter','Product Update Newsletter','Sale Announcement'])
  else if chance.bool({likelihood: 10})  
    utmParameters.utmSource = 'referral'
  else 
    utmParameters.utmSource = 'direct'
  return utmParameters

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
    total += (+item.price * +item.qty_ordered)
  return total.toFixed(2)

getOrderStatus = () ->
  if chance.bool({likelihood: 83}) then "complete" #83% of orders
  else if chance.bool({likelihood: 90}) then "processing" #90% of 17% of orders
  else getRandomItem(['pending','canceled','picked','shipped','picking']) 

exportCustomerGroups = (customerGroups) ->
  console.log "Exporting customer group list... "
  csvData = convertArrayToCsv(customerGroups)
  writeCsv(CUSTOMER_GROUPS_FILE, csvData)

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
        base_price: +item.price
        name: item.name
        order_id: order.entity_id
        parent_item_id: null
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
    csvParse data, {delimiter: ','}, (err, result) ->
      products = convertArrayToObjectList(result)
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
    # Write null values as real nulls
    csv += if value? then "\"#{escapeQuotesForCsv(value)}\"," else ","
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
  ],
  (err, result) ->
    products = result[0]
    if err
      console.log "Something went wrong: #{err}"
    go(products)
)

