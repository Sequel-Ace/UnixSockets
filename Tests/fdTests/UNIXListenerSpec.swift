import Spectre
import fd


public func testUNIXListener() {
  describe("UNIXListener") {
    $0.it("may be initialised with a path") {
      let listener = try UNIXListener(path: "/tmp/fd-unixlistener-test")
      try expect(listener.fileNumber) != -1
    }
  }
}
