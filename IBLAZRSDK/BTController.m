//
//  BTController.m
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

#import "BTController.h"
#import <stdint.h>

@implementation BTController

NSMutableDictionary *dictionaryPeripherals;

dispatch_queue_t centralBTQueue;


+(BTController *)sharedInstance{
    static BTController* _sharedClient = nil;
    static dispatch_once_t onceClient;
    dispatch_once(&onceClient, ^{
        _sharedClient = [[BTController alloc] init];
    });
    return _sharedClient;
}


-(instancetype)init{
    if (self = [super init]) {
        
        dictionaryPeripherals = [NSMutableDictionary dictionaryWithCapacity:1];
        centralBTQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);//dispatch_queue_create("com.concepter.centralBTQueue",0);
        self.discoveredPeripherals = [NSMutableArray new];
        dispatch_async(centralBTQueue, ^{
            _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        });
    }
    return self;
}

#pragma deprecated

-(void)shot:(int)temperature color:(int)brightness {
    
}
-(void)configIblazrFor:(int)command time:(int)time temperature:(int)temperature power:(int)power {
    
}

#pragma mark - Central Methods
/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            NSLog(@"CBCentralManagerStateUnknown");
            break;
        case CBCentralManagerStateResetting:
            NSLog(@"CBCentralManagerStateResetting");
            break;
        case CBCentralManagerStateUnsupported:
            NSLog(@"CBCentralManagerStateUnsupported");
            break;
        case CBCentralManagerStateUnauthorized:
            NSLog(@"CBCentralManagerStateUnauthorized");
            break;
        case CBCentralManagerStatePoweredOff:
            NSLog(@"CBCentralManagerStatePoweredOff");
            [self cleanup];
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"CBCentralManagerStatePoweredOn");
            [self scan:@[[CBUUID UUIDWithString:@"180F"]]];
            break;
        default:
            break;
    }
}



/** Scan for peripherals - specifically for our service's 128bit CBUUID
 */
- (void)scan {
    [self scan:@[[CBUUID UUIDWithString:@"180F"]]];
}
- (void)scan:(NSArray *)services {
    
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        NSLog(@"%s power off", __PRETTY_FUNCTION__);
        return;
    }
    
    for (CBPeripheral *peripheral in [self.centralManager retrieveConnectedPeripheralsWithServices:services]) {
        NSLog(@"peripheral is: %@",peripheral);
        [self connectPeripheral:peripheral];
    }
    [self.centralManager scanForPeripheralsWithServices:nil
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    
    NSLog(@"%s Scanning started",__PRETTY_FUNCTION__);
  
}


/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    //NSLog(@"Discovered %@ at %@", peripheral, RSSI);
    [self connectPeripheral:peripheral];
}

- (void)connectPeripheral:(CBPeripheral *)peripheral {
    
    NSString *kPredicateQuery = @"iblazr";
    NSPredicate *rpjPredicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", kPredicateQuery];
    if (![rpjPredicate evaluateWithObject:peripheral.name]) {return;}
    
    if (![self.discoveredPeripherals containsObject:peripheral]) {
        [self.discoveredPeripherals addObject:peripheral];
        
        if ([self.delegate respondsToSelector:@selector(BTController:connectPeripheral:)]) {
            [self.delegate BTController:self connectPeripheral:peripheral];
        }
    }
    
}

- (void)centralManagerConnectPeripheral:(CBPeripheral*)peripheral {
    [self.centralManager connectPeripheral:peripheral options:nil];
}


/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup:peripheral];
}


/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected: %@ %@", peripheral.name, peripheral);
    
    // Stop scanning
    // [self.centralManager stopScan];
    // NSLog(@"Scanning stopped");
    
    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    //[self startScanForRSSI];
    
    // Search only for services that match our UUID
//    [peripheral discoverServices:@[[CBUUID UUIDWithString:@"FAFA"]]];
     [peripheral discoverServices:nil];
    
    
    //call delegate
    
    if ([self.delegate respondsToSelector:@selector(BTController:didConnectPeripheral:)]) {
        [self.delegate BTController:self didConnectPeripheral:peripheral];
    }
    
}


#pragma mark - RSSI!!
/*NSTimer *timerRSSI;
-(void) startScanForRSSI{
    timerRSSI = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(detectRSSI) userInfo:nil repeats:YES];
}

- (void)detectRSSI {
    return;
    ///i'm sorry for the next code lines
    
    int stop = false;
    for (CBPeripheral *peripheral in peripherals) {
        if (peripheral.state == CBPeripheralStateConnected) {
            //self.discoveredPeripheral.delegate = self;
            [peripheral readRSSI];
        }else{
            stop = true;
        }
    }
    if (stop) {
        if (timerRSSI && [timerRSSI isValid])  {
            [timerRSSI invalidate];
        }
    }
}
-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error{
  //  NSLog(@"RSSI: %@",RSSI);
}*/

/** The Transfer Service was discovered
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup: peripheral];
        return;
    }
    
    // Discover the characteristic we want...
    NSLog(@"Discover the characteristic we want...");
    
    // Loop through the newly filled peripheral.services array, just in case there's more than one.
    for (CBService *service in peripheral.services) {
       [peripheral discoverCharacteristics:nil forService:service];
    }
}


/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup:peripheral];
        return;
    }
    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([self.delegate respondsToSelector:@selector(BTController:peripheral:didDiscoverCharacteristicsForService:characteristic:)]) {
            [self.delegate BTController:self peripheral:peripheral didDiscoverCharacteristicsForService:service characteristic:characteristic];
        }
    }
    // Once this is complete, we just need to wait for the data to come in.
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error writing characteristic %@",error);
        return;
    }else{
        //NSLog(@"peripheral: %@, characteristic: %@, write success, with value: %@",peripheral.name,characteristic.UUID.UUIDString, characteristic.value);
    }
}
/** This callback lets us know more data has arrived via notification on the characteristic
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(BTController:peripheral:didUpdateValueForCharacteristic:)]) {
        [self.delegate BTController:self peripheral:peripheral didUpdateValueForCharacteristic:characteristic];
    }
}


/** The peripheral letting us know whether our subscribe/unsubscribe happened or not
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"didUpdateNotificationStateForCharacteristic: %@",characteristic.UUID);
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Exit if it's not the transfer characteristic
    if (![characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FAF2"]])
    {
        NSLog(@"notification for FAF2, return;");
        return;
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSLog(@"Notification began on %@", characteristic);
    }
    
    // Notification has stopped
    else {
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        //[self.centralManager cancelPeripheralConnection:peripheral];
    }
}


/** Once the disconnection happens, we need to clean up our local copy of the peripheral
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self.discoveredPeripherals removeObject:peripheral];
    if ([self.delegate respondsToSelector:@selector(BTController:didDisconnectPeripheral:)]) {
        [self.delegate BTController:self didDisconnectPeripheral:peripheral];
    }
}


/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup:(CBPeripheral*)peripheral {
    
    if (peripheral.state != CBPeripheralStateConnected) {
        return;
    }
    
    // See if we are subscribed to a characteristic on the peripheral
    if (peripheral.services != nil) {
        for (CBService *service in peripheral.services) {
            if (service.characteristics != nil) {
                for (CBCharacteristic *characteristic in service.characteristics) {
                    if ([characteristic.UUID isEqual:@""]) {
                        if (characteristic.isNotifying) {
                            // It is notifying, so unsubscribe
                            [peripheral setNotifyValue:NO forCharacteristic:characteristic];
                            // And we're done.
                            
                            [self.discoveredPeripherals removeObject:peripheral];
                            
                            return;
                        }
                    }
                }
            }
        }
    }
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    [self.centralManager cancelPeripheralConnection:peripheral];
}
- (void)cleanup {
    for (CBPeripheral *peripheral in self.discoveredPeripherals) {
        // Don't do anything if we're not connected
        [self cleanup:peripheral];
    }
}


@end
