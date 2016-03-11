#if os(Linux)
import Glibc
private let system_pipe = Glibc.pipe
#else
import Darwin
private let system_pipe = Darwin.pipe
#endif


class PipeConnection : Connection {
  let fileNumber: FileNumber

  init(fileNumber: FileNumber) {
    self.fileNumber = fileNumber
  }

  deinit {
    let _ = try? close()
  }
}


public func pipe() throws -> (reader: Connection, writer: Connection) {
  var fileNumbers: [FileNumber] = [0, 0]
  if system_pipe(&fileNumbers) == -1 {
    throw FileDescriptorError()
  }
  return (PipeConnection(fileNumber: fileNumbers[0]), PipeConnection(fileNumber: fileNumbers[1]))
}
