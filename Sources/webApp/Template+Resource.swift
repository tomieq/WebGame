//
//  Template+Resource.swift
//  
//
//  Created by Tomasz Kucharski on 26/02/2021.
//

import Foundation

extension Template {
    convenience init(from path: String) {
        self.init(raw: Resource.getAppResource(relativePath: path))
    }
}
