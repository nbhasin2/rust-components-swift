// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!
import Foundation

// Depending on the consumer's build setup, the low-level FFI code
// might be in a separate module, or it might be compiled inline into
// this module. This is a bit of light hackery to work with both.
#if canImport(MozillaRustComponents)
    import MozillaRustComponents
#endif

private extension RustBuffer {
    // Allocate a new buffer, copying the contents of a `UInt8` array.
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        try! rustCall { ffi_push_7ba2_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_push_7ba2_rustbuffer_free(self, $0) }
    }
}

private extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

// For every type used in the interface, we provide helper methods for conveniently
// lifting and lowering that type from C-compatible data, and for reading and writing
// values of that type in a buffer.

// Helper classes/extensions that don't change.
// Someday, this will be in a libray of its own.

private extension Data {
    init(rustBuffer: RustBuffer) {
        // TODO: This copies the buffer. Can we read directly from a
        // Rust buffer?
        self.init(bytes: rustBuffer.data!, count: Int(rustBuffer.len))
    }
}

// A helper class to read values out of a byte buffer.
private class Reader {
    let data: Data
    var offset: Data.Index

    init(data: Data) {
        self.data = data
        offset = 0
    }

    // Reads an integer at the current offset, in big-endian order, and advances
    // the offset on success. Throws if reading the integer would move the
    // offset past the end of the buffer.
    func readInt<T: FixedWidthInteger>() throws -> T {
        let range = offset ..< offset + MemoryLayout<T>.size
        guard data.count >= range.upperBound else {
            throw UniffiInternalError.bufferOverflow
        }
        if T.self == UInt8.self {
            let value = data[offset]
            offset += 1
            return value as! T
        }
        var value: T = 0
        _ = withUnsafeMutableBytes(of: &value) { data.copyBytes(to: $0, from: range) }
        offset = range.upperBound
        return value.bigEndian
    }

    // Reads an arbitrary number of bytes, to be used to read
    // raw bytes, this is useful when lifting strings
    func readBytes(count: Int) throws -> [UInt8] {
        let range = offset ..< (offset + count)
        guard data.count >= range.upperBound else {
            throw UniffiInternalError.bufferOverflow
        }
        var value = [UInt8](repeating: 0, count: count)
        value.withUnsafeMutableBufferPointer { buffer in
            data.copyBytes(to: buffer, from: range)
        }
        offset = range.upperBound
        return value
    }

    // Reads a float at the current offset.
    @inlinable
    func readFloat() throws -> Float {
        return Float(bitPattern: try readInt())
    }

    // Reads a float at the current offset.
    @inlinable
    func readDouble() throws -> Double {
        return Double(bitPattern: try readInt())
    }

    // Indicates if the offset has reached the end of the buffer.
    @inlinable
    func hasRemaining() -> Bool {
        return offset < data.count
    }
}

// A helper class to write values into a byte buffer.
private class Writer {
    var bytes: [UInt8]
    var offset: Array<UInt8>.Index

    init() {
        bytes = []
        offset = 0
    }

    func writeBytes<S>(_ byteArr: S) where S: Sequence, S.Element == UInt8 {
        bytes.append(contentsOf: byteArr)
    }

    // Writes an integer in big-endian order.
    //
    // Warning: make sure what you are trying to write
    // is in the correct type!
    func writeInt<T: FixedWidthInteger>(_ value: T) {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { bytes.append(contentsOf: $0) }
    }

    @inlinable
    func writeFloat(_ value: Float) {
        writeInt(value.bitPattern)
    }

    @inlinable
    func writeDouble(_ value: Double) {
        writeInt(value.bitPattern)
    }
}

// Types conforming to `Serializable` can be read and written in a bytebuffer.
private protocol Serializable {
    func write(into: Writer)
    static func read(from: Reader) throws -> Self
}

// Types confirming to `ViaFfi` can be transferred back-and-for over the FFI.
// This is analogous to the Rust trait of the same name.
private protocol ViaFfi: Serializable {
    associatedtype FfiType
    static func lift(_ v: FfiType) throws -> Self
    func lower() -> FfiType
}

// Types conforming to `Primitive` pass themselves directly over the FFI.
private protocol Primitive {}

private extension Primitive {
    typealias FfiType = Self

    static func lift(_ v: Self) throws -> Self {
        return v
    }

    func lower() -> Self {
        return self
    }
}

// Types conforming to `ViaFfiUsingByteBuffer` lift and lower into a bytebuffer.
// Use this for complex types where it's hard to write a custom lift/lower.
private protocol ViaFfiUsingByteBuffer: Serializable {}

private extension ViaFfiUsingByteBuffer {
    typealias FfiType = RustBuffer

    static func lift(_ buf: FfiType) throws -> Self {
        let reader = Reader(data: Data(rustBuffer: buf))
        let value = try Self.read(from: reader)
        if reader.hasRemaining() {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

    func lower() -> FfiType {
        let writer = Writer()
        write(into: writer)
        return RustBuffer(bytes: writer.bytes)
    }
}

// An error type for FFI errors. These errors occur at the UniFFI level, not
// the library level.
private enum UniffiInternalError: LocalizedError {
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

private let CALL_SUCCESS: Int8 = 0
private let CALL_ERROR: Int8 = 1
private let CALL_PANIC: Int8 = 2

private extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            errorBuf: RustBuffer(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

private func rustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: {
        $0.deallocate()
        return UniffiInternalError.unexpectedRustCallError
    })
}

private func rustCallWithError<T, E: ViaFfiUsingByteBuffer & Error>(_: E.Type, _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: { try E.lift($0) })
}

private func makeRustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T, errorHandler: (RustBuffer) throws -> Error) throws -> T {
    var callStatus = RustCallStatus()
    let returnedVal = callback(&callStatus)
    switch callStatus.code {
    case CALL_SUCCESS:
        return returnedVal

    case CALL_ERROR:
        throw try errorHandler(callStatus.errorBuf)

    case CALL_PANIC:
        // When the rust code sees a panic, it tries to construct a RustBuffer
        // with the message.  But if that code panics, then it just sends back
        // an empty buffer.
        if callStatus.errorBuf.len > 0 {
            throw UniffiInternalError.rustPanic(try String.lift(callStatus.errorBuf))
        } else {
            callStatus.errorBuf.deallocate()
            throw UniffiInternalError.rustPanic("Rust panic")
        }

    default:
        throw UniffiInternalError.unexpectedRustCallStatusCode
    }
}

// Protocols for converters we'll implement in templates

private protocol FfiConverter {
    associatedtype SwiftType
    associatedtype FfiType

    static func lift(_ ffiValue: FfiType) throws -> SwiftType
    static func lower(_ value: SwiftType) -> FfiType

    static func read(from: Reader) throws -> SwiftType
    static func write(_ value: SwiftType, into: Writer)
}

private protocol FfiConverterUsingByteBuffer: FfiConverter where FfiType == RustBuffer {
    // Empty, because we want to declare some helper methods in the extension below.
}

extension FfiConverterUsingByteBuffer {
    static func lower(_ value: SwiftType) -> FfiType {
        let writer = Writer()
        Self.write(value, into: writer)
        return RustBuffer(bytes: writer.bytes)
    }

    static func lift(_ buf: FfiType) throws -> SwiftType {
        let reader = Reader(data: Data(rustBuffer: buf))
        let value = try Self.read(from: reader)
        if reader.hasRemaining() {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }
}

// Helpers for structural types. Note that because of canonical_names, it /should/ be impossible
// to make another `FfiConverterSequence` etc just using the UDL.
private enum FfiConverterSequence {
    static func write<T>(_ value: [T], into buf: Writer, writeItem: (T, Writer) -> Void) {
        let len = Int32(value.count)
        buf.writeInt(len)
        for item in value {
            writeItem(item, buf)
        }
    }

    static func read<T>(from buf: Reader, readItem: (Reader) throws -> T) throws -> [T] {
        let len: Int32 = try buf.readInt()
        var seq = [T]()
        seq.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            seq.append(try readItem(buf))
        }
        return seq
    }
}

private enum FfiConverterOptional {
    static func write<T>(_ value: T?, into buf: Writer, writeItem: (T, Writer) -> Void) {
        guard let value = value else {
            buf.writeInt(Int8(0))
            return
        }
        buf.writeInt(Int8(1))
        writeItem(value, buf)
    }

    static func read<T>(from buf: Reader, readItem: (Reader) throws -> T) throws -> T? {
        switch try buf.readInt() as Int8 {
        case 0: return nil
        case 1: return try readItem(buf)
        default: throw UniffiInternalError.unexpectedOptionalTag
        }
    }
}

private enum FfiConverterDictionary {
    static func write<T>(_ value: [String: T], into buf: Writer, writeItem: (String, T, Writer) -> Void) {
        let len = Int32(value.count)
        buf.writeInt(len)
        for (key, value) in value {
            writeItem(key, value, buf)
        }
    }

    static func read<T>(from buf: Reader, readItem: (Reader) throws -> (String, T)) throws -> [String: T] {
        let len: Int32 = try buf.readInt()
        var dict = [String: T]()
        dict.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            let (key, value) = try readItem(buf)
            dict[key] = value
        }
        return dict
    }
}

// Public interface members begin here.

// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.

public enum BridgeType {
    case fcm
    case adm
    case apns
    case test
}

extension BridgeType: ViaFfiUsingByteBuffer, ViaFfi {
    fileprivate static func read(from buf: Reader) throws -> BridgeType {
        let variant: Int32 = try buf.readInt()
        switch variant {
        case 1: return .fcm
        case 2: return .adm
        case 3: return .apns
        case 4: return .test
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    fileprivate func write(into buf: Writer) {
        switch self {
        case .fcm:
            buf.writeInt(Int32(1))

        case .adm:
            buf.writeInt(Int32(2))

        case .apns:
            buf.writeInt(Int32(3))

        case .test:
            buf.writeInt(Int32(4))
        }
    }
}

extension BridgeType: Equatable, Hashable {}

public protocol PushManagerProtocol {
    func subscribe(channelId: String, scope: String, appServerSey: String?) throws -> SubscriptionResponse
    func unsubscribe(channelId: String) throws -> Bool
    func unsubscribeAll() throws
    func update(registrationToken: String) throws -> Bool
    func verifyConnection() throws -> [PushSubscriptionChanged]
    func decrypt(channelId: String, body: String, encoding: String, salt: String, dh: String) throws -> [Int8]
    func dispatchInfoForChid(channelId: String) throws -> DispatchInfo?
}

public class PushManager: PushManagerProtocol {
    fileprivate let pointer: UnsafeMutableRawPointer

    // TODO: We'd like this to be `private` but for Swifty reasons,
    // we can't implement `ViaFfi` without making this `required` and we can't
    // make it `required` without making it `public`.
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    public convenience init(senderId: String, serverHost: String = "updates.push.services.mozilla.com", httpProtocol: String = "https", bridgeType: BridgeType, registrationId: String = "", databasePath: String = "push.sqlite") throws {
        self.init(unsafeFromRawPointer: try

            rustCallWithError(PushError.self) {
                push_7ba2_PushManager_new(senderId.lower(), serverHost.lower(), httpProtocol.lower(), bridgeType.lower(), registrationId.lower(), databasePath.lower(), $0)
            })
    }

    deinit {
        try! rustCall { ffi_push_7ba2_PushManager_object_free(pointer, $0) }
    }

    public func subscribe(channelId: String = "", scope: String = "", appServerSey: String? = nil) throws -> SubscriptionResponse {
        let _retval = try
            rustCallWithError(PushError.self) {
                push_7ba2_PushManager_subscribe(self.pointer, channelId.lower(), scope.lower(), FfiConverterOptionString.lower(appServerSey), $0)
            }
        return try SubscriptionResponse.lift(_retval)
    }

    public func unsubscribe(channelId: String) throws -> Bool {
        let _retval = try
            rustCallWithError(PushError.self) {
                push_7ba2_PushManager_unsubscribe(self.pointer, channelId.lower(), $0)
            }
        return try Bool.lift(_retval)
    }

    public func unsubscribeAll() throws {
        try
            rustCallWithError(PushError.self) {
                push_7ba2_PushManager_unsubscribe_all(self.pointer, $0)
            }
    }

    public func update(registrationToken: String) throws -> Bool {
        let _retval = try
            rustCallWithError(PushError.self) {
                push_7ba2_PushManager_update(self.pointer, registrationToken.lower(), $0)
            }
        return try Bool.lift(_retval)
    }

    public func verifyConnection() throws -> [PushSubscriptionChanged] {
        let _retval = try
            rustCallWithError(PushError.self) {
                push_7ba2_PushManager_verify_connection(self.pointer, $0)
            }
        return try FfiConverterSequenceRecordPushSubscriptionChanged.lift(_retval)
    }

    public func decrypt(channelId: String, body: String, encoding: String = "aes128gcm", salt: String = "", dh: String = "") throws -> [Int8] {
        let _retval = try
            rustCallWithError(PushError.self) {
                push_7ba2_PushManager_decrypt(self.pointer, channelId.lower(), body.lower(), encoding.lower(), salt.lower(), dh.lower(), $0)
            }
        return try FfiConverterSequenceInt8.lift(_retval)
    }

    public func dispatchInfoForChid(channelId: String) throws -> DispatchInfo? {
        let _retval = try
            rustCallWithError(PushError.self) {
                push_7ba2_PushManager_dispatch_info_for_chid(self.pointer, channelId.lower(), $0)
            }
        return try FfiConverterOptionRecordDispatchInfo.lift(_retval)
    }
}

private extension PushManager {
    typealias FfiType = UnsafeMutableRawPointer

    static func read(from buf: Reader) throws -> Self {
        let v: UInt64 = try buf.readInt()
        // The Rust code won't compile if a pointer won't fit in a UInt64.
        // We have to go via `UInt` because that's the thing that's the size of a pointer.
        let ptr = UnsafeMutableRawPointer(bitPattern: UInt(truncatingIfNeeded: v))
        if ptr == nil {
            throw UniffiInternalError.unexpectedNullPointer
        }
        return try lift(ptr!)
    }

    func write(into buf: Writer) {
        // This fiddling is because `Int` is the thing that's the same size as a pointer.
        // The Rust code won't compile if a pointer won't fit in a `UInt64`.
        buf.writeInt(UInt64(bitPattern: Int64(Int(bitPattern: lower()))))
    }

    static func lift(_ pointer: UnsafeMutableRawPointer) throws -> Self {
        return Self(unsafeFromRawPointer: pointer)
    }

    func lower() -> UnsafeMutableRawPointer {
        return pointer
    }
}

// Ideally this would be `fileprivate`, but Swift says:
// """
// 'private' modifier cannot be used with extensions that declare protocol conformances
// """
extension PushManager: ViaFfi, Serializable {}

public struct DispatchInfo {
    public var scope: String
    public var endpoint: String
    public var appServerKey: String?

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(scope: String, endpoint: String, appServerKey: String?) {
        self.scope = scope
        self.endpoint = endpoint
        self.appServerKey = appServerKey
    }
}

extension DispatchInfo: Equatable, Hashable {
    public static func == (lhs: DispatchInfo, rhs: DispatchInfo) -> Bool {
        if lhs.scope != rhs.scope {
            return false
        }
        if lhs.endpoint != rhs.endpoint {
            return false
        }
        if lhs.appServerKey != rhs.appServerKey {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(scope)
        hasher.combine(endpoint)
        hasher.combine(appServerKey)
    }
}

private extension DispatchInfo {
    static func read(from buf: Reader) throws -> DispatchInfo {
        return try DispatchInfo(
            scope: String.read(from: buf),
            endpoint: String.read(from: buf),
            appServerKey: FfiConverterOptionString.read(from: buf)
        )
    }

    func write(into buf: Writer) {
        scope.write(into: buf)
        endpoint.write(into: buf)
        FfiConverterOptionString.write(appServerKey, into: buf)
    }
}

extension DispatchInfo: ViaFfiUsingByteBuffer, ViaFfi {}

public struct KeyInfo {
    public var auth: String
    public var p256dh: String

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(auth: String, p256dh: String) {
        self.auth = auth
        self.p256dh = p256dh
    }
}

extension KeyInfo: Equatable, Hashable {
    public static func == (lhs: KeyInfo, rhs: KeyInfo) -> Bool {
        if lhs.auth != rhs.auth {
            return false
        }
        if lhs.p256dh != rhs.p256dh {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(auth)
        hasher.combine(p256dh)
    }
}

private extension KeyInfo {
    static func read(from buf: Reader) throws -> KeyInfo {
        return try KeyInfo(
            auth: String.read(from: buf),
            p256dh: String.read(from: buf)
        )
    }

    func write(into buf: Writer) {
        auth.write(into: buf)
        p256dh.write(into: buf)
    }
}

extension KeyInfo: ViaFfiUsingByteBuffer, ViaFfi {}

public struct SubscriptionInfo {
    public var endpoint: String
    public var keys: KeyInfo

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(endpoint: String, keys: KeyInfo) {
        self.endpoint = endpoint
        self.keys = keys
    }
}

extension SubscriptionInfo: Equatable, Hashable {
    public static func == (lhs: SubscriptionInfo, rhs: SubscriptionInfo) -> Bool {
        if lhs.endpoint != rhs.endpoint {
            return false
        }
        if lhs.keys != rhs.keys {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(endpoint)
        hasher.combine(keys)
    }
}

private extension SubscriptionInfo {
    static func read(from buf: Reader) throws -> SubscriptionInfo {
        return try SubscriptionInfo(
            endpoint: String.read(from: buf),
            keys: KeyInfo.read(from: buf)
        )
    }

    func write(into buf: Writer) {
        endpoint.write(into: buf)
        keys.write(into: buf)
    }
}

extension SubscriptionInfo: ViaFfiUsingByteBuffer, ViaFfi {}

public struct SubscriptionResponse {
    public var channelId: String
    public var subscriptionInfo: SubscriptionInfo

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(channelId: String, subscriptionInfo: SubscriptionInfo) {
        self.channelId = channelId
        self.subscriptionInfo = subscriptionInfo
    }
}

extension SubscriptionResponse: Equatable, Hashable {
    public static func == (lhs: SubscriptionResponse, rhs: SubscriptionResponse) -> Bool {
        if lhs.channelId != rhs.channelId {
            return false
        }
        if lhs.subscriptionInfo != rhs.subscriptionInfo {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(channelId)
        hasher.combine(subscriptionInfo)
    }
}

private extension SubscriptionResponse {
    static func read(from buf: Reader) throws -> SubscriptionResponse {
        return try SubscriptionResponse(
            channelId: String.read(from: buf),
            subscriptionInfo: SubscriptionInfo.read(from: buf)
        )
    }

    func write(into buf: Writer) {
        channelId.write(into: buf)
        subscriptionInfo.write(into: buf)
    }
}

extension SubscriptionResponse: ViaFfiUsingByteBuffer, ViaFfi {}

public struct PushSubscriptionChanged {
    public var channelId: String
    public var scope: String

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(channelId: String, scope: String) {
        self.channelId = channelId
        self.scope = scope
    }
}

extension PushSubscriptionChanged: Equatable, Hashable {
    public static func == (lhs: PushSubscriptionChanged, rhs: PushSubscriptionChanged) -> Bool {
        if lhs.channelId != rhs.channelId {
            return false
        }
        if lhs.scope != rhs.scope {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(channelId)
        hasher.combine(scope)
    }
}

private extension PushSubscriptionChanged {
    static func read(from buf: Reader) throws -> PushSubscriptionChanged {
        return try PushSubscriptionChanged(
            channelId: String.read(from: buf),
            scope: String.read(from: buf)
        )
    }

    func write(into buf: Writer) {
        channelId.write(into: buf)
        scope.write(into: buf)
    }
}

extension PushSubscriptionChanged: ViaFfiUsingByteBuffer, ViaFfi {}

public enum PushError {
    // Simple error enums only carry a message
    case GeneralError(message: String)

    // Simple error enums only carry a message
    case CryptoError(message: String)

    // Simple error enums only carry a message
    case CommunicationError(message: String)

    // Simple error enums only carry a message
    case CommunicationServerError(message: String)

    // Simple error enums only carry a message
    case AlreadyRegisteredError(message: String)

    // Simple error enums only carry a message
    case StorageError(message: String)

    // Simple error enums only carry a message
    case RecordNotFoundError(message: String)

    // Simple error enums only carry a message
    case StorageSqlError(message: String)

    // Simple error enums only carry a message
    case MissingRegistrationTokenError(message: String)

    // Simple error enums only carry a message
    case TranscodingError(message: String)

    // Simple error enums only carry a message
    case UrlParseError(message: String)

    // Simple error enums only carry a message
    case JsonDeserializeError(message: String)

    // Simple error enums only carry a message
    case UaidNotRecognizedError(message: String)

    // Simple error enums only carry a message
    case RequestError(message: String)

    // Simple error enums only carry a message
    case OpenDatabaseError(message: String)
}

extension PushError: ViaFfiUsingByteBuffer, ViaFfi {
    fileprivate static func read(from buf: Reader) throws -> PushError {
        let variant: Int32 = try buf.readInt()
        switch variant {
        case 1: return .GeneralError(
                message: try String.read(from: buf)
            )

        case 2: return .CryptoError(
                message: try String.read(from: buf)
            )

        case 3: return .CommunicationError(
                message: try String.read(from: buf)
            )

        case 4: return .CommunicationServerError(
                message: try String.read(from: buf)
            )

        case 5: return .AlreadyRegisteredError(
                message: try String.read(from: buf)
            )

        case 6: return .StorageError(
                message: try String.read(from: buf)
            )

        case 7: return .RecordNotFoundError(
                message: try String.read(from: buf)
            )

        case 8: return .StorageSqlError(
                message: try String.read(from: buf)
            )

        case 9: return .MissingRegistrationTokenError(
                message: try String.read(from: buf)
            )

        case 10: return .TranscodingError(
                message: try String.read(from: buf)
            )

        case 11: return .UrlParseError(
                message: try String.read(from: buf)
            )

        case 12: return .JsonDeserializeError(
                message: try String.read(from: buf)
            )

        case 13: return .UaidNotRecognizedError(
                message: try String.read(from: buf)
            )

        case 14: return .RequestError(
                message: try String.read(from: buf)
            )

        case 15: return .OpenDatabaseError(
                message: try String.read(from: buf)
            )

        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    fileprivate func write(into buf: Writer) {
        switch self {
        case let .GeneralError(message):
            buf.writeInt(Int32(1))
            message.write(into: buf)
        case let .CryptoError(message):
            buf.writeInt(Int32(2))
            message.write(into: buf)
        case let .CommunicationError(message):
            buf.writeInt(Int32(3))
            message.write(into: buf)
        case let .CommunicationServerError(message):
            buf.writeInt(Int32(4))
            message.write(into: buf)
        case let .AlreadyRegisteredError(message):
            buf.writeInt(Int32(5))
            message.write(into: buf)
        case let .StorageError(message):
            buf.writeInt(Int32(6))
            message.write(into: buf)
        case let .RecordNotFoundError(message):
            buf.writeInt(Int32(7))
            message.write(into: buf)
        case let .StorageSqlError(message):
            buf.writeInt(Int32(8))
            message.write(into: buf)
        case let .MissingRegistrationTokenError(message):
            buf.writeInt(Int32(9))
            message.write(into: buf)
        case let .TranscodingError(message):
            buf.writeInt(Int32(10))
            message.write(into: buf)
        case let .UrlParseError(message):
            buf.writeInt(Int32(11))
            message.write(into: buf)
        case let .JsonDeserializeError(message):
            buf.writeInt(Int32(12))
            message.write(into: buf)
        case let .UaidNotRecognizedError(message):
            buf.writeInt(Int32(13))
            message.write(into: buf)
        case let .RequestError(message):
            buf.writeInt(Int32(14))
            message.write(into: buf)
        case let .OpenDatabaseError(message):
            buf.writeInt(Int32(15))
            message.write(into: buf)
        }
    }
}

extension PushError: Equatable, Hashable {}

extension PushError: Error {}
extension Int8: Primitive, ViaFfi {
    fileprivate static func read(from buf: Reader) throws -> Self {
        return try lift(buf.readInt())
    }

    fileprivate func write(into buf: Writer) {
        buf.writeInt(lower())
    }
}

extension Bool: ViaFfi {
    fileprivate typealias FfiType = Int8

    fileprivate static func read(from buf: Reader) throws -> Self {
        return try lift(buf.readInt())
    }

    fileprivate func write(into buf: Writer) {
        buf.writeInt(lower())
    }

    fileprivate static func lift(_ v: FfiType) throws -> Self {
        return v != 0
    }

    fileprivate func lower() -> FfiType {
        return self ? 1 : 0
    }
}

extension String: ViaFfi {
    fileprivate typealias FfiType = RustBuffer

    fileprivate static func lift(_ v: FfiType) throws -> Self {
        defer {
            v.deallocate()
        }
        if v.data == nil {
            return String()
        }
        let bytes = UnsafeBufferPointer<UInt8>(start: v.data!, count: Int(v.len))
        return String(bytes: bytes, encoding: String.Encoding.utf8)!
    }

    fileprivate func lower() -> FfiType {
        return utf8CString.withUnsafeBufferPointer { ptr in
            // The swift string gives us int8_t, we want uint8_t.
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                // The swift string gives us a trailing null byte, we don't want it.
                let buf = UnsafeBufferPointer(rebasing: ptr.prefix(upTo: ptr.count - 1))
                return RustBuffer.from(buf)
            }
        }
    }

    fileprivate static func read(from buf: Reader) throws -> Self {
        let len: Int32 = try buf.readInt()
        return String(bytes: try buf.readBytes(count: Int(len)), encoding: String.Encoding.utf8)!
    }

    fileprivate func write(into buf: Writer) {
        let len = Int32(utf8.count)
        buf.writeInt(len)
        buf.writeBytes(utf8)
    }
}

// Helper code for PushManager class is found in ObjectTemplate.swift
// Helper code for DispatchInfo record is found in RecordTemplate.swift
// Helper code for KeyInfo record is found in RecordTemplate.swift
// Helper code for PushSubscriptionChanged record is found in RecordTemplate.swift
// Helper code for SubscriptionInfo record is found in RecordTemplate.swift
// Helper code for SubscriptionResponse record is found in RecordTemplate.swift
// Helper code for BridgeType enum is found in EnumTemplate.swift
// Helper code for PushError error is found in ErrorTemplate.swift

private enum FfiConverterOptionString: FfiConverterUsingByteBuffer {
    typealias SwiftType = String?

    static func write(_ value: SwiftType, into buf: Writer) {
        FfiConverterOptional.write(value, into: buf) { item, buf in
            item.write(into: buf)
        }
    }

    static func read(from buf: Reader) throws -> SwiftType {
        try FfiConverterOptional.read(from: buf) { buf in
            try String.read(from: buf)
        }
    }
}

private enum FfiConverterOptionRecordDispatchInfo: FfiConverterUsingByteBuffer {
    typealias SwiftType = DispatchInfo?

    static func write(_ value: SwiftType, into buf: Writer) {
        FfiConverterOptional.write(value, into: buf) { item, buf in
            item.write(into: buf)
        }
    }

    static func read(from buf: Reader) throws -> SwiftType {
        try FfiConverterOptional.read(from: buf) { buf in
            try DispatchInfo.read(from: buf)
        }
    }
}

private enum FfiConverterSequenceInt8: FfiConverterUsingByteBuffer {
    typealias SwiftType = [Int8]

    static func write(_ value: SwiftType, into buf: Writer) {
        FfiConverterSequence.write(value, into: buf) { item, buf in
            item.write(into: buf)
        }
    }

    static func read(from buf: Reader) throws -> SwiftType {
        try FfiConverterSequence.read(from: buf) { buf in
            try Int8.read(from: buf)
        }
    }
}

private enum FfiConverterSequenceRecordPushSubscriptionChanged: FfiConverterUsingByteBuffer {
    typealias SwiftType = [PushSubscriptionChanged]

    static func write(_ value: SwiftType, into buf: Writer) {
        FfiConverterSequence.write(value, into: buf) { item, buf in
            item.write(into: buf)
        }
    }

    static func read(from buf: Reader) throws -> SwiftType {
        try FfiConverterSequence.read(from: buf) { buf in
            try PushSubscriptionChanged.read(from: buf)
        }
    }
}

/**
 * Top level initializers and tear down methods.
 *
 * This is generated by uniffi.
 */
public enum PushLifecycle {
    /**
     * Initialize the FFI and Rust library. This should be only called once per application.
     */
    func initialize() {
        // No initialization code needed
    }
}
