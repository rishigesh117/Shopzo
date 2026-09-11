package com.shopzo.app.features.reports.data

import com.shopzo.app.core.database.ShopzoDatabase
import com.shopzo.app.core.database.dao.BestSellerAggregate
import com.shopzo.app.core.database.entity.ProductEntity
import com.shopzo.app.core.database.entity.lowStockThreshold
import com.shopzo.app.core.database.entity.stockQuantity
import kotlinx.coroutines.flow.*
import java.util.Calendar

enum class DateRangePeriod(val displayName: String) {
    TODAY("Today"),
    YESTERDAY("Yesterday"),
    THIS_WEEK("This Week"),
    THIS_MONTH("This Month"),
    LAST_MONTH("Last Month"),
    CUSTOM("Custom")
}

data class TimeRange(val startTime: Long, val endTime: Long)

fun DateRangePeriod.getTimeRange(customStart: Long? = null, customEnd: Long? = null): TimeRange {
    val cal = Calendar.getInstance()
    return when (this) {
        DateRangePeriod.TODAY -> {
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val start = cal.timeInMillis
            cal.set(Calendar.HOUR_OF_DAY, 23)
            cal.set(Calendar.MINUTE, 59)
            cal.set(Calendar.SECOND, 59)
            cal.set(Calendar.MILLISECOND, 999)
            TimeRange(start, cal.timeInMillis)
        }
        DateRangePeriod.YESTERDAY -> {
            cal.add(Calendar.DAY_OF_YEAR, -1)
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val start = cal.timeInMillis
            cal.set(Calendar.HOUR_OF_DAY, 23)
            cal.set(Calendar.MINUTE, 59)
            cal.set(Calendar.SECOND, 59)
            cal.set(Calendar.MILLISECOND, 999)
            TimeRange(start, cal.timeInMillis)
        }
        DateRangePeriod.THIS_WEEK -> {
            cal.set(Calendar.DAY_OF_WEEK, cal.firstDayOfWeek)
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val start = cal.timeInMillis
            val end = System.currentTimeMillis()
            TimeRange(start, end)
        }
        DateRangePeriod.THIS_MONTH -> {
            cal.set(Calendar.DAY_OF_MONTH, 1)
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val start = cal.timeInMillis
            val end = System.currentTimeMillis()
            TimeRange(start, end)
        }
        DateRangePeriod.LAST_MONTH -> {
            cal.add(Calendar.MONTH, -1)
            cal.set(Calendar.DAY_OF_MONTH, 1)
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            cal.set(Calendar.MILLISECOND, 0)
            val start = cal.timeInMillis
            cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH))
            cal.set(Calendar.HOUR_OF_DAY, 23)
            cal.set(Calendar.MINUTE, 59)
            cal.set(Calendar.SECOND, 59)
            cal.set(Calendar.MILLISECOND, 999)
            TimeRange(start, cal.timeInMillis)
        }
        DateRangePeriod.CUSTOM -> {
            TimeRange(customStart ?: 0L, customEnd ?: System.currentTimeMillis())
        }
    }
}

data class SalesReportData(
    val totalSalesPaise: Long = 0L,
    val billCount: Int = 0,
    val totalProductsSold: Double = 0.0,
    val averageBillValuePaise: Long = 0L,
    val totalPaidPaise: Long = 0L,
    val totalPendingPaise: Long = 0L,
    val totalReturnedPaise: Long = 0L
)

data class ProfitReportData(
    val grossSalesPaise: Long = 0L,
    val costOfGoodsSoldPaise: Long = 0L,
    val grossProfitPaise: Long = 0L,
    val returnedAmountPaise: Long = 0L,
    val netProfitPaise: Long = 0L
)

data class StockReportData(
    val totalProductsCount: Int = 0,
    val totalStockQuantity: Double = 0.0,
    val lowStockCount: Int = 0,
    val outOfStockCount: Int = 0,
    val stockCostValuePaise: Long = 0L,
    val stockRetailValuePaise: Long = 0L,
    val potentialProfitPaise: Long = 0L
)

enum class BestSellerMetric { QUANTITY, REVENUE, PROFIT }

class ReportRepository(
    private val database: ShopzoDatabase
) {
    private val billDao = database.billDao()
    private val billItemDao = database.billItemDao()
    private val returnDao = database.returnDao()
    private val productDao = database.productDao()
    private val customerDao = database.customerDao()

    fun getSalesReport(shopId: String, timeRange: TimeRange): Flow<SalesReportData> {
        val billsFlow = billDao.getBillsInPeriod(shopId, timeRange.startTime, timeRange.endTime)
        val itemsSoldFlow = billItemDao.getTotalProductsSoldInPeriod(shopId, timeRange.startTime, timeRange.endTime)
        val refundsFlow = returnDao.getTotalRefundsInPeriod(shopId, timeRange.startTime, timeRange.endTime)

        return combine(billsFlow, itemsSoldFlow, refundsFlow) { bills, itemsSold, refunds ->
            val totalSales = bills.sumOf { it.grandTotalPaise }
            val totalPaid = bills.sumOf { it.paidAmountPaise }
            val totalPending = bills.sumOf { it.pendingAmountPaise }
            val count = bills.size
            val avgBill = if (count > 0) totalSales / count else 0L
            val returned = refunds ?: 0L

            SalesReportData(
                totalSalesPaise = totalSales,
                billCount = count,
                totalProductsSold = itemsSold ?: 0.0,
                averageBillValuePaise = avgBill,
                totalPaidPaise = totalPaid,
                totalPendingPaise = totalPending,
                totalReturnedPaise = returned
            )
        }
    }

    fun getProfitReport(shopId: String, timeRange: TimeRange): Flow<ProfitReportData> {
        val billsFlow = billDao.getBillsInPeriod(shopId, timeRange.startTime, timeRange.endTime)
        val refundsFlow = returnDao.getTotalRefundsInPeriod(shopId, timeRange.startTime, timeRange.endTime)

        return combine(billsFlow, refundsFlow) { bills, refunds ->
            var grossSales = 0L
            var cogs = 0L

            for (bill in bills) {
                val items = billItemDao.getItemsForBill(bill.id)
                for (item in items) {
                    grossSales += item.subtotalPaise
                    cogs += (item.buyingPricePaise * item.quantity).toLong()
                }
            }

            val grossProfit = grossSales - cogs
            val returned = refunds ?: 0L
            val netProfit = grossProfit - returned

            ProfitReportData(
                grossSalesPaise = grossSales,
                costOfGoodsSoldPaise = cogs,
                grossProfitPaise = grossProfit,
                returnedAmountPaise = returned,
                netProfitPaise = netProfit
            )
        }
    }

    fun getStockReport(shopId: String): Flow<StockReportData> {
        return productDao.getProductsByShop(shopId).map { products ->
            val totalCount = products.size
            var totalQty = 0.0
            var lowStockCount = 0
            var outOfStockCount = 0
            var costValue = 0L
            var retailValue = 0L

            for (p in products) {
                totalQty += p.stockQuantity
                if (p.stockQuantity <= 0.0) {
                    outOfStockCount++
                } else if (p.stockQuantity <= p.lowStockThreshold) {
                    lowStockCount++
                }
                costValue += (p.buyingPricePaise * p.stockQuantity).toLong()
                retailValue += (p.sellingPricePaise * p.stockQuantity).toLong()
            }

            StockReportData(
                totalProductsCount = totalCount,
                totalStockQuantity = totalQty,
                lowStockCount = lowStockCount,
                outOfStockCount = outOfStockCount,
                stockCostValuePaise = costValue,
                stockRetailValuePaise = retailValue,
                potentialProfitPaise = retailValue - costValue
            )
        }
    }

    fun getBestSellers(
        shopId: String,
        timeRange: TimeRange,
        metric: BestSellerMetric,
        limit: Int
    ): Flow<List<BestSellerAggregate>> {
        return when (metric) {
            BestSellerMetric.QUANTITY -> billItemDao.getTopSellersByQuantity(shopId, timeRange.startTime, timeRange.endTime, limit)
            BestSellerMetric.REVENUE -> billItemDao.getTopSellersByRevenue(shopId, timeRange.startTime, timeRange.endTime, limit)
            BestSellerMetric.PROFIT -> billItemDao.getTopSellersByProfit(shopId, timeRange.startTime, timeRange.endTime, limit)
        }
    }
}
