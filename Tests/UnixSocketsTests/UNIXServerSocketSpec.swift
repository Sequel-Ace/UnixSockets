import Foundation
import Spectre
import UnixSockets
import Dispatch

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

        $0.it("can communicate over a socket") {
            let sockURL = newSockURL()
            defer { try? fm.removeItem(at: sockURL) }
            let server = try UNIXSocket(path: sockURL)
            try expect(server.fileNumber) != -1

            try expect(fm.fileExists(atPath: sockURL.relativePath)) == false
            try server.bind()
            try expect(fm.fileExists(atPath: sockURL.relativePath)) == true
            try server.listen()

            var clientRcvd = false
            var serverRcvd = false
            DispatchQueue.global().async {
                do {
                    let client = try UNIXSocket(path: sockURL)
                    // print("Client connecting")
                    let conn = try client.connect()
                    // print("Client connected")
                    _ = try conn.write("fromClient".data(using: .utf8)!)
                    // print("Client wrote")
                    if let rcvd: Data = try? conn.read(64), let text = String(data: rcvd, encoding: .utf8) {
                        // print("Client rcvd: \(text)")
                        clientRcvd = text == "fromServer"
                    }
                    // print("Client closing")
                    try conn.close()
                    try client.close()
                    // print("Client closed")
                } catch {}
            }

            // print("Server accepting")
            let listener = try server.accept()
            // print("Server accepted")
            _ = try listener.write("fromServer".data(using: .utf8)!)
            // print("Server wrote")
            if let rcvd: Data = try? listener.read(64), let text = String(data: rcvd, encoding: .utf8) {
                // print("Server received \(text)")
                serverRcvd = text == "fromClient"
            }
            // print("Server closing")
            try listener.close()
            try server.close()
            // print("Server closed")

            try expect(clientRcvd) == true
            try expect(serverRcvd) == true
        }
    }
}
