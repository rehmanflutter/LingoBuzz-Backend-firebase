import UIKit
import Flutter
import WidgetKit
import BackgroundTasks
import firebase_core
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var widgetActionsChannel: FlutterMethodChannel?
    private var widgetKitChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Register custom background tasks FIRST (before plugins)
        if #available(iOS 13.0, *) {
            registerCustomBackgroundTasks()
        }

        // Register Flutter plugins (this includes Firebase)
        GeneratedPluginRegistrant.register(with: self)

        // 🔔 Register for remote notifications (AFTER GeneratedPluginRegistrant)
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        application.registerForRemoteNotifications()

        // Setup Flutter <-> Native channels for widgets
        setupFlutterChannels()

        // iOS background fetch for widgets
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Flutter Channels Setup
    private func setupFlutterChannels() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            print("⚠️ FlutterViewController not found")
            return
        }

        widgetActionsChannel = FlutterMethodChannel(
            name: "widget_actions",
            binaryMessenger: controller.binaryMessenger
        )

        widgetKitChannel = FlutterMethodChannel(
            name: "widgetkit_reload",
            binaryMessenger: controller.binaryMessenger
        )

        widgetKitChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "Self unavailable", details: nil))
                return
            }

            if call.method == "reloadAllTimelines" {
                if #available(iOS 14.0, *) {
                    WidgetCenter.shared.reloadAllTimelines()
                    print("🔄 WidgetKit: All timelines reloaded from Flutter")
                    result(true)
                } else {
                    result(FlutterError(
                        code: "UNAVAILABLE",
                        message: "WidgetKit not available",
                        details: nil
                    ))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        print("✅ Flutter channels setup complete")
    }

    // MARK: - 🔔 Push Notification Handlers

    // Handle APNs token registration - CRITICAL for iOS push notifications
    override func application(_ application: UIApplication,
                              didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 APNs Device Token registered")
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Token: \(tokenString)")

        // Pass to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken

        // Also call super to let Flutter plugins handle it
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    // Handle APNs registration failure
    override func application(_ application: UIApplication,
                              didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    // MARK: - UNUserNotificationCenterDelegate (iOS 10+)

    // Handle notification when app is in foreground
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         willPresent notification: UNNotification,
                                         withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("📨 Notification in FOREGROUND: \(notification.request.content.title)")

        // Let Flutter handle the notification, but also show it
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }

        // Call super to let Flutter plugins handle it
        super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: { _ in })
    }

    // Handle notification tap
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                         didReceive response: UNNotificationResponse,
                                         withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📱 Notification TAPPED: \(response.notification.request.content.title)")

        // Call super to let Flutter plugins handle it
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }

    // MARK: - Background Tasks Registration
    @available(iOS 13.0, *)
    private func registerCustomBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.lingobuzz.midnight",
            using: nil
        ) { [weak self] task in
            self?.handleMidnightFetch(task: task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.lingobuzz.wordupdate",
            using: nil
        ) { [weak self] task in
            self?.handleWordUpdate(task: task as! BGAppRefreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.lingobuzz.immediate",
            using: nil
        ) { [weak self] task in
            self?.handleImmediateUpdate(task: task as! BGAppRefreshTask)
        }

        print("✅ Custom background tasks registered (midnight, wordupdate, immediate)")
    }

    // MARK: - Background Task Handlers
    @available(iOS 13.0, *)
    private func handleMidnightFetch(task: BGAppRefreshTask) {
        print("🌙 Midnight fetch triggered at \(Date())")

        scheduleMidnightTask()

        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ WidgetKit timelines reloaded for midnight")
        }

        task.setTaskCompleted(success: true)
    }

    @available(iOS 13.0, *)
    private func handleWordUpdate(task: BGAppRefreshTask) {
        print("🔄 Word update task triggered at \(Date())")

        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ WidgetKit timelines reloaded for word update")
        }

        task.setTaskCompleted(success: true)
    }

    @available(iOS 13.0, *)
    private func handleImmediateUpdate(task: BGAppRefreshTask) {
        print("⚡ Immediate update task triggered at \(Date())")

        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ WidgetKit timelines reloaded for immediate update")
        }

        task.setTaskCompleted(success: true)
    }

    @available(iOS 13.0, *)
    private func scheduleMidnightTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.lingobuzz.midnight")

        request.earliestBeginDate = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Date(timeIntervalSinceNow: 86400)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 Scheduled midnight task for \(request.earliestBeginDate!)")
        } catch {
            print("⚠️ Failed to schedule midnight task: \(error)")
        }
    }

    // MARK: - iOS Background Fetch (for older iOS versions and additional widget updates)
    override func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("🔄 performFetchWithCompletionHandler invoked at \(Date())")

        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("✅ WidgetKit timelines reloaded from background fetch")
        }

        completionHandler(.newData)
    }

    // MARK: - Deep Link Handling (for widget actions)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        print("🔗 Deep link received: \(url)")

        if let host = url.host {
            print("🎯 Widget action: \(host)")
            widgetActionsChannel?.invokeMethod("onWidgetAction", arguments: ["action": host])

            if #available(iOS 14.0, *) {
                WidgetCenter.shared.reloadAllTimelines()
                print("🔄 Widgets reloaded after deep link action")
            }
        }

        return super.application(app, open: url, options: options)
    }

    // MARK: - App Lifecycle (Critical for widget updates)
    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        print("📲 App entering foreground")
        reloadAllWidgets()

        // Clear badge count
        application.applicationIconBadgeNumber = 0
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        print("✅ App became active")
        reloadAllWidgets()
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        print("🌙 App entered background")

        // Reload widgets when app goes to background
        reloadAllWidgets()
    }

    private func reloadAllWidgets() {
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 All widgets reloaded")
        }
    }
}