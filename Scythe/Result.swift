//
//  Result.swift
//  Scythe
//
//  Created by Brandon Evans on 2017-01-04.
//  Copyright © 2017 Robots and Pencils. All rights reserved.
//

import Foundation

enum Result<T> {
    case success(T)
    case failure(Error)
}
