package com.example.buddy

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        // Notification handling is done by the Flutter plugin
        // This service just needs to exist to be registered in the manifest
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // Notification handling is done by the Flutter plugin
    }
}
