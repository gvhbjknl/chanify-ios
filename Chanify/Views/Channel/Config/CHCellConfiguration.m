//
//  CHCellConfiguration.m
//  Chanify
//
//  Created by WizJin on 2021/2/8.
//

#import "CHCellConfiguration.h"
#import "CHDateCellConfiguration.h"
#import "CHTextMsgCellConfiguration.h"
#import "CHUnknownMsgCellConfiguration.h"

@implementation CHCellConfiguration

+ (instancetype)cellConfiguration:(CHMessageModel *)model {
    switch (model.type) {
        case CHMessageTypeText:
            return [CHTextMsgCellConfiguration cellConfiguration:model];
        default:
            break;
    }
    return [CHUnknownMsgCellConfiguration cellConfiguration:model];;
}

+ (NSDictionary<NSString *, UICollectionViewCellRegistration *> *)cellRegistrations {
#define CellConfiguration(_clz) NSStringFromClass(_clz.class): cellRegistration(_clz.class)
    return @{
        CellConfiguration(CHDateCellConfiguration),
        CellConfiguration(CHTextMsgCellConfiguration),
        CellConfiguration(CHUnknownMsgCellConfiguration),
    };
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithMID:self.mid];
}

- (nonnull __kindof UIView<UIContentView> *)makeContentView {
    return nil;
}

- (nonnull instancetype)updatedConfigurationForState:(nonnull id<UIConfigurationState>)state {
    return self;
}

- (instancetype)initWithMID:(uint64_t)mid {
    if (self = [super init]) {
        _mid = mid;
    }
    return self;
}

- (NSDate *)date {
    return [NSDate dateWithTimeIntervalSince1970:self.mid/1000000000.0];
}

- (BOOL)isEqual:(CHCellConfiguration *)rhs {
    return self.mid == rhs.mid && self.class == rhs.class;
}

- (NSUInteger)hash {
    return self.mid;
}

- (CGFloat)calcHeight:(CGSize)size {
    return size.height;
}

inline static UICollectionViewCellRegistration *cellRegistration(Class clz) {
    return [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewCell.class configurationHandler:^(UICollectionViewCell *cell, NSIndexPath *indexPath, CHCellConfiguration *item) {
        if ([item isKindOfClass:clz]) {
            cell.contentConfiguration = item;
        }
    }];
}


@end
