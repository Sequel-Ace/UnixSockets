import XCTest


class FDTests: XCTestCase {
  func testRunFDTests() {
    testFileDescriptor()
    testPipe()

    testUNIXConnection()
    testUNIXServerSocket()
  }
}
