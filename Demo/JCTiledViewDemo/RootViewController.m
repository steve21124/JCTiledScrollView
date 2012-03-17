//
//  RootViewController.m
//  JCTiledViewDemo
//
//  Created by Jesse Collis on 1/02/12.
//  Copyright (c) 2012 JC Multimedia Design. All rights reserved.
//

#import "RootViewController.h"
#import "JCTiledPDFScrollView.h"
#import "JCTiledScrollViewAnnotationView.h"
#import "WidgetAnnotation.h"

#define SkippingGirlImageSize CGSizeMake(432., 648.)

@implementation RootViewController

@synthesize scrollView = scrollView_;
@synthesize detailView = detailView_;

- (void)dealloc
{
  [scrollView_ release];
  scrollView_ = nil;

  [detailView_ release];
  detailView_ = nil;
  
  [super dealloc];
}


#pragma mark - View lifecycle

- (void)loadView
{
  UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 460.0f)] autorelease];
  view.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
  self.view = view;
}

- (void)viewDidLoad
{
  self.detailView = [[[DetailView alloc] initWithFrame:CGRectZero] autorelease];
  self.detailView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  CGSize size_for_detail = [self.detailView sizeThatFits:self.view.bounds.size];
  [self.detailView setFrame:CGRectMake(0,0,size_for_detail.width, size_for_detail.height)];
  [self.view addSubview:self.detailView];
  
  CGRect scrollView_frame = CGRectOffset(CGRectInset(self.view.bounds,0.,size_for_detail.height/2.0f),0.,size_for_detail.height/2.0f);
  
  //PDF
  //self.scrollView = [[[JCTiledPDFScrollView alloc] initWithFrame:scrollView_frame URL:[[NSBundle mainBundle] URLForResource:@"Map" withExtension:@"pdf"]] autorelease];
  
  //Bitmap
  self.scrollView = [[[JCTiledScrollView alloc] initWithFrame:scrollView_frame contentSize:SkippingGirlImageSize] autorelease];
  self.scrollView.dataSource = self;

  self.scrollView.tiledScrollViewDelegate = self;
  self.scrollView.zoomScale = 1.0f;

  // totals 4 sets of tiles across all devices, retina devices will miss out on the first 1x set
  self.scrollView.levelsOfZoom = 3;
  self.scrollView.levelsOfDetail = 3;
  
  [self.view addSubview:self.scrollView];

  [self tiledScrollViewDidZoom:self.scrollView]; //force the detailView to update the frist time
  
  WidgetAnnotation *annotation = [[[WidgetAnnotation alloc] init] autorelease];
  [self.scrollView addAnnotation:annotation];
}

- (void)viewDidUnload
{
  [super viewDidUnload];

  self.scrollView = nil;
  self.detailView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

#pragma mark - JCTiledScrollViewDelegate

- (void)tiledScrollViewDidZoom:(JCTiledScrollView *)scrollView
{
  self.detailView.textLabel.text = [NSString stringWithFormat:@"zoomScale: %0.2f", scrollView.zoomScale];
}

- (void)tiledScrollView:(JCTiledScrollView *)scrollView didReceiveSingleTap:(UIGestureRecognizer *)gestureRecognizer
{
  CGPoint tapPoint = [gestureRecognizer locationInView:(UIView *)scrollView.tiledView];

  //tap point on the tiledView does not inlcude the zoomScale applied by the scrollView
  self.detailView.textLabel.text = [NSString stringWithFormat:@"zoomScale: %0.2f, x: %0.0f y: %0.0f", scrollView.zoomScale, tapPoint.x, tapPoint.y];
}

- (JCTiledScrollViewAnnotationView *)annotationViewForAnnotation:(id<JCTiledScrollViewAnnotation>)annotation
{
  JCTiledScrollViewAnnotationView *annotationView = [[WidgetAnnotationView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
  annotationView.backgroundColor = [UIColor greenColor];
  return [annotationView autorelease];
}

#pragma mark - JCTileSource

#define SkippingGirlImageName @"SkippingGirl"

- (UIImage *)tiledScrollView:(JCTiledScrollView *)scrollView imageForRow:(NSInteger)row column:(NSInteger)column scale:(NSInteger)scale
{
 return [UIImage imageNamed:[NSString stringWithFormat:@"tiles/%@_%dx_%d_%d.png", SkippingGirlImageName, scale, row, column]]; 
}


@end
