open class TCPConnection : FileDescriptor, Connection {
  open let fileNumber: FileNumber

  public init(fileNumber: FileNumber) {
    self.fileNumber = fileNumber
  }
}
