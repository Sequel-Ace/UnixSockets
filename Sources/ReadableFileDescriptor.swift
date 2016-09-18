#if os(Linux)
import Glibc
private let system_read = Glibc.read
#else
import Darwin
private let system_read = Darwin.read
#endif


public protocol ReadableFileDescriptor : FileDescriptor {
}


extension ReadableFileDescriptor {
  /// Read attempts to read the given size from the file descriptor
  public func read(_ bufferSize: Int) throws -> [Byte] {
    let buffer = UnsafeMutableRawPointer(malloc(bufferSize))
    defer { free(buffer) }
    let size = system_read(fileNumber, buffer!, bufferSize)

    if size > 0 {
      let readSize = min(size, bufferSize)
      var bytes = [Byte](repeating: 0, count: readSize)
      memcpy(&bytes, buffer!, readSize)
      return bytes
    }

    throw FileDescriptorError()
  }
}
