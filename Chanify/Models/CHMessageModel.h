//
//  CHMessageModel.h
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHNSDataSource;
@class CHUserDataSource;
@class UNMutableNotificationContent;

typedef NS_ENUM(NSInteger, CHMessageType) {
    CHMessageTypeNone       = -1,
    CHMessageTypeSystem     = 0,
    CHMessageTypeText       = 1,
    CHMessageTypeImage      = 2,
};

@interface CHMessageModel : NSObject

@property (nonatomic, readonly, strong) NSString *mid;
@property (nonatomic, readonly, assign) CHMessageType type;
@property (nonatomic, readonly, strong) NSString *from;
@property (nonatomic, readonly, strong) NSData *channel;
@property (nonatomic, readonly, nullable, strong) NSString *text;

+ (nullable instancetype)modelWithData:(nullable NSData *)data mid:(NSString *)mid;
+ (nullable instancetype)modelWithDS:(CHNSDataSource *)ds uid:(NSString *)uid mid:(NSString *)mid data:(nullable NSData *)data raw:(NSData * _Nullable * _Nullable)raw;
+ (nullable instancetype)modelWithKey:(nullable NSData *)key ds:(CHUserDataSource *)ds mid:(NSString *)mid data:(nullable NSData *)data raw:(NSData * _Nullable * _Nullable)raw;
+ (nullable NSString *)parsePacket:(NSDictionary *)info mid:(NSString * _Nullable * _Nullable)mid data:(NSData * _Nullable * _Nullable)data;
- (void)formatNotification:(UNMutableNotificationContent *)content;


@end

NS_ASSUME_NONNULL_END
