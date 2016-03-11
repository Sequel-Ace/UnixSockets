#if os(Linux)
import Glibc
private let system_accept = Glibc.accept
private let system_listen = Glibc.listen
private let sock_stream = Int32(SOCK_STREAM.rawValue)
private let system_bind = Glibc.bind
#else
import Darwin
private let system_accept = Darwin.accept
private let system_listen = Darwin.listen
private let sock_stream = SOCK_STREAM
private let system_bind = Darwin.bind
#endif


public class UNIXListener : FileDescriptor {
  public let fileNumber: FileNumber

  public init(path: String) throws {
    fileNumber = socket(AF_UNIX, sock_stream, 0)
    if fileNumber == -1 {
      throw FileDescriptorError()
    }

    do {
      try bind(path)
    } catch {
      try close()
      throw error
    }
  }

  deinit {
    let _ = try? close()
  }

  private func bind(path: String) throws {
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)

    let lengthOfPath = path.withCString { Int(strlen($0)) }

    guard lengthOfPath < sizeofValue(addr.sun_path) else {
      throw FileDescriptorError()
    }

    withUnsafeMutablePointer(&addr.sun_path.0) { ptr in
      path.withCString {
        strncpy(ptr, $0, lengthOfPath)
      }
    }

#if os(Linux)
    let len = socklen_t(UInt8(sizeof(sockaddr_un)))
#else
    addr.sun_len = UInt8(sizeof(sockaddr_un) - sizeofValue(addr.sun_path) + lengthOfPath)
    let len = socklen_t(addr.sun_len)
#endif

    guard system_bind(fileNumber, sockaddr_cast(&addr), len) != -1 else {
      throw FileDescriptorError()
    }
  }

  private func sockaddr_cast(p: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<sockaddr> {
    return UnsafeMutablePointer<sockaddr>(p)
  }

  private func listen(backlog backlog: Int32) throws {
    if system_listen(fileNumber, backlog) == -1 {
      throw FileDescriptorError()
    }
  }

  /// Accepts a connection socket
  public func accept() throws -> UNIXConnection {
    let fileNumber = system_accept(self.fileNumber, nil, nil)
    if fileNumber == -1 {
      throw FileDescriptorError()
    }

    return UNIXConnection(fileNumber: fileNumber)
  }
}
