//
//  AppDelegate.swift
//  ARkitDemo
//
//  Created by 洪德晟 on 2017/7/11.
//  Copyright © 2017年 洪德晟. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var rootViewController: RootViewController!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        self.rootViewController = RootViewController()
        let navigationController: UINavigationController = UINavigationController(rootViewController: self.rootViewController)
        navigationController.navigationBar.isTranslucent = false
        navigationController.interactivePopGestureRecognizer!.isEnabled = false

        self.window = UIWindow(frame: UIScreen.main.bounds)

        if let window = self.window {
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
        
        return true
    }

}

