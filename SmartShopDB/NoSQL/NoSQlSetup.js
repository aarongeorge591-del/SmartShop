// MongoDB shell script for setting up a NoSQL version of SmartShop
// Run this in the mongo shell (e.g. `mongo < NoSQlSetup.js`) or adapt for use
// with a Node.js driver.

// use a separate database to avoid clashing with the relational version
// choose the NoSQL database; compatible approach for shell or driver
if (typeof db !== 'undefined' && db.getSiblingDB) {
    db = db.getSiblingDB("SmartShopNoSQL");
} else {
    // when running under mongo shell, uncomment the following line:
    // use SmartShopNoSQL;
}

// drop existing collections to start clean
["customers","products","orders","reviews","weblogs","branches"].forEach(c => db[c].drop());

// ------------------------------------------------------------------
// Branches (added for BI lookups)
// ------------------------------------------------------------------
db.branches.insertMany([
    { _id: 1, branchName: "Colombo Central", location: "Colombo Downtown" },
    { _id: 2, branchName: "Kandy City", location: "Kandy Shopping Mall" },
    { _id: 3, branchName: "Galle Fort", location: "Galle Historic District" },
    { _id: 4, branchName: "Online Warehouse", location: "Distribution Center" }
]);

// ------------------------------------------------------------------
// Customers
// ------------------------------------------------------------------
db.customers.insertMany([
    { _id: 1, firstName: "Kasun", lastName: "Fernando", email: "kasun@email.com",
      phone: "0771234567", address: "Colombo", createdAt: new Date() },
    { _id: 2, firstName: "Malini", lastName: "Perera", email: "malini@email.com",
      phone: "0719876543", address: "Kandy", createdAt: new Date() },
    { _id: 3, firstName: "Ruwan", lastName: "Silva", email: "ruwan@email.com",
      phone: "0751122334", address: "Galle", createdAt: new Date() }
]);

// ------------------------------------------------------------------
// Products
// ------------------------------------------------------------------
db.products.insertMany([
    { _id: 1, name: "Laptop", category: "Electronics", price: 250000, stock: 10, branchId: 1 },
    { _id: 2, name: "Smartphone", category: "Electronics", price: 150000, stock: 20, branchId: 1 },
    { _id: 3, name: "Office Chair", category: "Furniture", price: 45000, stock: 15, branchId: 2 },
    { _id: 4, name: "Headphones", category: "Electronics", price: 15000, stock: 30, branchId: 3 }
]);

// ------------------------------------------------------------------
// Orders (embedded order items to show denormalised document)
// ------------------------------------------------------------------
db.orders.insertMany([
    { _id: 1, customerId: 1, branchId: 1, orderDate: new Date(),
      orderType: "In-Store", totalAmount: 265000,
      items: [ { productId: 1, qty: 1, unitPrice: 250000 },
               { productId: 4, qty: 1, unitPrice: 15000 } ] },
    { _id: 2, customerId: 2, branchId: 2, orderDate: new Date(),
      orderType: "In-Store", totalAmount: 45000,
      items: [ { productId: 3, qty: 1, unitPrice: 45000 } ] },
    { _id: 3, customerId: 3, branchId: 3, orderDate: new Date(),
      orderType: "Online", totalAmount: 15000,
      items: [ { productId: 4, qty: 1, unitPrice: 15000 } ] }
]);

// ------------------------------------------------------------------
// Reviews - unstructured customer feedback demonstrating NoSQL usage
// ------------------------------------------------------------------
db.reviews.insertMany([
    { _id: 1, productId: 1, customerId: 1,
      rating: 4, comment: "Good performance but battery life could be better.",
      tags: ["electronics","portable","business"],
      createdAt: new Date() },
    { _id: 2, productId: 4, customerId: 3,
      rating: 5, comment: "Excellent sound quality, very comfortable.",
      extra: { colour: "black", warrantyMonths: 12 },
      createdAt: new Date() }
]);

// ------------------------------------------------------------------
// Web logs - semi-structured data from website
// ------------------------------------------------------------------
db.weblogs.insertMany([
    { sessionId: "abc123", path: "/home", timestamp: new Date(),
      metadata: { ip: "192.168.1.10", userAgent: "Mozilla/5.0" } },
    { sessionId: "abc123", path: "/product/4", timestamp: new Date(),
      metadata: { ip: "192.168.1.10", userAgent: "Mozilla/5.0" } }
]);

// ------------------------------------------------------------------
// Sample queries illustrating NoSQL capabilities
// ------------------------------------------------------------------

// 1. Top-selling products (aggregation on embedded items)
print("Top-selling products:");
db.orders.aggregate([
    { $unwind: "$items" },
    { $group: { _id: "$items.productId", qty: { $sum: "$items.qty" } } },
    { $sort: { qty: -1 } }
]).forEach(printjson);

// 2. Find all reviews for product 1 with rating >=4
print("High-rated reviews for product 1:");
db.reviews.find({ productId: 1, rating: { $gte: 4 } }).forEach(printjson);

// 3. Count page views per path in the weblogs
print("Page views summary:");
db.weblogs.aggregate([
    { $group: { _id: "$path", views: { $sum: 1 } } },
    { $sort: { views: -1 } }
]).forEach(printjson);

// 4. Example of a document with evolving schema
print("Inspect a review document:");
printjson(db.reviews.findOne({ _id: 2 }));
