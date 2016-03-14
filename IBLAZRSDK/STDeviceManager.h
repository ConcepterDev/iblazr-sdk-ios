//
//  STDeviceManager.h
//  shotlite
//
//  Created by Andrew Skrypnik on 9/22/15.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014-2016 Andrew Skrypnik, Concepter HQ, Inc
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "BTController.h"

#import "STDevice.h"
#import "STDeviceIblazr2.h"
#import "STDeviceIblazrOriginal.h"

typedef enum STDeviceManagerComand{
    STDeviceManagerComandShot = 15,
    STDeviceManagerComandLight = 16,
    STDeviceManagerComandStatus = 17,
    STDeviceManagerComandVideo = 22,
    STDeviceManagerComandStop = 18,
    STDeviceManagerComandTurnOff = 32
} STDeviceManagerComand;

@protocol STDeviceManagerDelegate;
@class STDeviceManager;

@interface STDeviceManager : NSObject <BTControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) id<STDeviceManagerDelegate> delegate __deprecated_msg("just use multiple delegates");
@property (nonatomic, strong, readwrite) NSPointerArray *delegates;

@property (strong, nonatomic) NSMutableDictionary *devices;


+ (STDeviceManager *)sharedInstance;

- (void)addDevice:(STDevice *)device;
- (void)removeDevice:(STDevice *)device;
- (void)removeDeviceWithType:(STDeviceType)type __deprecated;

- (void)scan;
- (void)disconnectDevice:(STDevice *)device;
- (void)disconnectDeviceWithType:(STDeviceType)type;

- (void)shot:(NSInteger)temperature color:(NSInteger)brightness;
- (void)configDevice:(STDevice *)device forCommand:(NSInteger)command time:(NSInteger)time;
- (void)configDevice:(STDevice *)device forCommand:(NSInteger)command time:(NSInteger)time temperature:(NSInteger)temperature power:(CGFloat)power;
- (void)configDevicesForCommand:(NSInteger)command time:(NSInteger)time;
- (void)configDevicesForCommand:(NSInteger)command time:(NSInteger)time temperature:(NSInteger)temperature power:(CGFloat)power;

- (void)updateOAD:(STDevice *)device;
- (BOOL)checkFirmware:(CGFloat) version;

- (void)addDelegate:(id<STDeviceManagerDelegate>)delegate;
- (void)removeDelegate:(id<STDeviceManagerDelegate>)delegate;

@end

@protocol STDeviceManagerDelegate <NSObject>;
@optional

- (void)deviceManager:(STDeviceManager *)manager didConnectDevice:(STDevice *)device;
- (void)deviceManager:(STDeviceManager *)manager willConnectDevice:(STDevice *)device;
- (void)deviceManager:(STDeviceManager *)manager didDisconnectDevice:(STDevice *)device;
- (void)deviceManager:(STDeviceManager *)manager willDisconnectDevice:(STDevice *)device;
- (void)deviceManager:(STDeviceManager *)manager didUpdateDevice:(STDevice *)device;
- (void)deviceManager:(STDeviceManager *)manager didBatteryInfoUpdated:(STDevice *)device;
- (void)deviceManager:(STDeviceManager *)manager didUpdateOADProgress:(NSNumber *)progress withTime:(NSNumber *)time;

@end
