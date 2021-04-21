//
//  CHWebObjectManager.h
//  Chanify
//
//  Created by WizJin on 2021/3/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHWebObjectItem <NSObject>

- (void)webObjectUpdated:(nullable id)item fileURL:(nullable NSString *)fileURL;
- (void)webObjectProgress:(double)progress fileURL:(nullable NSString *)fileURL;

@end

@protocol CHWebObjectDecoder <NSObject>

- (nullable id)webObjectDecode:(nullable NSData *)data;

@end

@interface CHWebImageDecoder : NSObject<CHWebObjectDecoder>

@end

@interface CHWebObjectManager<Item> : NSObject

@property (nonatomic, nullable, strong) NSString *uid;

+ (instancetype)webObjectManagerWithURL:(NSURL *)fileBaseDir decoder:(id<CHWebObjectDecoder>)decoder;
- (void)close;
- (void)loadFileURL:(nullable NSString *)fileURL toItem:(id<CHWebObjectItem>)item expectedSize:(uint64_t)expectedSize;
- (void)resetFileURLFailed:(nullable NSString *)fileURL;
- (nullable Item)loadLocalFile:(nullable NSString *)fileURL;
- (nullable NSURL *)localFileURL:(nullable NSString *)fileURL;


@end

NS_ASSUME_NONNULL_END
