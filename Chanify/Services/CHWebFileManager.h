//
//  CHWebFileManager.h
//  Chanify
//
//  Created by WizJin on 2021/4/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CHWebFileItem <NSObject>

- (void)webFileUpdated:(nullable NSURL *)item fileURL:(nullable NSString *)fileURL;
- (void)webFileProgress:(double)progress fileURL:(nullable NSString *)fileURL;

@end

@interface CHWebFileManager : NSObject

@property (nonatomic, nullable, strong) NSString *uid;

+ (instancetype)webFileManagerWithURL:(NSURL *)fileBaseDir userAgent:(NSString *)userAgent;
- (void)close;
- (void)loadFileURL:(nullable NSString *)fileURL filename:(nullable NSString *)filename toItem:(id<CHWebFileItem>)item expectedSize:(uint64_t)expectedSize ;
- (void)resetFileURLFailed:(nullable NSString *)fileURL;

@end

NS_ASSUME_NONNULL_END
