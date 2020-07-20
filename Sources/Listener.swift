public protocol Listener : FileDescriptor {
    func accept<C: Connection>() throws -> C
}
