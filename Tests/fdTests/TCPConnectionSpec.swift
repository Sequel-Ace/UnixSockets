import Spectre
import fd


public func testTCPConnection() {
  describe("TCPConnection") {
    $0.it("may be initialised with a file number") {
      let connection = TCPConnection(fileNumber: -1)
      try expect(connection.fileNumber) == -1
    }
  }
}
