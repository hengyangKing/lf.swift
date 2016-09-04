import Foundation

protocol RTSPSocketDelegate: class {
    func listen(_ response:RTSPResponse)
}

// MARK: -
final class RTSPSocket: NetSocket {
    static internal let defaultPort:Int = 554

    weak internal var delegate:RTSPSocketDelegate?
    fileprivate var requests:[RTSPRequest] = []

    override internal var connected:Bool {
        didSet {
            if (connected) {
                for request in requests {
                    if (logger.isEnabledForLogLevel(.verbose)) {
                        logger.verbose("\(request)")
                    }
                    doOutput(bytes: request.bytes)
                }
                requests.removeAll()
            }
        }
    }

    internal func doOutput(_ request:RTSPRequest) {
        if (connected) {
            if (logger.isEnabledForLogLevel(.verbose)) {
                logger.verbose("\(request)")
            }
            doOutput(bytes: request.bytes)
            return
        }
        requests.append(request)
        guard let uri:URL = URL(string: request.uri), let host:String = uri.host else {
            return
        }
        connect(host, port: (uri as NSURL).port?.intValue ?? RTSPSocket.defaultPort)
    }

    override internal func listen() {
        guard let response:RTSPResponse = RTSPResponse(bytes: inputBuffer) else {
            return
        }
        if (logger.isEnabledForLogLevel(.verbose)) {
            logger.verbose("\(response)")
        }
        delegate?.listen(response)
        inputBuffer.removeAll()
    }

    fileprivate func connect(_ hostname:String, port:Int) {
        networkQueue.async {
            Stream.getStreamsToHost(
                withName: hostname,
                port: port,
                inputStream: &self.inputStream,
                outputStream: &self.outputStream
            )
            self.initConnection()
        }
    }
}