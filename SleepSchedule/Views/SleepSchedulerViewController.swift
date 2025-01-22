//
//  SleepSchedulerViewController.swift
//  SleepSchedule
//
//  Created by seda yılmaz on 21.01.2025.
//

import UIKit
import UserNotifications

class SleepSchedulerViewController: UIViewController {
    @IBOutlet weak var changeWakeUpLabel: UILabel!
    @IBOutlet weak var bedTimeWithHourLabel: UILabel!
    @IBOutlet weak var wakeUpWithHourLabel: UILabel!
    @IBOutlet weak var totalSleepTimeLabel: UILabel!
    @IBOutlet weak var goalInfoLabel: UILabel!
    @IBOutlet weak var circularSliderView: CircularSliderView!
    @IBOutlet weak var bedTimeLabel: UILabel!
    @IBOutlet weak var wakeUpLabel: UILabel!
    @IBOutlet weak var alarmOptionsLabel: UILabel!
    @IBOutlet weak var day1Label: UILabel!
    @IBOutlet weak var day2Label: UILabel!
    @IBOutlet weak var alarmOptionsView: UIView!
    
    @IBAction func editSleepScheduleinHealthButton(_ sender: UIButton) {
        sender.layer.cornerRadius = 20
        sender.clipsToBounds = true
    }
    private var viewModel = SleepSchedulerViewModel()
    
    private let defaultStartTime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
    private let defaultEndTime = Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date())!
    
    private var currentStartTime: Date!
    private var currentEndTime: Date!

    override func viewDidLoad() {
        super.viewDidLoad()
        checkNotificationPermission()
        circularSliderView.delegate = self
        resetToDefaultValues()
        updateUI(startTime: defaultStartTime, endTime: defaultEndTime)
        alarmOptionsView.layer.cornerRadius = 10
    }
//Bildirim izinleri kontrolü
    private func checkNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    self.requestNotificationAuthorization()
                } else if settings.authorizationStatus == .denied {
                    self.showNotificationPermissionAlert()
                } else {
                    print("Notification permission already granted.")
                }
            }
        }
    }

    private func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification authorization error: \(error)")
                }
                if granted {
                    print("Notification permission granted.")
                } else {
                    self.showNotificationPermissionAlert()
                }
            }
        }
    }

    private func showNotificationPermissionAlert() {
        let alert = UIAlertController(
            title: "Enable Notifications",
            message: "To receive Good Night and Good Morning alerts, please allow notifications in the settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func cancelButton(_ sender: Any) {
        resetToDefaultValues()
    }

    @IBAction func doneButton(_ sender: Any) {

        // Yeni bildirimleri ayarlamak
        viewModel.updateSchedule(start: currentStartTime, end: currentEndTime)
        scheduleGoodNightNotification(for: currentStartTime) // Good Night bildirimi
        scheduleGoodMorningNotification(for: currentEndTime) // Good Morning bildirimi
        scheduleAlarmNotification(for: currentEndTime) // Alarm bildirimi

        // Bildirimlerin başarıyla ayarlandığının kullanıcıya gösterilmesi
        showAlarmScheduledAlert()
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            print("Pending notifications:")
            for request in requests {
                print("Identifier: \(request.identifier), Content: \(request.content.title)")
            }
        }

    }

    private func showAlarmScheduledAlert() {
        let alert = UIAlertController(
            title: "Alarm Scheduled",
            message: "Your Good Night and Good Morning notifications have been successfully scheduled!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

//İyi geceler bildirimi ayarı
    private func scheduleGoodNightNotification(for bedTime: Date) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Good Night"
        content.body = "It's almost bedtime! Prepare to sleep well."
        content.sound = .default

        guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: bedTime) else { return }
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: triggerDate),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: "goodNightNotification", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule Good Night notification: \(error)")
            }
        }
    }
// Günaydın bildirimi ayarı
    private func scheduleGoodMorningNotification(for wakeUpTime: Date) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Good Morning"
        content.body = "It's almost time to wake up! Have a wonderful day."
        content.sound = .default

        guard let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: wakeUpTime) else { return }
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: triggerDate),
            repeats: false
        )

        let request = UNNotificationRequest(identifier: "goodMorningNotification", content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule Good Morning notification: \(error)")
            }
        }
    }
//Alarm bildirimi
    private func scheduleAlarmNotification(for endTime: Date) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = "It's time to wake up!"
        content.sound = UNNotificationSound.default

        let triggerDate = Calendar.current.dateComponents([.hour, .minute, .second], from: endTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: "alarmNotification", content: content, trigger: trigger)
        center.add(request)
    }
//Cancel butonuna tıklandığında varsayılan değerlere dönmek için
    private func resetToDefaultValues() {
        currentStartTime = defaultStartTime
        currentEndTime = defaultEndTime
        updateUI(startTime: currentStartTime, endTime: currentEndTime)

        // Slider'ı varsayılan değerlere sıfırla
        let startValue = timeToSliderValue(defaultStartTime)
        let endValue = timeToSliderValue(defaultEndTime)
        circularSliderView.resetToDefault(startValue: startValue, endValue: endValue)
    }


    private func updateUI(startTime: Date, endTime: Date) {
        currentStartTime = startTime
        currentEndTime = endTime
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        bedTimeWithHourLabel.text = formatter.string(from: startTime)
        wakeUpWithHourLabel.text = formatter.string(from: endTime)
        
        let sleepDuration = viewModel.calculateSleepDuration(start: startTime, end: endTime)
        totalSleepTimeLabel.text = "\(sleepDuration.hours) hr \(sleepDuration.minutes) min"
        goalInfoLabel.text = sleepDuration.hours >= 8 ? "The target sleep duration has been achieved." : "This sleep duration does not meet your goal."

        let sliderColor: UIColor = sleepDuration.hours >= 8 ? .lightGray : .orange
        circularSliderView.updateSliderColor(to: sliderColor)
        
        updateDayLabels(currentTime: Date(), bedTime: startTime, wakeUpTime: endTime)
    }
//Ayarlanan saatin güncel saat ile karşılaştırılıp Today ya da Tomorrow olduğunun, 6PM-12AM arası Tonight  gösterilmesi
    private func updateDayLabels(currentTime: Date, bedTime: Date, wakeUpTime: Date) {
        let calendar = Calendar.current

        // Saat 18:00 (6 PM) ve gece yarısı (12 AM) sınırlarını belirle
        let sixPM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: currentTime)!
        let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: currentTime.addingTimeInterval(86400))! // Ertesi gün 12 AM

        // Bedtime kontrolü
        if bedTime >= sixPM && bedTime < midnight {
            day1Label.text = "Tonight"
        } else if bedTime >= currentTime {
            day1Label.text = "Today"
        } else {
            day1Label.text = "Tomorrow"
        }

        // WakeupTime kontrolü
        if wakeUpTime >= sixPM && wakeUpTime < midnight {
            day2Label.text = "Tonight"
        } else if wakeUpTime < currentTime {
            day2Label.text = "Tomorrow"
        } else if wakeUpTime < bedTime {
            day2Label.text = "Tomorrow"
        } else {
            day2Label.text = "Today"
        }
    }


    private func timeToSliderValue(_ time: Date) -> CGFloat {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let totalMinutes = (components.hour! * 60) + components.minute!
        return CGFloat(totalMinutes) / 1440.0
    }
}

extension SleepSchedulerViewController: CircularSliderDelegate {
    func didChangeValues(startValue: CGFloat, endValue: CGFloat, isStartThumbMoving: Bool) {
        let startTime = calculateTime(from: startValue)
        let endTime = calculateTime(from: endValue)
        currentStartTime = startTime
        currentEndTime = endTime
        updateUI(startTime: startTime, endTime: endTime)

        // Etkileşim sırasında label parlaklığını ayarla
        if isStartThumbMoving {
            setLabelHighlight(for: bedTimeLabel, highlight: true)
            setLabelHighlight(for: wakeUpLabel, highlight: false)
        } else {
            setLabelHighlight(for: bedTimeLabel, highlight: false)
            setLabelHighlight(for: wakeUpLabel, highlight: true)
        }
    }

    private func setLabelHighlight(for label: UILabel, highlight: Bool) {
        label.textColor = highlight ? UIColor.systemOrange : UIColor.lightGray
    }

    private func calculateTime(from value: CGFloat) -> Date {
        let totalMinutes = Int(value * 1440)
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60

        return Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date())!
    }
}

