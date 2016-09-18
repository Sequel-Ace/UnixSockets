import Spectre
import fd


public func testTCPListener() {
  describe("TCPListener") {
    $0.it("may be initialised with an address and port") {
      let listener = try TCPListener(address: "127.0.0.1", port: 0)
      try expect(listener.fileNumber) != -1
    }
  }
}
