import Spectre
import fd


func testUNIXListener() {
  describe("UNIXListener") {
    $0.xit("may be initialised with a path") {
      let _ = try UNIXListener(path: "/tmp/fd-unixlistener-test")
    }
  }
}
