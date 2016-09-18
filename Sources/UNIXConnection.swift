open class UNIXConnection : FileDescriptor, Connection {
  open let fileNumber: FileNumber

  init(fileNumber: FileNumber) {
    self.fileNumber = fileNumber
  }
}
