//
//  DispatchQueueExtension.swift
//  Nappa
//
//  Created by Alexandre Tavares on 17/02/17.
//  Copyright © 2017 Nappa. All rights reserved.
//

import Dispatch
import Foundation

public extension DispatchQueue {
    public static var userInteractive: DispatchQueue { return DispatchQueue.global(qos: .userInteractive) }
    public static var userInitiated: DispatchQueue { return DispatchQueue.global(qos: .userInitiated) }
    public static var utility: DispatchQueue { return DispatchQueue.global(qos: .utility) }
    public static var background: DispatchQueue { return DispatchQueue.global(qos: .background) }

    public func after(_ delay: TimeInterval, execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + delay, execute: closure)
    }
}
