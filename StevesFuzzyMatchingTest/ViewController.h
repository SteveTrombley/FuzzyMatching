//
//  ViewController.h
//  StevesFuzzyMatchingTest
//
//  Created by Steve Trombley on 7/14/17.
//  Copyright © 2017 Steve Trombley. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView  *fuzzySampleText;
@property (weak, nonatomic) IBOutlet UITextField *fuzzyPattern;
@property (weak, nonatomic) IBOutlet UITextField *fuzzyLocation;
@property (weak, nonatomic) IBOutlet UITextField *fuzzyDistance;
@property (weak, nonatomic) IBOutlet UITextField *fuzzyThreshold;
@property (weak, nonatomic) IBOutlet UILabel     *fuzzyMatchResult;

@end

