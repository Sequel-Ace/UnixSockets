import Foundation

#if os(Linux)
import Glibc
private let system_close = Glibc.close
private let system_read = Glibc.read
private let system_write = Glibc.write
#else
import Darwin
private let system_close = Darwin.close
private let system_read = Darwin.read
private let system_write = Darwin.write
#endif

public typealias Byte = UInt8
public typealias FileNumber = Int32

/// A proxy for system-specific file descriptors.
public protocol FileDescriptor {
    var fileNumber: FileNumber { get }
}

public protocol Connection : ReadableFileDescriptor, WritableFileDescriptor {}

public protocol Listener : FileDescriptor {
    associatedtype AnyConnection : Connection

    func accept() throws -> AnyConnection
}

extension FileDescriptor {
    /// Close deletes the file descriptor from the per-process object reference table
    public func close() throws {
        if system_close(fileNumber) == -1 {
            throw FileDescriptorError(kind: .closeError, errno: errno)
        }
    }
    
    public var isClosed: Bool {
        if fcntl(fileNumber, F_GETFL) == -1 {
            return errno == EBADF
        }
        
        return false
    }
}

public protocol ReadableFileDescriptor : FileDescriptor {}

extension ReadableFileDescriptor {
    /// Read attempts to read the given size from the file descriptor
    public func read(_ bufferSize: Int) throws -> [Byte] {
        let buffer = UnsafeMutableRawPointer(malloc(bufferSize))
        defer { free(buffer) }
        let size = system_read(fileNumber, buffer!, bufferSize)

        guard size != -1 else {
            throw FileDescriptorError(kind: .readError, errno: errno)
        }

        let readSize = min(size, bufferSize)
        var bytes = [Byte](repeating: 0, count: readSize)
        memcpy(&bytes, buffer!, readSize)
        return bytes
    }

    /// Read attempts to read the given size from the file descriptor
    public func read(_ bufferSize: Int) throws -> Data {
        let bytes: [Byte] = try read(bufferSize)

        return Data(bytes: bytes, count: bytes.count)
    }

    public func readAll() throws -> Data {
        var result = Data()
        var data = CChar()
        var data_read: size_t = 0

        var done = false
        while (!done) {
            data_read = recv(fileNumber, &data, 1, 0)
            if data_read <= 0 {
                break
            }
            done = Character(UnicodeScalar(UInt8(bitPattern: data))).isNewline
            result.append(contentsOf: [data].map(UInt8.init))
        }

        guard data_read != -1 else {
            throw FileDescriptorError(kind: .unknown, errno: errno)
        }

        return result
    }
}

public protocol WritableFileDescriptor : FileDescriptor {}

extension WritableFileDescriptor {
    /// Write attemps to write the given bytes to the file descriptor
    public func write(_ bytes: [Byte]) throws -> Int {
        let size = system_write(fileNumber, bytes, bytes.count)

        guard size != -1 else {
            throw FileDescriptorError(kind: .writeError, errno: errno)
        }

        return size
    }

    /// Write attemps to write the given data to the file descriptor
    public func write(_ data: Data) throws -> Int {
        let bytes = [Byte](data)

        return try write(bytes)
    }
}
