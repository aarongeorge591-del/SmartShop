// MongoDB shell script demonstrating BI-style queries on the NoSQL SmartShop dataset
// Run this with: mongosh --file NoSQL_BI_Demo.js
// or: mongosh "mongodb://localhost:27017/SmartShopNoSQL" NoSQL_BI_Demo.js

// switch to the NoSQL database; use getSiblingDB for compatibility
if (typeof db !== 'undefined' && db.getSiblingDB) {
    db = db.getSiblingDB("SmartShopNoSQL");
} else {
    // when running under mongo shell, the `use` command works
    // (uncomment the next line if needed)
    // use SmartShopNoSQL;
}

print("========================================");
print("SmartShop NoSQL Business Intelligence");
print("========================================\n");


// 1. Top-selling products by quantity
print("=== Top-selling products (by quantity) ===");
db.orders.aggregate([
    { $unwind: "$items" },
    { $group: { _id: "$items.productId", quantitySold: { $sum: "$items.qty" },
                salesAmount: { $sum: { $multiply: ["$items.qty", "$items.unitPrice"] } } } },
    { $lookup: { from: "products", localField: "_id", foreignField: "_id", as: "product" } },
    { $unwind: "$product" },
    { $project: { _id: 0, productName: "$product.name", quantitySold: 1, salesAmount: 1 } },
    { $sort: { quantitySold: -1 } }
]).forEach(printjson);

// 2. Monthly sales per branch
print("\n=== Monthly sales per branch ===");
db.orders.aggregate([
    { $group: { _id: { branchId: "$branchId", month: { $dateToString: { format: "%Y-%m", date: "$orderDate" } } },
                totalSales: { $sum: "$totalAmount" } } },
    { $lookup: { from: "branches", localField: "_id.branchId", foreignField: "_id", as: "branch" } },
    { $unwind: "$branch" },
    { $project: { _id: 0, branchName: "$branch.branchName", month: "$_id.month", totalSales: 1 } },
    { $sort: { branchName: 1, month: 1 } }
]).forEach(printjson);

// 3. Customer spend summary
print("\n=== Customer spend summary ===");
db.orders.aggregate([
    { $group: { _id: "$customerId", numberOfOrders: { $sum: 1 }, totalSpent: { $sum: "$totalAmount" } } },
    { $lookup: { from: "customers", localField: "_id", foreignField: "_id", as: "customer" } },
    { $unwind: "$customer" },
    { $project: { _id: 0, customer: { $concat: ["$customer.firstName", " ", "$customer.lastName"] }, numberOfOrders: 1, totalSpent: 1 } },
    { $sort: { totalSpent: -1 } }
]).forEach(printjson);

// 4. Orders in the last 7 days
print("\n=== Orders in the last 7 days ===");
db.orders.find({ orderDate: { $gte: new Date(new Date().getTime() - 7*24*60*60*1000) } })
    .sort({ orderDate: -1 })
    .forEach(printjson);

// 5. Product sales per category
print("\n=== Product sales per category ===");
db.orders.aggregate([
    { $unwind: "$items" },
    { $lookup: { from: "products", localField: "items.productId", foreignField: "_id", as: "product" } },
    { $unwind: "$product" },
    { $group: { _id: "$product.category", totalQuantity: { $sum: "$items.qty" },
                totalSales: { $sum: { $multiply: ["$items.qty", "$items.unitPrice"] } } } },
    { $sort: { totalSales: -1 } }
]).forEach(printjson);

// ========== ADDITIONAL QUERIES FOR REPORT ==========

// 6. Customer reviews analysis - finding highly rated products
print("\n=== Highly-rated products (rating >= 4) ===");
db.reviews.find({ rating: { $gte: 4 } })
    .sort({ rating: -1, createdAt: -1 })
    .forEach(function(doc) {
        print("Product ID: " + doc.productId + " | Rating: " + doc.rating + " | Comment: " + doc.comment);
    });

// 7. Find all reviews for a specific product
print("\n=== All reviews for Product 1 ===");
db.reviews.find({ productId: 1 }).forEach(printjson);

// 8. Review count per product
print("\n=== Review count and average rating per product ===");
db.reviews.aggregate([
    { $group: { 
        _id: "$productId", 
        reviewCount: { $sum: 1 },
        avgRating: { $avg: "$rating" },
        maxRating: { $max: "$rating" },
        minRating: { $min: "$rating" }
    }},
    { $lookup: { from: "products", localField: "_id", foreignField: "_id", as: "product" } },
    { $unwind: "$product" },
    { $project: { _id: 0, productName: "$product.name", reviewCount: 1, avgRating: 1, maxRating: 1, minRating: 1 } },
    { $sort: { reviewCount: -1 } }
]).forEach(printjson);

// 9. Web logs analysis - page views per path
print("\n=== Web activity: Page views summary ===");
db.weblogs.aggregate([
    { $group: { _id: "$path", viewCount: { $sum: 1 } } },
    { $sort: { viewCount: -1 } }
]).forEach(printjson);

// 10. Customers with their purchase history (denormalized structure advantage)
print("\n=== Customer order summary ===");
db.customers.aggregate([
    { $lookup: { from: "orders", localField: "_id", foreignField: "customerId", as: "orderHistory" } },
    { $project: {
        _id: 0,
        fullName: { $concat: ["$firstName", " ", "$lastName"] },
        email: 1,
        region: { $literal: "Western" },  // Note: region not in MongoDB schema, showing limitation
        orderCount: { $size: "$orderHistory" },
        totalOrderValue: { $sum: "$orderHistory.totalAmount" }
    }},
    { $sort: { totalOrderValue: -1 } }
]).forEach(printjson);

// 11. High-value customers (spent > 100000)
print("\n=== High-value customers (spent > 100000) ===");
db.customers.aggregate([
    { $lookup: { from: "orders", localField: "_id", foreignField: "customerId", as: "orders" } },
    { $addFields: { totalSpent: { $sum: "$orders.totalAmount" } } },
    { $match: { totalSpent: { $gt: 100000 } } },
    { $project: {
        _id: 0,
        fullName: { $concat: ["$firstName", " ", "$lastName"] },
        email: 1,
        totalSpent: 1,
        orderCount: { $size: "$orders" }
    }},
    { $sort: { totalSpent: -1 } }
]).forEach(printjson);

// 12. Top customers by order frequency
print("\n=== Top customers by number of orders ===");
db.customers.aggregate([
    { $lookup: { from: "orders", localField: "_id", foreignField: "customerId", as: "orders" } },
    { $project: {
        _id: 0,
        fullName: { $concat: ["$firstName", " ", "$lastName"] },
        email: 1,
        orderCount: { $size: "$orders" },
        totalSpent: { $sum: "$orders.totalAmount" }
    }},
    { $sort: { orderCount: -1 } }
]).forEach(printjson);

// 13. Product inventory status - low stock alert
print("\n=== Low stock alert (stock < 25) ===");
db.products.find({ stock: { $lt: 25 } })
    .sort({ stock: 1 })
    .forEach(function(doc) {
        print("Product: " + doc.name + " | Stock: " + doc.stock + " | Category: " + doc.category);
    });

// 14. Demonstrate NoSQL flexibility: Documents with additional fields
print("\n=== Inspecting document with flexible schema (review with extra field) ===");
db.reviews.findOne({ _id: 2 });

// 15. Order data structure (showing embedded items)
print("\n=== Sample order with embedded items (denormalized) ===");
db.orders.findOne({ _id: 1 });

print("\n========================================");
print("End of BI Demo Queries");
print("========================================");

