//
//  Models.swift
//  ssriapp
//
//  Created by Finlay Carson Moretti on 28/09/2026.
//

import SwiftData
import Foundation
import SwiftDate
import Playgrounds

//weekdays structure is a bitwise OptionSet
//7 slots that can be turned on and off
struct Weekdays: OptionSet, Codable {
    let rawValue: Int
    
    static let sunday    = Weekdays(rawValue: 1)
    static let monday    = Weekdays(rawValue: 2)
    static let tuesday   = Weekdays(rawValue: 4)
    static let wednesday = Weekdays(rawValue: 8)
    static let thursday  = Weekdays(rawValue: 16)
    static let friday    = Weekdays(rawValue: 32)
    static let saturday  = Weekdays(rawValue: 64)
    
}

//medication model
//meds have a name and days of the week they should be taken on
//this app is only really targeted at me right now and i only take one type of med
//but should be good for making it useful to other people
@Model
class Medication{
    var name: String
    var daysOfWeek: Weekdays
    var presetDose: Int = 0

    // Store a local clock time, independent of a particular date or time zone.
    // The default also supplies a value for medications saved before this field existed.
    private(set) var reminderMinutes: Int = 540

    var reminderTime: Date {
        get { reminderDate(on: .now) }
        set {
            let calendar = Calendar.current
            reminderMinutes = calendar.component(.hour, from: newValue) * 60
                + calendar.component(.minute, from: newValue)
        }
    }

    func reminderDate(on date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(
            bySettingHour: reminderMinutes / 60,
            minute: reminderMinutes % 60,
            second: 0,
            of: date
        ) ?? calendar.startOfDay(for: date)
    }

    // Keep log history and clear its medication reference when this medication is deleted.
    @Relationship(deleteRule: .nullify, inverse: \TakeLog.medication)
    var logs: [TakeLog] = []
    
    init(name: String, daysOfWeek: Weekdays, presetDose: Int = 0, reminderTime: Date? = nil) {
        self.name = name
        self.daysOfWeek = daysOfWeek
        self.presetDose = presetDose
        if let reminderTime {
            self.reminderTime = reminderTime
        }
    }
    
    @MainActor func isDueToday() -> Bool{
        var returnBool = false
        let todaysDate = Date.now

        let weekdayBits = Weekdays(rawValue: 1 << (todaysDate.weekday - 1))
        
        //you can convert to weekday rawvalue to check its okay...
        
        if self.daysOfWeek.contains(weekdayBits){
            returnBool = true
        } else {
            returnBool = false
        }
        
        return returnBool
    }
}

//log model for each diary entry
//each log has a medication, a dosage, and a time and date.
@Model
class TakeLog{
    var medication: Medication?
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

//SWIFTDATA FUNCTIONS 😄



//#Playground {
//    var evilPills = Medication(name: "Evil Pills", daysOfWeek: [.monday,.tuesday])
//    
//    //you can convert to weekday rawvalue to check its okay...
//    
//    if evilPills.isDueToday(){
//        print("pills should be taken today")
//    } else {
//        print("no pills today")
//    }
//}

