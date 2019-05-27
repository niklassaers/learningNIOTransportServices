import Foundation
import NIO
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
        let channel = try bootstrap.connect(host: self.hostname, port: self.port).wait()
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
            .tlsConfigOneTrustedCert()
            //.tlsConfigIgnoreCertificateValidity()
    }

}

extension NIOTSConnectionBootstrap {

    func tlsConfigDefault() -> NIOTSConnectionBootstrap {
        return self.tlsOptions(.init()) // To remove TLS (unencrypted), just return self
    }
    

    class func getCert() -> SecCertificate {
        let path = "/tmp/server.der"
        let data: Data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let cert = SecCertificateCreateWithData(nil, data as CFData)
        return cert!
    }

    
    func tlsConfigOneTrustedCert() -> NIOTSConnectionBootstrap {
        let options = NWProtocolTLS.Options()
        let verifyQueue = DispatchQueue(label: "verifyQueue")
        let mySelfSignedCert: SecCertificate = NIOTSConnectionBootstrap.getCert()
        let verifyBlock: sec_protocol_verify_t = { (metadata, trust, verifyCompleteCB) in
            let actualTrust = sec_trust_copy_ref(trust).takeRetainedValue()
            SecTrustSetAnchorCertificates(actualTrust, [mySelfSignedCert] as CFArray)
            SecTrustSetPolicies(actualTrust, SecPolicyCreateSSL(true, nil))
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
    }

    func tlsConfigIgnoreCertificateValidity() -> NIOTSConnectionBootstrap {
        let options = NWProtocolTLS.Options()
        sec_protocol_options_set_peer_authentication_required(options.securityProtocolOptions, false)

        /*
         sec_protocol_options_set_local_identity(sec_protocol_options_t options, sec_identity_t identity);
         sec_protocol_options_add_tls_ciphersuite(sec_protocol_options_t options, SSLCipherSuite ciphersuite);
         sec_protocol_options_add_tls_ciphersuite_group(sec_protocol_options_t options, SSLCiphersuiteGroup group);
         sec_protocol_options_set_tls_min_version(sec_protocol_options_t options, SSLProtocol version);
         sec_protocol_options_set_tls_max_version(sec_protocol_options_t options, SSLProtocol version);
         sec_protocol_options_add_tls_application_protocol(sec_protocol_options_t options, const char *application_protocol);
         sec_protocol_options_set_tls_server_name(sec_protocol_options_t options, const char *server_name);
         sec_protocol_options_set_tls_diffie_hellman_parameters(sec_protocol_options_t options, dispatch_data_t params);
         sec_protocol_options_add_pre_shared_key(sec_protocol_options_t options, dispatch_data_t psk, dispatch_data_t psk_identity);
         sec_protocol_options_set_tls_tickets_enabled(sec_protocol_options_t options, bool tickets_enabled);
         sec_protocol_options_set_tls_is_fallback_attempt(sec_protocol_options_t options, bool is_fallback_attempt);
         sec_protocol_options_set_tls_resumption_enabled(sec_protocol_options_t options, bool resumption_enabled);
         sec_protocol_options_set_tls_false_start_enabled(sec_protocol_options_t options, bool false_start_enabled);
         sec_protocol_options_set_tls_ocsp_enabled(sec_protocol_options_t options, bool ocsp_enabled);
         sec_protocol_options_set_tls_sct_enabled(sec_protocol_options_t options, bool sct_enabled);
         sec_protocol_options_set_tls_renegotiation_enabled(sec_protocol_options_t options, bool renegotiation_enabled);
         sec_protocol_options_set_peer_authentication_required(sec_protocol_options_t options, bool peer_authentication_required);
         sec_protocol_options_set_key_update_block(sec_protocol_options_t options, sec_protocol_key_update_t key_update_block, dispatch_queue_t key_update_queue);
         sec_protocol_options_set_challenge_block(sec_protocol_options_t options, sec_protocol_challenge_t challenge_block, dispatch_queue_t challenge_queue);
         sec_protocol_options_set_verify_block(sec_protocol_options_t options, sec_protocol_verify_t verify_block, dispatch_queue_t verify_block_queue);

         */
        
        return self.tlsOptions(options)
    }
}
