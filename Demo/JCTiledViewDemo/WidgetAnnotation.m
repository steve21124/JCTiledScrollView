//
//  WidgetAnnotation.m
//  JCTiledViewDemo
//
//  Created by Jesse Collis on 17/03/12.
//  Copyright (c) 2012 JC Multimedia Design. All rights reserved.
//

#import "WidgetAnnotation.h"

@implementation WidgetAnnotation 

- (CGPoint)mapPoint
{
  return CGPointMake(256, 256);
}

@end

@implementation WidgetAnnotationView

- (void)drawRect:(CGRect)rect
{
  CGContextRef c = UIGraphicsGetCurrentContext();
  CGFloat scale = CGContextGetCTM(c).a;
  
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, nil, CGRectGetMidX(rect), 0);
  CGPathAddLineToPoint(path, nil, CGRectGetMidX(rect), CGRectGetMaxY(rect));
  CGPathMoveToPoint(path, nil, 0, CGRectGetMidY(rect));
  CGPathAddLineToPoint(path, nil, CGRectGetMaxX(rect), CGRectGetMidY(rect));
  CGPathMoveToPoint(path, nil, 0, 0);
  CGPathAddEllipseInRect(path, nil, CGRectInset(rect, 6, 6));
  
  CGContextSetStrokeColorWithColor(c, [[UIColor colorWithWhite:0 alpha:0.7] CGColor]); 
  CGContextSetLineWidth(c, 2 / scale);
  CGContextAddPath(c, path);
  CGContextStrokePath(c);
  CGPathRelease(path);
  
  path = CGPathCreateMutable();
  CGPathAddRect(path, nil, CGRectInset(rect, 2, 2));
  CGContextSetStrokeColorWithColor(c, [[UIColor colorWithWhite:0 alpha:0.5] CGColor]);
  CGContextSetLineWidth(c, 1/scale);
  CGContextAddPath(c, path);
  CGContextStrokePath(c);
  CGPathRelease(path);
}

@end
