#if os(Linux)
import Glibc
private let system_accept = Glibc.accept
private let system_listen = Glibc.listen
private let system_bind = Glibc.bind
private let sock_stream = Int32(SOCK_STREAM.rawValue)
#else
import Darwin
private let system_accept = Darwin.accept
private let system_listen = Darwin.listen
private let system_bind = Darwin.bind
private let sock_stream = SOCK_STREAM
#endif

public class TCPListener : UNIXSocket, Listener {
    
    public init(address: String, port: UInt16) throws {
        try super.init(kind: AF_INET)
        
        do {
            try bind(address, port: port)
        } catch {
            try close()
            throw error
        }
    }
    
    private func bind(_ address: String, port: UInt16) throws {
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(htons(in_port_t(port)))
        addr.sin_addr = in_addr(s_addr: address.withCString { inet_addr($0) })
        addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
        
        let len = socklen_t(UInt8(MemoryLayout<sockaddr_in>.size))
        
        try withUnsafePointer(to: &addr) {
            try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                guard system_bind(fileNumber, $0, len) != -1 else {
                    throw UNIXSocketError(kind: .bindError, errno: errno)
                }
            }
        }
    }
    
    private func listen(backlog: Int32) throws {
        guard system_listen(fileNumber, backlog) != -1 else {
            throw UNIXSocketError(kind: .listenError, errno: errno)
        }
    }
    
    private func htons(_ value: CUnsignedShort) -> CUnsignedShort {
        return (value << 8) + (value >> 8)
    }
    
    /// Accepts a connection socket
    public func accept<TCPConnection>() throws -> TCPConnection {
        let fileNumber = system_accept(self.fileNumber, nil, nil)
        guard fileNumber != -1 else {
            throw UNIXSocketError(kind: .acceptError, errno: errno)
        }
        
        return TCPConnection(fileNumber: fileNumber)
    }
}
