//
//  CircularSliderView.swift
//  SleepSchedule
//
//  Created by seda yılmaz on 21.01.2025.
//

import UIKit

protocol CircularSliderDelegate: AnyObject {
    func didChangeValues(startValue: CGFloat, endValue: CGFloat, isStartThumbMoving: Bool)
}

class CircularSliderView: UIView {
    weak var delegate: CircularSliderDelegate?

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let startThumbIcon = UIImageView(image: UIImage(systemName: "bed.double.fill"))
    private let endThumbIcon = UIImageView(image: UIImage(systemName: "alarm.fill"))

    private let trackWidth: CGFloat = 30

    private var radius: CGFloat {
        return (min(bounds.width, bounds.height) - trackWidth - 40) / 2
    }

    private var centerPoint: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private var startAngle: CGFloat = -CGFloat.pi / 2
    private var endAngle: CGFloat = CGFloat.pi / 2

    private var isMovingStartThumb = false
    private var isMovingEndThumb = false
    private var lastTouchAngle: CGFloat = 0

    private let maxDuration: TimeInterval = 20 * 3600 // 20 saat

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupThumbIcons()
        addClockLabels()
        
    }
   

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        setupThumbIcons()
        addClockLabels()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePath()
        updateThumbPositions()
        // Kenarları yuvarlama
        layer.cornerRadius = 50
        layer.masksToBounds = true

        
    }

    private func setupLayers() {
        trackLayer.strokeColor = UIColor.darkGray.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = trackWidth
        layer.addSublayer(trackLayer)

        progressLayer.strokeColor = UIColor.orange.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = trackWidth
        progressLayer.lineCap = .round
        layer.addSublayer(progressLayer)
    }

    private func setupThumbIcons() {
        startThumbIcon.tintColor = .black
        startThumbIcon.contentMode = .scaleAspectFit
        startThumbIcon.frame.size = CGSize(width: 20, height: 20)
        addSubview(startThumbIcon)

        endThumbIcon.tintColor = .black
        endThumbIcon.contentMode = .scaleAspectFit
        endThumbIcon.frame.size = CGSize(width: 20, height: 20)
        addSubview(endThumbIcon)
    }

    private func addClockLabels() {
        let hours = ["12 AM", "2", "4", "6 AM", "8", "10", "12 PM", "2", "4", "6 PM", "8", "10"]
        let hourCount = hours.count
        let angleIncrement = 2 * CGFloat.pi / CGFloat(hourCount)

        for i in 0..<hourCount {
            let angle = -CGFloat.pi / 2 + angleIncrement * CGFloat(i)
            let labelPosition = calculateLabelPosition(angle: angle)
            let label = createClockLabel(with: hours[i], at: labelPosition)
            addSubview(label)
        }
    }

    private func calculateLabelPosition(angle: CGFloat) -> CGPoint {
        let labelRadius = radius + 30
        return CGPoint(
            x: centerPoint.x + labelRadius * cos(angle),
            y: centerPoint.y + labelRadius * sin(angle)
        )
    }

    private func createClockLabel(with text: String, at position: CGPoint) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.sizeToFit()
        label.center = position
        return label
    }

    private func updatePath() {
        let path = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true)
        trackLayer.path = path.cgPath

        let progressPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressLayer.path = progressPath.cgPath
    }

    private func updateThumbPositions() {
        let startThumbPosition = calculateThumbPosition(angle: startAngle)
        startThumbIcon.center = startThumbPosition

        let endThumbPosition = calculateThumbPosition(angle: endAngle)
        endThumbIcon.center = endThumbPosition
    }

    private func calculateThumbPosition(angle: CGFloat) -> CGPoint {
        return CGPoint(
            x: centerPoint.x + radius * cos(angle),
            y: centerPoint.y + radius * sin(angle)
        )
    }

    func updateSliderColor(to color: UIColor) {
        progressLayer.strokeColor = color.cgColor
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let startThumbDistance = distance(from: location, to: calculateThumbPosition(angle: startAngle))
        let endThumbDistance = distance(from: location, to: calculateThumbPosition(angle: endAngle))
        let threshold: CGFloat = 40 // Uçlara yakınlık eşiği

        isMovingStartThumb = startThumbDistance < threshold
        isMovingEndThumb = endThumbDistance < threshold
        lastTouchAngle = angleForPoint(location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        let currentTouchAngle = angleForPoint(location)

        if isMovingStartThumb {
            let newStartAngle = normalizeAngle(currentTouchAngle)
            let potentialStartValue = normalizeValue(from: newStartAngle)

            let startMinutes = potentialStartValue * 1440
            let endMinutes = normalizeValue(from: endAngle) * 1440

            let duration = endMinutes >= startMinutes ? endMinutes - startMinutes : (1440 - startMinutes + endMinutes)

            if duration <= maxDuration / 60 {
                startAngle = newStartAngle
            }
        } else if isMovingEndThumb {
            let newEndAngle = normalizeAngle(currentTouchAngle)
            let potentialEndValue = normalizeValue(from: newEndAngle)

            let startMinutes = normalizeValue(from: startAngle) * 1440
            let endMinutes = potentialEndValue * 1440

            let duration = endMinutes >= startMinutes ? endMinutes - startMinutes : (1440 - startMinutes + endMinutes)

            if duration <= maxDuration / 60 {
                endAngle = newEndAngle
            }
        } else {
            let deltaAngle = currentTouchAngle - lastTouchAngle
            startAngle = normalizeAngle(startAngle + deltaAngle)
            endAngle = normalizeAngle(endAngle + deltaAngle)
            lastTouchAngle = currentTouchAngle
        }

        updatePath()
        updateThumbPositions()

        let startValue = normalizeValue(from: startAngle)
        let endValue = normalizeValue(from: endAngle)

        delegate?.didChangeValues(startValue: startValue, endValue: endValue, isStartThumbMoving: isMovingStartThumb)
    }

    private func angleForPoint(_ point: CGPoint) -> CGFloat {
        let deltaX = point.x - centerPoint.x
        let deltaY = point.y - centerPoint.y
        var angle = atan2(deltaY, deltaX)

        if angle < -CGFloat.pi / 2 {
            angle += 2 * CGFloat.pi
        }
        return angle
    }

    private func distance(from point: CGPoint, to thumbCenter: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - thumbCenter.x, 2) + pow(point.y - thumbCenter.y, 2))
    }

    private func normalizeAngle(_ angle: CGFloat) -> CGFloat {
        var normalizedAngle = angle
        if angle < 0 {
            normalizedAngle += 2 * CGFloat.pi
        } else if angle > 2 * CGFloat.pi {
            normalizedAngle -= 2 * CGFloat.pi
        }
        return normalizedAngle
    }

    private func normalizeValue(from angle: CGFloat) -> CGFloat {
        return (angle + CGFloat.pi / 2) / (2 * CGFloat.pi)
    }

    func setSliderValues(startValue: CGFloat, endValue: CGFloat) {
        startAngle = normalizeAngle((startValue * 2 * CGFloat.pi) - CGFloat.pi / 2)
        endAngle = normalizeAngle((endValue * 2 * CGFloat.pi) - CGFloat.pi / 2)
       
        }
    //Cancel butonuna tıklandıktan sonrası için
    func resetToDefault(startValue: CGFloat, endValue: CGFloat) {
        startAngle = normalizeAngle((startValue * 2 * CGFloat.pi) - CGFloat.pi / 2)
        endAngle = normalizeAngle((endValue * 2 * CGFloat.pi) - CGFloat.pi / 2)
        updatePath()
        updateThumbPositions()
    }

    }
