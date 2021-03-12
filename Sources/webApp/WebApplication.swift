//
//  WebApplication.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation
import Swifter

class WebApplication {

    
    init(_ server: HttpServer) {

        server.GET["/"] = { request, _ in
            let rawPage = Resource.getAppResource(relativePath: "templates/pageResponse.html")
            let template = Template(raw: rawPage)
            
            let canvas = Template.htmlNode(type: "canvas", attributes: ["id":"canvasMap"])
            template.set(variables: ["body": canvas])
            return template.asResponse()
        }
        
        server.GET["js/loadMap.js"] = { request, responseHeaders in
            responseHeaders.addHeader("Content-Type", "text/javascript;charset=UTF-8")
            let jsCode = Resource.getAppResource(relativePath: "templates/loadMap.js")
            return .ok(.text(jsCode))
        }
        
        
        server.notFoundHandler = { request, responseHeaders in
            
            let filePath = Resource.absolutePath(forPublicResource: request.path)
            if FileManager.default.fileExists(atPath: filePath) {

                guard let file = try? filePath.openForReading() else {
                    Logger.error("File", "Could not open `\(filePath)`")
                    return .notFound
                }
                let mimeType = filePath.mimeType()
                responseHeaders.addHeader("Content-Type", mimeType)

                if let attr = try? FileManager.default.attributesOfItem(atPath: filePath),
                    let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                    responseHeaders.addHeader("Content-Length", String(fileSize))
                }

                return .raw(200, "OK", { writer in
                    try writer.write(file)
                    file.close()
                })
            }
            Logger.error("Unhandled request", "File `\(filePath)` doesn't exist")
            return .notFound
        }
        
        server.middleware.append { request, responseHeaders in
            Logger.info("Incoming request", "\(request.method) \(request.path)")
            return nil
        }
    }
}
