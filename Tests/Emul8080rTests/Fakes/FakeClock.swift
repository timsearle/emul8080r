import Foundation
@testable import Emul8080r

struct FakeClock: SystemClock {
    func currentMicroseconds() -> Double {
        0
    }
}
