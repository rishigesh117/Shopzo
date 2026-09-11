package com.shopzo.app.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.outlined.Inventory2
import androidx.compose.material.icons.outlined.People
import androidx.compose.material.icons.outlined.Receipt
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.shopzo.app.ShopzoApplication
import com.shopzo.app.core.model.UserRole
import com.shopzo.app.features.auth.ui.AuthViewModel
import com.shopzo.app.features.auth.ui.LoginScreen
import com.shopzo.app.features.auth.ui.RegisterScreen
import com.shopzo.app.features.billing.ui.*
import com.shopzo.app.features.customers.ui.*
import com.shopzo.app.features.dashboard.ui.DashboardScreen
import com.shopzo.app.features.dashboard.ui.DashboardViewModel
import com.shopzo.app.features.payments.ui.PaymentViewModel
import com.shopzo.app.features.products.ui.*
import com.shopzo.app.features.reports.ui.ReportsScreen
import com.shopzo.app.features.reports.ui.ReportsViewModel
import com.shopzo.app.features.returns.ui.ReturnsScreen
import com.shopzo.app.features.returns.ui.ReturnsViewModel
import com.shopzo.app.features.settings.ui.MoreScreen
import com.shopzo.app.features.shop.ui.CreateShopScreen
import com.shopzo.app.features.shop.ui.ShopSettingsScreen
import com.shopzo.app.features.shop.ui.ShopViewModel
import com.shopzo.app.features.staff.ui.*
import com.shopzo.app.features.stock.ui.*
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

data class BottomNavItem(val route: String, val icon: ImageVector, val label: String)

val bottomNavItems = listOf(
    BottomNavItem(Routes.DASHBOARD, Icons.Filled.Home, "Home"),
    BottomNavItem(Routes.BILLS, Icons.Outlined.Receipt, "Bills"),
    BottomNavItem(Routes.PRODUCTS, Icons.Outlined.Inventory2, "Products"),
    BottomNavItem(Routes.CUSTOMERS, Icons.Outlined.People, "Customers"),
    BottomNavItem(Routes.MORE, Icons.Filled.MoreHoriz, "More")
)

val screensWithBottomNav = setOf(Routes.DASHBOARD, Routes.BILLS, Routes.PRODUCTS, Routes.CUSTOMERS, Routes.MORE)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ShopzoNavGraph() {
    val context = LocalContext.current
    val app = context.applicationContext as ShopzoApplication
    val navController = rememberNavController()
    val scope = rememberCoroutineScope()

    // Determine start destination based on session
    var startDestination by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        val session = app.sessionManager.sessionFlow.first()
        startDestination = when {
            session == null -> Routes.LOGIN
            session.shopId.isEmpty() && session.userRole == UserRole.OWNER -> Routes.CREATE_SHOP
            else -> Routes.DASHBOARD
        }
    }

    if (startDestination == null) return // Loading

    val currentBackStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = currentBackStackEntry?.destination?.route
    val showBottomNav = currentRoute in screensWithBottomNav

    // Session data for ViewModels
    var userName by remember { mutableStateOf("") }
    var shopId by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        app.sessionManager.sessionFlow.collect { session ->
            userName = session?.userName ?: ""
            shopId = session?.shopId ?: ""
        }
    }

    Scaffold(
        bottomBar = {
            if (showBottomNav) {
                NavigationBar {
                    bottomNavItems.forEach { item ->
                        NavigationBarItem(
                            selected = currentRoute == item.route,
                            onClick = {
                                if (currentRoute != item.route) {
                                    navController.navigate(item.route) {
                                        popUpTo(Routes.DASHBOARD) { saveState = true }
                                        launchSingleTop = true
                                        restoreState = true
                                    }
                                }
                            },
                            icon = { Icon(item.icon, contentDescription = item.label) },
                            label = { Text(item.label) }
                        )
                    }
                }
            }
        }
    ) { padding ->
        NavHost(
            navController = navController,
            startDestination = startDestination!!,
            modifier = Modifier.padding(padding)
        ) {
            // Auth
            composable(Routes.LOGIN) {
                val vm: AuthViewModel = viewModel(factory = AuthViewModel.Factory(app.authRepository, app.shopRepository, app.sessionManager))
                LoginScreen(
                    viewModel = vm,
                    onNavigateToRegister = { navController.navigate(Routes.REGISTER) },
                    onNavigateToDashboard = { navController.navigate(Routes.DASHBOARD) { popUpTo(0) { inclusive = true } } },
                    onNavigateToCreateShop = { navController.navigate(Routes.CREATE_SHOP) { popUpTo(0) { inclusive = true } } }
                )
            }
            composable(Routes.REGISTER) {
                val vm: AuthViewModel = viewModel(factory = AuthViewModel.Factory(app.authRepository, app.shopRepository, app.sessionManager))
                RegisterScreen(
                    viewModel = vm,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToCreateShop = { navController.navigate(Routes.CREATE_SHOP) { popUpTo(0) { inclusive = true } } }
                )
            }
            composable(Routes.CREATE_SHOP) {
                val vm: ShopViewModel = viewModel(factory = ShopViewModel.Factory(app.shopRepository, app.sessionManager))
                CreateShopScreen(
                    viewModel = vm,
                    onNavigateToDashboard = { navController.navigate(Routes.DASHBOARD) { popUpTo(0) { inclusive = true } } }
                )
            }

            // Main screens
            composable(Routes.DASHBOARD) {
                val vm: DashboardViewModel = viewModel(factory = DashboardViewModel.Factory(app.productRepository, app.reportRepository, app.customerRepository, app.sessionManager))
                DashboardScreen(
                    viewModel = vm,
                    onNavigateToProducts = { navController.navigate(Routes.PRODUCTS) },
                    onNavigateToAddProduct = { navController.navigate(Routes.ADD_PRODUCT) },
                    onNavigateToNewBill = { navController.navigate(Routes.NEW_BILL) },
                    onNavigateToCustomers = { navController.navigate(Routes.CUSTOMERS) },
                    onNavigateToReturns = { navController.navigate(Routes.RETURNS) },
                    onNavigateToReports = { navController.navigate(Routes.REPORTS) },
                    userName = userName
                )
            }
            composable(Routes.NEW_BILL) {
                val posVm: POSViewModel = viewModel(factory = POSViewModel.Factory(app.productRepository, app.customerRepository, app.billingRepository, app.sessionManager))
                val customerVm: CustomerViewModel = viewModel(factory = CustomerViewModel.Factory(app.customerRepository, app.billingRepository, app.paymentRepository, app.returnRepository, app.sessionManager))
                NewBillScreen(
                    viewModel = posVm,
                    customerViewModel = customerVm,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToBillDetail = { billId ->
                        navController.navigate(Routes.billDetail(billId)) {
                            popUpTo(Routes.NEW_BILL) { inclusive = true }
                        }
                    }
                )
            }
            composable(Routes.BILLS) {
                val billsVm: BillsViewModel = viewModel(factory = BillsViewModel.Factory(app.billingRepository, app.paymentRepository, app.returnRepository, app.sessionManager))
                BillsScreen(
                    viewModel = billsVm,
                    onNavigateToNewBill = { navController.navigate(Routes.NEW_BILL) },
                    onNavigateToBillDetail = { billId -> navController.navigate(Routes.billDetail(billId)) }
                )
            }
            composable(
                Routes.BILL_DETAIL,
                arguments = listOf(navArgument("billId") { type = NavType.StringType })
            ) { backStackEntry ->
                val billId = backStackEntry.arguments?.getString("billId") ?: return@composable
                val billsVm: BillsViewModel = viewModel(factory = BillsViewModel.Factory(app.billingRepository, app.paymentRepository, app.returnRepository, app.sessionManager))
                val paymentVm: PaymentViewModel = viewModel(factory = PaymentViewModel.Factory(app.paymentRepository, app.sessionManager))
                val returnsVm: ReturnsViewModel = viewModel(factory = ReturnsViewModel.Factory(app.returnRepository, app.sessionManager))
                BillDetailScreen(
                    billId = billId,
                    viewModel = billsVm,
                    paymentViewModel = paymentVm,
                    returnsViewModel = returnsVm,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToReceipt = { id -> navController.navigate(Routes.receipt(id)) }
                )
            }
            composable(
                Routes.RECEIPT,
                arguments = listOf(navArgument("billId") { type = NavType.StringType })
            ) { backStackEntry ->
                val billId = backStackEntry.arguments?.getString("billId") ?: return@composable
                val billsVm: BillsViewModel = viewModel(factory = BillsViewModel.Factory(app.billingRepository, app.paymentRepository, app.returnRepository, app.sessionManager))
                ReceiptScreen(
                    billId = billId,
                    viewModel = billsVm,
                    onNavigateBack = { navController.popBackStack() }
                )
            }

            composable(Routes.CUSTOMERS) {
                val customerVm: CustomerViewModel = viewModel(factory = CustomerViewModel.Factory(app.customerRepository, app.billingRepository, app.paymentRepository, app.returnRepository, app.sessionManager))
                CustomerListScreen(
                    viewModel = customerVm,
                    onNavigateToCustomerDetail = { customerId -> navController.navigate(Routes.customerDetail(customerId)) }
                )
            }
            composable(
                Routes.CUSTOMER_DETAIL,
                arguments = listOf(navArgument("customerId") { type = NavType.StringType })
            ) { backStackEntry ->
                val customerId = backStackEntry.arguments?.getString("customerId") ?: return@composable
                val customerVm: CustomerViewModel = viewModel(factory = CustomerViewModel.Factory(app.customerRepository, app.billingRepository, app.paymentRepository, app.returnRepository, app.sessionManager))
                val paymentVm: PaymentViewModel = viewModel(factory = PaymentViewModel.Factory(app.paymentRepository, app.sessionManager))
                CustomerDetailScreen(
                    customerId = customerId,
                    viewModel = customerVm,
                    paymentViewModel = paymentVm,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToBillDetail = { billId -> navController.navigate(Routes.billDetail(billId)) }
                )
            }

            composable(Routes.RETURNS) {
                val returnsVm: ReturnsViewModel = viewModel(factory = ReturnsViewModel.Factory(app.returnRepository, app.sessionManager))
                ReturnsScreen(
                    viewModel = returnsVm,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToBillDetail = { billId -> navController.navigate(Routes.billDetail(billId)) }
                )
            }
            composable(Routes.REPORTS) {
                val reportsVm: ReportsViewModel = viewModel(factory = ReportsViewModel.Factory(app.reportRepository, app.customerRepository, app.sessionManager))
                ReportsScreen(
                    viewModel = reportsVm,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToCustomerDetail = { customerId -> navController.navigate(Routes.customerDetail(customerId)) }
                )
            }

            composable(Routes.PRODUCTS) {
                val vm: ProductsViewModel = viewModel(factory = ProductsViewModel.Factory(app.productRepository, app.sessionManager))
                ProductListScreen(
                    viewModel = vm,
                    onNavigateToAddProduct = { navController.navigate(Routes.ADD_PRODUCT) },
                    onNavigateToProductDetail = { navController.navigate(Routes.productDetail(it)) }
                )
            }
            composable(Routes.MORE) {
                MoreScreen(
                    onNavigateToStaff = { navController.navigate(Routes.STAFF_LIST) },
                    onNavigateToCategories = { navController.navigate(Routes.CATEGORIES) },
                    onNavigateToShopSettings = { navController.navigate(Routes.SHOP_SETTINGS) },
                    onLogout = {
                        scope.launch {
                            app.sessionManager.clearSession()
                            navController.navigate(Routes.LOGIN) { popUpTo(0) { inclusive = true } }
                        }
                    }
                )
            }

            // Products
            composable(Routes.ADD_PRODUCT) {
                val vm: ProductsViewModel = viewModel(factory = ProductsViewModel.Factory(app.productRepository, app.sessionManager))
                AddEditProductScreen(viewModel = vm, productId = null, onNavigateBack = { navController.popBackStack() })
            }
            composable(
                Routes.EDIT_PRODUCT,
                arguments = listOf(navArgument("productId") { type = NavType.StringType })
            ) { backStackEntry ->
                val productId = backStackEntry.arguments?.getString("productId") ?: return@composable
                val vm: ProductsViewModel = viewModel(factory = ProductsViewModel.Factory(app.productRepository, app.sessionManager))
                AddEditProductScreen(viewModel = vm, productId = productId, onNavigateBack = { navController.popBackStack() })
            }
            composable(
                Routes.PRODUCT_DETAIL,
                arguments = listOf(navArgument("productId") { type = NavType.StringType })
            ) { backStackEntry ->
                val productId = backStackEntry.arguments?.getString("productId") ?: return@composable
                val vm: ProductsViewModel = viewModel(factory = ProductsViewModel.Factory(app.productRepository, app.sessionManager))
                ProductDetailScreen(
                    productId = productId,
                    viewModel = vm,
                    productRepository = app.productRepository,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToEdit = { navController.navigate(Routes.editProduct(it)) },
                    onNavigateToRestock = { navController.navigate(Routes.restock(it)) },
                    onNavigateToAdjust = { navController.navigate(Routes.stockAdjustment(it)) },
                    onNavigateToHistory = { navController.navigate(Routes.stockHistory(it)) }
                )
            }
            composable(Routes.CATEGORIES) {
                val vm: ProductsViewModel = viewModel(factory = ProductsViewModel.Factory(app.productRepository, app.sessionManager))
                CategoryManagementScreen(viewModel = vm, onNavigateBack = { navController.popBackStack() })
            }

            // Stock
            composable(
                Routes.RESTOCK,
                arguments = listOf(navArgument("productId") { type = NavType.StringType })
            ) { backStackEntry ->
                val productId = backStackEntry.arguments?.getString("productId") ?: return@composable
                val vm: StockViewModel = viewModel(factory = StockViewModel.Factory(app.stockRepository, app.sessionManager))
                RestockScreen(productId = productId, viewModel = vm, onNavigateBack = { navController.popBackStack() })
            }
            composable(
                Routes.STOCK_ADJUSTMENT,
                arguments = listOf(navArgument("productId") { type = NavType.StringType })
            ) { backStackEntry ->
                val productId = backStackEntry.arguments?.getString("productId") ?: return@composable
                val vm: StockViewModel = viewModel(factory = StockViewModel.Factory(app.stockRepository, app.sessionManager))
                StockAdjustmentScreen(productId = productId, viewModel = vm, onNavigateBack = { navController.popBackStack() })
            }
            composable(
                Routes.STOCK_HISTORY,
                arguments = listOf(navArgument("productId") { type = NavType.StringType })
            ) { backStackEntry ->
                val productId = backStackEntry.arguments?.getString("productId") ?: return@composable
                val vm: StockViewModel = viewModel(factory = StockViewModel.Factory(app.stockRepository, app.sessionManager))
                StockHistoryScreen(productId = productId, viewModel = vm, onNavigateBack = { navController.popBackStack() })
            }

            // Staff
            composable(Routes.STAFF_LIST) {
                val vm: StaffViewModel = viewModel(factory = StaffViewModel.Factory(app.staffRepository, app.sessionManager))
                StaffListScreen(
                    viewModel = vm,
                    onNavigateBack = { navController.popBackStack() },
                    onNavigateToAddStaff = { navController.navigate(Routes.ADD_STAFF) },
                    onNavigateToPermissions = { navController.navigate(Routes.staffPermissions(it)) }
                )
            }
            composable(Routes.ADD_STAFF) {
                val vm: StaffViewModel = viewModel(factory = StaffViewModel.Factory(app.staffRepository, app.sessionManager))
                AddStaffScreen(viewModel = vm, onNavigateBack = { navController.popBackStack() })
            }
            composable(
                Routes.STAFF_PERMISSIONS,
                arguments = listOf(navArgument("userId") { type = NavType.StringType })
            ) { backStackEntry ->
                val userId = backStackEntry.arguments?.getString("userId") ?: return@composable
                val vm: StaffViewModel = viewModel(factory = StaffViewModel.Factory(app.staffRepository, app.sessionManager))
                StaffPermissionsScreen(userId = userId, viewModel = vm, onNavigateBack = { navController.popBackStack() })
            }

            // Shop Settings
            composable(Routes.SHOP_SETTINGS) {
                val backupVm: com.shopzo.app.features.backup.ui.BackupViewModel = viewModel(
                    factory = com.shopzo.app.features.backup.ui.BackupViewModel.Factory(app.backupRepository, app.sessionManager)
                )
                ShopSettingsScreen(
                    shopId = shopId,
                    shopRepository = app.shopRepository,
                    syncManager = app.syncManager,
                    backupViewModel = backupVm,
                    onNavigateBack = { navController.popBackStack() }
                )
            }
        }
    }
}
