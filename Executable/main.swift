import Dispatch
import Foundation
import Swifter
import WebGameLib

let server = HttpServer()
let application = WebApplication(server)

do {
    try server.start(5920, forceIPv4: true)
    print("WebGame has started on port = \(try server.port()), workDir = \(FileManager.default.currentDirectoryPath)")
    dispatchMain()
} catch {
    print("WebGame start error: \(error)")
}


