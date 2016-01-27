import Foundation

extension NSObject {
    func na_perform(closure: () -> Void, afterDelay delay: Double) {
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            closure()
        }
    }
}
