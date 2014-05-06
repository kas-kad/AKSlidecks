//
//  HorizontalSwipe.m
//  deleteme4
//
//  Created by Robert Ryan on 6/13/13.
//  Copyright (c) 2013 Robert Ryan. All rights reserved.
//

#import "EdgeSwipeGestureRecognizer.h"

@interface EdgeSwipeGestureRecognizer ()

@property (nonatomic) CGPoint startPoint;
@property (nonatomic) CGPoint currentPoint;
@property (nonatomic) NSTimeInterval currentPointTime;
@property (nonatomic) CGPoint previousPoint;
@property (nonatomic) NSTimeInterval previousPointTime;

@end

@implementation EdgeSwipeGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self) {
        _minimumRecognitionDistance = 5.0;
        _margin = 20.0;
        _side = kEdgeSwipeGestureRecognizerLeft;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    // if not single finger, then fail
    
    if ([touches count] != 1)
    {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }

    UITouch *touch = touches.anyObject;
    CGPoint location = [touches.anyObject locationInView:self.view];

    // if gesture started beyond the margin, then fail

    if ((self.side == kEdgeSwipeGestureRecognizerLeft   && location.x > self.margin) ||
        (self.side == kEdgeSwipeGestureRecognizerRight  && location.x < (self.view.bounds.size.width - self.margin)) ||
        (self.side == kEdgeSwipeGestureRecognizerTop    && location.y > self.margin) ||
        (self.side == kEdgeSwipeGestureRecognizerBottom && location.y < (self.view.bounds.size.height - self.margin)))
    {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }

    // otherwise, then this gesture is still possible, so let's save the current state
    
    self.startPoint = [touches.anyObject locationInView:self.view];
    self.currentPoint = self.startPoint;
    self.currentPointTime = touch.timestamp;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];

    if (self.state == UIGestureRecognizerStateFailed) return;

    UITouch *touch = touches.anyObject;
    self.previousPoint = self.currentPoint;
    self.previousPointTime = self.currentPointTime;
    self.currentPoint = [touch locationInView:self.view];
    self.currentPointTime = touch.timestamp;

    if (self.state == UIGestureRecognizerStatePossible)
    {
        CGPoint translate = CGPointMake(self.currentPoint.x - self.startPoint.x, self.currentPoint.y - self.startPoint.y);

        // see if we've moved the necessary minimum distance

        if (sqrt(translate.x * translate.x + translate.y * translate.y) >= self.minimumRecognitionDistance)
        {
            // recognize if the angle is roughly horizontal, otherwise fail

            double angle = atan2(translate.y, translate.x);            

            if ([self isAngleCloseEnough:angle])
                self.state = UIGestureRecognizerStateBegan;
            else
                self.state = UIGestureRecognizerStateFailed;
        }
    }
    else if (self.state == UIGestureRecognizerStateBegan)
    {
        self.state = UIGestureRecognizerStateChanged;
    }
}

- (double) angleForGestureSide:(EdgeSwipeGestureRecognizerSide)side
{
    switch (side) {
        case kEdgeSwipeGestureRecognizerLeft:
            return 0;

        case kEdgeSwipeGestureRecognizerRight:
            return M_PI;

        case kEdgeSwipeGestureRecognizerTop:
            return M_PI_2;

        case kEdgeSwipeGestureRecognizerBottom:
            return M_PI_2 * 3.0;

        default:
            break;
    }
}

- (BOOL)isAngleCloseEnough:(CGFloat)angle
{
    double angleForGestureEdge = [self angleForGestureSide:self.side];

    if (self.side != kEdgeSwipeGestureRecognizerLeft)
    {
        if (angle < 0.0) angle += (M_PI * 2.0);
    }

    return (angle > (angleForGestureEdge - M_PI_4) && angle < (angleForGestureEdge + M_PI_4));
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    if (self.state == UIGestureRecognizerStatePossible)
    {
        self.state = UIGestureRecognizerStateFailed;
    }
    if (self.state == UIGestureRecognizerStateChanged || self.state == UIGestureRecognizerStateBegan)
    {
        self.state = UIGestureRecognizerStateEnded;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    self.startPoint = CGPointZero;
    self.state = UIGestureRecognizerStateFailed;
}

- (CGPoint)translationInView:(UIView *)view
{
    CGPoint start   = [view convertPoint:self.startPoint   fromView:self.view];
    CGPoint current = [view convertPoint:self.currentPoint fromView:self.view];
    return CGPointMake(current.x - start.x, current.y - start.y);
}

- (CGPoint)velocityInView:(UIView *)view
{
    CGPoint current  = [view convertPoint:self.currentPoint  fromView:self.view];
    CGPoint previous = [view convertPoint:self.previousPoint fromView:self.view];

    CFTimeInterval elapsed = self.currentPointTime - self.previousPointTime;
    if (elapsed == 0.0)
        return CGPointZero;

    return CGPointMake((current.x - previous.x) / elapsed, (current.y - previous.y) / elapsed);
}

@end
