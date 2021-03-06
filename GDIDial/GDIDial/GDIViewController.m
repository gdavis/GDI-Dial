//
//  GDIViewController.m
//  GDIDial
//
//  Created by Grant Davis on 1/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIViewController.h"
#import "GDIArcLabel.h"
#import "GrillGuideDialSlice.h"
#import "GDIMath.h"

#define kDialRadius 241.f
#define kDialSlicePadding 25.f

@implementation GDIViewController
@synthesize currentSliceLabel = _currentSliceLabel;
@synthesize selectedSliceLabel = _selectedSliceLabel;
@synthesize dialContainerView = _dialContainerView;
@synthesize reloadButton = _reloadButton;
@synthesize dataItems = _dataItems;
@synthesize dialViewController = _dialViewController;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Rare,Medium Rare,Medium,Medium Well,Well Done
    
//    _dataItems = [NSArray arrayWithObjects:@"Rare", @"Medium Rare", @"Medium",@"Medium Well", @"Well Done", nil];
    
//    "1\U00bd\" thick,2\" thick,1\" thick,1\U00bc\" thick"
    // 1½" thick,2" thick,1" thick,1¼" thick
    _dataItems = [NSArray arrayWithObjects:@"1½\" thick", @"2\" thick", @"1\" thick", @"1¼\" thick", nil];
    _dialViewController = [[GDIDialViewController alloc] initWithNibName:@"GDIDialView" bundle:nil];
    _dialViewController.delegate = self;
    _dialViewController.dialRadius = kDialRadius;
    _dialViewController.dialPosition = GDIDialPositionBottom;
    _dialViewController.dialRegistrationViewRadius = 183.f;
    _dialViewController.view.frame = CGRectMake(self.dialContainerView.frame.size.width * .5 - kDialRadius, -kDialRadius*2 - 44.f + self.dialContainerView.frame.size.height, kDialRadius*2, kDialRadius*2);
    [self.dialContainerView addSubview:_dialViewController.view];    
    _dialViewController.dataSource = self;
}

- (void)viewDidUnload
{
    [self setCurrentSliceLabel:nil];
    [self setSelectedSliceLabel:nil];
    [self setDialContainerView:nil];
    [self setReloadButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - GDIDialViewControllerDelegate Methods


- (void)dialViewController:(GDIDialViewController *)dialVC didRotateToIndex:(NSUInteger)index
{
//    NSLog(@"%@ did rotate to index: %i", dialVC, index); 
    self.currentSliceLabel.text = [NSString stringWithFormat:@"Current slice index: %i", index];
}

- (void)dialViewController:(GDIDialViewController *)dialVC didSelectIndex:(NSUInteger)selectedIndex
{
//    NSLog(@"%@ did select index: %i", dialVC, selectedIndex);
    self.selectedSliceLabel.text = [NSString stringWithFormat:@"Selected slice index: %i", selectedIndex];
}


#pragma mark - GDIDialViewControllerDataSource Methods

- (NSUInteger)numberOfSlicesForDialViewController:(GDIDialViewController *)dialVC
{
    return _dataItems.count;
}

- (GDIDialSlice *)dialViewController:(GDIDialViewController *)dialVC viewForDialSliceAtIndex:(NSUInteger)index
{        
//    NSString *sliceLabel = [[NSString stringWithFormat:@"Dial Slice %i", index] uppercaseString];
    NSString *sliceLabel = [[_dataItems objectAtIndex:index] uppercaseString];
    UIFont *font = [UIFont boldSystemFontOfSize:18.f];
    
    // here we calculate how big the slice will be with the given text. we use the convenience method on the GDICurvedLabel
    // to get how many radians it takes to draw that text with that font at the given radius, 
    // create two points for the two corners of the triangle for the given arc the text will sit on, 
    // measure the distance between them, and use that as our slice width plus a little extra padding to give the slices some room.
    CGFloat textRadius = kDialRadius - 18;
    CGPoint rightCornerPoint = cartesianCoordinateFromPolar(textRadius, 0);
    CGPoint leftCornerPoint =  cartesianCoordinateFromPolar(textRadius, [GDIArcLabel sizeInRadiansOfText:sliceLabel font:font radius:textRadius kerning:2.f]);
    CGFloat dist = fabsf(distance(rightCornerPoint.x, rightCornerPoint.y, leftCornerPoint.x, leftCornerPoint.y));
    
    GrillGuideDialSlice *slice = [[GrillGuideDialSlice alloc] initWithRadius:kDialRadius width:dist+kDialSlicePadding*2];
    
//    slice.backgroundLayer.lineWidth = 1.f;
//    slice.backgroundLayer.strokeColor = [[UIColor redColor] CGColor];
//    slice.backgroundLayer.fillColor = [[self randomColor] CGColor];

    slice.label.radius = textRadius;
    slice.label.text = sliceLabel;
    slice.label.font = font;
    
    return slice;
}


- (UIColor *)randomColor {
    CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:.5];
}



- (IBAction)handleReload:(id)sender {
    [_dialViewController reloadData];
}


@end
