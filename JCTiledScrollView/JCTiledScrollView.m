//
//  JCTiledScrollView.m
//  
//  Created by Jesse Collis on 1/2/2012.
//  Copyright (c) 2012, Jesse Collis JC Multimedia Design. <jesse@jcmultimedia.com.au>
//  All rights reserved.
//
//  * Redistribution and use in source and binary forms, with or without 
//   modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright 
//   notice, this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright 
//   notice, this list of conditions and the following disclaimer in the 
//   documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY 
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES 
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND 
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE
//

#import "JCTiledScrollView.h"
#import "JCTiledView.h"

#import "JCTiledScrollViewAnnotation.h"
#import "JCTiledScrollViewAnnotationView.h"

@interface JCTiledScrollView () <JCTiledBitmapViewDelegate> {
  NSMutableSet *_annotations;
  NSMutableSet *_annotationViews;
}

@property (nonatomic, retain) UIView *canvasView; //remove property

@property (nonatomic, retain) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *twoFingerTapGestureRecognizer;

- (void)singleTapReceived:(UITapGestureRecognizer *)gestureRecognizer;
- (void)twoFingerTapReceived:(UITapGestureRecognizer *)gestureRecognizer;
- (void)doubleTapReceived:(UITapGestureRecognizer *)gestureRecognizer;

- (void)updateAnnotationViews;

@end

@implementation JCTiledScrollView

@synthesize tiledScrollViewDelegate = _tiledScrollViewDelegate;
@synthesize levelsOfZoom = _levelsOfZoom;
@synthesize levelsOfDetail = _levelsOfDetail;
@synthesize tiledView = _tiledView;
@synthesize canvasView = _canvasView;
@synthesize dataSource = _dataSource;
@synthesize zoomsOutOnTwoFingerTap = _zoomsOutOnTwoFingerTap;
@synthesize zoomsInOnDoubleTap = _zoomsInOnDoubleTap;
@synthesize centerSingleTap = _centerSingleTap;
@synthesize singleTapGestureRecognizer = _singleTapGestureRecognizer;
@synthesize doubleTapGestureRecognizer = _doubleTapGestureRecognizer;
@synthesize twoFingerTapGestureRecognizer = _twoFingerTapGestureRecognizer;
@dynamic annotations;

+ (Class)tiledLayerClass
{
  return [JCTiledView class];
}

- (id)initWithFrame:(CGRect)frame contentSize:(CGSize)contentSize
{
	if ((self = [super initWithFrame:frame]))
  {
    self.autoresizingMask = (UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth);
    self.levelsOfZoom = 2;
    self.minimumZoomScale = 1.;
    self.delegate = self;
    self.backgroundColor = [UIColor whiteColor];
    self.contentSize = contentSize;
    self.bouncesZoom = YES;
    self.bounces = YES;

    self.zoomsInOnDoubleTap = YES;
    self.zoomsOutOnTwoFingerTap = YES;
    self.centerSingleTap = YES;

    _annotations = [[NSMutableSet alloc] init];
    _annotationViews = [[NSMutableSet alloc] init];

    CGRect canvas_frame = CGRectMake(0.0f, 0.0f, self.contentSize.width, self.contentSize.height);
    _canvasView = [[UIView alloc] initWithFrame:canvas_frame];

    self.tiledView = [[[[[self class] tiledLayerClass] alloc] initWithFrame:canvas_frame] autorelease];
    self.tiledView.delegate = self;
    
    [self.canvasView addSubview:self.tiledView];
    [self addSubview:self.canvasView];

    _singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapReceived:)];
    _singleTapGestureRecognizer.numberOfTapsRequired = 1;
    [self.canvasView addGestureRecognizer:self.singleTapGestureRecognizer];

    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapReceived:)];
    _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.canvasView addGestureRecognizer:self.doubleTapGestureRecognizer];

    [self.singleTapGestureRecognizer requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];

    _twoFingerTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerTapReceived:)];
    _twoFingerTapGestureRecognizer.numberOfTouchesRequired = 2;
    _twoFingerTapGestureRecognizer.numberOfTapsRequired = 1;
    [self.canvasView addGestureRecognizer:_twoFingerTapGestureRecognizer];
	}

	return self;
}

-(void)dealloc
{	
  RELEASE(_tiledView);
  RELEASE(_canvasView);
  RELEASE(_singleTapGestureRecognizer);
  RELEASE(_doubleTapGestureRecognizer);
  RELEASE(_twoFingerTapGestureRecognizer);
  RELEASE(_annotations);
  RELEASE(_annotationViews);

	[super dealloc];
}

#pragma mark - UIScrolViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
  return self.canvasView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
  if ([self.tiledScrollViewDelegate respondsToSelector:@selector(tiledScrollViewDidZoom:)])
  {
    [self.tiledScrollViewDelegate tiledScrollViewDidZoom:self];
  }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
  //float closestLOD = powf(2, floorf(log2f(scrollView.zoomScale))) * [[UIScreen mainScreen] scale];
  float newScale = scrollView.zoomScale * [[UIScreen mainScreen] scale];
  for (UIView *annotationView in _annotationViews)
  {
    annotationView.contentScaleFactor = newScale;
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if ([self.tiledScrollViewDelegate respondsToSelector:@selector(tiledScrollViewDidScroll:)])
  {
    [self.tiledScrollViewDelegate tiledScrollViewDidScroll:self];
  }
}

#pragma mark - Gesture Suport

- (void)singleTapReceived:(UITapGestureRecognizer *)gestureRecognizer
{
  if (self.centerSingleTap)
  {
    [self setContentCenter:[gestureRecognizer locationInView:self.tiledView] animated:YES];
  }

  if ([self.tiledScrollViewDelegate respondsToSelector:@selector(tiledScrollView:didReceiveSingleTap:)])
  {
    [self.tiledScrollViewDelegate tiledScrollView:self didReceiveSingleTap:gestureRecognizer];
  }
}

- (void)doubleTapReceived:(UITapGestureRecognizer *)gestureRecognizer
{
  if (self.zoomsInOnDoubleTap)
  {
    float newZoom = MIN(powf(2, (log2f(self.zoomScale) + 1.0f)), self.maximumZoomScale); //zoom in one level of detail
    [self setZoomScale:newZoom animated:YES];
  }

  if ([self.tiledScrollViewDelegate respondsToSelector:@selector(tiledScrollView:didReceiveDoubleTap:)])
  {
    [self.tiledScrollViewDelegate tiledScrollView:self didReceiveDoubleTap:gestureRecognizer];
  }
}

- (void)twoFingerTapReceived:(UITapGestureRecognizer *)gestureRecognizer
{
  if (self.zoomsOutOnTwoFingerTap)
  {
    float newZoom = MAX(powf(2, (log2f(self.zoomScale) - 1.0f)), self.minimumZoomScale); //zoom out one level of detail
    [self setZoomScale:newZoom animated:YES];
  }

  if ([self.tiledScrollViewDelegate respondsToSelector:@selector(tiledScrollView:didReceiveTwoFingerTap:)])
  {
    [self.tiledScrollViewDelegate tiledScrollView:self didReceiveTwoFingerTap:gestureRecognizer];
  }
}


#pragma mark - Annotations

- (NSArray *)annotations
{
  return [_annotations allObjects];
}

- (void)addAnnotation:(id<JCTiledScrollViewAnnotation>)annotation
{
  [self addAnnotations:[NSArray arrayWithObject:annotation]];
}

- (void)addAnnotations:(NSArray *)annotations
{
  NSUInteger before = [_annotations count];
  [_annotations addObjectsFromArray:annotations];

  if ([_annotations count] > before)
  {
    [self updateAnnotationViews];
  }
}

- (void)removeAnnotation:(id<JCTiledScrollViewAnnotation>)annotation
{
  [self removeAnnotations:[NSArray arrayWithObject:annotation]];
}

- (void)removeAnnotations:(NSArray *)annotations
{
  NSUInteger before = [_annotations count];

  for (id annotation in annotations)
  {
    [_annotations removeObject:annotation];
  }

  if ([_annotations count] < before)
  {
    [self updateAnnotationViews];
  }
}

//FIXME: implementation can be optimised by not searching all arrays and sets so many times
//       consider saving (privately) the relationship between the annotation and annotation view

- (void)updateAnnotationViews
{
  // remove orphaned annotation views
  for (JCTiledScrollViewAnnotationView *annotationView in _annotationViews)
  {
    if (![_annotations containsObject:[annotationView annotation]])
    {
      [annotationView removeFromSuperview];
      [_annotationViews removeObject:annotationView];
    } 
  }

  //add new annotation views
  for (id<JCTiledScrollViewAnnotation>annotation in _annotations)
  {
    id annotationView = nil;
    for (JCTiledScrollViewAnnotationView *view in _annotationViews)
    {
      if (annotation == view.annotation)
      {
        annotationView = view;
        break;
      }
    }
    if (annotationView != nil) continue; //already exists

    if ([self.tiledScrollViewDelegate respondsToSelector:@selector(annotationViewForAnnotation:)])
    {
      JCTiledScrollViewAnnotationView *newAnnotationView = [self.tiledScrollViewDelegate annotationViewForAnnotation:annotation];
      if (nil == newAnnotationView) continue;

      [annotationView sizeToFit];

      CGPoint centerPoint = annotation.mapPoint;
      centerPoint.x += newAnnotationView.offset.width;
      centerPoint.y += newAnnotationView.offset.height;

      newAnnotationView.center = centerPoint;
      newAnnotationView.contentScaleFactor = self.contentScaleFactor * self.zoomScale;

      [_annotationViews addObject:newAnnotationView];
      [self.canvasView addSubview:newAnnotationView];
    }
  }
}

#pragma mark - JCTiledScrollView

- (void)setLevelsOfZoom:(size_t)levelsOfZoom
{
  _levelsOfZoom = levelsOfZoom;
  self.maximumZoomScale = (float)powf(2.0f, MAX(0.0f, levelsOfZoom));
}

- (void)setLevelsOfDetail:(size_t)levelsOfDetail
{
  if (levelsOfDetail == 1) NSLog(@"Note: Setting levelsOfDetail to 1 causes strange behaviour");

  _levelsOfDetail = levelsOfDetail;
  [self.tiledView setNumberOfZoomLevels:levelsOfDetail];
}

- (void)setContentCenter:(CGPoint)center animated:(BOOL)animated
{
  CGPoint new_contentOffset;
  new_contentOffset.x = MAX(0.0f, (center.x * self.zoomScale) - (self.bounds.size.width / 2.0f));
  new_contentOffset.y = MAX(0.0f, (center.y * self.zoomScale) - (self.bounds.size.height / 2.0f));
  
  new_contentOffset.x = MIN(new_contentOffset.x, (self.contentSize.width - self.bounds.size.width));
  new_contentOffset.y = MIN(new_contentOffset.y, (self.contentSize.height - self.bounds.size.height));
  
  [self setContentOffset:new_contentOffset animated:animated];
}

#pragma mark - JCTileSource

- (UIImage *)tiledView:(JCTiledView *)tiledView imageForRow:(NSInteger)row column:(NSInteger)column scale:(NSInteger)scale
{
  return [self.dataSource tiledScrollView:self imageForRow:row column:column scale:scale];
}

@end
