//
//  CHMsgsDataSource.m
//  OSX
//
//  Created by WizJin on 2021/6/7.
//

#import "CHMsgsDataSource.h"
#import "CHUserDataSource.h"
#import "CHUnknownMsgCellConfiguration.h"
#import "CHDateCellConfiguration.h"
#import "CHLoadMoreView.h"
#import "CHLogic+OSX.h"

@interface CHMsgsDataSource ()

@property (nonatomic, readonly, strong) NSString *cid;
@property (nonatomic, nullable, strong) CHLoadMoreView *headerView;
@property (nonatomic, readonly, weak) NSCollectionView *collectionView;

@end

@implementation CHMsgsDataSource

typedef NSDiffableDataSourceSnapshot<NSString *, CHCellConfiguration *> CHConversationDiffableSnapshot;

+ (instancetype)dataSourceWithCollectionView:(NSCollectionView *)collectionView channelID:(NSString *)cid {
    return [[self.class alloc] initWithCollectionView:collectionView channelID:cid];
}

- (instancetype)initWithCollectionView:(NSCollectionView *)collectionView channelID:(NSString *)cid {
    NSDictionary<NSString *, CHCollectionViewCellRegistration *> *cellRegistrations = [CHCellConfiguration cellRegistrations];
    loadRegistrationsToCollectionVoew(collectionView, cellRegistrations.allValues);
    CHCollectionViewCellRegistration *unknownCellRegistration = [cellRegistrations objectForKey:NSStringFromClass(CHUnknownMsgCellConfiguration.class)];
    NSCollectionViewDiffableDataSourceItemProvider cellProvider = ^NSCollectionViewItem *(NSCollectionView *collectionView, NSIndexPath *indexPath, CHCellConfiguration *item) {
        CHCollectionViewCellRegistration *cellRegistration = [cellRegistrations objectForKey:NSStringFromClass(item.class)];
        if (cellRegistration != nil) {
            return loadCell(collectionView, cellRegistration, indexPath, item);
        }
        return loadCell(collectionView, unknownCellRegistration, indexPath, item);
    };
    if (self = [super initWithCollectionView:collectionView itemProvider:cellProvider]) {
        _cid = cid;
        _collectionView = collectionView;
        [collectionView registerClass:CHLoadMoreView.class forSupplementaryViewOfKind:NSCollectionElementKindSectionHeader withIdentifier:@"CHLoadMoreView"];
        @weakify(self);
        self.supplementaryViewProvider = ^NSView * _Nullable(NSCollectionView *collectionView, NSString *kind, NSIndexPath *indexPath) {
            @strongify(self);
            if (self.headerView == nil) {
                self.headerView = [collectionView makeSupplementaryViewOfKind:kind withIdentifier:@"CHLoadMoreView" forIndexPath:indexPath];
                [self updateHeaderView];
            }
            return self.headerView;
        };
        [self reset:NO];
    }
    return self;
}

- (void)reset:(BOOL)animated {
    CHConversationDiffableSnapshot *snapshot = [CHConversationDiffableSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@"main"]];
    [self applySnapshot:snapshot animatingDifferences:NO];
    
    [self loadLatestMessage:animated];
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeMake(self.collectionView.bounds.size.width, 30);
    CHCellConfiguration *item = [self itemIdentifierForIndexPath:indexPath];
    if (item != nil) {
        size.height = [item calcSize:size].height;
    }
    return size;
}

- (CGSize)sizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.collectionView.bounds.size.width, 30);
}

- (void)scrollViewDidScroll {
    if (self.headerView != nil && self.headerView.status == CHLoadStatusNormal) {
        self.headerView.status = ([self.collectionView numberOfItemsInSection:0] > 0 ? CHLoadStatusLoading : CHLoadStatusFinish);
        @weakify(self);
        dispatch_main_after(kCHLoadingDuration, ^{
            @strongify(self);
            [self loadEarlistMessage];
        });
    }
}

- (void)loadLatestMessage:(BOOL)animated {
    NSDate *last = nil;
    NSString *to = @"";
    NSString *from = @"7FFFFFFFFFFFFFFF";
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if (count > 0) {
        CHCellConfiguration *item = [self itemIdentifierForIndexPath:[NSIndexPath indexPathForItem:count - 1 inSection:0]];
        to = item.mid;
        last = item.date;
    }
    NSArray<CHMessageModel *> *items = [CHLogic.shared.userDataSource messageWithCID:self.cid from:from to:to count:kCHMessageListPageSize];
    if (items.count > 0) {
        CHConversationDiffableSnapshot *snapshot = self.snapshot;
        [snapshot appendItemsWithIdentifiers:[self calcItems:items last:last]];
        [self applySnapshot:snapshot animatingDifferences:animated];
        @weakify(self);
        dispatch_main_async(^{
            @strongify(self);
            [self scrollToBottom:animated];
            [self updateHeaderView];
        });
    }
}

- (void)selectItemWithIndexPaths:(NSSet<NSIndexPath *> *)indexPaths {
    [self.collectionView deselectItemsAtIndexPaths:indexPaths];
}

#pragma mark - Private Methods
- (void)updateHeaderView {
    if (self.headerView != nil && self.headerView.status != CHLoadStatusLoading) {
        self.headerView.status = ([self.collectionView numberOfItemsInSection:0] < kCHMessageListPageSize ? CHLoadStatusFinish : CHLoadStatusNormal);
    }
}

- (void)scrollToBottom:(BOOL)animated {
    NSInteger count = [self.collectionView numberOfItemsInSection:0];
    if (count > 0) {
        [self.collectionView layoutSubtreeIfNeeded];
        [self.collectionView scrollToItemsAtIndexPaths:[NSSet setWithObject:[NSIndexPath indexPathForItem:count-1 inSection:0]] scrollPosition:NSCollectionViewScrollPositionBottom];
    }
}

- (void)performAndKeepOffset:(void (NS_NOESCAPE ^)(void))actions {
    if (actions != NULL) {
        if (self.scroller == nil) {
            actions();
        } else {
            CGPoint offset = self.scroller.documentVisibleRect.origin;
            [self.scroller.documentView scrollPoint:offset];
            CGFloat height = self.scroller.documentView.frame.size.height;
            actions();
            [self.scroller layoutSubtreeIfNeeded];
            offset.y += self.scroller.documentView.frame.size.height - height;
            [self.scroller.documentView scrollPoint:offset];
        }
    }
}

- (void)loadEarlistMessage {
    if ([self.collectionView numberOfItemsInSection:0] <= 0) {
        [self loadLatestMessage:YES];
    } else {
        CHCellConfiguration *item = [self itemIdentifierForIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        NSArray<CHMessageModel *> *items = [CHLogic.shared.userDataSource messageWithCID:self.cid from:item.mid to:@"" count:kCHMessageListPageSize];
        self.headerView.status = (items.count < kCHMessageListPageSize ? CHLoadStatusFinish : CHLoadStatusNormal);
        if (items.count > 0) {
            NSMutableArray<CHCellConfiguration *> *selectedCells = nil;
            [self performAndKeepOffset:^{
                NSArray<CHCellConfiguration *> *cells = [self calcItems:items last:nil];
                CHConversationDiffableSnapshot *snapshot = self.snapshot;
                [snapshot insertItemsWithIdentifiers:cells beforeItemWithIdentifier:item];
                [self applySnapshot:snapshot animatingDifferences:NO];
            }];
            if (selectedCells.count > 0) {
                for (CHCellConfiguration *cell in selectedCells) {
                    NSIndexPath *indexPath = [self indexPathForItemIdentifier:cell];
                    [self.collectionView selectItemsAtIndexPaths:[NSSet setWithObject:indexPath] scrollPosition:NSCollectionViewScrollPositionNone];
                }
            }
        }
    }
}

- (NSArray<CHCellConfiguration *> *)calcItems:(NSArray<CHMessageModel *> *)items last:(NSDate *)last {
    NSInteger count = items.count;
    NSMutableArray<CHCellConfiguration *> *cells = [NSMutableArray arrayWithCapacity:items.count];
    for (NSInteger index = count - 1; index >= 0; index--) {
        CHCellConfiguration *item = [CHCellConfiguration cellConfiguration:[items objectAtIndex:index]];
        if (last == nil || [item.date timeIntervalSinceDate:last] > kCHMessageListDateDiff) {
            CHCellConfiguration *itm = [CHDateCellConfiguration cellConfiguration:item.mid];
            last = itm.date;
            [cells addObject:itm];
        }
        [cells addObject:item];
    }
    return cells;
}

static inline void loadRegistrationsToCollectionVoew(NSCollectionView * collectionView, NSArray<CHCollectionViewCellRegistration *> *cellRegistrations) {
    for (CHCollectionViewCellRegistration *registration in cellRegistrations) {
        [registration registerCollectionView:collectionView];
    }
}

static inline NSCollectionViewItem* loadCell(NSCollectionView *collectionView, CHCollectionViewCellRegistration *registration, NSIndexPath *indexPath, CHCellConfiguration *item) {
    CHCollectionViewCell *cell = [collectionView makeItemWithIdentifier:registration.itemIdentifier forIndexPath:indexPath];
    registration.configurationHandler(cell, indexPath, item);
    return cell;
}


@end
