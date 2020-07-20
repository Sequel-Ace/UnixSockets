#if os(Linux)
import Glibc
private let system_close = Glibc.close
#else
import Darwin
private let system_close = Darwin.close
#endif


public typealias Byte = UInt8
public typealias FileNumber = Int32


public protocol FileDescriptor {
    var fileNumber: FileNumber { get }
}

struct FileDescriptorError : Error {
}

extension FileDescriptor {
  /// Close deletes the file descriptor from the per-process object reference table
  public func close() throws {
    if system_close(fileNumber) == -1 {
      throw FileDescriptorError()
    }
  }

  public var isClosed: Bool {
    if fcntl(fileNumber, F_GETFL) == -1 {
      return errno == EBADF
    }

    return false
  }
}
