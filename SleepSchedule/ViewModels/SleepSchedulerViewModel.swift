//
//  SleepSchedulerViewModel.swift
//  UykuZamanlayıcı
//
//  Created by seda yılmaz on 21.01.2025.
//


import Foundation
import UserNotifications

class SleepSchedulerViewModel {
    private var sleepSchedule: SleepSchedule?

    func updateSchedule(start: Date, end: Date) {
        sleepSchedule = SleepSchedule(startTime: start, endTime: end)
        scheduleNotifications()
    }
//Toplam uyunulacak saat hesabı için
    func calculateSleepDuration(start: Date, end: Date) -> (hours: Int, minutes: Int) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: start, to: end)
        
        // Eğer fark negatifse, bitiş saatine bir gün ekle
        if components.hour! < 0 || components.minute! < 0 {
            let adjustedEnd = calendar.date(byAdding: .day, value: 1, to: end)!
            components = calendar.dateComponents([.hour, .minute], from: start, to: adjustedEnd)
        }
        
        return (components.hour ?? 0, components.minute ?? 0)
    }


//Bildirimlerin ayarlanması (Bildirimler 15 dk öncesi için)
    private func scheduleNotifications() {
        guard let schedule = sleepSchedule else { return }

        // Bildirim içerikleri
        let goodNightContent = UNMutableNotificationContent()
        goodNightContent.title = "İyi Geceler"
        goodNightContent.body = "Uyuma vaktin geldi. İyi uykular!"
        goodNightContent.sound = .default

        let goodMorningContent = UNMutableNotificationContent()
        goodMorningContent.title = "Günaydın"
        goodMorningContent.body = "Uyanma vakti! Harika bir gün dileriz!"
        goodMorningContent.sound = .default

        // Zamanlamalar
        let goodNightTrigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: schedule.startTime.addingTimeInterval(-900)),
            repeats: false
        )

        let goodMorningTrigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: schedule.endTime.addingTimeInterval(900)),
            repeats: false
        )

        // Bildirimleri planlama
        let goodNightRequest = UNNotificationRequest(identifier: "goodNightNotification", content: goodNightContent, trigger: goodNightTrigger)
        let goodMorningRequest = UNNotificationRequest(identifier: "goodMorningNotification", content: goodMorningContent, trigger: goodMorningTrigger)

        let center = UNUserNotificationCenter.current()
        center.add(goodNightRequest)
        center.add(goodMorningRequest)
    }
}
