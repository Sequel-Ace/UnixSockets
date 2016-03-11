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


public class TCPListener : FileDescriptor {
  public let fileNumber: FileNumber

  init(fileNumber: FileNumber) {
    self.fileNumber = fileNumber
  }

  public init(address: String, port: UInt16) throws {
    fileNumber = socket(AF_INET, sock_stream, 0)
    if fileNumber == -1 {
      throw FileDescriptorError()
    }

    do {
      try bind(address, port: port)
    } catch {
      try close()
      throw error
    }
  }

  deinit {
    let _ = try? close()
  }

  private func bind(address: String, port: UInt16) throws {
    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = in_port_t(htons(in_port_t(port)))
    addr.sin_addr = in_addr(s_addr: address.withCString { inet_addr($0) })
    addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)

   let len = socklen_t(UInt8(sizeof(sockaddr_in)))
    guard system_bind(fileNumber, sockaddr_cast(&addr), len) != -1 else {
      throw FileDescriptorError()
    }
  }

  private func listen(backlog backlog: Int32) throws {
    if system_listen(fileNumber, backlog) == -1 {
      throw FileDescriptorError()
    }
  }

  private func htons(value: CUnsignedShort) -> CUnsignedShort {
    return (value << 8) + (value >> 8)
  }

  private func sockaddr_cast(p: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
  }

  /// Accepts a connection socket
  public func accept() throws -> TCPConnection {
    let fileNumber = system_accept(self.fileNumber, nil, nil)
    if fileNumber == -1 {
      throw FileDescriptorError()
    }

    return TCPConnection(fileNumber: fileNumber)
  }
}
