//
//  Models.swift
//  ssriapp
//
//  Created by Finlay Carson Moretti on 28/09/2026.
//

import SwiftData
import Foundation
import SwiftDate

//medication model
//meds have a name and days of the week they should be taken on
//this app is only really targeted at me right now and i only take one type of med
//but should be good for making it useful to other people
@Model
class Medication{
    var name: String
    var daysOfWeek: [Int]
    
    init(name: String, daysOfWeek: [Int]) {
        self.name = name
        self.daysOfWeek = daysOfWeek
    }
}

//log model for each diary entry
//each log has a medication, a dosage, and a time and date.
@Model
class log{
    var medication: Medication
    var dose: Int
    var date: Date
    
    //dose defaults to 0 and date defaults to current
    //medication is required
    init(medication: Medication, dose: Int = 0, date: Date = Date.now) {
        self.medication = medication
        self.dose = dose
        self.date = date
    }
}
