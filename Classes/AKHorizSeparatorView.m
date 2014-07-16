//
//  AKHorizSeparator.m
//
//  Created by Andrey Kadochnikov on 04.04.14.
//  Copyright (c) 2014 Andrey Kadochnikov. All rights reserved.
//

#define RETINA ([UIScreen mainScreen].scale > 1.0f)
#import "AKHorizSeparatorView.h"

@interface AKHorizSeparatorView () {
@private
	UIColor *_separatorColor;
}

@end

@implementation AKHorizSeparatorView

- (void) setBackgroundColor:(UIColor *) backgroundColor {
	_separatorColor = backgroundColor;
	[super setBackgroundColor:[UIColor clearColor]];
}

- (UIColor *)backgroundColor {
	return [UIColor clearColor];
}

- (CGSize) intrinsicContentSize {
	return CGSizeMake (UIViewNoIntrinsicMetric, 1.0f);
}

- (void) drawRect:(CGRect) rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext ();
	CGContextSaveGState (ctx);
	
	CGContextSetShouldAntialias (ctx, false);
	CGContextSetStrokeColorWithColor (ctx, _separatorColor.CGColor);
	CGContextSetLineWidth (ctx, (RETINA ? 0.5f : 1.0f));
	
	CGContextMoveToPoint (ctx, CGRectGetMinX (rect), (RETINA ? 0.5f : 1.0f));
	CGContextAddLineToPoint (ctx, CGRectGetMaxX (rect), (RETINA ? 0.5f : 1.0f));
	CGContextStrokePath (ctx);
	
	CGContextRestoreGState (ctx);
}

@end
