//
//  BookletController.swift
//  secretmap
//
//  Created by Anton McConville on 2017-12-18.
//  Copyright © 2017 Anton McConville. All rights reserved.
//

import Foundation

import UIKit

struct Article: Codable {
    let page: Int
    let title: String
    let subtitle: String
    let imageEncoded:String
    let subtext:String
    let description: String
}

class BookletController: UIViewController, UIPageViewControllerDataSource {
    
    private var pageViewController: UIPageViewController?
    
    private var pages:[Article]?
    // testedit
    private var pageCount = 0
    
    var blockchainUser: BlockchainUser?
    
    // Put this in viewDidLoad
    override func viewDidAppear(_ animated: Bool) {
        if let existingUserId = loadUser() {
            
            // Debugging alert
//            print("Found an existing User")
//            let alert = UIAlertController(title: "DEBUG: (already enrolled)", message: existingUserId.userId, preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
            
            blockchainUser = existingUserId
        }
        else {
            
            // Debugging alert
//            print("NO EXISTING USER")
//            let alert = UIAlertController(title: "DEBUG", message: "NO EXISTING USER", preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
            
            guard let url = URL(string: "http://148.100.108.176:3001/api/execute") else { return }
            let parameters: [String:Any]
            let request = NSMutableURLRequest(url: url)
            
            let session = URLSession.shared
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            parameters = ["type":"enroll", "params":[]]
            request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
            
            let enrollUser = session.dataTask(with: request as URLRequest) { (data, response, error) in
                
                if let data = data {
                    do {
                        // Convert the data to JSON
                        let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                        
                        if let json = jsonSerialized, let status = json["status"], let resultId = json["resultId"] {
                            NSLog(status as! String)
                            NSLog(resultId as! String) // Use this one to get blockchain payload - should contain userId
                            
                            // Start pinging backend with resultId
                            self.requestResults(resultId: resultId as! String, attemptNumber: 0)
                        }
                    }  catch let error as NSError {
                        print(error.localizedDescription)
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
            enrollUser.resume()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let urlString = "http://kube.ibm-fitchain.com/pages"
        guard let url = URL(string: urlString) else {
            print("url error")
            return
            
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
            guard let data = data else { return }
            
            do {
                //Decode retrived data with JSONDecoder and assing type of Article object
                let pages = try JSONDecoder().decode([Article].self, from: data)
                
                //Get back to the main queue
                DispatchQueue.main.async {
                    self.pages = pages
                    self.pageCount = pages.count
                    self.createPageViewController()
                    self.setupPageControl()
                }
            } catch let jsonError {
                print(jsonError)
            }
        }.resume()
        
//        if let path = Bundle.main.url(forResource: "booklet", withExtension: "json") {
//            do {
//                _ = try Data(contentsOf: path, options: .mappedIfSafe)
//                let jsonData = try Data(contentsOf: path, options: .mappedIfSafe)
//                if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String: AnyObject] {
//
//                    if let pages = jsonDict["pages"] as? [[String: AnyObject]] {
//                        self.pages = pages
//                        self.pageCount = pages.count
//                        createPageViewController()
//                        setupPageControl()
//                    }
//                }
//            } catch {
//                print("couldn't parse JSON data")
//            }
//        }
    }
    
    private func createPageViewController() {
        
        let pageController = self.storyboard!.instantiateViewController(withIdentifier: "booklet") as! UIPageViewController
        pageController.dataSource = self
        
        if self.pageCount > 0 {
            let firstController = getItemController(itemIndex: 0)!
            let startingViewControllers = [firstController]
            pageController.setViewControllers(startingViewControllers, direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        }
        
        pageViewController = pageController
        addChildViewController(pageViewController!)
        self.view.addSubview(pageViewController!.view)
        pageViewController!.didMove(toParentViewController: self)
    }
    
    private func setupPageControl() {
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor(red:0.92, green:0.59, blue:0.53, alpha:1.0)
        appearance.currentPageIndicatorTintColor = UIColor(red:0.47, green:0.22, blue:0.22, alpha:1.0)
        appearance.backgroundColor = UIColor.white
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let itemController = viewController as! BookletItemController
        
        if itemController.itemIndex > 0 {
            return getItemController(itemIndex: itemController.itemIndex-1)
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let itemController = viewController as! BookletItemController
        
        if itemController.itemIndex+1 < self.pageCount {
            return getItemController(itemIndex: itemController.itemIndex+1)
        }
        
        return nil
    }
    
    private func getItemController(itemIndex: Int) -> BookletItemController? {
        
        if itemIndex < self.pages!.count {
            let pageItemController = self.storyboard!.instantiateViewController(withIdentifier: "ItemController") as! BookletItemController
            pageItemController.itemIndex = itemIndex
            pageItemController.titleString = self.pages![itemIndex].title
            pageItemController.subTitleString = self.pages![itemIndex].subtitle
            pageItemController.image = self.base64ToImage(base64: self.pages![itemIndex].imageEncoded)
            pageItemController.subtextString = self.pages![itemIndex].subtext
            pageItemController.statementString = self.pages![itemIndex].description
            
            return pageItemController
        }
        
        return nil
    }
    
    func base64ToImage(base64: String) -> UIImage {
        var img: UIImage = UIImage()
        if (!base64.isEmpty) {
            let decodedData = NSData(base64Encoded: base64 , options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)
            let decodedimage = UIImage(data: decodedData! as Data)
            img = (decodedimage as UIImage?)!
        }
        return img
    }
    
    // MARK: - Page Indicator
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.pages!.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: - Additions
    
    func currentControllerIndex() -> Int {
        
        let pageItemController = self.currentController()
        
        if let controller = pageItemController as? BookletItemController {
            return controller.itemIndex
        }
        
        return -1
    }
    
    // request results of enrollment to blockchain
    
    private func requestResults(resultId: String, attemptNumber: Int) {
        if attemptNumber < 60 {
            guard let url = URL(string: "http://148.100.108.176:3001/api/results/" + resultId) else { return }
            
            let session = URLSession.shared
            let enrollUser = session.dataTask(with: url) { (data, response, error) in
                if let data = data {
                    do {
                        // data is
                        // {"status":"done","result":"{\"message\":\"success\",\"result\":\"{\\\"user\\\":\\\"4226e3af-5ae3-49bc-870c-886af9ec53a3\\\"}\"}"}
                        // Convert the data to JSON
                        
                        let jsonSerialized = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
                        
                        if let json = jsonSerialized, let status = json["status"] {
                            NSLog(status as! String)
                            if status as! String == "done" {
                                let resultData = jsonSerialized!["result"]
                                NSLog(resultData as! String) // {"message":"success","result":"{\"user\":\"4226e3af-5ae3-49bc-870c-886af9ec53a3\"}"}
                                
                                let resultSerialized = try JSONSerialization.jsonObject(with: (resultData as! String).data(using: .utf8)!, options: []) as? [String : Any]
                                
                                let userData = resultSerialized!["result"]
                                NSLog(userData as! String) // {"user":"4226e3af-5ae3-49bc-870c-886af9ec53a3"}
                                
                                let userId = try JSONSerialization.jsonObject(with: (userData as! String).data(using: .utf8)!, options: []) as? [String : Any]
                                
                                self.blockchainUser = BlockchainUser(userId: userId!["user"] as! String)
                                NSLog(userId!["user"] as! String) // 4226e3af-5ae3-49bc-870c-886af9ec53a3
                                self.saveUser()
                                
                                // Debugging alert
                                let alert = UIAlertController(title: "You have been enrolled to the blockchain network", message: userId!["user"] as? String, preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                            else {
                                let when = DispatchTime.now() + 3 // 3 seconds from now
                                DispatchQueue.main.asyncAfter(deadline: when) {
                                    self.requestResults(resultId: resultId, attemptNumber: attemptNumber+1)
                                }
                            }
                        }
                    }  catch let error as NSError {
                        print(error.localizedDescription)
                    }
                } else if let error = error {
                    print(error.localizedDescription)
                }
            }
            enrollUser.resume()
        }
        else {
            NSLog("Attempted 60 times to enroll... No results")
        }
    }
    
    
    // Save User generated from Blockchain Network
    
    private func saveUser() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(blockchainUser!, toFile: BlockchainUser.ArchiveURL.path)
        if isSuccessfulSave {
            print("User has been enrolled and persisted.")
        } else {
            print("Failed to save user...")
        }
    }
    
    // Load User
    
    func loadUser() -> BlockchainUser?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: BlockchainUser.ArchiveURL.path) as? BlockchainUser
    }
    
    func currentController() -> UIViewController? {
        
        let count:Int = (self.pageViewController?.viewControllers?.count)!;
        
        if count > 0 {
            return self.pageViewController?.viewControllers![0]
        }
        
        return nil
    }
}
