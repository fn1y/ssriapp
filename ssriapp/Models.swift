//
//  Models.swift
//  ssriapp
//
//  Created by Finlay Carson Moretti on 28/09/2026.
//

import SwiftData
import Foundation
import SwiftDate

//weekdays structure is a bitwise OptionSet
//7 slots that can be turned on and off
struct Weekdays: OptionSet {
    let rawValue: Int
    
    static let sunday    = Weekdays(rawValue: 1)
    static let monday    = Weekdays(rawValue: 2)
    static let tuesday   = Weekdays(rawValue: 4)
    static let wednesday = Weekdays(rawValue: 8)
    static let thursday  = Weekdays(rawValue: 16)
    static let friday    = Weekdays(rawValue: 32)
    static let saturday  = Weekdays(rawValue: 64)
    
    static let weekdays: Weekdays = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekend:  Weekdays = [.saturday, .sunday]
    static let everyDay: Weekdays = [.weekdays, .weekend]
    
}

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
