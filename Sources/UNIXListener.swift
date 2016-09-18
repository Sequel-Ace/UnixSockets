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


open class UNIXListener : FileDescriptor {
  open let fileNumber: FileNumber

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

  fileprivate func bind(_ path: String) throws {
    var addr = sockaddr_un()
    addr.sun_family = sa_family_t(AF_UNIX)

    let lengthOfPath = path.withCString { Int(strlen($0)) }

    guard lengthOfPath < MemoryLayout.size(ofValue: addr.sun_path) else {
      throw FileDescriptorError()
    }

    addr.sun_len = UInt8(MemoryLayout<sockaddr_un>.size - MemoryLayout.size(ofValue: addr.sun_path) + lengthOfPath)

    _ = withUnsafeMutablePointer(to: &addr.sun_path.0) { ptr in
      path.withCString {
        strncpy(ptr, $0, lengthOfPath)
      }
    }

    try withUnsafePointer(to: &addr) {
      try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        guard system_bind(fileNumber, $0, UInt32(MemoryLayout<sockaddr_un>.stride)) != -1 else {
          throw FileDescriptorError()
        }
      }
    }
  }

  fileprivate func listen(backlog: Int32) throws {
    if system_listen(fileNumber, backlog) == -1 {
      throw FileDescriptorError()
    }
  }

  /// Accepts a connection socket
  open func accept() throws -> UNIXConnection {
    let fileNumber = system_accept(self.fileNumber, nil, nil)
    if fileNumber == -1 {
      throw FileDescriptorError()
    }

    return UNIXConnection(fileNumber: fileNumber)
  }
}
