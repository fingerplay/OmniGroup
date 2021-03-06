// Copyright 2010-2014 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.


#import <OmniUI/OUIImagePickerGroupListViewController.h>

#import <OmniFoundation/NSArray-OFExtensions.h>

#import <AssetsLibrary/AssetsLibrary.h>

#import <OmniUI/OUIImagePickerGroupCell.h>
#import <OmniUI/OUIImagePickerAssetsViewController.h>

RCS_ID("$Id$")

#pragma mark - ALAssetsGroup Category for Sorting
@interface ALAssetsGroup (OUIImagePickerGroupListViewController_Sorting)

- (NSUInteger)oui_sortingOrder;
- (NSString *)oui_sortingName;

@end

@implementation ALAssetsGroup (OUIImagePickerGroupListViewController_Sorting)

- (NSUInteger)oui_sortingOrder;
{
    static NSArray *sortingOrderArray;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sortingOrderArray = @[
                              @(ALAssetsGroupSavedPhotos),
                              @(ALAssetsGroupLibrary),
                              @(ALAssetsGroupPhotoStream),
                              @(ALAssetsGroupAlbum),
                              @(ALAssetsGroupEvent),
                              @(ALAssetsGroupFaces)
                              ];
    });

    NSNumber *typeNumber = [self valueForProperty:ALAssetsGroupPropertyType];
    
    return [sortingOrderArray indexOfObject:typeNumber];
}

- (NSString *)oui_sortingName;
{
    return [self valueForProperty:ALAssetsGroupPropertyName];
}

@end

#pragma mark - OUIImagePickerGroupListViewController
@interface OUIImagePickerGroupListViewController ()

@property (nonatomic, strong) UIView *accessDeniedView;
@property (nonatomic, strong) UIView *emptyView;

@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, strong) NSMutableArray *groups;

@end

@implementation OUIImagePickerGroupListViewController

static NSString *imagePickerGroupCellId = @"OUIImagePickerGroupCell";

static NSString *OUIImagePickerAccessDeniedViewName = @"OUIImagePickerAccessDeniedView";
static NSString *OUIImagePickerEmptyViewName = @"OUIImagePickerEmptyView";

+ (instancetype)imagePickerGroupListViewController;
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"OUIImagePickerViewControllers" bundle:nil];
    OUIImagePickerGroupListViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"OUIImagePickerGroupListViewController"];
    controller.title = NSLocalizedStringFromTableInBundle(@"Photos", @"OmniUI", OMNI_BUNDLE, @"Photos view controller title.");
    
    return controller;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self _updateGroupsAndSwitchViews];
}

- (void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
}

#pragma mark - Private API
- (UIView *)_topLevelViewFromNibNamed:(NSString *)nibName;
{
    UINib *nib = [UINib nibWithNibName:nibName bundle:nil];
    NSArray *topLevelObjects = [nib instantiateWithOwner:nil options:nil];
    OBASSERT([topLevelObjects count] == 1);
    
    UIView *topLevelView = (UIView *)[topLevelObjects firstObject];
    OBASSERT([topLevelView isKindOfClass:[UIView class]]);
    
    return topLevelView;
}

- (UIView *)accessDeniedView;
{
    if (!_accessDeniedView) {
        _accessDeniedView = [self _topLevelViewFromNibNamed:OUIImagePickerAccessDeniedViewName];
    }
    
    return _accessDeniedView;
}

- (UIView *)emptyView;
{
    if (!_emptyView) {
        _emptyView = [self _topLevelViewFromNibNamed:OUIImagePickerEmptyViewName];
    }
    
    return _emptyView;
}

#pragma mark - Private Helpers
- (void)_updateGroupsAndSwitchViews;
{
    self.library = [[ALAssetsLibrary alloc] init];
    self.groups = [[NSMutableArray alloc] init];
    
    // Grab the 'all group' type from the assets library does not create an explicit 'Photo Library' group with all of the photos. (Nor does oring it in with the 'all group'.) Because of this, we need to explicitly pull the 'Library' type separately.
    NSArray *groupTypesToFetch = @[@(ALAssetsGroupAll), @(ALAssetsGroupLibrary)];
    
    [self _fetchAssetGroupsWithTypes:groupTypesToFetch completion:^{
            if ([_groups count] > 0) {
                [self _sortGroups];
                self.tableView.backgroundView = nil;
                [self.tableView reloadData];
            }
            else {
                self.tableView.backgroundView = self.emptyView;
            }
    }];
}

- (void)_fetchAssetGroupsWithTypes:(NSArray *)types completion:(void (^)(void))completion;
{
    OBPRECONDITION([types count] > 0);
    
    NSNumber *firstTypeNumber = [types firstObject];
    ALAssetsGroupType type = [firstTypeNumber unsignedIntegerValue];
    
    if (completion) {
        completion = [completion copy];
    }
    
    [_library enumerateGroupsWithTypes:type usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        NSInteger numberOfPhotos = [group numberOfAssets];
        // The last group will be nil. This alerts you that you are done enumerating the library.
        if (numberOfPhotos > 0) {
            [_groups addObject:group];
        }
        else if (group == nil) {
            NSArray *remainingTypes = [types arrayByRemovingObject:firstTypeNumber];
            if ([remainingTypes count] > 0) {
                [self _fetchAssetGroupsWithTypes:remainingTypes completion:completion];
            }
            else {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion();
                    });
                }
            }
        }
    } failureBlock:^(NSError *error) {
        self.tableView.backgroundView = self.accessDeniedView;
    }];
}

- (void)_sortGroups;
{
    [_groups sortUsingDescriptors:@[
                                    [NSSortDescriptor sortDescriptorWithKey:@"oui_sortingOrder" ascending:YES],
                                    [NSSortDescriptor sortDescriptorWithKey:@"oui_sortingName" ascending:YES selector:@selector(localizedStandardCompare:)]
                                    ]];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    ALAssetsGroup *group = _groups[indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(imagePickerGroupListViewController:didSelectAssetsGroup:)]) {
        [self.delegate imagePickerGroupListViewController:self didSelectAssetsGroup:group];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return [_groups count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    OUIImagePickerGroupCell *groupCell = (OUIImagePickerGroupCell *)[tableView dequeueReusableCellWithIdentifier:imagePickerGroupCellId forIndexPath:indexPath];
    
    ALAssetsGroup *group = _groups[indexPath.row];
    
    groupCell.posterImageView.image = [UIImage imageWithCGImage:[group posterImage]];
    groupCell.groupNameLabel.text = [group valueForProperty:ALAssetsGroupPropertyName];
    groupCell.assetsCountLabel.text = [NSString stringWithFormat:@"%ld", (long)[group numberOfAssets]];
    
    return groupCell;
}

@end
