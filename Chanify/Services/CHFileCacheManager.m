//
//  CHFileCacheManager.m
//  iOS
//
//  Created by WizJin on 2021/5/18.
//

#import "CHFileCacheManager.h"

@interface CHFileCacheManager ()

@property (nonatomic, assign) NSUInteger totalAllocatedFileSize;

@end

@implementation CHFileCacheManager

- (instancetype)initWithFileBase:(NSURL *)fileBaseDir {
    if (self = [super init]) {
        _uid = nil;
        _fileBaseDir = fileBaseDir;
        _dataCache = [NSCache new];
        _totalAllocatedFileSize = 0;
        self.dataCache.countLimit = kCHWebFileCacheMaxN;
        [NSFileManager.defaultManager fixDirectory:self.fileBaseDir];
    }
    return self;
}

- (NSUInteger)allocatedFileSize {
    if (_totalAllocatedFileSize <= 0) {
        NSUInteger size = 0;
        NSArray *fieldKeys = @[NSURLIsRegularFileKey, NSURLTotalFileAllocatedSizeKey];
        NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtURL:self.fileBaseDir includingPropertiesForKeys:fieldKeys options:0 errorHandler:nil];
        for (NSURL *url in enumerator) {
            NSDictionary *fields = [url resourceValuesForKeys:fieldKeys error:nil];
            if ([[fields valueForKey:NSURLIsRegularFileKey] boolValue]) {
                size += [[fields valueForKey:NSURLTotalFileAllocatedSizeKey] unsignedIntegerValue];
            }
        }
        _totalAllocatedFileSize = size;
    }
    return _totalAllocatedFileSize;
}

- (void)notifyAllocatedFileSizeChanged:(NSURL *)filepath {
    @weakify(self);
    dispatch_main_async(^{
        if (self->_totalAllocatedFileSize > 0) {
            @strongify(self);
            NSNumber *value = nil;
            if ([filepath getResourceValue:&value forKey:NSURLTotalFileAllocatedSizeKey error:nil]) {
                self->_totalAllocatedFileSize += [value unsignedIntegerValue];
            }
        }
        [self sendNotifyWithSelector:@selector(fileCacheAllocatedFileSizeChanged:) withObject:self];
    });
}

- (void)setNeedUpdateAllocatedFileSize {
    @weakify(self);
    dispatch_main_async(^{
        @strongify(self);
        self->_totalAllocatedFileSize = 0;
        [self sendNotifyWithSelector:@selector(fileCacheAllocatedFileSizeChanged:) withObject:self];
    });
}

- (NSDirectoryEnumerator *)fileEnumerator {
    return [NSFileManager.defaultManager enumeratorAtURL:self.fileBaseDir includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
}


@end