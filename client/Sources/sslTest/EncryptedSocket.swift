import Foundation
import NIO
//import NIOExtras
//import NIOSSL
//import NIOTLS
import NIOTransportServices
import Network

public typealias Byte = UInt8

public class EncryptedSocket {

    let hostname: String
    let port: Int

    var group: EventLoopGroup?
    var bootstrap: NIOTSConnectionBootstrap?
    var channel: Channel?

    var readGroup: DispatchGroup?
    var receivedData: [UInt8] = []

    fileprivate static let readBufferSize = 8192

    public init(hostname: String, port: Int) throws {
        self.hostname = hostname
        self.port = port
    }

    public func connect(timeout: Int) throws {

        let dataHandler = ReadDataHandler()
        let leave = { [weak self] (identifier: String) in
            self?.readGroup?.leave()
        }

        dataHandler.dataReceivedBlock = { data in
            self.receivedData = data
            leave("leave")
        }

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group
        let bootstrap = setupBootstrap(group, dataHandler)
        self.bootstrap = bootstrap
        let channel = try bootstrap.connect(host: hostname, port: port).wait()
        self.channel = channel
    }

    public func disconnect() {
        try? channel?.close(mode: .all).wait()
        try? group?.syncShutdownGracefully()
    }

    public func send(bytes: [Byte]) throws {

        guard let channel = channel else { return }

        var buffer = channel.allocator.buffer(capacity: bytes.count)
        buffer.writeBytes(bytes)
        _ = channel.writeAndFlush(buffer)
    }

    public func receive(expectedNumberOfBytes: Int32) throws -> [Byte] {

        if self.readGroup != nil {
            print("Error: already reading")
            return []
        }
        self.readGroup = DispatchGroup()
        self.readGroup?.enter()

        self.channel?.read()
        self.readGroup?.wait()
        self.readGroup = nil

        let outData = self.receivedData
        self.receivedData = []
        return outData
    }

    func setupBootstrap(_ group: MultiThreadedEventLoopGroup, _ dataHandler: ReadDataHandler) -> (NIOTSConnectionBootstrap) {

        let overrideGroup = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .utility)

        return NIOTSConnectionBootstrap(group: overrideGroup)
            .channelInitializer { channel in
                return channel.pipeline.addHandlers([dataHandler], position: .last)
            }
            .tlsConfigIgnoreCertificateValidity()
    }

}

extension NIOTSConnectionBootstrap {

    func tlsConfigDefault() -> NIOTSConnectionBootstrap {
        return self.tlsOptions(.init()) // To remove TLS (unencrypted), just return self
    }

    /*
     func tlsConfigOneTrustedCert() -> NIOTSConnectionBootstrap {
     let options = NWProtocolTLS.Options()
     let verifyQueue = DispatchQueue(label: "verifyQueue")
     let mySelfSignedCert: SecCertificate = getCert() // You must implement this!
     let verifyBlock: sec_protocol_verify_t = { (metadata, trust, verifyCompleteCB) in
     let actualTrust = sec_trust_copy_ref(trust).takeRetainedValue()
     SecTrustSetAnchorCertificates(actualTrust, [mySelfSignedCert] as CFArray)
     SecTrustEvaluateAsync(actualTrust, verifyQueue) { (_, result) in
     switch result {
     case .proceed, .unspecified:
     verifyCompleteCB(true)
     default:
     verifyCompleteCB(false)
     }
     }
     }
     
     sec_protocol_options_set_verify_block(options.securityProtocolOptions, verifyBlock, verifyQueue)
     return self.tlsOptions(options)
     }*/

    func tlsConfigIgnoreCertificateValidity() -> NIOTSConnectionBootstrap {
        let options = NWProtocolTLS.Options()
        sec_protocol_options_set_peer_authentication_required(options.securityProtocolOptions, false)

        return self.tlsOptions(options)
    }
}
