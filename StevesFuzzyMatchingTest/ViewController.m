//
//  ViewController.m
//  StevesFuzzyMatchingTest
//
//  Created by Steve Trombley on 7/14/17.
//  Copyright © 2017 Steve Trombley. All rights reserved.
//

#import "ViewController.h"
@import StevesFuzzyAdaptation;


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    fuzzying *fuzzy=[fuzzying new];
    NSInteger result=[fuzzy getFuzzyMatchResultWithSample:@"ER$$%GREE$$$%%EDDE" pattern:@"EDDE" location:0 threshold:1 distance:1000];
    NSLog(@"%lu", (long)result);
    
    
    
    

 
                   



}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
