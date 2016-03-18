# fd: File Descriptor

Swift file descriptor library.

## Usage

### FileDescriptor

FileDescriptor is a protocol containing a single property (fileNumber).

```swift
protocol FileDescriptor {
  var fileNumber: FileNumber { get }
}
```

There are various protocol extensions to FileDescriptor to add functionality.

##### Close

You may close a file descriptor.

```swift
try descriptor.close()
```

##### Select

You may use the select function to examine which file descriptors are ready for
reading, writing or have error conditions.

```swift
let readable = try select(reads: [descriptor]).reads
```

### ReadableFileDescriptor

You may read from a readable file descriptor.

```swift
let bytes = try descriptor.read(1024)
```

##### WritableFileDescriptor

You may write to a writable file descriptor.

```swift
try descriptor.write([1])
```

#### Pipe

You may use the pipe function to create a unidirectional data flow. The reader
allows you to read data which was previously written to the writer.

```swift
let (reader, writer) = try pipe()
try writer.write([1])
let bytes = try reader.read(1)
```

### Listener

A listener is a file descriptor which can accept connections.

```swift
let connection = try listener.accept()
```

#### TCPListener

```swift
let listener = try TCPListener(address: "127.0.0.1", port: 8000)
```

#### UNIXListener

UNIXListener is a Unix domain socket listener.

```swift
let listener = try UNIXListener(path: "/tmp/my-unix-listener")
```

### Connection

A connection conforms to FileDescriptor so you can use the previously
documented `read` and `write` capabilities.
