//
//  Template+HttpResponse.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

import Foundation
import Swifter

extension Template {
    func asResponse() -> HttpResponse {
        if let data = self.output().data(using: .utf8) {
            return .raw(200, "OK", { writer in
                try? writer.write(data)
            })
        }
        return .noContent
    }
}
