//
//  GDIDialViewController.m
//  GDIDial
//
//  Created by Grant Davis on 1/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GDIDialViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "GDIMath.h"

#define kDefaultFriction .95f
#define kAnimationInterval 1.f/60.f

@interface GDIDialViewController()

@property(strong,nonatomic) UIView *rotatingDialContainerView;
@property(strong,nonatomic) UIView *rotatingSlicesContainerView;
@property(nonatomic) CGFloat initialRotation;
@property(nonatomic) CGFloat currentRotation;
@property(nonatomic) CGFloat velocity;
@property(nonatomic) CGPoint lastPoint;
@property(nonatomic) CGPoint dialPoint;
@property(nonatomic) CGFloat dialRotation;
@property(strong,nonatomic) NSTimer *decelerationTimer;
@property(strong,nonatomic) NSTimer *rotateToSliceTimer;
@property(nonatomic) CGFloat targetRotation;
@property(strong,nonatomic) NSMutableArray *visibleSlices;
@property(nonatomic) NSInteger indexOfFirstSlice;
@property(nonatomic) NSInteger indexOfLastSlice;

- (void)initializeDialPoint;
- (void)buildVisibleSlices;
- (void)setInitialStartingPosition;
- (void)updateVisibleSlices;

- (void)addFirstSlice;
- (void)removeFirstSlice;
- (void)addEndSlice;
- (void)removeEndSlice;

- (void)beginDeceleration;
- (void)endDeceleration;

- (void)beginNearestSliceRotation;
- (void)endNearestSliceRotation;

- (void)rotateToNearestSlice;
- (void)rotateDialByRadians:(CGFloat)radians;

- (CGPoint)normalizedPoint:(CGPoint)point inView:(UIView *)view;
- (void)trackTouchPoint:(CGPoint)point inView:(UIView*)view;

@end


@implementation GDIDialViewController

@synthesize dialPosition = _dialPosition;
@synthesize dialRadius = _dialRadius;
@synthesize rotatingDialView = _rotatingDialView;
@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize currentIndex = _currentIndex;
@synthesize friction = _friction;

@synthesize rotatingSlicesContainerView = _rotatingSlicesContainerView;
@synthesize rotatingDialContainerView = _rotatingDialContainerView;
@synthesize gestureView = _gestureView;
@synthesize initialRotation = _initialRotation;
@synthesize currentRotation = _currentRotation;
@synthesize velocity = _velocity;
@synthesize lastPoint = _lastPoint;
@synthesize dialPoint = _dialPoint;
@synthesize dialRotation = _dialRotation;
@synthesize decelerationTimer = _decelerationTimer;
@synthesize rotateToSliceTimer = _rotateToSliceTimer;
@synthesize targetRotation = _targetRotation;
@synthesize visibleSlices = _visibleSlices;
@synthesize indexOfFirstSlice = _indexOfFirstSlice;
@synthesize indexOfLastSlice = _indexOfLastSlice;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil dataSource:(NSObject<GDIDialViewControllerDataSource>*)dataSource
{
    self = [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        _dataSource = dataSource;
        _dialPosition = GDIDialPositionBottom;
        _dialRadius = 160.f;
        _friction = kDefaultFriction;
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // add rotating dial view
    _rotatingDialContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.view.center.x, self.view.center.y, 0, 0)];
    [self.view addSubview:_rotatingDialContainerView];
    
    // position dial view in negative space for easy rotation
    self.rotatingDialView.frame = CGRectMake(-self.rotatingDialView.frame.size.width*.5, -self.rotatingDialView.frame.size.height*.5, self.rotatingDialView.frame.size.width, self.rotatingDialView.frame.size.height);
    [_rotatingDialContainerView addSubview:self.rotatingDialView];
    
    
    
    // add container for the slices
    _rotatingSlicesContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.view.center.x, self.view.center.y, 0, 0)];
    [self.view addSubview:_rotatingSlicesContainerView];
    
    
    // create a custom gesture view which tells us when there are touches on the dial
    CGRect gestureViewFrame = CGRectMake(self.view.bounds.size.width * .5 - self.rotatingDialView.frame.size.width * .5, self.view.bounds.size.height * .5 - self.rotatingDialView.frame.size.height * .5, self.rotatingDialView.frame.size.width, self.rotatingDialView.frame.size.height);
    
    _gestureView = [[GDIDialGestureView alloc] initWithFrame:gestureViewFrame dialRadius:_dialRadius];
    _gestureView.delegate = self;
    [self.view addSubview:_gestureView];
    
    [self buildVisibleSlices];
    [self setInitialStartingPosition];
    [self initializeDialPoint];
}


- (void)viewDidUnload
{
    [self setRotatingDialContainerView:nil];
    [self setRotatingDialView:nil];
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Class Methods

- (void)rotateDialToIndex:(NSUInteger)index
{
    
}


- (NSArray *)visibleSlices
{
    return [NSArray arrayWithArray:_visibleSlices];
}


#pragma mark - Private Methods


- (void)initializeDialPoint
{
    if (_dialPosition == GDIDialPositionTop) { 
        _dialRotation = degreesToRadians(-90);
    }
    else if (_dialPosition == GDIDialPositionBottom) {
        _dialRotation = degreesToRadians(90);
    }
    else if (_dialPosition == GDIDialPositionLeft) {
        _dialRotation = degreesToRadians(-180);
    }
    else {
        _dialRotation = 0;
    }
    
    _dialPoint = cartesianCoordinateFromPolar(_dialRadius, _dialRotation);
    
    _dialPoint.x += self.view.center.x;
    _dialPoint.y += self.view.center.y;
    
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(-5 + _dialPoint.x, -5 + _dialPoint.y, 10, 10);
    layer.backgroundColor = [[UIColor redColor] CGColor];
    [self.view.layer addSublayer:layer];
}


- (void)buildVisibleSlices
{
    _visibleSlices = [NSMutableArray array];
    _indexOfFirstSlice = 0;
    
    NSUInteger dl = [_dataSource numberOfSlicesForDial];
    
    // we limit our dial to only show half of the dial at a time.
    // this allows us to have an infinite number of slices within the dial
    CGFloat maxRadians = M_PI;
    CGFloat currentRadians = 0.f;
    
    for (int i=0; i<dl; i++) {
        
        GDIDialSlice *slice = [_dataSource viewForDialSliceAtIndex:i];
        slice.rotation = currentRadians - [slice sizeInRadians] * .5;
        currentRadians -= [slice sizeInRadians];
        
        [_rotatingSlicesContainerView addSubview:slice];
        [_visibleSlices addObject:slice];
        
        if (currentRadians <= -maxRadians) {
            _indexOfLastSlice = i;
            break;
        }
    }
}


- (void)addFirstSlice
{
    GDIDialSlice *firstSlice = [_visibleSlices objectAtIndex:0];
    CGFloat currentRadians = atan2(firstSlice.transform.b, firstSlice.transform.a) + [firstSlice sizeInRadians]*.5;
    
    _indexOfFirstSlice--;
    if (_indexOfFirstSlice < 0) {
        _indexOfFirstSlice = [_dataSource numberOfSlicesForDial]-1;
    }
    
    GDIDialSlice *slice = [_dataSource viewForDialSliceAtIndex:_indexOfFirstSlice];
    slice.rotation = currentRadians + [slice sizeInRadians] * .5;
    
    [_rotatingSlicesContainerView addSubview:slice];
    [_visibleSlices insertObject:slice atIndex:0];
}


- (void)removeFirstSlice
{
    GDIDialSlice *firstSlice = [_visibleSlices objectAtIndex:0];
    [firstSlice removeFromSuperview];
    [_visibleSlices removeObject:firstSlice];
    
    _indexOfFirstSlice++;
    if (_indexOfFirstSlice > [_dataSource numberOfSlicesForDial]-1) {
        _indexOfFirstSlice = 0;
    }
}


- (void)addEndSlice
{
    GDIDialSlice *lastSlice = [_visibleSlices lastObject];
    CGFloat currentRadians = atan2(lastSlice.transform.b, lastSlice.transform.a) - [lastSlice sizeInRadians]*.5;
    
    _indexOfLastSlice++;
    if (_indexOfLastSlice >= [_dataSource numberOfSlicesForDial]) {
        _indexOfLastSlice = 0;
    }
    
    GDIDialSlice *slice = [_dataSource viewForDialSliceAtIndex:_indexOfLastSlice];
    slice.rotation = currentRadians - [slice sizeInRadians] * .5;
    
    [_rotatingSlicesContainerView addSubview:slice];
    [_visibleSlices addObject:slice];
}


- (void)removeEndSlice
{
    GDIDialSlice *lastSlice = [_visibleSlices lastObject];
    [lastSlice removeFromSuperview];
    [_visibleSlices removeObject:lastSlice];
    
    _indexOfLastSlice--;
    if (_indexOfLastSlice < 0) {
        _indexOfLastSlice = [_dataSource numberOfSlicesForDial]-1;
    }
}


- (void)setInitialStartingPosition
{
    if (_dialPosition == GDIDialPositionTop) {
        _initialRotation = degreesToRadians(-90);
    }
    else if (_dialPosition == GDIDialPositionBottom) {
        _initialRotation = degreesToRadians(90);
    }
    else if (_dialPosition == GDIDialPositionLeft) {
        _initialRotation = degreesToRadians(180);
    }
    else {
        _initialRotation = 0;
    }
    _currentRotation = _initialRotation;
    _rotatingSlicesContainerView.transform = CGAffineTransformMakeRotation(_initialRotation);
    _rotatingDialContainerView.transform = CGAffineTransformMakeRotation(_initialRotation);
}


- (void)rotateToNearestSlice
{
    float closestDistance = FLT_MAX;
    
    NSLog(@"dial point: %@, dial rotation: %.2f, currentRotation: %.2f, initialRotation: %.2f", NSStringFromCGPoint(_dialPoint), _dialRotation, _currentRotation, _initialRotation);
    
    for (int i=0; i<[_visibleSlices count]; i++) {
        GDIDialSlice *slice = [_visibleSlices objectAtIndex:i];
        
        float dist = ( _dialRotation - _initialRotation - M_PI * .5) - slice.rotation;
        
        NSLog(@"slice rotation: %.2f, distance from dial: %.2f", slice.rotation, dist);
        
        if (fabsf(dist) < fabsf(closestDistance)) {
            
            closestDistance = dist;
            
            _targetRotation = _currentRotation + dist;
            _currentIndex = i;
        }
    }
    
    NSLog(@"closest index is: %i with a distance of: %.2f, targetRotation: %.2f", _currentIndex, closestDistance, _targetRotation);
    
    [self beginNearestSliceRotation];
}

- (void)beginNearestSliceRotation
{
    [_rotateToSliceTimer invalidate];
    _rotateToSliceTimer = [NSTimer scheduledTimerWithTimeInterval:kAnimationInterval target:self selector:@selector(handleRotateToSliceTimer) userInfo:nil repeats:YES];
}

- (void)endNearestSliceRotation
{
    [_rotateToSliceTimer invalidate];
    _rotateToSliceTimer = nil;
}


- (void)handleRotateToSliceTimer 
{
    CGFloat delta = (_targetRotation - _currentRotation) * (1 - _friction);
    [self rotateDialByRadians:delta];
    
    if (fabsf(delta) < .0001) {
        [self rotateDialByRadians:_targetRotation - _currentRotation];
        [self endNearestSliceRotation];
    }
}


- (void)rotateDialByRadians:(CGFloat)radians
{    
    _currentRotation += radians;
    
    if (fabsf(_currentRotation) > M_PI * 2) {
       if (_currentRotation < 0) {
           _currentRotation += M_PI*2;
       }
       else {
           _currentRotation -= M_PI*2;
        }
    }
    
    NSArray *slices = _rotatingSlicesContainerView.subviews;
    for (GDIDialSlice *slice in slices) {
        slice.rotation += radians;
    }
    
    _rotatingDialContainerView.transform = CGAffineTransformMakeRotation(_currentRotation);
    
    [self updateVisibleSlices];
}


- (void)updateVisibleSlices
{        
    CGFloat visibleDistance = -M_PI;    
    
    GDIDialSlice *firstSlice = [_visibleSlices objectAtIndex:0];

    CGFloat firstSliceRotation = firstSlice.rotation;
    CGFloat firstSliceLeftSideRadians = firstSliceRotation + [firstSlice sizeInRadians]*.5;
    CGFloat firstSliceRightSideRadians = firstSliceRotation - [firstSlice sizeInRadians]*.5;
    
    if ( firstSliceLeftSideRadians < 0 ) {
        [self addFirstSlice];
    }
    
    else if ( firstSliceRightSideRadians > 0 ) {
        [self removeFirstSlice];
    }
    
    
    GDIDialSlice *lastSlice = [_visibleSlices lastObject];
    
    CGFloat lastSliceRotation = lastSlice.rotation;
    CGFloat lastSliceLeftSideRadians = lastSliceRotation + [lastSlice sizeInRadians]*.5;
    CGFloat lastSliceRightSideRadians = lastSliceRotation - [lastSlice sizeInRadians]*.5;    
    
    if ( lastSliceLeftSideRadians > visibleDistance && lastSliceRightSideRadians > visibleDistance) {
        [self addEndSlice];
    }
    
    if ( lastSliceRightSideRadians < visibleDistance && lastSliceLeftSideRadians < visibleDistance ) {
        [self removeEndSlice];
    }
    
//    NSLog(@"current rotation radians: %.2f, degrees: %2.f", _currentRotation, radiansToDegrees(_currentRotation));
}



// this method takes touch interaction points and rotates the dial container to match the movement
- (void)trackTouchPoint:(CGPoint)point inView:(UIView*)view
{    
    CGPoint normalizedPoint = [self normalizedPoint:point inView:view];
    
    CGFloat angleBetweenInitalTouchAndCenter = atan2f(_lastPoint.y, _lastPoint.x);
    CGFloat angleBetweenCurrerntTouchAndCenter = atan2f(normalizedPoint.y, normalizedPoint.x);
    CGFloat rotationAngle = angleBetweenCurrerntTouchAndCenter - angleBetweenInitalTouchAndCenter;
    
    // fix large, negative values that can throw off the velocity.
    // this fixes those values and uses the "short way" to determine the rotation
    float angle1 = M_PI*2 + rotationAngle;
    if (angle1 < M_PI) {   
        rotationAngle += M_PI*2;
    }
    
    [self rotateDialByRadians:rotationAngle];
    
    _velocity = rotationAngle;
    _lastPoint = normalizedPoint;
}

// the point we are provided is based from the top-left corner of the view instead of from the center.
// this offsets the positions to make the point based off the center of the view
- (CGPoint)normalizedPoint:(CGPoint)point inView:(UIView *)view
{
    return CGPointMake(point.x - view.bounds.size.width * .5, point.y - view.bounds.size.height * .5);
}



- (void)beginDeceleration
{
//    NSLog(@"begin deceleration with velocity: %.2f", _velocity);
    [_decelerationTimer invalidate];
    _decelerationTimer = [NSTimer scheduledTimerWithTimeInterval:kAnimationInterval target:self selector:@selector(handleDecelerateTick) userInfo:nil repeats:YES];
}


- (void)endDeceleration
{
    [_decelerationTimer invalidate];
    self.decelerationTimer = nil;
    
    _velocity = 0;
}


- (void)handleDecelerateTick 
{
    _velocity *= _friction;
    
    if ( fabsf(_velocity) < .001f) {
        [self endDeceleration];
        [self rotateToNearestSlice];
    }
    else {
        [self rotateDialByRadians:_velocity];
    }
}


#pragma mark - Gesture View Delegate


- (void)gestureView:(GDIDialGestureView *)gv touchBeganAtPoint:(CGPoint)point
{
//    NSLog(@"gestureView:touchBeganAtPoint: %@", NSStringFromCGPoint(point));
    
    // reset the last point to where we start from.
    _lastPoint = [self normalizedPoint:point inView:gv];
    
    [self endNearestSliceRotation];
    [self endDeceleration];
    [self trackTouchPoint:point inView:gv];
}


- (void)gestureView:(GDIDialGestureView *)gv touchMovedToPoint:(CGPoint)point
{
//    NSLog(@"gestureView:touchMovedToPoint: %@", NSStringFromCGPoint(point));    
    
    [self trackTouchPoint:point inView:gv];
}


- (void)gestureView:(GDIDialGestureView *)gv touchEndedAtPoint:(CGPoint)point
{
//    NSLog(@"gestureView:touchEndedAtPoint: %@", NSStringFromCGPoint(point));
    
    [self beginDeceleration];
}


@end
