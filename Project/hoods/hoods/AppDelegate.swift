//
//  AppDelegate.swift
//  hoods
//
//  Created by Andrew Carvajal on 8/10/16.
//  Copyright © 2016 YugeTech. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var navigationController = UIViewController()
    var maskBgView = UIView()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(openHole), name: "LocationManagerAuthChanged", object: nil)

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.backgroundColor = UIColor.whiteColor()
        self.window!.makeKeyAndVisible()

        // rootViewController from Storyboard
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        navigationController = mainStoryboard.instantiateViewControllerWithIdentifier("navigationController")
        self.window!.rootViewController = navigationController

        // circle mask
        navigationController.view.layer.mask = CALayer()
        navigationController.view.layer.mask!.contents = UIImage(named: "CircleBlack")!.CGImage
        navigationController.view.layer.mask!.bounds = CGRect(x: 0, y: 0, width: 0, height: 0)
        navigationController.view.layer.mask!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        navigationController.view.layer.mask!.position = CGPoint(x: navigationController.view.frame.width / 2, y: navigationController.view.frame.height / 2)

        // circle mask background view
        maskBgView = UIView(frame: navigationController.view.frame)
        maskBgView.backgroundColor = UIColor.clearColor()
        navigationController.view.addSubview(maskBgView)
        navigationController.view.bringSubviewToFront(maskBgView)
        
        DataSource.sharedInstance.locationManager.requestWhenInUseAuthorization()

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    @objc private func openHole() {
                
        // logo mask animation
        let transformAnimation = CAKeyframeAnimation(keyPath: "bounds")
        transformAnimation.delegate = self
        transformAnimation.duration = 1.2
        transformAnimation.beginTime = CACurrentMediaTime() + 1 // add 1 second of delay
        let initialBounds = NSValue(CGRect: navigationController.view.layer.mask!.bounds)
        let secondBounds = NSValue(CGRect: CGRect(x: 0, y: 0, width: 50, height: 50))
        let finalBounds = NSValue(CGRect: CGRect(x: 0, y: 0, width: 2000, height: 2000))
        transformAnimation.values = [initialBounds, secondBounds, finalBounds]
        transformAnimation.keyTimes = [0, 0.5, 1.2]
        transformAnimation.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut), CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)]
        transformAnimation.removedOnCompletion = false
        transformAnimation.fillMode = kCAFillModeForwards
        navigationController.view.layer.mask?.addAnimation(transformAnimation, forKey: "maskAnimation")
        
        // logo mask background view animation
        UIView.animateWithDuration(0.1, delay: 1.35, options: .CurveEaseIn, animations: {
            self.maskBgView.alpha = 0.0
        }) { finished in
            self.maskBgView.removeFromSuperview()
        }
    }
}

