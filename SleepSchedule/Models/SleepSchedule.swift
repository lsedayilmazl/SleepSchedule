//
//  SleepSchedule.swift
//  UykuZamanlayıcı
//
//  Created by seda yılmaz on 21.01.2025.
//

import Foundation

struct SleepSchedule {
    var startTime: Date
    var endTime: Date
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}
