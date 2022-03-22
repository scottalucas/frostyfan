//
//  whf001App.swift
//  Shared
//
//  Created by Scott Lucas on 12/9/20.
//

import SwiftUI
import CoreLocation
import Combine
import BackgroundTasks
import UserNotifications

@main
struct AirspaceFanApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    
    let location = Location()
    let weather = WeatherMonitor.shared
    let sharedHouseData = HouseMonitor.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sharedHouseData)
                .environmentObject(weather)
                .environmentObject(location)
                .onChange(of: scenePhase, perform: { newPhase in
                    switch newPhase {
                        case .active:
                            BGTaskScheduler.shared.cancelAllTaskRequests()
                            weather.monitor()
                        case .background:
                            print("background")
                            WeatherBackgroundTaskManager.scheduleBackgroundTempCheckTask (forId: BackgroundTaskIdentifier.tempertureOutOfRange, waitUntil: WeatherMonitor.shared.weatherServiceNextCheckDate())
                            weather.suspendMonitor()
                        case .inactive:
                            break
                        @unknown default:
                            break
                    }
                })
        }
    }
    
    init () {
        UITableView.appearance().backgroundColor = .main
        UITableView.appearance().separatorColor = .main
        UIPageControl.appearance().currentPageIndicatorTintColor = .main
        UIPageControl.appearance().pageIndicatorTintColor = .main.withAlphaComponent(0.25)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
//    var scheduler: BGTaskScheduler = BGTaskScheduler.shared
        
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            
            if error != nil || !granted {
                print("Error requesting notification authorization, \(error?.localizedDescription ?? "not permitted by user.")")
            } else {
                
                if BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundTaskIdentifier.tempertureOutOfRange, using: nil, launchHandler: { task in
                    print("Background task called")
                    guard let task = task as? BGRefreshTask else { return }
                    Task {
                        await WeatherBackgroundTaskManager.handleTempCheckTask(task: task, loader: Weather.load)
                    }
                }) {
                    print("Task registration succeeded")
                } else {
                    print("Task registration failed")
                }
            }
        }
        
        return true
    }
}

private struct ProgressKey: EnvironmentKey {
    static let defaultValue: Double? = nil
}

extension EnvironmentValues {
    var updateProgress: Double? {
        get { self[ProgressKey.self] }
        set { self[ProgressKey.self] = newValue }
    }
}

extension View {
    func scanProgress(_ progress: Double?) -> some View {
        environment(\.updateProgress, progress)
    }
}

protocol BGTaskSched {
    static var shared: BGTaskScheduler { get }
    func register(forTaskWithIdentifier identifier: String,
                  using queue: DispatchQueue?,
                  launchHandler: @escaping (BGTask) -> Void) -> Bool
    func submit(_ taskRequest: BGTaskRequest) throws
    func cancel(taskRequestWithIdentifier: String)
    func cancelAllTaskRequests()
}

extension BGTaskScheduler: BGTaskSched { }

protocol BGRefreshTask: AnyObject {
    var identifier: String { get }
    var expirationHandler: (() -> Void)? { get set }
    func setTaskCompleted(success: Bool)
}

extension BGAppRefreshTask: BGRefreshTask { }
