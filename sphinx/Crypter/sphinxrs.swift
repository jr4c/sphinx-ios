// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!
import Foundation

// Depending on the consumer's build setup, the low-level FFI code
// might be in a separate module, or it might be compiled inline into
// this module. This is a bit of light hackery to work with both.
#if canImport(sphinxrsFFI)
import sphinxrsFFI
#endif

fileprivate extension RustBuffer {
    // Allocate a new buffer, copying the contents of a `UInt8` array.
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        try! rustCall { ffi_sphinxrs_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_sphinxrs_rustbuffer_free(self, $0) }
    }
}

fileprivate extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

// For every type used in the interface, we provide helper methods for conveniently
// lifting and lowering that type from C-compatible data, and for reading and writing
// values of that type in a buffer.

// Helper classes/extensions that don't change.
// Someday, this will be in a library of its own.

fileprivate extension Data {
    init(rustBuffer: RustBuffer) {
        // TODO: This copies the buffer. Can we read directly from a
        // Rust buffer?
        self.init(bytes: rustBuffer.data!, count: Int(rustBuffer.len))
    }
}

// Define reader functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.
//
// With external types, one swift source file needs to be able to call the read
// method on another source file's FfiConverter, but then what visibility
// should Reader have?
// - If Reader is fileprivate, then this means the read() must also
//   be fileprivate, which doesn't work with external types.
// - If Reader is internal/public, we'll get compile errors since both source
//   files will try define the same type.
//
// Instead, the read() method and these helper functions input a tuple of data

fileprivate func createReader(data: Data) -> (data: Data, offset: Data.Index) {
    (data: data, offset: 0)
}

// Reads an integer at the current offset, in big-endian order, and advances
// the offset on success. Throws if reading the integer would move the
// offset past the end of the buffer.
fileprivate func readInt<T: FixedWidthInteger>(_ reader: inout (data: Data, offset: Data.Index)) throws -> T {
    let range = reader.offset..<reader.offset + MemoryLayout<T>.size
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    if T.self == UInt8.self {
        let value = reader.data[reader.offset]
        reader.offset += 1
        return value as! T
    }
    var value: T = 0
    let _ = withUnsafeMutableBytes(of: &value, { reader.data.copyBytes(to: $0, from: range)})
    reader.offset = range.upperBound
    return value.bigEndian
}

// Reads an arbitrary number of bytes, to be used to read
// raw bytes, this is useful when lifting strings
fileprivate func readBytes(_ reader: inout (data: Data, offset: Data.Index), count: Int) throws -> Array<UInt8> {
    let range = reader.offset..<(reader.offset+count)
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    var value = [UInt8](repeating: 0, count: count)
    value.withUnsafeMutableBufferPointer({ buffer in
        reader.data.copyBytes(to: buffer, from: range)
    })
    reader.offset = range.upperBound
    return value
}

// Reads a float at the current offset.
fileprivate func readFloat(_ reader: inout (data: Data, offset: Data.Index)) throws -> Float {
    return Float(bitPattern: try readInt(&reader))
}

// Reads a float at the current offset.
fileprivate func readDouble(_ reader: inout (data: Data, offset: Data.Index)) throws -> Double {
    return Double(bitPattern: try readInt(&reader))
}

// Indicates if the offset has reached the end of the buffer.
fileprivate func hasRemaining(_ reader: (data: Data, offset: Data.Index)) -> Bool {
    return reader.offset < reader.data.count
}

// Define writer functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.  See the above discussion on Readers for details.

fileprivate func createWriter() -> [UInt8] {
    return []
}

fileprivate func writeBytes<S>(_ writer: inout [UInt8], _ byteArr: S) where S: Sequence, S.Element == UInt8 {
    writer.append(contentsOf: byteArr)
}

// Writes an integer in big-endian order.
//
// Warning: make sure what you are trying to write
// is in the correct type!
fileprivate func writeInt<T: FixedWidthInteger>(_ writer: inout [UInt8], _ value: T) {
    var value = value.bigEndian
    withUnsafeBytes(of: &value) { writer.append(contentsOf: $0) }
}

fileprivate func writeFloat(_ writer: inout [UInt8], _ value: Float) {
    writeInt(&writer, value.bitPattern)
}

fileprivate func writeDouble(_ writer: inout [UInt8], _ value: Double) {
    writeInt(&writer, value.bitPattern)
}

// Protocol for types that transfer other types across the FFI. This is
// analogous go the Rust trait of the same name.
fileprivate protocol FfiConverter {
    associatedtype FfiType
    associatedtype SwiftType

    static func lift(_ value: FfiType) throws -> SwiftType
    static func lower(_ value: SwiftType) -> FfiType
    static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType
    static func write(_ value: SwiftType, into buf: inout [UInt8])
}

// Types conforming to `Primitive` pass themselves directly over the FFI.
fileprivate protocol FfiConverterPrimitive: FfiConverter where FfiType == SwiftType { }

extension FfiConverterPrimitive {
    public static func lift(_ value: FfiType) throws -> SwiftType {
        return value
    }

    public static func lower(_ value: SwiftType) -> FfiType {
        return value
    }
}

// Types conforming to `FfiConverterRustBuffer` lift and lower into a `RustBuffer`.
// Used for complex types where it's hard to write a custom lift/lower.
fileprivate protocol FfiConverterRustBuffer: FfiConverter where FfiType == RustBuffer {}

extension FfiConverterRustBuffer {
    public static func lift(_ buf: RustBuffer) throws -> SwiftType {
        var reader = createReader(data: Data(rustBuffer: buf))
        let value = try read(from: &reader)
        if hasRemaining(reader) {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

    public static func lower(_ value: SwiftType) -> RustBuffer {
          var writer = createWriter()
          write(value, into: &writer)
          return RustBuffer(bytes: writer)
    }
}
// An error type for FFI errors. These errors occur at the UniFFI level, not
// the library level.
fileprivate enum UniffiInternalError: LocalizedError {
    case bufferOverflow
    case incompleteData
    case unexpectedOptionalTag
    case unexpectedEnumCase
    case unexpectedNullPointer
    case unexpectedRustCallStatusCode
    case unexpectedRustCallError
    case unexpectedStaleHandle
    case rustPanic(_ message: String)

    public var errorDescription: String? {
        switch self {
        case .bufferOverflow: return "Reading the requested value would read past the end of the buffer"
        case .incompleteData: return "The buffer still has data after lifting its containing value"
        case .unexpectedOptionalTag: return "Unexpected optional tag; should be 0 or 1"
        case .unexpectedEnumCase: return "Raw enum value doesn't match any cases"
        case .unexpectedNullPointer: return "Raw pointer value was null"
        case .unexpectedRustCallStatusCode: return "Unexpected RustCallStatus code"
        case .unexpectedRustCallError: return "CALL_ERROR but no errorClass specified"
        case .unexpectedStaleHandle: return "The object in the handle map has been dropped already"
        case let .rustPanic(message): return message
        }
    }
}

fileprivate let CALL_SUCCESS: Int8 = 0
fileprivate let CALL_ERROR: Int8 = 1
fileprivate let CALL_PANIC: Int8 = 2

fileprivate extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            errorBuf: RustBuffer.init(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

private func rustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: nil)
}

private func rustCallWithError<T>(
    _ errorHandler: @escaping (RustBuffer) throws -> Error,
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: errorHandler)
}

private func makeRustCall<T>(
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T,
    errorHandler: ((RustBuffer) throws -> Error)?
) throws -> T {
    uniffiEnsureInitialized()
    var callStatus = RustCallStatus.init()
    let returnedVal = callback(&callStatus)
    try uniffiCheckCallStatus(callStatus: callStatus, errorHandler: errorHandler)
    return returnedVal
}

private func uniffiCheckCallStatus(
    callStatus: RustCallStatus,
    errorHandler: ((RustBuffer) throws -> Error)?
) throws {
    switch callStatus.code {
        case CALL_SUCCESS:
            return

        case CALL_ERROR:
            if let errorHandler = errorHandler {
                throw try errorHandler(callStatus.errorBuf)
            } else {
                callStatus.errorBuf.deallocate()
                throw UniffiInternalError.unexpectedRustCallError
            }

        case CALL_PANIC:
            // When the rust code sees a panic, it tries to construct a RustBuffer
            // with the message.  But if that code panics, then it just sends back
            // an empty buffer.
            if callStatus.errorBuf.len > 0 {
                throw UniffiInternalError.rustPanic(try FfiConverterString.lift(callStatus.errorBuf))
            } else {
                callStatus.errorBuf.deallocate()
                throw UniffiInternalError.rustPanic("Rust panic")
            }

        default:
            throw UniffiInternalError.unexpectedRustCallStatusCode
    }
}

// Public interface members begin here.


fileprivate struct FfiConverterUInt16: FfiConverterPrimitive {
    typealias FfiType = UInt16
    typealias SwiftType = UInt16

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> UInt16 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: SwiftType, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

fileprivate struct FfiConverterUInt32: FfiConverterPrimitive {
    typealias FfiType = UInt32
    typealias SwiftType = UInt32

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> UInt32 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: SwiftType, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

fileprivate struct FfiConverterUInt64: FfiConverterPrimitive {
    typealias FfiType = UInt64
    typealias SwiftType = UInt64

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> UInt64 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: SwiftType, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

fileprivate struct FfiConverterString: FfiConverter {
    typealias SwiftType = String
    typealias FfiType = RustBuffer

    public static func lift(_ value: RustBuffer) throws -> String {
        defer {
            value.deallocate()
        }
        if value.data == nil {
            return String()
        }
        let bytes = UnsafeBufferPointer<UInt8>(start: value.data!, count: Int(value.len))
        return String(bytes: bytes, encoding: String.Encoding.utf8)!
    }

    public static func lower(_ value: String) -> RustBuffer {
        return value.utf8CString.withUnsafeBufferPointer { ptr in
            // The swift string gives us int8_t, we want uint8_t.
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                // The swift string gives us a trailing null byte, we don't want it.
                let buf = UnsafeBufferPointer(rebasing: ptr.prefix(upTo: ptr.count - 1))
                return RustBuffer.from(buf)
            }
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> String {
        let len: Int32 = try readInt(&buf)
        return String(bytes: try readBytes(&buf, count: Int(len)), encoding: String.Encoding.utf8)!
    }

    public static func write(_ value: String, into buf: inout [UInt8]) {
        let len = Int32(value.utf8.count)
        writeInt(&buf, len)
        writeBytes(&buf, value.utf8)
    }
}

fileprivate struct FfiConverterData: FfiConverterRustBuffer {
    typealias SwiftType = Data

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Data {
        let len: Int32 = try readInt(&buf)
        return Data(bytes: try readBytes(&buf, count: Int(len)))
    }

    public static func write(_ value: Data, into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        writeBytes(&buf, value)
    }
}


public struct Keys {
    public var `secret`: String
    public var `pubkey`: String

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(`secret`: String, `pubkey`: String) {
        self.`secret` = `secret`
        self.`pubkey` = `pubkey`
    }
}


extension Keys: Equatable, Hashable {
    public static func ==(lhs: Keys, rhs: Keys) -> Bool {
        if lhs.`secret` != rhs.`secret` {
            return false
        }
        if lhs.`pubkey` != rhs.`pubkey` {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(`secret`)
        hasher.combine(`pubkey`)
    }
}


public struct FfiConverterTypeKeys: FfiConverterRustBuffer {
    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Keys {
        return try Keys(
            `secret`: FfiConverterString.read(from: &buf), 
            `pubkey`: FfiConverterString.read(from: &buf)
        )
    }

    public static func write(_ value: Keys, into buf: inout [UInt8]) {
        FfiConverterString.write(value.`secret`, into: &buf)
        FfiConverterString.write(value.`pubkey`, into: &buf)
    }
}


public func FfiConverterTypeKeys_lift(_ buf: RustBuffer) throws -> Keys {
    return try FfiConverterTypeKeys.lift(buf)
}

public func FfiConverterTypeKeys_lower(_ value: Keys) -> RustBuffer {
    return FfiConverterTypeKeys.lower(value)
}


public struct VlsResponse {
    public var `topic`: String
    public var `bytes`: Data
    public var `sequence`: UInt16
    public var `cmd`: String
    public var `state`: Data

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(`topic`: String, `bytes`: Data, `sequence`: UInt16, `cmd`: String, `state`: Data) {
        self.`topic` = `topic`
        self.`bytes` = `bytes`
        self.`sequence` = `sequence`
        self.`cmd` = `cmd`
        self.`state` = `state`
    }
}


extension VlsResponse: Equatable, Hashable {
    public static func ==(lhs: VlsResponse, rhs: VlsResponse) -> Bool {
        if lhs.`topic` != rhs.`topic` {
            return false
        }
        if lhs.`bytes` != rhs.`bytes` {
            return false
        }
        if lhs.`sequence` != rhs.`sequence` {
            return false
        }
        if lhs.`cmd` != rhs.`cmd` {
            return false
        }
        if lhs.`state` != rhs.`state` {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(`topic`)
        hasher.combine(`bytes`)
        hasher.combine(`sequence`)
        hasher.combine(`cmd`)
        hasher.combine(`state`)
    }
}


public struct FfiConverterTypeVlsResponse: FfiConverterRustBuffer {
    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> VlsResponse {
        return try VlsResponse(
            `topic`: FfiConverterString.read(from: &buf), 
            `bytes`: FfiConverterData.read(from: &buf), 
            `sequence`: FfiConverterUInt16.read(from: &buf), 
            `cmd`: FfiConverterString.read(from: &buf), 
            `state`: FfiConverterData.read(from: &buf)
        )
    }

    public static func write(_ value: VlsResponse, into buf: inout [UInt8]) {
        FfiConverterString.write(value.`topic`, into: &buf)
        FfiConverterData.write(value.`bytes`, into: &buf)
        FfiConverterUInt16.write(value.`sequence`, into: &buf)
        FfiConverterString.write(value.`cmd`, into: &buf)
        FfiConverterData.write(value.`state`, into: &buf)
    }
}


public func FfiConverterTypeVlsResponse_lift(_ buf: RustBuffer) throws -> VlsResponse {
    return try FfiConverterTypeVlsResponse.lift(buf)
}

public func FfiConverterTypeVlsResponse_lower(_ value: VlsResponse) -> RustBuffer {
    return FfiConverterTypeVlsResponse.lower(value)
}

public enum SphinxError {

    
    
    case DerivePublicKey(`r`: String)
    case DeriveSharedSecret(`r`: String)
    case Encrypt(`r`: String)
    case Decrypt(`r`: String)
    case BadPubkey(`r`: String)
    case BadSecret(`r`: String)
    case BadNonce(`r`: String)
    case BadCiper(`r`: String)
    case InvalidNetwork(`r`: String)
    case BadRequest(`r`: String)
    case BadResponse(`r`: String)
    case BadTopic(`r`: String)
    case BadArgs(`r`: String)
    case BadState(`r`: String)
    case BadVelocity(`r`: String)
    case InitFailed(`r`: String)
    case LssFailed(`r`: String)
    case VlsFailed(`r`: String)

    fileprivate static func uniffiErrorHandler(_ error: RustBuffer) throws -> Error {
        return try FfiConverterTypeSphinxError.lift(error)
    }
}


public struct FfiConverterTypeSphinxError: FfiConverterRustBuffer {
    typealias SwiftType = SphinxError

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SphinxError {
        let variant: Int32 = try readInt(&buf)
        switch variant {

        

        
        case 1: return .DerivePublicKey(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 2: return .DeriveSharedSecret(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 3: return .Encrypt(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 4: return .Decrypt(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 5: return .BadPubkey(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 6: return .BadSecret(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 7: return .BadNonce(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 8: return .BadCiper(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 9: return .InvalidNetwork(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 10: return .BadRequest(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 11: return .BadResponse(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 12: return .BadTopic(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 13: return .BadArgs(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 14: return .BadState(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 15: return .BadVelocity(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 16: return .InitFailed(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 17: return .LssFailed(
            `r`: try FfiConverterString.read(from: &buf)
            )
        case 18: return .VlsFailed(
            `r`: try FfiConverterString.read(from: &buf)
            )

         default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: SphinxError, into buf: inout [UInt8]) {
        switch value {

        

        
        
        case let .DerivePublicKey(`r`):
            writeInt(&buf, Int32(1))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .DeriveSharedSecret(`r`):
            writeInt(&buf, Int32(2))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .Encrypt(`r`):
            writeInt(&buf, Int32(3))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .Decrypt(`r`):
            writeInt(&buf, Int32(4))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadPubkey(`r`):
            writeInt(&buf, Int32(5))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadSecret(`r`):
            writeInt(&buf, Int32(6))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadNonce(`r`):
            writeInt(&buf, Int32(7))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadCiper(`r`):
            writeInt(&buf, Int32(8))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .InvalidNetwork(`r`):
            writeInt(&buf, Int32(9))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadRequest(`r`):
            writeInt(&buf, Int32(10))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadResponse(`r`):
            writeInt(&buf, Int32(11))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadTopic(`r`):
            writeInt(&buf, Int32(12))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadArgs(`r`):
            writeInt(&buf, Int32(13))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadState(`r`):
            writeInt(&buf, Int32(14))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .BadVelocity(`r`):
            writeInt(&buf, Int32(15))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .InitFailed(`r`):
            writeInt(&buf, Int32(16))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .LssFailed(`r`):
            writeInt(&buf, Int32(17))
            FfiConverterString.write(`r`, into: &buf)
            
        
        case let .VlsFailed(`r`):
            writeInt(&buf, Int32(18))
            FfiConverterString.write(`r`, into: &buf)
            
        }
    }
}


extension SphinxError: Equatable, Hashable {}

extension SphinxError: Error { }

fileprivate struct FfiConverterOptionUInt16: FfiConverterRustBuffer {
    typealias SwiftType = UInt16?

    public static func write(_ value: SwiftType, into buf: inout [UInt8]) {
        guard let value = value else {
            writeInt(&buf, Int8(0))
            return
        }
        writeInt(&buf, Int8(1))
        FfiConverterUInt16.write(value, into: &buf)
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType {
        switch try readInt(&buf) as Int8 {
        case 0: return nil
        case 1: return try FfiConverterUInt16.read(from: &buf)
        default: throw UniffiInternalError.unexpectedOptionalTag
        }
    }
}

public func `pubkeyFromSecretKey`(`mySecretKey`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_pubkey_from_secret_key(
        FfiConverterString.lower(`mySecretKey`),$0)
}
    )
}

public func `deriveSharedSecret`(`theirPubkey`: String, `mySecretKey`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_derive_shared_secret(
        FfiConverterString.lower(`theirPubkey`),
        FfiConverterString.lower(`mySecretKey`),$0)
}
    )
}

public func `encrypt`(`plaintext`: String, `secret`: String, `nonce`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_encrypt(
        FfiConverterString.lower(`plaintext`),
        FfiConverterString.lower(`secret`),
        FfiConverterString.lower(`nonce`),$0)
}
    )
}

public func `decrypt`(`ciphertext`: String, `secret`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_decrypt(
        FfiConverterString.lower(`ciphertext`),
        FfiConverterString.lower(`secret`),$0)
}
    )
}

public func `nodeKeys`(`net`: String, `seed`: String) throws -> Keys {
    return try  FfiConverterTypeKeys.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_node_keys(
        FfiConverterString.lower(`net`),
        FfiConverterString.lower(`seed`),$0)
}
    )
}

public func `mnemonicFromEntropy`(`entropy`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_mnemonic_from_entropy(
        FfiConverterString.lower(`entropy`),$0)
}
    )
}

public func `entropyFromMnemonic`(`mnemonic`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_entropy_from_mnemonic(
        FfiConverterString.lower(`mnemonic`),$0)
}
    )
}

public func `mnemonicToSeed`(`mnemonic`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_mnemonic_to_seed(
        FfiConverterString.lower(`mnemonic`),$0)
}
    )
}

public func `entropyToSeed`(`entropy`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_entropy_to_seed(
        FfiConverterString.lower(`entropy`),$0)
}
    )
}

public func `buildRequest`(`msg`: String, `secret`: String, `nonce`: UInt64) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_build_request(
        FfiConverterString.lower(`msg`),
        FfiConverterString.lower(`secret`),
        FfiConverterUInt64.lower(`nonce`),$0)
}
    )
}

public func `parseResponse`(`res`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_parse_response(
        FfiConverterString.lower(`res`),$0)
}
    )
}

public func `makeAuthToken`(`ts`: UInt32, `secret`: String) throws -> String {
    return try  FfiConverterString.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_make_auth_token(
        FfiConverterUInt32.lower(`ts`),
        FfiConverterString.lower(`secret`),$0)
}
    )
}

public func `run`(`topic`: String, `args`: String, `state`: Data, `msg1`: Data, `expectedSequence`: UInt16?) throws -> VlsResponse {
    return try  FfiConverterTypeVlsResponse.lift(
        try rustCallWithError(FfiConverterTypeSphinxError.lift) {
    uniffi_sphinxrs_fn_func_run(
        FfiConverterString.lower(`topic`),
        FfiConverterString.lower(`args`),
        FfiConverterData.lower(`state`),
        FfiConverterData.lower(`msg1`),
        FfiConverterOptionUInt16.lower(`expectedSequence`),$0)
}
    )
}

private enum InitializationResult {
    case ok
    case contractVersionMismatch
    case apiChecksumMismatch
}
// Use a global variables to perform the versioning checks. Swift ensures that
// the code inside is only computed once.
private var initializationResult: InitializationResult {
    // Get the bindings contract version from our ComponentInterface
    let bindings_contract_version = 22
    // Get the scaffolding contract version by calling the into the dylib
    let scaffolding_contract_version = ffi_sphinxrs_uniffi_contract_version()
    if bindings_contract_version != scaffolding_contract_version {
        return InitializationResult.contractVersionMismatch
    }
    if (uniffi_sphinxrs_checksum_func_pubkey_from_secret_key() != 14435) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_derive_shared_secret() != 20125) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_encrypt() != 43446) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_decrypt() != 47725) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_node_keys() != 21192) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_mnemonic_from_entropy() != 32309) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_entropy_from_mnemonic() != 33294) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_mnemonic_to_seed() != 23084) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_entropy_to_seed() != 33710) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_build_request() != 31264) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_parse_response() != 12980) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_make_auth_token() != 13236) {
        return InitializationResult.apiChecksumMismatch
    }
    if (uniffi_sphinxrs_checksum_func_run() != 47350) {
        return InitializationResult.apiChecksumMismatch
    }

    return InitializationResult.ok
}

private func uniffiEnsureInitialized() {
    switch initializationResult {
    case .ok:
        break
    case .contractVersionMismatch:
        fatalError("UniFFI contract version mismatch: try cleaning and rebuilding your project")
    case .apiChecksumMismatch:
        fatalError("UniFFI API checksum mismatch: try cleaning and rebuilding your project")
    }
}