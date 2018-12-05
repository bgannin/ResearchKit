/*
 Copyright (c) 2018, Muh-Tarng Lin. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKTouchAbilitySwipeStepViewController.h"


#import "ORKActiveStepView.h"
#import "ORKTouchAbilitySwipeContentView.h"
#import "ORKTouchAbilitySwipeResult.h"
#import "ORKTouchAbilityTrial.h"
#import "ORKTouchAbilityTrial_Internal.h"
#import "ORKTouchAbilitySwipeTrial.h"

#import "ORKActiveStepViewController_Internal.h"
#import "ORKStepViewController_Internal.h"
#import "ORKTaskViewController_Internal.h"
#import "ORKNavigationContainerView_Internal.h"

#import "ORKCollectionResult_Private.h"
#import "ORKTouchAbilitySwipeStep.h"
#import "ORKNavigableOrderedTask.h"
#import "ORKVerticalContainerView_Internal.h"
#import "ORKHelpers_Internal.h"


@interface ORKTouchAbilitySwipeStepViewController () <ORKTouchAbilitySwipeContentViewDataSource, ORKTouchAbilityCustomViewDelegate>

// Data
@property (nonatomic, assign) NSUInteger currentTrialIndex;
@property (nonatomic, strong) NSArray<NSNumber *> *targetDirectionQueue;
@property (nonatomic, strong) NSMutableArray<ORKTouchAbilitySwipeTrial *> *trials;

@property (nonatomic, assign) BOOL success;

// UI
@property (nonatomic, strong) ORKTouchAbilitySwipeContentView *swipeContentView;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRecognizer;

@end

@implementation ORKTouchAbilitySwipeStepViewController


#pragma mark - ORKActiveStepViewController

- (UISwipeGestureRecognizer *)swipeGestureRecognizer {
    if (!_swipeGestureRecognizer) {
        _swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGestureRecoginzer:)];
    }
    return _swipeGestureRecognizer;
}

- (void)handleSwipeGestureRecoginzer:(UISwipeGestureRecognizer *)sender {
    
    if (sender.direction == self.targetDirectionQueue[self.currentTrialIndex].intValue) {
        self.success = YES;
    } else {
        self.success = NO;
    }
}

- (instancetype)initWithStep:(ORKStep *)step {
    self = [super initWithStep:step];
    if (self) {
        self.suspendIfInactive = YES;
    }
    return self;
}

- (void)initializeInternalButtonItems {
    [super initializeInternalButtonItems];
    
    self.internalContinueButtonItem = nil;
    self.internalDoneButtonItem = nil;
}

- (ORKStepResult *)result {
    
    ORKStepResult *sResult = [super result];
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithArray:sResult.results];
    
    ORKTouchAbilitySwipeResult *swipeResult = [[ORKTouchAbilitySwipeResult alloc] initWithIdentifier:self.step.identifier];
    
    swipeResult.trials = [self.trials mutableCopy];
    
    [results addObject:swipeResult];
    sResult.results = [results copy];
    
    return sResult;
}

- (void)finish {
    [self.swipeContentView stopTracking];
    [super finish];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.currentTrialIndex = 0;
    self.targetDirectionQueue = [self targetDirections];
    self.trials = [NSMutableArray new];
    self.swipeGestureRecognizer.direction = self.targetDirectionQueue[self.currentTrialIndex].intValue;
    
    self.swipeContentView = [[ORKTouchAbilitySwipeContentView alloc] init];
    self.swipeContentView.dataSource = self;
    self.swipeContentView.delegate = self;
    
    self.activeStepView.activeCustomView = self.swipeContentView;
    self.activeStepView.stepViewFillsAvailableSpace = YES;
    self.activeStepView.scrollContainerShouldCollapseNavbar = NO;
    
    [self.activeStepView updateTitle:nil text:@"SWIPE foobarrrrrrr"];
    
    [self.swipeContentView addGestureRecognizer:self.swipeGestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self start];
    self.success = NO;
    [self.swipeContentView startTracking];
}

- (NSArray<NSNumber *> *)targetDirections {
    
    NSMutableArray *directions = @[@(UISwipeGestureRecognizerDirectionUp),
                                   @(UISwipeGestureRecognizerDirectionDown),
                                   @(UISwipeGestureRecognizerDirectionLeft),
                                   @(UISwipeGestureRecognizerDirectionRight)].mutableCopy;
    [directions addObjectsFromArray:directions];
    
    NSUInteger count = [directions count];
    for (NSUInteger i = 0; i < count; i++) {
        NSUInteger nElements = count - i;
        NSUInteger n = (arc4random() % nElements) + i;
        [directions exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
    
    return [directions copy];
}

#pragma mark - ORKTouchAbilitySwipeContentViewDataSource

- (UISwipeGestureRecognizerDirection)targetDirection:(ORKTouchAbilitySwipeContentView *)swipeContentView {
    return [self.targetDirectionQueue[self.currentTrialIndex] intValue];

}


#pragma mark - ORKTouchAbilityCustomViewDelegate

- (void)touchAbilityCustomViewDidBeginNewTrack:(ORKTouchAbilityCustomView *)customView {
    
}

- (void)touchAbilityCustomViewDidCompleteNewTracks:(ORKTouchAbilityCustomView *)customView {
    
    [self.swipeContentView reloadData];
    
    
    // Calculate current progress and display using progress view.
    
    NSUInteger total = self.targetDirectionQueue.count;
    NSUInteger done = self.currentTrialIndex + 1;
    CGFloat progress = (CGFloat)done/(CGFloat)total;
    
    [self.swipeContentView setProgress:progress animated:YES];
    
    
    // Animate the target view.
    
    __weak __typeof(self) weakSelf = self;
    [self.swipeContentView setArrowViewHidden:YES animated:YES completion:^(BOOL finished) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        
        
        // Stop tracking new touch events.
        
        [strongSelf.swipeContentView stopTracking];
        
        
        // Get current target direction
        UISwipeGestureRecognizerDirection direction = strongSelf.targetDirectionQueue[strongSelf.currentTrialIndex].intValue;
        
        // Initiate a new trial.
        
        ORKTouchAbilitySwipeTrial *trial = [[ORKTouchAbilitySwipeTrial alloc] initWithTargetDirection:direction];
        trial.tracks = strongSelf.swipeContentView.tracks;
        trial.gestureRecognizerEvents = strongSelf.swipeContentView.gestureRecognizerEvents;
        trial.success = strongSelf.success;
        
        // Add the trial to trials and remove the target point from the target points queue.
        
        [strongSelf.trials addObject:trial];
        
        
        // Determind if should continue or finish.
        
        strongSelf.currentTrialIndex += 1;
        if (strongSelf.currentTrialIndex < strongSelf.targetDirectionQueue.count) {
            
            // Reload and start tracking again.
            strongSelf.success = NO;
            strongSelf.swipeGestureRecognizer.direction = strongSelf.targetDirectionQueue[strongSelf.currentTrialIndex].intValue;
            [strongSelf.swipeContentView reloadData];
            [strongSelf.swipeContentView setArrowViewHidden:NO animated:NO];
            [strongSelf.swipeContentView startTracking];
            
        } else {
            
            // Finish step.
            [strongSelf finish];
        }
        
    }];
    
}

@end
