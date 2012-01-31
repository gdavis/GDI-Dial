//
//  GDIViewController.m
//  GDIDial
//
//  Created by Grant Davis on 1/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIViewController.h"

#define kDialRadius 160.f

@implementation GDIViewController
@synthesize dataItems = _dataItems;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _dataItems = [NSArray arrayWithObjects:@"One", @"Two", @"Three",@"Four", nil];
    GDIDialViewController *dialViewController = [[GDIDialViewController alloc] initWithNibName:@"GDIDialView" bundle:nil dataSource:self];
    dialViewController.dialRadius = kDialRadius;
    dialViewController.dialPosition = GDIDialPositionBottom;
    [self.view addSubview:dialViewController.view];
}

- (void)viewDidUnload
{
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
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


#pragma mark - GDIDialViewControllerDataSource Methods

- (NSUInteger)numberOfSlicesForDial
{
    return 100; //[_dataItems count];
}

- (GDIDialSlice *)viewForDialSliceAtIndex:(NSUInteger)index
{
    CGFloat width = 100.f;
    
    GDIDialSlice *slice = [[GDIDialSlice alloc] initWithRadius:kDialRadius width:width];
    
    UIView *debugView = [[UIView alloc] initWithFrame:CGRectMake(-width*.5, 0, width, kDialRadius)];
    debugView.backgroundColor = [self randomColor];
    [slice addSubview:debugView];
    
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(-width*.5, 0, width, kDialRadius)];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.text = [NSString stringWithFormat:@"%i", index];
    [slice addSubview:label];
    
    return slice;
}


- (UIColor *)randomColor {
    CGFloat red =  (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat blue = (CGFloat)random()/(CGFloat)RAND_MAX;
    CGFloat green = (CGFloat)random()/(CGFloat)RAND_MAX;
    return [UIColor colorWithRed:red green:green blue:blue alpha:.5];
}



@end
