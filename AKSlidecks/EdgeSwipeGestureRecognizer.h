//
//  HorizontalSwipe.h
//  deleteme4
//
//  Created by Robert Ryan on 6/13/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

typedef enum : NSInteger {
    kEdgeSwipeGestureRecognizerLeft,
    kEdgeSwipeGestureRecognizerRight,
    kEdgeSwipeGestureRecognizerTop,
    kEdgeSwipeGestureRecognizerBottom
} EdgeSwipeGestureRecognizerSide;

/** Continuous gesture recognized when swiping from the edge of the screen, travelling particular distance in particular direction.
 
 ##See Also
 
 - [Edge Swipe Demonstration GitHub Site](https://github.com/robertmryan/edge-swipe-demonstration)
 */

@interface EdgeSwipeGestureRecognizer : UIPanGestureRecognizer

/*********************************************
 * @name Properties
 *********************************************/

/// From which edge are we detecting swipe

@property (nonatomic) EdgeSwipeGestureRecognizerSide side;

/// Minimum distance that must be traveled before recognizing direction

@property (nonatomic) CGFloat minimumRecognitionDistance;

/// Margin from side to detect gesture

@property (nonatomic) CGFloat margin;
@end
