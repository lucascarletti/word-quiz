import Foundation
import UIKit

class QuizTimer {
    
    var displayLink: CADisplayLink?
    private var quizStartDate = Date()
    private var fiveMinutes = Date(timeInterval: 5 * 60, since: Date())
    
    var onUpdateMinutesAndSeconds: ((Int, Int) -> Void)?
    var onTimerFinished: (() -> Void)?
    
    func initTimer() {
        displayLink = CADisplayLink(target: self, selector: #selector(timer))
        displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
        quizStartDate = Date()
        fiveMinutes = Date(timeInterval: 5 * 60, since: Date())
    }
    
    @objc func timer() {
        let difference = quizStartDate.timeIntervalSinceNow
        let newDate = fiveMinutes.addingTimeInterval(difference)
        let timeInterval = newDate.timeIntervalSinceNow
        let minutes = Int(timeInterval / 60)
        let seconds = Int(60 + difference)
        debugPrint("Diff: \(difference)")
        debugPrint("Time: \(timeInterval)")
        debugPrint("Min: \(minutes)")
        debugPrint("Sec: \(seconds)")
        
        onUpdateMinutesAndSeconds?(minutes,seconds)
        if Date() > fiveMinutes {
            onTimerFinished?()
            displayLink?.invalidate()
        }
        
        debugPrint("---- Date: \(Date())")
    }
}
