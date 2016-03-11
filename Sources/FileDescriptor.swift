#if os(Linux)
import Glibc
private let system_close = Glibc.close
private let system_write = Glibc.write
private let system_read = Glibc.read
#else
import Darwin
private let system_close = Darwin.close
private let system_write = Darwin.write
private let system_read = Darwin.read
#endif


public typealias Byte = Int8
public typealias FileNumber = Int32


public protocol FileDescriptor {
  var fileNumber: FileNumber { get }
}


struct FileDescriptorError : ErrorType {

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

  /// Write attemps to write the given bytes to the file descriptor
  public func write(bytes: [Byte]) throws -> Int {
    let size = system_write(fileNumber, bytes, bytes.count)

    if size == -1 {
      throw FileDescriptorError()
    }

    return size
  }

  /// Read attempts to read the given size from the file descriptor
  public func read(bufferSize: Int) throws -> [Byte] {
    let buffer = UnsafeMutablePointer<Byte>(malloc(bufferSize))
    defer { free(buffer) }
    let size = system_read(fileNumber, buffer, bufferSize)

    if size > 0 {
      let readSize = min(size, bufferSize)
      var bytes = [Byte](count: readSize, repeatedValue: 0)
      memcpy(&bytes, buffer, readSize)
      return bytes
    }

    throw FileDescriptorError()
  }
}
