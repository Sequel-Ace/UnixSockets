public protocol Listener : FileDescriptor {
  func accept() throws -> Connection
}
