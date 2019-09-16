import Foundation
import UIKit

class QuizTimer {
    private var displayLink: CADisplayLink?
    private var quizStartDate = Date()
    
    private var dateLimit: Date
    private let timeLimit: TimeInterval
    
    var onUpdateTimer: ((Int, Int) -> Void)?
    var onTimerFinished: (() -> Void)?
    
    init(timeLimit: TimeInterval) {
        self.timeLimit = timeLimit
        self.dateLimit = Date().addingTimeInterval(timeLimit)
    }
    
    func startTimer() {
        displayLink = CADisplayLink(target: self, selector: #selector(timer))
        displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
        quizStartDate = Date()
        dateLimit = Date().addingTimeInterval(timeLimit)
    }
    
    func stopTimer() {
        displayLink?.invalidate()
    }
    
    @objc private func timer() {
        let diffTimeInterval = quizStartDate.timeIntervalSinceNow
        let difference = timeLimit + diffTimeInterval
        let minutes = Int(difference / 60)
        let seconds = Int(difference) % 60
        if seconds == 60 {
            onUpdateTimer?(minutes,0)
        } else {
            onUpdateTimer?(minutes,seconds)
        }
        if Date() > dateLimit {
            onTimerFinished?()
            stopTimer()
        }
    }
}
