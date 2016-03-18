#if os(Linux)
import Glibc
private let system_write = Glibc.write
#else
import Darwin
private let system_write = Darwin.write
#endif


public protocol WritableFileDescriptor : FileDescriptor {
}


extension WritableFileDescriptor {
  /// Write attemps to write the given bytes to the file descriptor
  public func write(bytes: [Byte]) throws -> Int {
    let size = system_write(fileNumber, bytes, bytes.count)

    if size == -1 {
      throw FileDescriptorError()
    }

    return size
  }
}
