
pub const Item = struct {
    section: u32,
    section_title: []const u8,
    query: []const u8,
    destructive: bool = false,
};

pub const items = [_]Item{
    .{ .section = 1, .section_title = "Count", .query = "orders.count()" },
    .{ .section = 1, .section_title = "Count", .query = "orders.filter(EmployeeID = 289).count()" },
    .{ .section = 1, .section_title = "Count", .query = "vendors.filter(ActiveFlag = 1).count()" },
    .{ .section = 1, .section_title = "Count", .query = "products.filter(MakeFlag = 1).count()" },

    .{ .section = 2, .section_title = "Filter - Equality", .query = "employees.filter(Gender = \"M\").count()" },
    .{ .section = 2, .section_title = "Filter - Equality", .query = "employees.filter(EmployeeID = 274).count()" },
    .{ .section = 2, .section_title = "Filter - Equality", .query = "products.filter(SubCategoryID = 14).count()" },
    .{ .section = 2, .section_title = "Filter - Equality", .query = "productcategories.filter(CategoryName = \"Bikes\").count()" },

    .{ .section = 3, .section_title = "Filter - Comparison Operators", .query = "orders.filter(TotalDue > 50000).count()" },
    .{ .section = 3, .section_title = "Filter - Comparison Operators", .query = "orders.filter(TotalDue < 100).count()" },
    .{ .section = 3, .section_title = "Filter - Comparison Operators", .query = "orders.filter(TotalDue >= 100000).count()" },
    .{ .section = 3, .section_title = "Filter - Comparison Operators", .query = "products.filter(ListPrice > 1000).count()" },
    .{ .section = 3, .section_title = "Filter - Comparison Operators", .query = "vendors.filter(CreditRating != 1).count()" },

    .{ .section = 4, .section_title = "Compound Filters (AND)", .query = "orders.filter(EmployeeID = 289 and CustomerID = 1045).count()" },
    .{ .section = 4, .section_title = "Compound Filters (AND)", .query = "employees.filter(Gender = \"M\" and MaritalStatus = \"M\").count()" },
    .{ .section = 4, .section_title = "Compound Filters (AND)", .query = "orders.filter(EmployeeID >= 285 and EmployeeID <= 287).count()" },

    .{ .section = 5, .section_title = "Limit & Skip", .query = "orders.limit(10).count()" },
    .{ .section = 5, .section_title = "Limit & Skip", .query = "orders.skip(3800).count()" },
    .{ .section = 5, .section_title = "Limit & Skip", .query = "customers.limit(100).count()" },

    .{ .section = 6, .section_title = "OrderBy (Sorting)", .query = "products.orderBy(ListPrice, desc).limit(5)" },
    .{ .section = 6, .section_title = "OrderBy (Sorting)", .query = "products.orderBy(ListPrice, asc).limit(5)" },
    .{ .section = 6, .section_title = "OrderBy (Sorting)", .query = "employees.orderBy(EmployeeID, asc).limit(3)" },
    .{ .section = 6, .section_title = "OrderBy (Sorting)", .query = "employees.orderBy(EmployeeID, desc).limit(3)" },

    .{ .section = 7, .section_title = "Multi-Sort", .query = "orders.orderBy(EmployeeID, asc).orderBy(TotalDue, desc).limit(10)" },
    .{ .section = 7, .section_title = "Multi-Sort", .query = "employees.orderBy(Gender, asc).orderBy(EmployeeID, desc).limit(10)" },
    .{ .section = 7, .section_title = "Multi-Sort", .query = "orders.filter(EmployeeID >= 285).orderBy(EmployeeID, asc).orderBy(TotalDue, asc).limit(20)" },

    .{ .section = 8, .section_title = "Projection (pluck)", .query = "employees.filter(EmployeeID = 274).pluck(EmployeeID, FullName)" },
    .{ .section = 8, .section_title = "Projection (pluck)", .query = "products.filter(SubCategoryID = 14).limit(1).pluck(ProductName, ListPrice)" },
    .{ .section = 8, .section_title = "Projection (pluck)", .query = "employees.limit(1).pluck(EmployeeID)" },
    .{ .section = 8, .section_title = "Projection (pluck)", .query = "orders.filter(EmployeeID = 289).orderBy(TotalDue, desc).limit(1).pluck(EmployeeID, TotalDue)" },

    .{ .section = 9, .section_title = "Aggregation - Count", .query = "orders.aggregate(total: count)" },
    .{ .section = 9, .section_title = "Aggregation - Count", .query = "orders.filter(EmployeeID = 289).aggregate(total: count)" },
    .{ .section = 9, .section_title = "Aggregation - Count", .query = "products.filter(MakeFlag = 1).aggregate(n: count)" },

    .{ .section = 10, .section_title = "Aggregation - Sum, Avg, Min, Max", .query = "orders.aggregate(total: sum(TotalDue))" },
    .{ .section = 10, .section_title = "Aggregation - Sum, Avg, Min, Max", .query = "orders.aggregate(avg_total: avg(TotalDue))" },
    .{ .section = 10, .section_title = "Aggregation - Sum, Avg, Min, Max", .query = "orders.aggregate(min_total: min(TotalDue))" },
    .{ .section = 10, .section_title = "Aggregation - Sum, Avg, Min, Max", .query = "orders.aggregate(max_total: max(TotalDue))" },
    .{ .section = 10, .section_title = "Aggregation - Sum, Avg, Min, Max", .query = "orders.filter(EmployeeID = 289).aggregate(revenue: sum(TotalDue))" },

    .{ .section = 11, .section_title = "GroupBy", .query = "orders.groupBy(EmployeeID).aggregate(n: count)" },
    .{ .section = 11, .section_title = "GroupBy", .query = "employees.groupBy(Gender).aggregate(n: count)" },
    .{ .section = 11, .section_title = "GroupBy", .query = "employees.groupBy(Gender, MaritalStatus).aggregate(n: count)" },
    .{ .section = 11, .section_title = "GroupBy", .query = "orders.groupBy(EmployeeID).aggregate(n: count, total: sum(TotalDue))" },

    .{ .section = 12, .section_title = "Filter + GroupBy", .query = "orders.filter(TotalDue > 10000).groupBy(EmployeeID).aggregate(n: count)" },
    .{ .section = 12, .section_title = "Filter + GroupBy", .query = "products.filter(ListPrice > 0).groupBy(SubCategoryID).aggregate(n: count, avg_price: avg(ListPrice))" },
    .{ .section = 12, .section_title = "Filter + GroupBy", .query = "orders.filter(EmployeeID = 289).groupBy(CustomerID).aggregate(n: count, total: sum(TotalDue))" },

    .{ .section = 13, .section_title = "$in Operator", .query = "orders.filter(EmployeeID in [289, 288]).count()" },
    .{ .section = 13, .section_title = "$in Operator", .query = "orders.filter(EmployeeID in [289, 287, 285]).count()" },
    .{ .section = 13, .section_title = "$in Operator", .query = "products.filter(SubCategoryID in [1, 2, 14]).count()" },
    .{ .section = 13, .section_title = "$in Operator", .query = "employees.filter(Gender in [\"M\"]).count()" },

    .{ .section = 14, .section_title = "$contains Operator", .query = "products.filter(ProductName contains \"Road\").count()" },
    .{ .section = 14, .section_title = "$contains Operator", .query = "products.filter(ProductName contains \"Mountain\").count()" },
    .{ .section = 14, .section_title = "$contains Operator", .query = "products.filter(ProductName contains \"Frame\").count()" },
    .{ .section = 14, .section_title = "$contains Operator", .query = "vendors.filter(VendorName contains \"Bike\").count()" },

    .{ .section = 15, .section_title = "$startsWith Operator", .query = "products.filter(ProductName startsWith \"HL\").count()" },
    .{ .section = 15, .section_title = "$startsWith Operator", .query = "products.filter(ProductName startsWith \"Mountain\").count()" },
    .{ .section = 15, .section_title = "$startsWith Operator", .query = "employees.filter(FirstName startsWith \"S\").count()" },

    .{ .section = 16, .section_title = "$exists Operator", .query = "products.filter(ProductName exists true).count()" },
    .{ .section = 16, .section_title = "$exists Operator", .query = "employees.filter(Gender exists true).count()" },

    .{ .section = 17, .section_title = "$regex Operator", .query = "products.filter(ProductName ~ \"^HL\").count()" },
    .{ .section = 17, .section_title = "$regex Operator", .query = "products.filter(ProductName ~ \"Frame\").count()" },
    .{ .section = 17, .section_title = "$regex Operator", .query = "products.filter(ProductName ~ \"58$\").count()" },
    .{ .section = 17, .section_title = "$regex Operator", .query = "products.filter(ProductName ~ \"^AWC Logo Cap$\").count()" },

    .{ .section = 18, .section_title = "OR Filters", .query = "employees.filter(Gender = \"M\" or MaritalStatus = \"S\").count()" },
    .{ .section = 18, .section_title = "OR Filters", .query = "products.filter(ProductName contains \"Road\" or ProductName contains \"Mountain\").count()" },
    .{ .section = 18, .section_title = "OR Filters", .query = "products.filter(SubCategoryID = 1 or SubCategoryID = 2).count()" },
    .{ .section = 18, .section_title = "OR Filters", .query = "orders.filter(TotalDue > 100000 or TotalDue < 100).count()" },
    .{ .section = 18, .section_title = "OR Filters", .query = "orders.filter(EmployeeID = 289 or EmployeeID = 288).count()" },

    .{ .section = 19, .section_title = "Range Scans (closed)", .query = "orders.filter(EmployeeID >= 285 and EmployeeID <= 287).count()" },
    .{ .section = 19, .section_title = "Range Scans (open)", .query = "orders.filter(EmployeeID > 285 and EmployeeID < 289).count()" },
    .{ .section = 19, .section_title = "Range Scans (one-sided)", .query = "orders.filter(EmployeeID > 288).count()" },
    .{ .section = 19, .section_title = "Range Scans (one-sided)", .query = "orders.filter(EmployeeID < 285).count()" },

    .{ .section = 20, .section_title = "$between Operator", .query = "orders.filter(TotalDue between 100 and 5000).count()" },
    .{ .section = 20, .section_title = "$between Operator", .query = "products.filter(ListPrice between 10.0 and 50.0).count()" },
    .{ .section = 20, .section_title = "$between Operator", .query = "employees.filter(EmployeeID between 280 and 290).count()" },
    .{ .section = 20, .section_title = "$between Operator", .query = "products.filter(ListPrice between 10.0 and 50.0 and MakeFlag = 1).count()" },
    .{ .section = 20, .section_title = "$between Operator", .query = "orders.filter(EmployeeID between 285 and 289).orderBy(TotalDue, desc).limit(10)" },

    .{ .section = 21, .section_title = "Nested Field Access", .query = "customers.filter(Address.City = \"New York\").count()" },
    .{ .section = 21, .section_title = "Nested Field Access", .query = "customers.filter(Address.State = \"CA\").count()" },
    .{ .section = 21, .section_title = "Nested Field Access", .query = "customers.filter(Address.Country = \"US\").count()" },
    .{ .section = 21, .section_title = "Nested Field Access", .query = "customers.filter(Address.City = \"Seattle\").count()" },

    .{ .section = 22, .section_title = "Insert", .destructive = true, .query = "products.insert({\"ProductID\": 9001, \"ProductName\": \"Test Widget\", \"ListPrice\": 99.99, \"SubCategoryID\": 1})" },
    .{ .section = 22, .section_title = "Insert", .destructive = true, .query = "vendors.insert({\"VendorID\": 9001, \"VendorName\": \"Test Vendor\", \"CreditRating\": 3, \"ActiveFlag\": 1})" },
    .{ .section = 22, .section_title = "Insert", .destructive = true, .query = "productcategories.insert({\"CategoryID\": 99, \"CategoryName\": \"TestCategory\"})" },

    .{ .section = 23, .section_title = "Update (set)", .destructive = true, .query = "products.filter(ProductID = 9001).set({\"ListPrice\": 149.99})" },
    .{ .section = 23, .section_title = "Update (set)", .destructive = true, .query = "vendors.filter(VendorName = \"Test Vendor\").set({\"CreditRating\": 5})" },
    .{ .section = 23, .section_title = "Update (set)", .destructive = true, .query = "products.filter(MakeFlag = 1 and ListPrice > 100).set({\"StandardCost\": 75.00})" },
    .{ .section = 23, .section_title = "Update (set)", .destructive = true, .query = "products.filter(ProductID = 9001).set({\"ListPrice\": 199.99, \"StandardCost\": 80.00})" },

    .{ .section = 24, .section_title = "Delete", .destructive = true, .query = "products.filter(ProductID = 9001).delete()" },
    .{ .section = 24, .section_title = "Delete", .destructive = true, .query = "vendors.filter(ActiveFlag = 0).delete()" },
    .{ .section = 24, .section_title = "Delete", .destructive = true, .query = "products.filter(MakeFlag = 0 and ListPrice < 5).delete()" },
};
