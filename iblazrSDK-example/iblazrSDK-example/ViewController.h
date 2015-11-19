//
//  ViewController.h
//  iblazrSDK-example
//
//  Created by Andrew Skrypnik on 11/18/15.
//  Copyright © 2015 Concepter HQ, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STDeviceManager.h"

@interface ViewController : UIViewController <STDeviceManagerDelegate>

@property (weak, nonatomic) IBOutlet UISlider *sliderBrightness;
@property (weak, nonatomic) IBOutlet UISlider *sliderTemperature;


@end

