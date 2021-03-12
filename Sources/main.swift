import Dispatch
import Foundation
import Swifter

let server = HttpServer()
let application = WebApplication(server)

let semaphore = DispatchSemaphore(value: 0)
do {
    try server.start(5920, forceIPv4: true)
    print("WebGame has started on port = \(try server.port()), workDir = \(FileManager.default.currentDirectoryPath)")
    semaphore.wait()
} catch {
    print("WebGame start error: \(error)")
    semaphore.signal()
}


