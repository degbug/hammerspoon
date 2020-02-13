//
//  AxUIElementWrap.swift
//  application
//
//  Created by xmly on 2020/2/13.
//  Copyright © 2020 Hammerspoon. All rights reserved.
//

import Foundation

class AxUIElementWrap: NSObject {
    
    init(element: AXUIElement) {
        self.element = element;
    }
    
    @objc
    var element : AXUIElement;
}
