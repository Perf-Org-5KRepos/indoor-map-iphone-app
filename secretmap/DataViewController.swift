//
//  SecondViewController.swift
//  secretmap
//
//  Created by Anton McConville on 2017-12-14.
//  Copyright © 2017 Anton McConville. All rights reserved.
//

import UIKit
import HealthKit
import CoreMotion

class DataViewController: UIViewController {
    
    let appDelegate = UIApplication.shared.delegate
    
    var pedometer = CMPedometer()
    
    public var startDate: Date = Date()
    
    @IBOutlet weak var stepsCountLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var userIdLabel: UILabel!
    
    var currentUser: BlockchainUser?

    override func viewDidAppear(_ animated: Bool) {
        currentUser = BookletController().loadUser()
        if currentUser != nil {
            
            // Debugging alert
//            let alert = UIAlertController(title: "DEBUG: (already enrolled)", message: currentUser?.userId, preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//
            userIdLabel?.text = currentUser?.userId
        }
        else {
            
            // Debugging alert
//            let alert = UIAlertController(title: "DEBUG: (not yet enrolled)", message: "refresh the page later", preferredStyle: UIAlertControllerStyle.alert)
//            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
            userIdLabel?.text = "Enrolling in progress. Refresh the page at a later time"
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getStepData()
        self.liveUpdateStepData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    let healthStore = HKHealthStore()
    
    func getStepData(){
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        var currentPerson:Person
        
        var people: [Person] = []
        
        do {
            people = try context.fetch(Person.fetchRequest())
            
            if( people.count > 0 ){
                currentPerson = people[0]
                
                self.startDate = currentPerson.startdate!
                
                pedometer.queryPedometerData(from: self.startDate, to: Date()) {
                    [weak self] pedometerData, error in
                    if let error = error {
                        //                        self?.on(error: error)
                    } else if let pedometerData = pedometerData {
                        DispatchQueue.main.async {
                            self?.stepsCountLabel.text = String(describing: pedometerData.numberOfSteps)
                            let distanceInKilometers: Double = (pedometerData.distance?.doubleValue)! / 1000.00
                            self?.distanceLabel.text = String(describing: distanceInKilometers)
                        }
                    }
                }
            }
        }catch{}
    }
    
    func liveUpdateStepData(){
        pedometer.startUpdates(from: self.startDate, withHandler: { (pedometerData, error) in
            if let pedometerData = pedometerData{
                DispatchQueue.main.async {
                    self.stepsCountLabel.text = String(describing: pedometerData.numberOfSteps)
                    let distanceInKilometers: Double = (pedometerData.distance?.doubleValue)! / 1000.00
                    self.distanceLabel.text = String(describing: distanceInKilometers)
                }
                
                /* Need to send steps to fitchain here */
                
            } else {
                print("steps are not available")
            }
        })
    }
}

