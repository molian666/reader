package com.htmake.reader.utils

/**
 * 记录最近一次来自阅读 App（User-Agent: Legado）的 WebDAV 请求，
 * 用于在 /reader3/getSyncStatus 里判断“App 到底有没有把进度传上来”。
 */
object SyncDebug {
    @Volatile
    var lastAppPutTime: Long = 0L

    @Volatile
    var lastAppPutPath: String = ""

    @Volatile
    var lastAppPutIp: String = ""

    @Volatile
    var lastAppPutBytes: Long = 0L

    fun recordPut(path: String, ip: String?, bytes: Long) {
        lastAppPutTime = System.currentTimeMillis()
        lastAppPutPath = path
        lastAppPutIp = ip ?: ""
        lastAppPutBytes = bytes
    }
}
