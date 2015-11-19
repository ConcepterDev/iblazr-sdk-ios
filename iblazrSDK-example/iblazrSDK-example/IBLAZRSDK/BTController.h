//
//  BTController.h
//  shotlite
//
//  Created by Andrew Skrypnik on 10.04.15.
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

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@protocol BTControllerDelegate;
@class CBPeripheral;


@interface BTController : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, weak) id<BTControllerDelegate> delegate;


@property (strong, nonatomic) CBCentralManager      *centralManager;
@property (strong, nonatomic) CBPeripheral          *discoveredPeripheral;
@property (strong, nonatomic) NSMutableArray        *discoveredPeripherals;


+ (BTController *)sharedInstance;

- (void)scan __deprecated;
- (void)scan:(NSArray *)services;
- (void)centralManagerConnectPeripheral:(CBPeripheral *)peripheral;

- (void)cleanup;
- (void)cleanup:(CBPeripheral *)peripheral;

- (void)shot:(int)temperature color:(int)brightness __deprecated;
- (void)configIblazrFor:(int)command time:(int)time temperature:(int)temperature power:(int)power __deprecated;
@end

@protocol BTControllerDelegate <NSObject>;
@optional

- (void)BTController:(BTController *)controller didConnectIblazr:(NSMutableDictionary *)dict __deprecated;
- (void)BTController:(BTController *)controller didDisconnectIblazr:(NSMutableDictionary*)dict __deprecated;

- (void)BTController:(BTController *)controller connectPeripheral:(CBPeripheral *)peripheral;
- (void)BTController:(BTController *)controller didConnectPeripheral:(CBPeripheral *)peripheral;
- (void)BTController:(BTController *)controller didDisconnectPeripheral:(CBPeripheral *)peripheral;

- (void)BTController:(BTController *)controller peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic;
- (void)BTController:(BTController *)controller peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service characteristic:(CBCharacteristic *)characteristic;

@end