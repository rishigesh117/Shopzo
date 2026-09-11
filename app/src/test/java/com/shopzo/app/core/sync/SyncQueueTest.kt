package com.shopzo.app.core.sync

import com.shopzo.app.core.database.entity.SyncQueueEntity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class SyncQueueTest {

    @Test
    fun testSyncQueueItemCreation() {
        val item = SyncQueueEntity(
            id = 1L,
            entityType = "BILL",
            entityId = "bill-uuid-101",
            operationType = "CREATE",
            payloadJson = """{"billNumber":"#1001","grandTotalPaise":5000}""",
            shopId = "shop-uuid-abc",
            status = "PENDING"
        )

        assertEquals("BILL", item.entityType)
        assertEquals("bill-uuid-101", item.entityId)
        assertEquals("CREATE", item.operationType)
        assertEquals("shop-uuid-abc", item.shopId)
        assertEquals("PENDING", item.status)
        assertNotNull(item.createdAt)
    }

    @Test
    fun testSyncStateDefaults() {
        val status = SyncStatusInfo()
        assertEquals(SyncState.SYNCED, status.state)
        assertEquals(0, status.pendingCount)
        assertEquals("All data synced", status.message)
    }
}
