//
//  HttpRequest+extension.swift
//  
//
//  Created by Tomasz Kucharski on 18/03/2021.
//

import Foundation
import Swifter

extension HttpRequest {
    func queryParam(_ name: String) -> String? {
        return self.queryParams.first{ $0.0 == name }?.1
    }
}
