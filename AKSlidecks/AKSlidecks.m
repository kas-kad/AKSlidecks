//
//  AKSlidecks.m
//
//  Created by Andrey Kadochnikov on 04.04.14.
//  Copyright (c) 2014 Andrey Kadochnikov. All rights reserved.
//

#import "AKSlidecks.h"
#import "AKHorizSeparatorView.h"
#import "EdgeSwipeGestureRecognizer.h"

#define HELV_NEUE_MEDIUM(_size) ([UIFont fontWithName:@"HelveticaNeue-Medium" size:(_size)])
#define RETINA ([UIScreen mainScreen].scale > 1.0f)
#define DECK_W 320.0f
#define TOOLBAR_H 64.0f
#define TOOLBAR_TAG 1001847
#define BTN_W_H 44.0f
#define COLOR_SHADOW [UIColor colorWithRed:178.0f/255.0f green:178.0f/255.0f blue:178.0f/255.0f alpha:1.0]
#define COLOR_NAVBAR_TINT [UIColor colorWithRed:120.0f/255.0f green:163.0f/255.0f blue:183.0f/255.0f alpha:1.0]
#define COLOR_NAVBAR_BG [UIColor colorWithRed:234.0f/255.0f green:234.0f/255.0f blue:234.0f/255.0f alpha:1.0]
#define BORDER_COLOR [UIColor colorWithRed:170.0f/255.0f green:170.0f/255.0f blue:170.0f/255.0f alpha:1.0]
#define MARGIN10 10.0f
#define BORDER_W (RETINA ? 0.5f : 1.0f)
#define SLIDE_BTN_TAG_OFFSET 712312
#define DECK_CONTAINER_TAG_OFFSET 939
#define DURATION 0.5f
#define DAMPING 0.8f
#define VELOCITY 0.4f
#define PAN_OFFSET_LIMIT 80.0f

@interface AKSlidecks ()
{
	__weak EdgeSwipeGestureRecognizer *_edgeGestureRec;
	UIView *slidingView;
	int32_t _buttonTypeMask;
	UIImageView *_snapshotView;
	NSArray* _navigationStacks;
	NSUInteger _currentRootItemIdx;
}
@end

@implementation AKSlidecks

#pragma mark - lifecycle
-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)initWithRootViewController:(UIViewController<AKSlidecksCapable>*)viewController itemsCount:(NSUInteger)itemsCount{
	self = [self init];
	if (self){
		_buttonTypeMask = 1;
		
		NSMutableArray *mutable = [NSMutableArray arrayWithCapacity:itemsCount];
		_currentRootItemIdx = 0;
		itemsCount = itemsCount > 0 ? itemsCount : 1;
		for(int i = 0; i < itemsCount; i++){
			[mutable addObject:[NSMutableOrderedSet orderedSet]];
		}
		_navigationStacks  = [NSArray arrayWithArray:mutable];
		
		self.rootViewController = viewController;
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.view.backgroundColor = [UIColor grayColor];
		self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		slidingView = [[UIView alloc] init];
		slidingView.backgroundColor = [UIColor clearColor];
		slidingView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		slidingView.frame = CGRectMake(0, 0, 0, CGRectGetHeight(self.view.bounds));
		
		[self.view addSubview:slidingView];
		
		EdgeSwipeGestureRecognizer *edgeGestureRec = [[EdgeSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        edgeGestureRec.side = kEdgeSwipeGestureRecognizerLeft;
		[self.view addGestureRecognizer: edgeGestureRec];
		_edgeGestureRec = edgeGestureRec;
    }
    return self;
}

#pragma mark - Pan handling
- (void)handlePanGesture:(EdgeSwipeGestureRecognizer *)gesture
{
    if (slidingView.frame.origin.x == 0){
		return;
	}
    CGPoint translation = [gesture translationInView:gesture.view];
  
	if (gesture.state == UIGestureRecognizerStateEnded ||
        gesture.state == UIGestureRecognizerStateCancelled ||
        gesture.state == UIGestureRecognizerStateFailed)
    {
        CGPoint velocity = [gesture velocityInView:gesture.view.superview];
       	if ((translation.x + velocity.x * 0.5) > 160){
			CGFloat xOffset = slidingView.transform.tx;
            slidingView.transform = CGAffineTransformIdentity;
			slidingView.frame = ({CGRect newFrame = slidingView.frame; newFrame.origin.x += xOffset; newFrame;});
			[self rightStepWithOffset:xOffset];
		} else {
			[UIView animateWithDuration:0.25f
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 slidingView.transform = CGAffineTransformIdentity;
                             } completion:nil];
		}
	} else {
		CGFloat xTranslation = 0;
		if (translation.x < PAN_OFFSET_LIMIT){
			xTranslation = translation.x;
		}else{
			xTranslation = PAN_OFFSET_LIMIT + ((translation.x-PAN_OFFSET_LIMIT) * 0.2f);
		}
		slidingView.transform = CGAffineTransformMakeTranslation(xTranslation, 0.0);
	}
}

#pragma mark - Setup
-(void)setSwipesEnabled:(BOOL)enabled{
	_swipesEnabled = enabled;
	_edgeGestureRec.enabled = enabled;
}
-(void)setRootViewController:(UIViewController<AKSlidecksCapable> *)rootViewController{
	_rootViewController = rootViewController;
	[self pushViewController:rootViewController from:nil animated:NO];
}


#pragma mark - Navigation stack
-(NSMutableOrderedSet*)currentNavStack{
	return _navigationStacks[_currentRootItemIdx];
}

-(NSMutableOrderedSet*)navStackForItemIdx:(NSUInteger)idx{
	if (idx < _navigationStacks.count){
		return _navigationStacks[idx];
	}
	return nil;
}

- (void)clearViewControllersSince:(NSUInteger)startingIndex {
	NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(startingIndex, [self currentNavStack].count-startingIndex)];
	
	[[self currentNavStack] enumerateObjectsAtIndexes:indexesToRemove
											  options:0
										   usingBlock:^(UIViewController<AKSlidecksCapable>*oldVC, NSUInteger idx, BOOL *stop) {
	
		[self setButtonType:AKSlidecksToTheLeftButton forViewController:oldVC];

		[oldVC removeFromParentViewController];
		[oldVC.view removeFromSuperview];
											   
		UIView *containerView = [self containerViewWithNodeIdx:_currentRootItemIdx index:idx];//[self.view viewWithTag: [self containerViewTagWithNodeIdx:_currentRootItemIdx index:idx]];
		[containerView removeFromSuperview];
											   
	}];
	[[self currentNavStack] removeObjectsAtIndexes:indexesToRemove];
}

- (void)inserChildController:(UIViewController<AKSlidecksCapable> *)childController inContainer:(UIView *)deckContainerView {

	if ([childController conformsToProtocol:@protocol(AKSlidecksCapable)]){
		if (childController.slidecksItem == nil)
		{
			childController.slidecksItem = [[AKSlidecksItem alloc] init];
			childController.slidecksItem.title = childController.navigationItem.title;
			childController.slidecksItem.titleView = childController.navigationItem.titleView;
		}
		childController.slidecksViewController = self;
	}
	[self addChildViewController:childController];

	
	CGRect newChildViewFrame;
	newChildViewFrame.origin.x = 0;
	newChildViewFrame.origin.y = 0;
	newChildViewFrame.size.height = CGRectGetHeight(deckContainerView.bounds);
	newChildViewFrame.size.width = CGRectGetWidth(deckContainerView.bounds) - BORDER_W;
	
	childController.view.frame = newChildViewFrame;
	childController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	switch (childController.edgesForExtendedLayout) {
		case UIRectEdgeNone:{
			newChildViewFrame = UIEdgeInsetsInsetRect(newChildViewFrame, UIEdgeInsetsMake(TOOLBAR_H, 0, 0, 0));
			childController.view.frame = newChildViewFrame;
		}break;
		default:
			break;
	}
	[deckContainerView insertSubview:childController.view atIndex:0];
	[childController didMoveToParentViewController:self];
	[childController.view setNeedsLayout];
}

- (void)refreshToolbarForViewController:(UIViewController<AKSlidecksCapable>*)childController inContainer:(UIView *)deckContainerView {
//	if (self.rootViewController != childController){
		childController.slidecksItem.slidecksBar = [self slidecksBarForViewController:childController];
		if ([deckContainerView viewWithTag:TOOLBAR_TAG]){
			AKSlidecksBar *oldBar = (AKSlidecksBar*)[deckContainerView viewWithTag:TOOLBAR_TAG];
			[oldBar removeFromSuperview];
		}
		childController.slidecksItem.slidecksBar.frame = CGRectMake(0, 0, CGRectGetWidth(deckContainerView.bounds) - BORDER_W, TOOLBAR_H);
		[deckContainerView addSubview:childController.slidecksItem.slidecksBar];
//	}
	[self refreshLeftButtonAppearance];
}

- (void)cleanPreviousViewHierarchy {
	// clean previous view hierarchy
	NSIndexSet *indexesToRemove = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [self currentNavStack].count-1)];
	[[self currentNavStack] enumerateObjectsAtIndexes:indexesToRemove
											  options:0
										   usingBlock:^(UIViewController<AKSlidecksCapable>*oldVC, NSUInteger idx, BOOL *stop){
											   
											   [self setButtonType:AKSlidecksToTheLeftButton forViewController:oldVC];
											   [oldVC removeFromParentViewController];
											   [oldVC.view removeFromSuperview];
											   UIView *containerView = [self containerViewWithNodeIdx:_currentRootItemIdx index:idx];//[self.view viewWithTag: [self containerViewTagWithNodeIdx:_currentRootItemIdx index:idx]];
											   [containerView removeFromSuperview];
											   
										   }];
}

-(void)restoreViewController:(UIViewController<AKSlidecksCapable>*)childController forNodeIndex:(NSUInteger)itemIndex{
	if ([self navStackForItemIdx:itemIndex].count <= 1) {
		if ([self navStackForItemIdx:itemIndex].count == 0){
			[[self navStackForItemIdx:itemIndex] addObject:_rootViewController];
		}
		[self cleanPreviousViewHierarchy];
		_currentRootItemIdx = itemIndex;
		[self presentViewController:childController from:_rootViewController animated:YES];
	
	} else {
		if (_currentRootItemIdx == itemIndex){
			return;
		}
		if (_rootViewController && [[self currentNavStack] containsObject:_rootViewController]){
			[self cleanPreviousViewHierarchy];
		}
		_currentRootItemIdx = itemIndex;

		// restoring saved navStack
		NSMutableOrderedSet *currentNavStack = [self currentNavStack];
		[currentNavStack enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [self currentNavStack].count-1)]
										   options:0
										usingBlock:^(UIViewController<AKSlidecksCapable>* restoredVC, NSUInteger idx, BOOL *stop) {

			UIView *deckContainerView = [self createNewDeckContainerForViewController:restoredVC animation:YES];
			[self inserChildController:restoredVC inContainer:deckContainerView];
			[self refreshToolbarForViewController:restoredVC inContainer:deckContainerView];
		}];
		[self jumpTo:0];
	}
}

-(void)presentViewController:(UIViewController<AKSlidecksCapable>*)childController from:(UIViewController<AKSlidecksCapable>*)fromVC  animated:(BOOL)animated{
	UIView *deckContainerView;
	NSUInteger stackIndexForPushedVC = 0;
	
	if (fromVC && [[self currentNavStack] containsObject: fromVC]){
		[self clearViewControllersSince: [[self currentNavStack] indexOfObject:fromVC] + 1];
		stackIndexForPushedVC = [[self currentNavStack] indexOfObject:fromVC] + 1;
	}
	deckContainerView = [self createNewDeckContainerForViewController:childController animation:animated];
	
	[[self currentNavStack] addObject:childController];
	[self inserChildController:childController inContainer:deckContainerView];
	[self refreshToolbarForViewController:childController inContainer:deckContainerView];
	
	[self adjustVisibility];
}

-(void)adjustVisibility{
	NSUInteger decksCount = [self currentNavStack].count;
	UIView *lastdeck = [self containerViewWithNodeIdx:_currentRootItemIdx index:decksCount-1];
	CGRect deckFrameRelativeToMainView = [self.view convertRect:lastdeck.frame fromView:slidingView];
	if (!CGRectContainsRect(self.view.bounds, deckFrameRelativeToMainView)){
		[self jumpTo:decksCount-2];
	}
}

-(void)pushViewController:(UIViewController<AKSlidecksCapable>*)childController from:(UIViewController<AKSlidecksCapable>*)fromVC  animated:(BOOL)animated{
	UIView *deckContainerView;
	NSUInteger stackIndexForPushedVC = 0;
	
	if (fromVC && [[self currentNavStack] containsObject: fromVC]){
		[self clearViewControllersSince: [[self currentNavStack] indexOfObject:fromVC] + 1];
		stackIndexForPushedVC = [[self currentNavStack] indexOfObject:fromVC] + 1;
	}
	deckContainerView = [self createNewDeckContainerForViewController:childController animation:animated];
	
	[[self currentNavStack] addObject:childController];
	[self jumpTo:stackIndexForPushedVC];
	[self inserChildController:childController inContainer:deckContainerView];
	[self refreshToolbarForViewController:childController inContainer:deckContainerView];
}

-(BOOL)isPositionLeftForIndex:(NSUInteger)index{
	UIView *deckContainerView = [self containerViewWithNodeIdx:_currentRootItemIdx index:index];//[self.view viewWithTag:[self containerViewTagWithNodeIdx:_currentRootItemIdx index:index]];
	CGFloat currentButtonViewX = deckContainerView.frame.origin.x;
	return fabs(slidingView.frame.origin.x) == currentButtonViewX;
}

#pragma mark - Toolbar
-(AKSlidecksBar*)toolbarForDeckContainer:(UIView*)deckContainer{
	return (AKSlidecksBar*)[deckContainer viewWithTag:TOOLBAR_TAG];
}

-(void)slidecksBar:(AKSlidecksBar*)bar slideBtnPressed:(UIButton*)button{
	NSUInteger index = button.tag - SLIDE_BTN_TAG_OFFSET -1;
	if ([self isPositionLeftForIndex:index]){
		[self rightStepWithOffset:0];
	} else {
		[self jumpTo:index];
	}
}

-(void)slidecksDismissBtnPressed:(UIButton*)button{
	NSUInteger index = button.tag - SLIDE_BTN_TAG_OFFSET -1;
	UIView *deckContainerView = [self containerViewWithNodeIdx:_currentRootItemIdx index:index];//[self.view viewWithTag:[self containerViewTagWithNodeIdx:_currentRootItemIdx index:index]];
	
	CGRect offScreenPosition = deckContainerView.frame;
	offScreenPosition.origin.x += deckContainerView.frame.size.width;
	
	[UIView animateWithDuration:0.2f animations:^{
		deckContainerView.frame = offScreenPosition;
	}completion:^(BOOL finished) {
		[self clearViewControllersSince:index];
	}];
}

-(void)slidecksBar:(AKSlidecksBar *)bar rightBtnPressed:(UIButton *)button{
	// TODO
}

- (void)rightStepWithOffset:(CGFloat)xOffset {
	if (slidingView.frame.origin.x != 0){
		NSLog(@">>>>>>");

		NSUInteger viewControllerIdx = log2f(_buttonTypeMask);
		UIViewController<AKSlidecksCapable> *previusVC = [self currentNavStack][viewControllerIdx];
		
		_buttonTypeMask = _buttonTypeMask >> 1;
		
		viewControllerIdx = log2f(_buttonTypeMask);
		UIViewController<AKSlidecksCapable> *destinationVC = [self currentNavStack][viewControllerIdx];
		CGFloat vcWidth = CGRectGetWidth(destinationVC.view.bounds);
		
		[self refreshLeftButtonAppearance];

		
		[UIView animateWithDuration:DURATION delay:0 usingSpringWithDamping:DAMPING initialSpringVelocity:VELOCITY options:0 animations:^{
			slidingView.frame = CGRectOffset(slidingView.frame, vcWidth + BORDER_W - xOffset, 0);
		} completion:^(BOOL finished) {
		}];
		if ([previusVC slidecksEstimatedWidth] == 0){
			//			[self.view setNeedsLayout];
			[self manualLayoutForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
		}

	}else {
		NSLog(@"||||||");
	}
}

-(void)jumpTo:(NSUInteger)index{
	
	NSLog(@"JUMP TO %lu", (unsigned long)index);
	
	_buttonTypeMask = 0;
	_buttonTypeMask = 1 << index;
	[self refreshLeftButtonAppearance];
	
	__block CGFloat newX = 0;
	[[self currentNavStack] enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, index)] options:0 usingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		newX += (CGRectGetWidth(vc.view.bounds) + BORDER_W);
	}];
	
	
	[UIView animateWithDuration:DURATION delay:0 usingSpringWithDamping:DAMPING initialSpringVelocity:VELOCITY options:0 animations:^{
		slidingView.frame = CGRectMake(-newX, 0, CGRectGetWidth(slidingView.bounds), CGRectGetHeight(slidingView.bounds));
	}completion:^(BOOL finished) {
		
	}];
	
	UIViewController <AKSlidecksCapable>* destinationVC = [self currentNavStack][index];
	if ([destinationVC slidecksEstimatedWidth] == 0){
		//[self.view setNeedsLayout];
		[self manualLayoutForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
	}
}

-(UIViewController<AKSlidecksCapable>*)leftViewController{
	NSUInteger leftViewIndex = abs(slidingView.frame.origin.x/(DECK_W+BORDER_W));
	if ([self currentNavStack].count > leftViewIndex){
		return [self currentNavStack][leftViewIndex];
	} else {
		return nil;
	}
}

-(void)refreshLeftButtonAppearance{
	[[self currentNavStack] enumerateObjectsUsingBlock:^(UIViewController<AKSlidecksCapable>* viewController, NSUInteger idx, BOOL *stop) {
		if ([viewController conformsToProtocol:@protocol(AKSlidecksCapable)]){
			if ((idx) != log2f(_buttonTypeMask)){
				viewController.slidecksItem.slidecksBar.buttonType = AKSlidecksToTheLeftButton;
			} else {
				viewController.slidecksItem.slidecksBar.buttonType = AKSlidecksToTheRightButton;
			}
		}
	}];
}

-(void)setButtonType:(AKSlidecksButtonType)type forViewController:(UIViewController<AKSlidecksCapable>*)vc{
	if ([vc conformsToProtocol:@protocol(AKSlidecksCapable)]){
		vc.slidecksItem.slidecksBar.buttonType = type;
	}
}

-(AKSlidecksBar*)slidecksBarForViewController:(UIViewController<AKSlidecksCapable>*)viewController{
	AKSlidecksBar *toolbar;
	if (viewController.slidecksItem.slidecksBar){
		toolbar = viewController.slidecksItem.slidecksBar;
	}else{
		toolbar = [[AKSlidecksBar alloc]initWithIndex:[self currentNavStack].count];
		viewController.slidecksItem.slidecksBar = toolbar;
	}
	toolbar.slidecksBarDelegate = self;
	toolbar.slideButton.hidden = ![viewController slidecksSlidingEnabled];
	toolbar.rightButtons = viewController.slidecksItem.rightButtons;
	
	if (viewController.slidecksItem.titleView){
		toolbar.titleView = viewController.slidecksItem.titleView;
	} else {
		toolbar.titleLabel.text = viewController.navigationItem.title;
	}
	return toolbar;
}

- (UIView *)createNewDeckContainerForViewController:(UIViewController<AKSlidecksCapable>*)viewController animation:(BOOL)animated{
	
	__block NSUInteger idxForNewContainer = 0;
	__block CGFloat newDeckX = 0;
	__block CGFloat prevDeckX = 0;
	[[self currentNavStack] enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		prevDeckX = newDeckX;
		if (vc == viewController){
			*stop = YES;
		} else {
			newDeckX += (CGRectGetWidth(vc.view.bounds) + BORDER_W);
			idxForNewContainer++;
		}
	}];

	
	CGRect newDeckFrame;
	newDeckFrame.origin.x = newDeckX;
	newDeckFrame.origin.y = 0;
	newDeckFrame.size.height = CGRectGetHeight(self.view.bounds);
	
	CGFloat newDeckWidth = [viewController slidecksEstimatedWidth] > 0 ? ([viewController slidecksEstimatedWidth] + BORDER_W) : (CGRectGetWidth(self.view.bounds) - (DECK_W + BORDER_W));
	newDeckFrame.size.width = newDeckWidth;
	
	UIView *deckContainerView = [[UIView alloc] init];
	deckContainerView.tag = [self containerViewTagWithNodeIdx:_currentRootItemIdx index:idxForNewContainer];
	deckContainerView.backgroundColor = BORDER_COLOR;
	deckContainerView.autoresizingMask = UIViewAutoresizingFlexibleHeight;

	
	__block CGFloat newTotalWidth = 0;
	[[self currentNavStack] enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		if (vc == viewController){
			*stop = YES;
		} else {
			newTotalWidth += (CGRectGetWidth(vc.view.bounds) + BORDER_W);
		}
	}];
	newTotalWidth += newDeckWidth;
	
	slidingView.frame = CGRectMake(CGRectGetMinX(slidingView.frame),
								   0,
								   newTotalWidth,
								   CGRectGetHeight(self.view.bounds));

	
	CGRect deckFrameRelativeToMainView = [self.view convertRect:newDeckFrame fromView:slidingView];
	if (!CGRectContainsRect(self.view.bounds, deckFrameRelativeToMainView)){
		animated = NO;
	}
	
	if (!animated){
		deckContainerView.frame = newDeckFrame;
		[slidingView addSubview:deckContainerView];
	} else {
		CGRect startingPointDeckFrame = newDeckFrame;
		startingPointDeckFrame.origin.x -= newDeckFrame.size.width;
		deckContainerView.frame = startingPointDeckFrame;
		[slidingView insertSubview:deckContainerView atIndex:slidingView.subviews.count > 2 ? slidingView.subviews.count-2 : 0];

		[UIView animateWithDuration:0.2f animations:^{
			deckContainerView.frame = newDeckFrame;
		}completion:^(BOOL finished) {
			[slidingView bringSubviewToFront:deckContainerView];
		}];
	}
	return deckContainerView;
}

-(UIView*)containerViewWithNodeIdx:(NSUInteger)nodeIdx index:(NSUInteger)idx{
	return [self.view viewWithTag:[self containerViewTagWithNodeIdx:_currentRootItemIdx index:idx]];
}

-(NSInteger)containerViewTagWithNodeIdx:(NSUInteger)nodeIdx index:(NSUInteger)idx{
	if (idx == 0){
		return DECK_CONTAINER_TAG_OFFSET; // tag for rootvc container
	}
	return (_currentRootItemIdx+1)*DECK_CONTAINER_TAG_OFFSET + idx;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[self manualLayoutForOrientation:toInterfaceOrientation];
}

- (void)manualLayoutForOrientation:(UIInterfaceOrientation)orientation {
	__block CGFloat newTotalWidth = 0;


	CGRect screenBounds = [[UIScreen mainScreen] bounds];
	CGRect mainFrame = screenBounds;
	switch ( orientation) {
		case UIInterfaceOrientationLandscapeLeft:
			mainFrame = CGRectApplyAffineTransform(mainFrame, CGAffineTransformMakeRotation(-M_PI_2));
			mainFrame = CGRectApplyAffineTransform(mainFrame, CGAffineTransformMakeTranslation(0, screenBounds.size.width));
			break;
		case UIInterfaceOrientationLandscapeRight:
			mainFrame = CGRectApplyAffineTransform(mainFrame, CGAffineTransformMakeRotation(M_PI_2));
			mainFrame = CGRectApplyAffineTransform(mainFrame, CGAffineTransformMakeTranslation(screenBounds.size.height, 0));
			break;
		default:
			break;
	}
	
	
	
	[[self currentNavStack] enumerateObjectsUsingBlock:^(UIViewController<AKSlidecksCapable> *vc, NSUInteger idx, BOOL *stop) {
		UIView *deckContainerView = [self containerViewWithNodeIdx:_currentRootItemIdx index:idx];
		
		if ([vc slidecksEstimatedWidth] == 0){
			CGRect deckFrameRelativeToMainView = [self.view convertRect:deckContainerView.frame fromView:slidingView];
			
			CGFloat newWidth = 0;
			
			if (deckFrameRelativeToMainView.origin.x < 0){
				newWidth = deckContainerView.frame.size.width;
			} else {
				
				if (UIInterfaceOrientationIsPortrait(orientation)){
					if ([self isPositionLeftForIndex:idx]){
						newWidth = CGRectGetWidth( mainFrame );
					} else {
						//						UIView *prevDeckContainerView = [self containerViewWithNodeIdx:_currentRootItemIdx index:idx-1];
						//						CGRect prevDeckFrameRelativeToMainView = [self.view convertRect:prevDeckContainerView.frame fromView:slidingView];
						//						newWidth = CGRectGetWidth(self.view.bounds) - CGRectGetMaxX(prevDeckFrameRelativeToMainView);
						newWidth = CGRectGetWidth( mainFrame ) - (DECK_W+BORDER_W);
					}
				} else {
					newWidth = CGRectGetWidth( mainFrame ) - (DECK_W+BORDER_W);
				}
			}
//			newWidth = newWidth == 0 ? deckContainerView.frame.size.width : newWidth;
			deckContainerView.frame = ({
				CGRect newFrame = deckContainerView.frame;
				newFrame.origin.x = newTotalWidth;
				newFrame.size.width = newWidth;
				newFrame;
			});
		} else {
						
			deckContainerView.frame = ({
				CGRect newFrame = deckContainerView.frame;
				newFrame.origin.x = newTotalWidth;
				newFrame.size.width = [vc slidecksEstimatedWidth]+BORDER_W;
				newFrame;
			});
		}
		//		newTotalWidth += CGRectGetWidth(deckContainerView.frame);
		newTotalWidth = CGRectGetMaxX(deckContainerView.frame);
	}];
	
	slidingView.frame = CGRectMake(CGRectGetMinX(slidingView.frame),
								   CGRectGetMinY(slidingView.frame),
								   newTotalWidth,
								   CGRectGetHeight(self.view.bounds));
}

#pragma mark - Orientations
-(NSUInteger)supportedInterfaceOrientations{
	return UIInterfaceOrientationMaskAll;
}
-(BOOL)shouldAutorotate{
	return YES;
}
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
	return [[UIApplication sharedApplication] statusBarOrientation];
}

@end


@implementation AKSlidecksBar
-(id)initWithIndex:(NSUInteger)index{
	self = [super initWithFrame:CGRectMake(0, 0, DECK_W, TOOLBAR_H)];
	if (self){
		_index = index;
		self.backgroundColor = COLOR_NAVBAR_BG;
		self.translucent = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth  | UIViewAutoresizingFlexibleBottomMargin;
		self.barTintColor = COLOR_NAVBAR_BG;
		self.barStyle = UIBarStyleDefault;
		self.tag = TOOLBAR_TAG;
		
		UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(BTN_W_H+MARGIN10, 20, DECK_W - 2*BTN_W_H - 2*MARGIN10, TOOLBAR_H-20)];
		title.textAlignment = NSTextAlignmentCenter;
		title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		title.font = HELV_NEUE_MEDIUM(17);
		title.textColor = COLOR_NAVBAR_TINT;
		title.numberOfLines = 1;
		[self addSubview:title];
		
		UIButton *slideBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, BTN_W_H, BTN_W_H)];
		slideBtn.backgroundColor = [UIColor clearColor];
		slideBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
		slideBtn.tag = SLIDE_BTN_TAG_OFFSET + index;
		[slideBtn setImageEdgeInsets:UIEdgeInsetsMake(1, 0, 0, 6)];
		[slideBtn setTitleColor:COLOR_NAVBAR_TINT forState:UIControlStateNormal];
		[slideBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
		[slideBtn addTarget:self action:@selector(slideBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:slideBtn];
		
		self.titleLabel = title;
		self.slideButton = slideBtn;
		self.buttonType = AKSlidecksToTheLeftButton;
		
		AKHorizSeparatorView *bottomLine = [[AKHorizSeparatorView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.frame), CGRectGetWidth(self.bounds), 1.0f)];
		bottomLine.backgroundColor = COLOR_SHADOW;
		bottomLine.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[self addSubview:bottomLine];
	}
	return self;
}
-(void)clearTitleLabel{
	self.titleLabel.text = @"";
}
-(void)clearTitleView{
	[_titleView removeFromSuperview];
	_titleView = nil;
}
-(void)clearRightButton{
	[_rightButtons enumerateObjectsUsingBlock:^(UIButton *btn, NSUInteger idx, BOOL *stop) {
		[btn removeFromSuperview];
	}];
	_rightButtons = nil;
//	[_rightButton removeFromSuperview];
//	_rightButton = nil;
}
-(void)setTitleView:(UIView *)titleView{
	[self clearTitleView];
	[self clearTitleLabel];
	UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(BTN_W_H+MARGIN10, 20, DECK_W - 2*BTN_W_H - 2*MARGIN10, TOOLBAR_H-20)];
	containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	containerView.contentMode = UIViewContentModeCenter;
	[containerView addSubview:titleView];
	_titleView = containerView;
	[self addSubview:_titleView];
}
-(void)setButtonType:(AKSlidecksButtonType)buttonType{
	_buttonType = buttonType;
	
	switch (buttonType) {
		case AKSlidecksToTheRightButton:
			[self.slideButton setImage:[UIImage imageNamed:@"icon_arrow_right"] forState:UIControlStateNormal];
			break;
		case AKSlidecksToTheLeftButton:
			[self.slideButton setImage:[UIImage imageNamed:@"icon_arrow_left"] forState:UIControlStateNormal];
			break;
	}
}
-(void)setRightButtons:(NSArray *)rightButtons{
	[self clearRightButton];
	[rightButtons enumerateObjectsUsingBlock:^(UIButton *btn, NSUInteger idx, BOOL *stop) {
		btn.frame = CGRectMake(CGRectGetMaxX(self.frame) - (idx + 1)*BTN_W_H, 20, BTN_W_H, BTN_W_H);
		btn.backgroundColor = COLOR_NAVBAR_BG;
		btn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		btn.tag = SLIDE_BTN_TAG_OFFSET + self.index;
		[self addSubview:btn];
	}];
	_rightButtons = rightButtons;
}
-(void)slideBtnPressed:(id)sender{
	if ([_slidecksBarDelegate respondsToSelector:@selector(slidecksBar:slideBtnPressed:)]){
		[_slidecksBarDelegate slidecksBar:self slideBtnPressed:sender];
	}
}
-(void)rightBtnPressed:(id)sender{
	if ([_slidecksBarDelegate respondsToSelector:@selector(slidecksBar:rightBtnPressed:)]){
		[_slidecksBarDelegate slidecksBar:self rightBtnPressed:sender];
	}
}
@end


@implementation AKSlidecksItem
-(void)setTitleView:(UIView *)titleView{
	_titleView = titleView;
	_slidecksBar.titleView = titleView;
}
-(void)setRightButtons:(NSArray *)rightButtons{
	_rightButtons = rightButtons;
	_slidecksBar.rightButtons = rightButtons;
}
@end