
//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.

#import "TUIGroupService_Minimalist.h"
#import <TIMCommon/TIMDefine.h>
#import <TUICore/NSDictionary+TUISafe.h>
#import <TUICore/TUIGlobalization.h>
#import <TUICore/TUIThemeManager.h>
#import "TUIGroupInfoController_Minimalist.h"
#import "TUIGroupRequestViewController_Minimalist.h"
#import "TUISelectGroupMemberViewController_Minimalist.h"

@implementation TUIGroupService_Minimalist

+ (void)load {
    [TUICore registerService:TUICore_TUIGroupService_Minimalist object:[TUIGroupService_Minimalist shareInstance]];
}

+ (TUIGroupService_Minimalist *)shareInstance {
    static dispatch_once_t onceToken;
    static TUIGroupService_Minimalist *g_sharedInstance = nil;
    dispatch_once(&onceToken, ^{
      g_sharedInstance = [[TUIGroupService_Minimalist alloc] init];
    });
    return g_sharedInstance;
}

- (void)createGroup:(NSString *)groupType
       createOption:(V2TIMGroupAddOpt)createOption
           contacts:(NSArray<TUICommonContactSelectCellData *> *)contacts
         completion:(void (^)(BOOL success, NSString *groupID, NSString *groupName))completion {
    NSString *loginUser = [[V2TIMManager sharedInstance] getLoginUser];
    [[V2TIMManager sharedInstance] getUsersInfo:@[ loginUser ]
        succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
          NSString *showName = loginUser;
          if (infoList.firstObject.nickName.length > 0) {
              showName = infoList.firstObject.nickName;
          }
          NSMutableString *groupName = [NSMutableString stringWithString:showName];
          NSMutableArray *members = [NSMutableArray array];
          for (TUICommonContactSelectCellData *item in contacts) {
              V2TIMCreateGroupMemberInfo *member = [[V2TIMCreateGroupMemberInfo alloc] init];
              member.userID = item.identifier;
              member.role = V2TIM_GROUP_MEMBER_ROLE_MEMBER;
              [groupName appendFormat:@"、%@", item.title];
              [members addObject:member];
          }

          if ([groupName length] > 10) {
              groupName = [groupName substringToIndex:10].mutableCopy;
          }

          V2TIMGroupInfo *info = [[V2TIMGroupInfo alloc] init];
          info.groupName = groupName;
          info.groupType = groupType;
          if (![info.groupType isEqualToString:GroupType_Work]) {
              info.groupAddOpt = createOption;
          }

          [[V2TIMManager sharedInstance] createGroup:info
              memberList:members
              succ:^(NSString *groupID) {
                NSString *content = TIMCommonLocalizableString(TUIGroupCreateTipsMessage);
                if ([info.groupType isEqualToString:GroupType_Community]) {
                    content = TIMCommonLocalizableString(TUICommunityCreateTipsMessage);
                }
                NSDictionary *dic = @{
                    @"version" : @(GroupCreate_Version),
                    BussinessID : BussinessID_GroupCreate,
                    @"opUser" : showName,
                    @"content" : content,
                    @"cmd" : [info.groupType isEqualToString:GroupType_Community] ? @1 : @0
                };
                NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
                V2TIMMessage *msg = [[V2TIMManager sharedInstance] createCustomMessage:data];
                [[V2TIMManager sharedInstance] sendMessage:msg
                                                  receiver:nil
                                                   groupID:groupID
                                                  priority:V2TIM_PRIORITY_DEFAULT
                                            onlineUserOnly:NO
                                           offlinePushInfo:nil
                                                  progress:nil
                                                      succ:nil
                                                      fail:nil];
                // wait for a second to ensure the group created message arrives first
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  if (completion) {
                      completion(YES, groupID, groupName);
                  }
                });
              }
              fail:^(int code, NSString *msg) {
                if (completion) {
                    completion(NO, nil, nil);
                }
                if (code == ERR_SDK_INTERFACE_NOT_SUPPORT) {
                    [TUITool postUnsupportNotificationOfService:TIMCommonLocalizableString(TUIKitErrorUnsupportIntefaceCommunity)
                                                    serviceDesc:TIMCommonLocalizableString(TUIKitErrorUnsupportIntefaceCommunityDesc)
                                                      debugOnly:YES];
                }
              }];
        }
        fail:^(int code, NSString *msg) {
          if (completion) {
              completion(NO, nil, nil);
          }
        }];
}

#pragma mark - TUIServiceProtocol
- (id)onCall:(NSString *)method param:(NSDictionary *)param {
    id returnObject = nil;
    if ([method isEqualToString:TUICore_TUIGroupService_CreateGroupMethod]) {
        NSString *groupType = [param tui_objectForKey:TUICore_TUIGroupService_CreateGroupMethod_GroupTypeKey asClass:NSString.class];
        NSNumber *option = [param tui_objectForKey:TUICore_TUIGroupService_CreateGroupMethod_OptionKey asClass:NSNumber.class];
        NSArray *contacts = [param tui_objectForKey:TUICore_TUIGroupService_CreateGroupMethod_ContactsKey asClass:NSArray.class];
        void (^completion)(BOOL, NSString *, NSString *) = [param objectForKey:TUICore_TUIGroupService_CreateGroupMethod_CompletionKey];

        [self createGroup:groupType createOption:[option intValue] contacts:contacts completion:completion];
    }
    return returnObject;
}
@end
