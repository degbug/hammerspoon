//
//  WindowsHelper.swift
//  application
// 默认的AXUIElementCopyAttributeValues(app, kAXWindowsAttribute, 0, 100, &windows)
// 获取的只能是当前space中窗体，全屏或者前台space中的窗体无法获取
// 这里参考https://github.com/lwouis/alt-tab-macos/issues/14 的解决方案，copy了大部分代码，实现获取应用的所有窗体
//
//
//  Created by xmly on 2020/2/13.
//  Copyright © 2020 Hammerspoon. All rights reserved.
//

import Foundation
import AppKit
import _SwiftAppKitOverlayShims


class WindowsHelper: NSObject {
    
    @objc
    public static func getAllWindows(_ axApp: AXUIElement) -> [AxUIElementWrap]{
        
        var pid : pid_t = 0;
        
        AXUIElementGetPid(axApp, &pid)
        
        var windows = [AxUIElementWrap]();
        
        let spaces = Spaces.allIdsAndIndexes()
        Spaces.currentSpaceId = CGSManagedDisplayGetCurrentSpace(cgsMainConnectionId, "Main" as CFString)
        Spaces.currentSpaceIndex = spaces.first { $0.0 == Spaces.currentSpaceId }!.1
        
       let windowsMap = mapWindowsWithRankAndSpace(spaces)
        
        for cgWindow in CGWindow.windows(.optionAll) {
            guard let cgId = cgWindow.value(.number, CGWindowID.self),
                             let ownerPid = cgWindow.value(.ownerPID, pid_t.self),
                             let app = NSRunningApplication(processIdentifier: ownerPid),
                             cgWindow.isNotMenubarOrOthers(),
                             cgWindow.isReasonablyBig() else {
                           continue
                       }
            
            if( pid != ownerPid){
                continue
            }
            
            let axApp = cgId.AXUIElementApplication(ownerPid)
       
            let (spaceId, _, _) = windowsMap[cgId] ?? (nil, nil, nil)
            
            if let (_, _, axWindow) = filter(cgId, spaceId, app, axApp) {
                if(axWindow != nil){
                    windows.append(AxUIElementWrap(element : axWindow!))
                }else{
                    let tmp = cgId.AXUIElementOfOtherSpaceWindow(axApp)
                    if(tmp != nil){
                        windows.append(AxUIElementWrap(element: tmp!))
                    }
                }
            }
        }
        
        return windows;
    }
    
    
    private static func filter(_ cgId: CGWindowID, _ spaceId: CGSSpaceID?, _ app: NSRunningApplication, _ axApp: AXUIElement) -> (Bool, Bool, AXUIElement?)? {
        // window is in another space
        if spaceId != nil && spaceId != Spaces.currentSpaceId {
            return (false, false, nil)
        }
        // window is in the current space, or is hidden/minimized
        if let axWindow = axApp.window(cgId), axWindow.isActualWindow() {
            if spaceId != nil {
                return (false, false, axWindow)
            }
            if app.isHidden {
                return (axWindow.isMinimized(), true, axWindow)
            }
            if axWindow.isMinimized() {
                return (true, false, axWindow)
            }
        }
        return nil
    }
    
    private static func mapWindowsWithRankAndSpace(_ spaces: [(CGSSpaceID, SpaceIndex)]) -> WindowsMap {
           var windowSpaceMap: [CGWindowID: (CGSSpaceID, SpaceIndex, WindowRank?)] = [:]
           for (spaceId, spaceIndex) in spaces {
               Spaces.windowsInSpaces([spaceId]).forEach {
                   windowSpaceMap[$0] = (spaceId, spaceIndex, nil)
               }
           }
           Spaces.windowsInSpaces(spaces.map { $0.0 }).enumerated().forEach {
               windowSpaceMap[$0.element]!.2 = $0.offset
           }
           return windowSpaceMap as! WindowsMap
    }
    
    typealias WindowRank = Int
    typealias WindowsMap = [CGWindowID: (CGSSpaceID, SpaceIndex, WindowRank)]

}
