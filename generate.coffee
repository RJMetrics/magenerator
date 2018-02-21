fs = require "fs"
randomDate = require "random-date"
Chance = require "chance"
chance = new Chance()
csvParse = require "csv-parse"
async = require "async"
require "should"

TOTAL_CUSTOMERS = 10000
TOTAL_ADDRESSES = 10000
TOTAL_PRODUCTS = 1000 #1994 is max number of products in file
TOTAL_ORDERS = 30000 #keep ratio of orders to customers at least 3:1 to allow interesting repeat ratios to form
ITEMS_MIN = 1
ITEMS_MAX = 20
TOTAL_STORES = 5
TOTAL_COMPANIES = 20
TOTAL_QUOTES = 1000 # These are the number of quotes without orders
TOTAL_NEGOTIABLE_QUOTES = 1000
TOTAL_ADMIN_USERS = 10
CUSTOMER_GROUPS_FILE = 'data/customer_group.csv'
CUSTOMER_FILE = 'data/customer_entity.csv'
PRODUCT_INPUT_FILE = 'data/products.csv'
ORDER_FILE = 'data/sales_order.csv'
ORDER_ITEM_FILE = 'data/sales_order_item.csv'
ADDRESS_FILE = 'data/sales_order_address.csv'
STORES_FILE = 'data/store.csv'
COMPANIES_FILE = 'data/company.csv'
QUOTES_FILE = 'data/quote.csv'
QUOTE_ITEMS_FILE = 'data/quote_item.csv'
RETURN_FILE = 'data/enterprise_rma.csv'
RETURN_ITEMS_FILE = 'data/enterprise_rma_item.csv'
PRODUCT_FILE = 'data/catalog_product_entity.csv'
CATEGORY_FILE = 'data/catalog_category_entity.csv'
CATEGORY_VARCHAR_FILE = 'data/catalog_category_entity_varchar.csv'
PRODUCT_CATEGORY_FILE = 'data/catalog_category_product.csv'
ADMIN_USER_FILE = 'data/admin_user.csv'

SHARED_CATALOG_FILE = 'data/shared_catalog.csv'
NEGOTIABLE_QUOTE_FILE = 'data/negotiable_quote.csv'
NEGOTIABLE_QUOTE_HISTORY_FILE = 'data/negotiable_quote_history.csv'
NEGOTIABLE_QUOTE_COMMENT_FILE = 'data/negotiable_quote_comment.csv'
COMPANY_PAYMENT_FILE = 'data/company_payment.csv'
COMPANY_ADVANCED_CUSTOMER_ENTITY_FILE = 'data/company_advanced_customer_entity.csv'
COMPANY_CREDIT_FILE = 'data/company_credit.csv'

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
RETURN_PERIOD_DAYS = 90 # Returns happen within 90 days of the order
RETURN_PERCENT = 3 # This is the percent of ITEMS that get returned!

go = (products) ->

  # Generate product and category tables
  productsAndCategories = generateProductsAndCategories(products) #[productEntities, productCategoryEntities, categoryEntities, catalogCategoryEntityVarchars]

  # Generate customer groups
  customerGroups = generateCustomerGroups()

  # Generate list of stores
  stores = generateStores(TOTAL_STORES)

  # Generate list of companies
  companies = generateCompanies(TOTAL_COMPANIES)

  # Generate list of customers
  customers = generateCustomers(TOTAL_CUSTOMERS, stores)

  # Generate a list of addresses where they want to ship stuff (1-3 places per customer) and add them to the customers
  addresses = generateAddresses(TOTAL_ADDRESSES)

  # Make customers buy the things and ship them to locations
  orders = generateOrders(TOTAL_ORDERS, customers, addresses, products, stores)

  # Make customers return some of the things :(
  returns = generateReturnsAndReturnItems(orders)

  # Generate list of quotes
  qResult = generateQuotes(TOTAL_QUOTES, customers, products, stores, orders)
  quotes = qResult[0]
  quoteItems = qResult[1]

  # Generate shared catalog
  sharedCatalog = generateSharedCatalogs() # shared catalogs hardcoded

  # Generate negotiable quotes
  negotiableQuotes = generateNegotiableQuotes(TOTAL_NEGOTIABLE_QUOTES, quotes)

  # Generate negotiable quote history
  # negotiableQuoteHistory = generateNegotiableQuoteHistories(1000)

  # Generate negotiable quote comment
  # negotiableQuoteComments = generateNegotiableQuoteComments(1000)

  # Generate company payment
  companyPayments = generateCompanyPayments(1000)

  # Generate company advanced_customer_entity
  companyAdvancedCustomerEntity = generateCompanyAdvancedCustomerEntities(1000)

  # Generate company credit
  companyCredit = generateCompanyCredits(1000)

  # Generate company credit
  adminUsers = generateAdminUsers(TOTAL_ADMIN_USERS)

  # Export all the data to CSV
  exportData(COMPANIES_FILE, companies, "Exporting company list... ")
  exportData(CUSTOMER_GROUPS_FILE, customerGroups, "Exporting customer group list... ")
  exportData(CUSTOMER_FILE, customers, "Exporting customer list... ")
  exportData(QUOTES_FILE, quotes, "Exporting quote list... ")
  exportData(QUOTE_ITEMS_FILE, quoteItems, "Exporting quote item list... ")
  exportData(STORES_FILE, stores, "Exporting store list... ")
  exportOrderData(orders, products, customers, addresses)
  exportReturnData(returns)
  exportData(PRODUCT_FILE, productsAndCategories[0], "Exporting products...")
  exportData(PRODUCT_CATEGORY_FILE, productsAndCategories[1], "Exporting product category mappings...")
  exportData(CATEGORY_FILE, productsAndCategories[2], "Exporting categories...")
  exportData(CATEGORY_VARCHAR_FILE, productsAndCategories[3], "Exporting category names...")

  exportData(SHARED_CATALOG_FILE, sharedCatalog, "Exporting shared catalog...")
  exportData(NEGOTIABLE_QUOTE_FILE, negotiableQuotes, "Exporting negotiable quotes...")
  # exportData(NEGOTIABLE_QUOTE_HISTORY_FILE, negotiableQuoteHistory, "Exporting negotiable quote history...")
  # exportData(NEGOTIABLE_QUOTE_COMMENT_FILE, negotiableQuoteComments, "Exporting negotiable quote comment...")
  exportData(COMPANY_PAYMENT_FILE, companyPayments, "Exporting company payments...")
  exportData(
    COMPANY_ADVANCED_CUSTOMER_ENTITY_FILE, companyAdvancedCustomerEntity, "Exporting company advanced customer entity...")
  exportData(COMPANY_CREDIT_FILE, companyCredit, "Exporting company credit...")
  exportData(ADMIN_USER_FILE, adminUsers, "Exporting admin users...")

  console.log "Complete!"

generateProductsAndCategories = (products) ->
  console.log "Generating products and categories..."

  productEntities = [] # Product objects
  productIndex = 0
  categoryNames = [] # Array of all category names, built when creating products and product-category mapping
  categoryEntities = [] # Category objects
  catalogCategoryEntityVarchars = []
  productCategoryEntities = [] # Product-category mapping

  # First, loop through all products
  for product in products

    # Create product
    productEntity = 
      entity_id: ++productIndex
      sku: product.sku
      name: product.name
    productEntities.push(productEntity)

    # For all categories associated with the product, add them to the categoryNames table if they don't already exist
    productsCategories = product.categories.split(',')
    for category in productsCategories
      if categoryNames.indexOf(category) < 0
        categoryNames.push(category)

        # Find other categories (may not be associated with products, but need for path), and add to the categoryNames table if they don't already exist
        subCategories = category.split("/")
        for i in [0..subCategories.length - 1]
          subCategory = subCategories.slice(0,i+1).join('/')
          if categoryNames.indexOf(subCategory) < 0
            categoryNames.push(subCategory)

      # Map product to categories
      categoryIndex = categoryNames.indexOf(category)
      productCategoryEntity = 
        category_id: categoryIndex
        prdouct_id: productIndex
      productCategoryEntities.push(productCategoryEntity)

  # Create category objects out each element of the categoryNames array
  for categoryId in [0..categoryNames.length-1]

    fullCategoryName = categoryNames[categoryId]
    path = []
    subCategories = fullCategoryName.split('/')

    for i in [0..subCategories.length-1]
      subCategory = subCategories.slice(0,i+1).join('/')
      subCategoryIndex = categoryNames.indexOf(subCategory)
      path.push(subCategoryIndex)

    parent_id = if path.length > 1 then path[path.length - 2] else 0
    path = path.join('/')
    level = subCategories.length - 1
    name = subCategories[subCategories.length-1]

    categoryEntity = 
      entity_id: categoryId
      parent_id: parent_id
      level: level
      path: path
      created_at: null
      updated_at: null
    categoryEntities.push(categoryEntity)

    catalogCategoryEntityVarchar = 
      value_id: null
      attribute_id: 41
      entity_id: categoryId
      value: name
    catalogCategoryEntityVarchars.push(catalogCategoryEntityVarchar)

  return [productEntities, productCategoryEntities, categoryEntities, catalogCategoryEntityVarchars]

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

generateCustomers = (total, stores) ->
  console.log "Generating customers..."
  customers = []
  for index in [1..total]
    createdAt = getRandomDate()
    customer =
      entity_id: index
      email: getRandomEmail()
      group_id: getRandomItem(CUSTOMER_GROUPS).id
      store_id: getRandomItem(stores).store_id
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

generateOrders = (total, customers, addresses, products, stores) ->
  console.log "Generating orders..."
  orders = []
  orderCounts = [] #a count of orders by customer_id
  itemId = 0
  for index in [1..total]
    address = getRandomItem(addresses)
    couponCode = if chance.bool({likelihood: 10}) then getRandomItem(COUPONS) else null
    customer = getCustomerToBuyFavoringRepeats(customers, orderCounts, createdAt)
    shippingAmount = getRandomItem([1.99,3.99,6.99])
    discountAmount = getDiscountAmount(couponCode, grandTotal)
    createdAt = getRandomDate()
    utmParameters = getUtmParameters()

    items = getItems(products, customer.store_id, ITEMS_MIN, ITEMS_MAX)
    grandTotal = getCartValue(items)
    
    orderReturned = false
    orderItems = []

    for item in items

      qty_ordered = getRandomInt(1,5)
      base_qty_refunded = 0
      base_amount_refunded = 0
      if chance.bool({likelihood: RETURN_PERCENT})
        orderReturned = true # At least one item in the order was returned
        base_qty_refunded = getRandomInt(1,qty_ordered+1)
        base_amount_refunded = item.price

      # Create order item
      orderItem =
        item_id: ++itemId
        qty_ordered: qty_ordered
        base_price: +item.price
        name: item.name
        order_id: index
        parent_item_id: null
        sku: item.sku
        product_type: 'tools'
        product_id: item.entity_id
        store_id: item.store_id
        created_at: createdAt
        updated_at: createdAt
        base_qty_refunded: base_qty_refunded
        base_amount_refunded: base_amount_refunded
      orderItems.push(orderItem)

    # Create order
    order =
      entity_id: index
      items: orderItems
      grand_total: grandTotal
      base_grand_total: grandTotal
      base_discount_amount: null
      base_subtotal: null
      customer_id: customer.entity_id
      status: getOrderStatus()
      customer_email: customer.email
      store_id: customer.store_id
      base_currency_code: CURRENCY
      order_currency_code: CURRENCY
      billing_address_id: address.entity_id
      shipping_address_id: address.entity_id
      store_name: getStoreById(stores, customer.store_id).name
      coupon_code: couponCode
      base_tax_amount: (0.08 * grandTotal).toFixed(2)
      base_shipping_amount: shippingAmount
      base_discount_amount: discountAmount
      utm_source: utmParameters.utmSource
      utm_medium: utmParameters.utmMedium
      utm_campaign: utmParameters.utmCampaign
      customer_group_id: customer.group_id
      created_at: createdAt
      updated_at: createdAt
      increment_id: index
      quote_id: index
      returned: orderReturned
      items: orderItems
    orders.push(order)
    orderCounts[customer.entity_id] = if orderCounts[customer.entity_id] then orderCounts[customer.entity_id] + 1 else 1
  return orders

generateReturnsAndReturnItems = (orders) ->
  console.log "Generating returns..."
  returns = []
  index = 1
  returnItems = []
  returnItemId = 0
  prevReturnItemId = 0

  for order in orders
    if (order.returned)

      dateRequested = getRandomReturnDate(order.created_at)
      status = getReturnStatus()

      returnItems = []
      for item in order.items
        if (item.base_qty_refunded > 0)
          returnItem = 
            entity_id: ++returnItemId
            rma_entity_id: index
            qty_returned: item.base_qty_refunded
            order_item_id: item.item_id
            product_name: item.name
            status: status
          returnItems.push(returnItem)

      ret = 
        entity_id: index++
        date_requested: dateRequested
        status: status
        order_id: order.entity_id
        customer_id: order.customer_id
        items: returnItems
      returns.push(ret)   

  return returns

getStoreById = (stores, id) ->
  for store in stores when store.store_id is id
    return store

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

getItems = (products, storeId, min, max) ->
  totalItems = getRandomInt(min,max)
  items = []
  for index in [0..totalItems]
    item = getRandomItem(products)
    item.qty_ordered = getRandomInt(1,5)
    item.store_id = storeId
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

getReturnStatus = () ->
  if chance.bool({likelihood: 83}) then "closed" #83% of orders
  else if chance.bool({likelihood: 90}) then getRandomItem(["pending","authorized","received"]) #90% of 17% of orders
  else getRandomItem(['partially_authorized','processed_closed'])

exportData = (path, data, msg) ->
  console.log msg
  csvData = convertArrayToCsv(data)
  writeCsv(path, csvData)

exportOrderData = (orders, products, customers, addresses) ->
  console.log "Exporting orders... "
  csvData = convertArrayToCsv(orders)
  writeCsv(ORDER_FILE, csvData)
  exportOrderItems(orders)
  exportData(ADDRESS_FILE, addresses, "Exporting addresses... ")

getProductType = () ->
  chance.pickone(["simple","configurable","bundle","downloadable","grouped","virtual"])

exportOrderItems = (orders) ->
  csv = ''
  orderItems = []
  for order in orders
    for item in order.items
      orderItems.push(item)

  csv = convertArrayToCsv(orderItems)
  writeCsv(ORDER_ITEM_FILE, csv)

exportReturnData = (returns) ->
  console.log "Exporting returns..."
  csvData = convertArrayToCsv(returns)
  writeCsv(RETURN_FILE, csvData)

  returnItems = []

  for ret in returns
    for item in ret.items
      returnItems.push(item)

  csv = convertArrayToCsv(returnItems)
  writeCsv(RETURN_ITEMS_FILE, csv)

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

getRandomReturnDate = (startDate) ->
  orderDate = new Date(startDate)
  today = new Date()
  returnMax = new Date(startDate)
  returnMax.setDate(orderDate.getDate() + RETURN_PERIOD_DAYS)
  if (returnMax > today)
    returnMax = today

  getRandomDateBetween(orderDate, returnMax)

  # min = orderDate.getTime()
  # max = returnMax.getTime()

  # date = new Date()
  # rand = Math.round(Math.random() * (max - min) + min)
  # date.setTime(rand)
  # date.toISOString().slice(0, 19).replace('T', ' ');

getRandomDateBetween = (start, end) ->

  min = start.getTime()
  max = end.getTime()

  date = new Date()
  rand = Math.round(Math.random() * (max - min) + min)
  date.setTime(rand)
  date.toISOString().slice(0, 19).replace('T', ' ');

getProducts = (callback) ->
  fs.readFile PRODUCT_INPUT_FILE, 'utf-8', (err, data) ->
    console.log "Loaded product data..."
    csvParse data, {delimiter: ','}, (err, result) ->
      products = convertArrayToObjectList(result)
      callback null, products

generateStores = (total) ->
  stores = []
  for index in [0..total]
    stores.push(generateStore(index))
  return stores

generateStore = (id) ->
  store_id: id
  name: "#{chance.country({full:true})} Store View"

generateCompanies = (total) ->
  companies = []
  for index in [0..total]
    companies.push(generateCompany(index))
  return companies

generateCompany = (id) ->
  name = "#{capitalize(chance.word())}#{generateCompanySuffix()}"
  company =
    entity_id: id
    status: 1
    company_name: name
    legal_name: name
    company_email: null
    vat_tax_id: null
    reseller_id: null
    comment: null
    street: null
    city: null
    country_id: null
    region: null
    region_id: null
    postcode: null
    telephone: null
    customer_group_id: chance.integer({min:2,max:6}) # Reference to customer_group.customer_group_id
    sales_representative_id: chance.integer({min:0,max:TOTAL_ADMIN_USERS}) # Reference to admin_user.user_id
    super_user_id: null
    reject_reason: null
    rejected_at: null

generateAdminUsers = (total) ->
  items = []
  for index in [0..total]
    items.push(generateAdminUser(index))
  return items

generateAdminUser = (index) ->
  item =
    user_id: index
    email: chance.email()
    username: null
    is_active: 1

generateCompanySuffix = () ->
  chance.pickone([".com", ".com", ".com", "", "", " LLC", " Party Ltd.", " GmbH", ".biz", "Co", " Co", "Corp"])

generateQuotes = (total, customers, products, stores, orders) ->
  quotes = []
  quoteItems = []

  # Generate quotes from existing orders - all orders have a quote!
  for order in orders
    quotes.push(generateQuoteFromOrder(order))
    quoteItems = quoteItems.concat(generateQuoteItemsFromOrderItems(order.items))

  # Generate some quotes that don't turn into orders :(
  total = orders.length + 1 + total
  for index in [orders.length+1..total]
    result = generateQuote(index, chance.pickone(customers), products, stores)
    quotes.push(result[0])
    quoteItems = quoteItems.concat(result[1])

  return [quotes, quoteItems]

generateQuoteItemsFromOrderItems = (items) ->
  
  quoteItems = []
  for item in items
    quoteItems.push(generateQuoteItemFromOrderItem(item))

generateQuoteItemFromOrderItem = (item) ->
  item =
    item_id: item.item_id # Can make item id same as id
    quote_id: item.order_id # This is guaranteed to be same as quote id for now
    created_at: null
    updated_at: null
    product_id: item.product_id
    store_id: null
    is_virtual: chance.integer({min: 0, max: 1})
    sku: item.sku
    name: item.name
    qty: item.qty_ordered
    price: item.base_price
    base_price: item.base_price
    product_type: item.product_type

generateQuoteFromOrder = (order) ->

  orderDate = new Date(order.created_at)
  minQuoteDate = new Date(orderDate)
  maxQuoteDate = orderDate
  if chance.bool({likelihood:66}) # 66% of quotes convert within an hour
    minQuoteDate.setHours(orderDate.getHours() - 1)
  else
    if chance.bool({likelihood:50}) # 1/2 of remaining quotes convert between 1 and 5 hours
      minQuoteDate.setHours(orderDate.getHours() - 5)
      maxQuoteDate.setHours(orderDate.getHours() - 1)
    else # remaining carts convert between 5 hours and 3 days
      minQuoteDate.setHours(orderDate.getHours() - 72)
      maxQuoteDate.setHours(orderDate.getHours() - 5)

  quote =
    entity_id: order.quote_id
    store_id: null
    created_at: getRandomDateBetween(minQuoteDate, maxQuoteDate)
    updated_at: null
    converted_at: null
    is_active: null
    is_virtual: null
    is_multi_shipping: null
    items_count: order.items.length
    items_qty: order.items.length
    grand_total: order.base_grand_total
    base_grand_total: order.base_grand_total
    checkout_method: null
    customer_id: order.customer_id
    coupon_code: null
    reserved_order_id: order.increment_id
    customer_email: order.customer_email
    base_subtotal: null

generateQuote = (id, customer, products, stores) ->
  total = chance.floating({min:1, max: 1000}).toFixed(2)
  items = generateQuoteItems(id, products, stores)
  quote =
    entity_id: id
    store_id: null
    created_at: getRandomDate()
    updated_at: null
    converted_at: null
    is_active: null
    is_virtual: null
    is_multi_shipping: null
    items_count: items.length
    items_qty: items.length
    grand_total: total
    base_grand_total: total
    checkout_method: null
    customer_id: customer.entity_id
    coupon_code: null
    reserved_order_id: null
    customer_email: customer.email
    base_subtotal: null

  return [quote, items]

generateQuoteItems = (quote_id, products, stores) ->
  total = chance.integer({min: 1, max: 10})
  items = []
  for index in [0..total]
    item = generateQuoteItem(index, quote_id, chance.pickone(products), chance.pickone(stores))
    items.push(item)
  return items

generateQuoteItem = (id, quote_id, product, store) ->
  price = chance.floating({min: 1, max: 10}).toFixed()
  item =
    item_id: id
    quote_id: quote_id
    created_at: null
    updated_at: null
    product_id: product.entity_id
    store_id: store.entity_id
    is_virtual: chance.integer({min: 0, max: 1})
    sku: product.sku
    name: product.name
    qty: chance.integer(min: 1, max: 100)
    price: price
    base_price: price
    product_type: product.product_type

generateSharedCatalogs = () ->
  items = []
  sharedCatalogNames = ["Men's","Women's","Seasonal","5% off","10% off","Standard"]
  for name, index in sharedCatalogNames
    items.push(generateSharedCatalog(name, index))
  return items

generateSharedCatalog = (name, index) ->
  item =
    entity_id: index
    name: name
    description: chance.word()
    customer_group_id: chance.integer({min:1,max:10})
    type: chance.integer({min:0,max:0})
    created_at: null
    created_by: chance.integer({min:0,max:10000})
    store_id: chance.integer({min:0,max:10})

generateNegotiableQuotes = (total, quotes) ->
  quotes = chance.pickset(quotes, total) # pick quotes to be negotiable
  items = []
  for quote in quotes
    items.push(generateNegotiableQuote(quote))
  return items

generateNegotiableQuote = (quote) ->
  item =
    quote_id: quote.entity_id
    is_regular_quote: 0
    status: chance.weighted(['Submitted by customer','Processing by admin','Ordered','Expired','Declined'],[18,15,50,10,7])
    quote_name: chance.word()
    negotiated_price_type: chance.integer({min:0,max:10})
    negotiated_price_value: chance.floating({min: 0, max: 1000})
    shipping_price: chance.floating({min: 0, max: 100})
    expiration_period: getRandomDate()
    status_email_notification: 0
    snapshot: ''
    has_unconfirmed_changes: 0
    is_customer_price_changed: 0
    is_shipping_tax_changed: 0
    notifications: 0
    applied_rule_ids: null
    is_address_draft: 0
    deleted_sku: ''
    creator_type: 3
    creator_id: chance.integer({min:1,max:TOTAL_CUSTOMERS})
    original_total_price: chance.floating({min:0,max:1000})
    base_original_total_price: chance.floating({min:0,max:1000})
    negotiated_total_price: chance.floating({min:0,max:1000})
    base_negotiated_total_price: chance.floating({min:0,max:1000})
    # reserved_order_id: chance.integer({min:1,max:1000})

generateNegotiableQuoteHistories = (total) ->
  items = []
  for index in [0..total]
    items.push(generateNegotiableQuoteHistory(index))
  return items

generateNegotiableQuoteHistory = (index) ->
  item =
    history_id: index
    quote_id: chance.integer({min:1,max:1000})
    is_seller: 0
    author_id: chance.integer({min:1,max:1000})
    is_draft: 0
    status: ''
    log_data: ''
    snapshot_data: ''
    created_at: null

generateNegotiableQuoteComments = (total) ->
  items = []
  for index in [0..total]
    items.push(generateNegotiableQuoteComment(index))
  return items

generateNegotiableQuoteComment = (index) ->
  item =
    enity_id: index
    parent_id: chance.integer({min:1,max:1000})
    creator_type: 0
    is_decline: 0
    is_draft: 0
    creator_id: chance.integer({min:1,max:1000})
    created_at: null

generateCompanyPayments = (total) ->
  items = []
  for index in [0..total]
    items.push(generateCompanyPayment(index))
  return items

generateCompanyPayment = (index) ->
  item =
    company_id: chance.integer({min:1,max:100})
    applicable_payment_method: 0
    available_payment_methods: chance.word()
    use_config_settings: 0

generateCompanyAdvancedCustomerEntities = (total) ->
  items = []
  for index in [0..total]
    items.push(generateCompanyAdvancedCustomerEntity(index))
  return items

generateCompanyAdvancedCustomerEntity = (index) ->
  item =
    customer_id: chance.integer({min:1,max:TOTAL_CUSTOMERS}) # Reference to customer_entity.entity_id
    company_id:  chance.integer({min:1,max:1000})
    job_title: chance.word()
    status: ''
    telephone: chance.phone()

generateCompanyCredits = (total) ->
  items = []
  for index in [0..total]
    items.push(generateCompanyCredit(index))
  return items

generateCompanyCredit = (index) ->
  item =
    enity_id: index
    company_id: chance.integer({min:1,max:TOTAL_COMPANIES}) # Reference to company.entity_id
    credit_limit: chance.floating({min:0,max:10000})
    balance: chance.floating({min:0,max:10000})
    currency_code: chance.currency().code
    exceed_limit: chance.integer({min:0,max:100000})

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

capitalize = (str) ->
  str[0].toUpperCase() + str.slice(1)

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
