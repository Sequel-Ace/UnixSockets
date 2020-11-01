import Foundation

#if os(Linux)
import Glibc
private let sock_stream = Int32(SOCK_STREAM.rawValue)
private let system_bind = Glibc.bind
private let system_listen = Glibc.listen
private let system_accept = Glibc.accept
private let system_connect = Glibc.connect
#else
import Darwin
private let sock_stream = SOCK_STREAM
private let system_bind = Darwin.bind
private let system_listen = Darwin.listen
private let system_accept = Darwin.accept
private let system_connect = Darwin.connect
#endif

typealias SocketAddr = sockaddr_un

/// create a unix sockaddr and set the addr's path to the specified path
/// - parameter path: the path for the socket
/// - throws: UNIXSocketError(.pathLength) if the provided path is too long
fileprivate func socketAddr(for path: String) throws -> SocketAddr {
    var sa = SocketAddr()
    sa.sun_family = sa_family_t(AF_UNIX)

    let lengthOfPath = path.withCString { Int(strlen($0)) }

    guard lengthOfPath < MemoryLayout.size(ofValue: sa.sun_path) else {
        throw UNIXSocketError(kind: .pathLength, message: "Path too long!")
    }

    _ = withUnsafeMutablePointer(to: &sa.sun_path.0) { pointer in
        path.withCString { strncpy(pointer, $0, lengthOfPath) }
    }

    return sa
}

public class UNIXSocket: FileDescriptor {
    public var fileNumber: FileNumber
    private var addr: SocketAddr
    
    /// `path` should either not exist, or should be a socket
    /// - parameter path: the path for this socket
    /// - throws:
    ///  UNIXSocketError(.notSocket) if `path` exists and _is not_ a socket
    ///  UNIXSocketError(.creationError) if the call to `socket` fails
    public init(path: URL) throws {
        let type = try? path.resourceValues(forKeys: [.fileResourceTypeKey]).fileResourceType
        let exists = FileManager.default.fileExists(atPath: path.relativePath)
        guard !exists || type == .socket else {
            print("exists: \(exists) type: \(String(describing: type))")
            throw UNIXSocketError(kind: .notSocket)
        }
        
        fileNumber = socket(AF_UNIX, sock_stream, 0)
        addr = try socketAddr(for: path.relativePath)

        guard fileNumber != -1 else {
            throw UNIXSocketError(kind: .creationError, errno: errno)
        }
    }
    
    deinit {
      let _ = try? close()
    }

    // Server side functions

    /// `bind`s the socket (used when this socket owns the fd)
    /// - throws: UNIXSocketError(.bindError) if the `bind` call fails
    public func bind() throws {
        try withUnsafePointer(to: &addr) {
            try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                guard system_bind(fileNumber, $0, UInt32(MemoryLayout<sockaddr_un>.stride)) != -1 else {
                    throw UNIXSocketError(kind: .bindError, errno: errno)
                }
            }
        }
    }

    /// Awaits connections from client sockets
    public func listen(backlog: Int32 = 1024) throws {
        guard system_listen(fileNumber, backlog) != -1 else {
            throw UNIXSocketError(kind: .listenError, errno: errno)
        }
    }

    /// Accepts a connection socket, blocking until a client connects
    public func accept() throws -> UNIXConnection {
        let fileNumber = system_accept(self.fileNumber, nil, nil)
        guard fileNumber != -1 else {
            throw UNIXSocketError(kind: .acceptError, errno: errno)
        }

        return UNIXConnection(fileNumber: fileNumber)
    }

    /// Connect to a socket that exists
    public func connect() throws -> UNIXConnection {
        try withUnsafePointer(to: &addr) { pointer in
            try pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                guard system_connect(fileNumber, $0, UInt32(MemoryLayout<sockaddr_un>.stride)) != -1 else {
                    throw UNIXSocketError(kind: .connectError, errno: errno)
                }
                return UNIXConnection(fileNumber: fileNumber)
            }
        }
    }
}
