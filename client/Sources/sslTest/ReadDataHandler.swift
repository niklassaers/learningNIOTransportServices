import Foundation
import NIO

class ReadDataHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    var dataBuffer: [UInt8] = []

    var dataReceivedBlock: (([UInt8]) -> Void)?

    func channelActive(ctx: ChannelHandlerContext) {
        ctx.fireChannelActive()
    }

    func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {

        defer {
            ctx.fireChannelRead(data)
        }

        let buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes

        if readableBytes == 0 {
            print("nothing left to read, close the channel")
            ctx.close(promise: nil)
            return
        }

        let bytes = buffer.getBytes(at: 0, length: readableBytes) ?? []

        if readableBytes <= 4 { // It's just a small message, pass it along without further testing
            dataReceivedBlock?(bytes)
            return
        }

        self.dataBuffer.append(contentsOf: bytes)

        // By this time we know we got a full message, so pass it back
        let receivedBuffer = self.dataBuffer
        self.dataBuffer = []
        dataReceivedBlock?(receivedBuffer)
    }

    func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        print("error: \(error.localizedDescription)")
        ctx.close(promise: nil)
    }

}
