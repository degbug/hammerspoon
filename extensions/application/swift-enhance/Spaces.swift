//
//  Spaces.swift
//  application
//
//  Created by xmly on 2020/2/13.
//  Copyright © 2020 Hammerspoon. All rights reserved.
//

import Cocoa
import Foundation

class Spaces : NSObject{
    static var singleSpace = true
    static var currentSpaceId = CGSSpaceID(1)
    static var currentSpaceIndex = SpaceIndex(1)

     public static func allIdsAndIndexes() -> [(CGSSpaceID, SpaceIndex)] {
        return (CGSCopyManagedDisplaySpaces(cgsMainConnectionId) as! [NSDictionary])
                .map { return $0["Spaces"] }.joined().enumerated()
                .map { (($0.element as! NSDictionary)["id64"]! as! CGSSpaceID, $0.offset + 1) }
        
    }
    
    
    @objc static func windowsInSpaces(_ spaceIds: [CGSSpaceID]) -> [CGWindowID] {
        var set_tags = UInt64(0)
        var clear_tags = UInt64(0)
        return CGSCopyWindowsWithOptionsAndTags(cgsMainConnectionId, 0, spaceIds as CFArray, 2, &set_tags, &clear_tags) as! [CGWindowID]
    }
    
   
}

typealias SpaceIndex = Int
