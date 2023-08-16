//
//  VideoSeatItem.swift
//  TUIVideoSeat
//
//  Created by jack on 2023/3/6.
//  Copyright © 2023 Tencent. All rights reserved.

import Foundation
import TUIRoomEngine

// VideoSeatItem类型
enum VideoSeatItemType {
    case original // 原始
    case share // original -> share
}

class VideoSeatItem: Equatable {
    static func == (lhs: VideoSeatItem, rhs: VideoSeatItem) -> Bool {
        return (lhs.userId == rhs.userId) && (lhs.type == rhs.type)
    }

    private var itemType: VideoSeatItemType = .original
    private var videoStreamType: TUIVideoStreamType = .cameraStream
    private var userInfo: TUIUserInfo
    var isPlaying: Bool = false
    var audioVolume: Int = 0
    weak var boundCell: TUIVideoSeatCell?
    var isSelf: Bool {
        return userInfo.userId == TUIRoomEngine.getSelfInfo().userId
    }
    
    var streamType: TUIVideoStreamType {
        return videoStreamType
    }

    var type: VideoSeatItemType {
        return itemType
    }

    var userId: String {
        return userInfo.userId
    }

    var isRoomOwner: Bool {
        return userRole == .roomOwner
    }

    var userName: String {
        return userInfo.userName
    }

    var avatarUrl: String {
        return userInfo.avatarUrl
    }

    var userRole: TUIRole {
        set {
            userInfo.userRole = newValue
        }
        get {
            return userInfo.userRole
        }
    }

    var hasAudioStream: Bool {
        set {
            userInfo.hasAudioStream = newValue
        }
        get {
            return userInfo.hasAudioStream
        }
    }

    var hasVideoStream: Bool {
        set {
            userInfo.hasVideoStream = newValue
        }
        get {
            return userInfo.hasVideoStream
        }
    }

    var hasScreenStream: Bool {
        set {
            userInfo.hasScreenStream = newValue
        }
        get {
            return userInfo.hasScreenStream
        }
    }

    var isHasVideoStream: Bool {
        return hasVideoStream || hasScreenStream
    }
    
    init(userId: String) {
        userInfo = TUIUserInfo()
        userInfo.userId = userId
    }

    init(userInfo: TUIUserInfo) {
        self.userInfo = userInfo
    }

    func updateUserInfo(_ userInfo: TUIUserInfo) {
        self.userInfo = userInfo
    }

    func cloneShare() -> VideoSeatItem {
        let item = VideoSeatItem(userInfo: userInfo)
        item.videoStreamType = .screenStream
        item.itemType = .share
        return item
    }

    func updateStreamType(streamType: TUIVideoStreamType) {
        if videoStreamType != .screenStream {
            videoStreamType = streamType
        }
    }
}
