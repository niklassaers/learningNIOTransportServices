import NIO
import NIOTransportServices
import Network
import Security
import Dispatch

class SimpleTest {
    
    static func theTest() {
//        let options = NWProtocolTLS.Options()
//        sec_protocol_options_set_peer_authentication_required(options.securityProtocolOptions, false)

        let options = NIOTSConnectionBootstrap.simpleTestOptions()
        
        let group = NIOTSEventLoopGroup()
        NIOTSConnectionBootstrap(group: group).tlsOptions(options).connect(host: "sample.saers.com", port: 4433).whenComplete {
            print($0)
        }
        dispatchMain()
    }
}

extension NIOTSConnectionBootstrap  {
    class func simpleTestOptions() -> NWProtocolTLS.Options {
        let options = NWProtocolTLS.Options()
        let verifyQueue = DispatchQueue(label: "verifyQueue")
        let mySelfSignedCert: SecCertificate = getCert()
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
        return options
    }
}
