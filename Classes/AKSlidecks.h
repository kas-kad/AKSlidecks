//
//  AKSlidecks.h
//
//  Created by Andrey Kadochnikov on 04.04.14.
//  Copyright (c) 2014 Andrey Kadochnikov. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AKSlidecks;
@class AKSlidecksItem;
@class AKSlidecksBar;

@protocol AKSlidecksBarDelegate <NSObject>
-(void)slidecksBar:(AKSlidecksBar*)bar slideBtnPressed:(UIButton*)button;
-(void)slidecksBar:(AKSlidecksBar*)bar rightBtnPressed:(UIButton*)button;
@end

/**
 Every viewController that is going to be pushed/presented with AKSlidecks must 100% conforms to the protocol
 */
@protocol AKSlidecksCapable <NSObject>
@required
/**
 returns parent slidecksViewController for particular child VC from navigation stack
 */
@property (nonatomic, weak) AKSlidecks *slidecksViewController;
/**
 contains several attributes used for navigation bar initializing
 */
@property (nonatomic, strong) AKSlidecksItem *slidecksItem;

/**
 returns estimated width for viewcontroller's view. 0 - means that the width is flexible, the view will resized to fill all available screen space
 */
-(CGFloat)slidecksEstimatedWidth;
/**
 determines whether the `slide` button (looks like `<` or `>`) has to be shown on left side of top slidecks navigation bar for particular child VC
 */
-(BOOL)slidecksSlidingEnabled;
@end



@interface AKSlidecks : UIViewController <AKSlidecksBarDelegate>
/**
 The flag to enable/disable left edge swipes. The swipe moves back the current navigation stack
 */
@property (nonatomic,assign) BOOL swipesEnabled;
/**
 The root view controller
 */
@property (nonatomic,strong) UIViewController<AKSlidecksCapable>* rootViewController;

/**
 Designated initializer. Initially presents the view controller without any animation
 
 @param viewController The root view controller
 @param itemsCount The root list items count for saving and restoring nodes from root list. The Slidecks will not save navigation stacks if this parameter is 0. TODO: should be removed to decrease coupling
 */
-(id) initWithRootViewController:(UIViewController<AKSlidecksCapable>*)viewController
					  itemsCount:(NSUInteger)itemsCount;

/**
 This method presents viewController immediatly jumping on it
 
 @param viewController The presented view controller which should be pushed into the navigation stack
 @param fromVC The presenting view controller which will be a parent view controller
 @param animated The animation flag
 */
- (void)pushViewController:(UIViewController <AKSlidecksCapable> *)viewController
					  from:(UIViewController <AKSlidecksCapable> *)fromVC
				  animated:(BOOL)animated;

/**
 This method presents viewController without jumping if the viewController is fully visible on the screen
 
 @param viewController The presented view controller which should be pushed into the navigation stack
 @param fromVC The presenting view controller which will be a parent view controller
 @param animated The animation flag
 */
- (void)presentViewController:(UIViewController<AKSlidecksCapable> *)viewController
						 from:(UIViewController<AKSlidecksCapable> *)fromVC
					 animated:(BOOL)animated;

/**
 This method restores saved navigation stack with all views hierarchy
 
 @param childController The view controller which going to be presented if there is no saved navigation stack at itemIndex
 @param itemIndex The index of array of saved navigation stacks which should be restored
 */
-(void)restoreViewController:(UIViewController<AKSlidecksCapable>*)childController
				forNodeIndex:(NSUInteger)itemIndex;
@end



@interface AKSlidecksItem : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) NSArray* rightButtons;
@property (nonatomic, strong) AKSlidecksBar *slidecksBar;
@end



typedef NS_ENUM(NSUInteger, AKSlidecksButtonType) {AKSlidecksToTheLeftButton, AKSlidecksToTheRightButton};
@interface AKSlidecksBar : UIToolbar
@property (nonatomic, assign) AKSlidecksButtonType buttonType;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) UIView* titleView;
@property (nonatomic, strong) UILabel* titleLabel;
@property (nonatomic, strong) UIButton* slideButton;
@property (nonatomic, weak) id <AKSlidecksBarDelegate> slidecksBarDelegate;
@property (nonatomic, strong) NSArray* rightButtons;
-(id)initWithIndex:(NSUInteger)index;
@end