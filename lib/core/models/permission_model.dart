class ShopzoPermissions {
  final bool createBills;
  final bool viewBills;
  final bool addProducts;
  final bool editProducts;
  final bool deleteProducts;
  final bool updateStock;
  final bool viewCustomers;
  final bool manageCustomers;
  final bool viewPayments;
  final bool managePayments;
  final bool processReturns;
  final bool viewReports;
  final bool viewProfit;
  final bool manageMembers;
  final bool shopSettings;

  const ShopzoPermissions({
    this.createBills = true,
    this.viewBills = true,
    this.addProducts = false,
    this.editProducts = false,
    this.deleteProducts = false,
    this.updateStock = true,
    this.viewCustomers = true,
    this.manageCustomers = false,
    this.viewPayments = true,
    this.managePayments = false,
    this.processReturns = true,
    this.viewReports = false,
    this.viewProfit = false,
    this.manageMembers = false,
    this.shopSettings = false,
  });

  static ShopzoPermissions fullAccess() {
    return const ShopzoPermissions(
      createBills: true,
      viewBills: true,
      addProducts: true,
      editProducts: true,
      deleteProducts: true,
      updateStock: true,
      viewCustomers: true,
      manageCustomers: true,
      viewPayments: true,
      managePayments: true,
      processReturns: true,
      viewReports: true,
      viewProfit: true,
      manageMembers: true,
      shopSettings: true,
    );
  }

  static ShopzoPermissions standardStaff() {
    return const ShopzoPermissions(
      createBills: true,
      viewBills: true,
      addProducts: false,
      editProducts: false,
      deleteProducts: false,
      updateStock: true,
      viewCustomers: true,
      manageCustomers: false,
      viewPayments: true,
      managePayments: false,
      processReturns: true,
      viewReports: false,
      viewProfit: false,
      manageMembers: false,
      shopSettings: false,
    );
  }

  ShopzoPermissions copyWith({
    bool? createBills,
    bool? viewBills,
    bool? addProducts,
    bool? editProducts,
    bool? deleteProducts,
    bool? updateStock,
    bool? viewCustomers,
    bool? manageCustomers,
    bool? viewPayments,
    bool? managePayments,
    bool? processReturns,
    bool? viewReports,
    bool? viewProfit,
    bool? manageMembers,
    bool? shopSettings,
  }) {
    return ShopzoPermissions(
      createBills: createBills ?? this.createBills,
      viewBills: viewBills ?? this.viewBills,
      addProducts: addProducts ?? this.addProducts,
      editProducts: editProducts ?? this.editProducts,
      deleteProducts: deleteProducts ?? this.deleteProducts,
      updateStock: updateStock ?? this.updateStock,
      viewCustomers: viewCustomers ?? this.viewCustomers,
      manageCustomers: manageCustomers ?? this.manageCustomers,
      viewPayments: viewPayments ?? this.viewPayments,
      managePayments: managePayments ?? this.managePayments,
      processReturns: processReturns ?? this.processReturns,
      viewReports: viewReports ?? this.viewReports,
      viewProfit: viewProfit ?? this.viewProfit,
      manageMembers: manageMembers ?? this.manageMembers,
      shopSettings: shopSettings ?? this.shopSettings,
    );
  }

  int get enabledCount {
    int count = 0;
    if (createBills) count++;
    if (viewBills) count++;
    if (addProducts) count++;
    if (editProducts) count++;
    if (deleteProducts) count++;
    if (updateStock) count++;
    if (viewCustomers) count++;
    if (manageCustomers) count++;
    if (viewPayments) count++;
    if (managePayments) count++;
    if (processReturns) count++;
    if (viewReports) count++;
    if (viewProfit) count++;
    if (manageMembers) count++;
    if (shopSettings) count++;
    return count;
  }

  bool get isFullAccess => enabledCount == 15;
}
