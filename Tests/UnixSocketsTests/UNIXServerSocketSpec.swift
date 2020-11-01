import Foundation
import Spectre
import UnixSockets

let fm = FileManager.default

func newSockURL() -> URL {
    let tempDir = fm.temporaryDirectory
    let name = UUID().uuidString.split(separator: "-", maxSplits: 2, omittingEmptySubsequences: true)[0]
    return tempDir.appendingPathComponent("\(name).sock")
}

public func testUNIXServerSocket() {
    describe("UNIXSocket") {
        $0.it("does not create a socket on init") {
            let sockURL = newSockURL()
            let server = try UNIXSocket(path: sockURL)
            try expect(server.fileNumber) != -1
            try expect(fm.fileExists(atPath: sockURL.relativePath)) == false
        }

        $0.it("creates a socket on `bind`") {
            let sockURL = newSockURL()
            defer { try? fm.removeItem(at: sockURL) }
            let server = try UNIXSocket(path: sockURL)
            try expect(server.fileNumber) != -1

            try expect(fm.fileExists(atPath: sockURL.relativePath)) == false
            try server.bind()
            try expect(fm.fileExists(atPath: sockURL.relativePath)) == true
        }

        $0.it("does not block on `listen`") {
            let sockURL = newSockURL()
            defer { try? fm.removeItem(at: sockURL) }
            let server = try UNIXSocket(path: sockURL)
            try expect(server.fileNumber) != -1

            try expect(fm.fileExists(atPath: sockURL.relativePath)) == false
            try server.bind()
            try expect(fm.fileExists(atPath: sockURL.relativePath)) == true
            try server.listen()
        }

//        $0.it("can listen for connections") {
//            let sockURL = newSockURL()
//            defer { try? fm.removeItem(at: sockURL) }
//            let server = try UNIXSocket(path: sockURL)
//            try expect(server.fileNumber) != -1
//
//            try expect(fm.fileExists(atPath: sockURL.relativePath)) == false
//            try server.bind()
//            try expect(fm.fileExists(atPath: sockURL.relativePath)) == true
//            try server.listen()
//
//            let listener = try server.accept()
//            try expect(listener.fileNumber) == server.fileNumber
//        }
    }
}
