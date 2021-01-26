import XCTest
@testable import Emul8080r

final class Emul8080rTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Emul8080r().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
