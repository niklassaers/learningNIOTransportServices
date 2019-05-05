import XCTest
@testable import sslTest

final class sslTestTests: XCTestCase {
    func testEncryptedSocket() {
        let socket = try! sslTest.EncryptedSocket(hostname: "127.0.0.1", port: 3000)
        try! socket.connect(timeout: 2000)
        let bytes: [sslTest.Byte] = Array("GET /".utf8)
        try! socket.send(bytes: bytes)
        let result = try! socket.receive(expectedNumberOfBytes: 8092)
        XCTAssertNotNil(result)
    }

    static var allTests = [
        ("testEncryptedSocket", testEncryptedSocket),
    ]
}
