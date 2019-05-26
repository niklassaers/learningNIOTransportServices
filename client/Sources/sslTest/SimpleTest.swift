import NIO
import NIOTransportServices
import Network
import Security
import Dispatch

class SimpleTest {
    
    static func theTest() {
        let options = NWProtocolTLS.Options()
        sec_protocol_options_set_peer_authentication_required(options.securityProtocolOptions, false)
        
        let group = NIOTSEventLoopGroup()
        NIOTSConnectionBootstrap(group: group).tlsOptions(options).connect(host: "sample.saers.com", port: 4433).whenComplete {
            print($0)
        }
        dispatchMain()
    }
}

