//
//  ViewController.m
//  iblazrSDK-example
//
//  Created by Andrew Skrypnik on 11/18/15.
//  Copyright © 2015 Concepter HQ, Inc. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController {
    CGFloat tmpLight;
    CGFloat tmpTemp;
    STDeviceManager *deviceManager;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    deviceManager = [STDeviceManager sharedInstance];
    [deviceManager addDelegate:self];
    [deviceManager scan];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)checkStatus:(UIButton *)sender {
    // setup custom time
    NSInteger time = 2000;
    for (NSString *key in [deviceManager.devices allKeys]) {
        for (STDevice *device in [deviceManager.devices objectForKey:key]) {
            [deviceManager configDevice:device
                             forCommand:STDeviceManagerComandStatus
                                   time:time
                            temperature:tmpTemp
                                  power:tmpLight];
        }
    }
}

- (IBAction)makeFlash:(UIButton *)sender {
    // setup custom time
    NSInteger time = 300;
    [deviceManager configDevicesForCommand:STDeviceManagerComandShot
                                      time:time];
}

#pragma mark UISlider delegates

- (IBAction)sliderValueChanged:(UISlider *)sender {
    
    if (sender == _sliderBrightness) {
        if (tmpLight != sender.value) {
            [self sliderConfigDevice:sender];
            tmpLight = sender.value;
        }
    }
    
    if (sender == _sliderTemperature) {
        if (tmpTemp != sender.value) {
            [self sliderConfigDevice:sender];
            tmpTemp = sender.value;
        }
    }
    
}

- (IBAction)sliderTouchUp:(UISlider *)sender {
    [self sliderConfigDevice:sender withCommand:STDeviceManagerComandStop];
}

- (void)sliderTouchDown:(UISlider *)sender {
    [self sliderConfigDevice:sender withCommand:STDeviceManagerComandLight];
}

- (void)sliderConfigDevice:(UISlider *)sender {
    [self sliderConfigDevice:sender withCommand:STDeviceManagerComandLight];
}

- (void)sliderConfigDevice:(UISlider *)sender withCommand:(STDeviceManagerComand)command {
    NSInteger time = 0; //0 - infinite
    for (NSString *key in [deviceManager.devices allKeys]) {
        for (STDevice *device in [deviceManager.devices objectForKey:key]) {
            if (sender == _sliderBrightness) {
                
                device.lightPower = sender.value;
                
                [deviceManager configDevice:device
                                 forCommand:command
                                       time:time
                                temperature:tmpTemp
                                      power:sender.value];
            }
            if (sender == _sliderTemperature) {
                
                if (device.type == STDeviceTypeIblazr2) {
                    ((STDeviceIblazr2*)device).lightTemperature = sender.value;
                }
                
                [deviceManager configDevice:device
                                 forCommand:command
                                       time:time
                                temperature:sender.value
                                      power:tmpLight];
            }
        }
    }
}



#pragma mark STDeviceManager delegates

-(void)deviceManager:(STDeviceManager *)manager didConnectDevice:(STDevice *)device {
    
}

-(void)deviceManager:(STDeviceManager *)manager didDisconnectDevice:(STDevice *)device {
    
}


@end
