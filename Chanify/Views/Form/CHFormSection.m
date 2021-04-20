//
//  CHFormSection.m
//  Chanify
//
//  Created by WizJin on 2021/3/5.
//

#import "CHFormSection.h"

@interface CHFormSection ()

@property (nonatomic, readonly, strong) NSMutableArray<CHFormItem *> *itemList;
@property (nonatomic, readonly, assign) BOOL isHidden;

@end

@implementation CHFormSection

+ (instancetype)sectionWithTitle:(NSString *)title {
    return [[self.class alloc] initWithTitle:title];
}

+ (instancetype)section {
    return [self.class sectionWithTitle:@""];
}

- (instancetype)initWithTitle:(NSString *)title {
    if (self = [super init]) {
        _title = (title ?: @"");
        _hidden = nil;
        _isHidden = NO;
        _itemList = [NSMutableArray new];
    }
    return self;
}

- (void)updateStatus {
    _isHidden = NO;
    if (self.hidden != nil) {
        _isHidden = [self.hidden evaluateWithObject:self];
    }
}

- (NSArray<CHFormItem *> *)items {
    NSMutableArray<CHFormItem *> *rows = [NSMutableArray arrayWithCapacity:self.itemList.count];
    for (CHFormItem *item in self.itemList) {
        if (!item.isHidden) {
            [rows addObject:item];
        }
    }
    return rows;
}

- (NSArray<CHFormItem *> *)allItems {
    return self.itemList;
}

- (void)addFormItem:(CHFormItem *)item {
    [self.itemList addObject:item];
    item.section = self;
}


@end
