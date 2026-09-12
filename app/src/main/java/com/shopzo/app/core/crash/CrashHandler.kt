package com.shopzo.app.core.crash

import android.content.Context
import android.content.Intent
import android.util.Log

object CrashHandler {

    fun install(context: Context) {
        val defaultHandler = Thread.getDefaultUncaughtExceptionHandler()

        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                val stackTrace = Log.getStackTraceString(throwable)
                Log.e("ShopzoCrash", "Uncaught exception on thread ${thread.name}: $stackTrace")

                // Save to SharedPreferences as backup
                val prefs = context.getSharedPreferences("shopzo_crash_prefs", Context.MODE_PRIVATE)
                prefs.edit()
                    .putString("last_crash_message", throwable.localizedMessage ?: throwable.javaClass.simpleName)
                    .putString("last_crash_trace", stackTrace)
                    .putLong("last_crash_timestamp", System.currentTimeMillis())
                    .commit()

                // Launch CrashActivity in a fresh task
                val intent = Intent(context, CrashActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    putExtra("error_message", throwable.localizedMessage ?: throwable.javaClass.simpleName)
                    putExtra("stack_trace", stackTrace)
                }
                context.startActivity(intent)

                // Terminate current crashed process
                android.os.Process.killProcess(android.os.Process.myPid())
                System.exit(10)
            } catch (e: Exception) {
                Log.e("ShopzoCrash", "Failed to launch CrashActivity", e)
                defaultHandler?.uncaughtException(thread, throwable)
            }
        }
    }
}
