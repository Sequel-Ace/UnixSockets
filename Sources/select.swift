#if os(Linux)
import Glibc
private let system_select = Glibc.select
#else
import Darwin
private let system_select = Darwin.select
#endif


func filter<T : FileDescriptor>(sockets: [T]?, inout _ set: fd_set) -> [T] {
  return sockets?.filter {
    fdIsSet($0.fileNumber, &set)
  } ?? []
}


public func select<T : FileDescriptor>(reads reads: [T] = [], writes: [T] = [], errors: [T] = [], timeout: timeval? = nil) throws -> (reads: [T], writes: [T], errors: [T]) {
  var readFDs = fd_set()
  fdZero(&readFDs)
  reads.forEach { fdSet($0.fileNumber, &readFDs) }

  var writeFDs = fd_set()
  fdZero(&writeFDs)
  writes.forEach { fdSet($0.fileNumber, &writeFDs) }

  var errorFDs = fd_set()
  fdZero(&errorFDs)
  errors.forEach { fdSet($0.fileNumber, &errorFDs) }

  let maxFD = (reads + writes + errors).map { $0.fileNumber }.reduce(0, combine: max)
  let result: Int32
  if let timeout = timeout {
    var timeout = timeout
    result = system_select(maxFD + 1, &readFDs, &writeFDs, &errorFDs, &timeout)
  } else {
    result = system_select(maxFD + 1, &readFDs, &writeFDs, &errorFDs, nil)
  }

  if result == 0 {
    return ([], [], [])
  } else if result > 0 {
    return (
      filter(reads, &readFDs),
      filter(writes, &writeFDs),
      filter(errors, &errorFDs)
    )
  }

  throw FileDescriptorError()
}
