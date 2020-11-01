import Foundation

struct UNIXSocketError: Error {
    enum ErrorKind: String {
        case notSocket, pathLength, creationError, bindError, listenError, acceptError, connectError, unknownError
    }

    let kind: ErrorKind
    let message: String?

    var localizedDescription: String {
        "UNIXSocketError of kind \(kind.rawValue)\(message != nil ? "\nmessage: \(message!)" : "")"
    }

    init(kind: ErrorKind, message: String? = nil) {
        self.kind = kind
        self.message = message
    }

    init(kind: ErrorKind, errno: Int32) {
        let message = String(utf8String: strerror(errno))
        self.init(kind: kind, message: message)
    }
}

struct FileDescriptorError : Error {
    enum ErrorKind: String {
        case readError, writeError, selectError, pipeError, closeError, unknown
    }

    let kind: ErrorKind
    let message: String?

    var localizedDescription: String {
        "FileDescriptorError of kind \(kind.rawValue)\(message != nil ? "\nmessage: \(message!)" : "")"
    }

    init(kind: ErrorKind, message: String? = nil) {
        self.kind = kind
        self.message = message
    }

    init(kind: ErrorKind, errno: Int32) {
        let message = String(utf8String: strerror(errno))
        self.init(kind: kind, message: message)
    }
}
