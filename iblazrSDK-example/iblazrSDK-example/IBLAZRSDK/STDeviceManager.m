//
//  STDeviceManager.m
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

#import "STDeviceManager.h"


#import "ToneGenerator.h"
//#import "BLEDevice.h"
//#import "BLETIOADProfile.h"
//#import "BLETIOADProgressViewController.h"





@implementation STDeviceManager {
    BTController *_btController;
    UIAlertView *_iblazrOriginalConnectAlert;
}


@synthesize delegates;

+ (STDeviceManager *)sharedInstance{
    static STDeviceManager *_sharedClient = nil;
    static dispatch_once_t onceClient;
    dispatch_once(&onceClient, ^{
        _sharedClient = [[STDeviceManager alloc] init];
    });
    return _sharedClient;
}

- (id)init {
    if (self = [super init]){
        self.devices = [NSMutableDictionary dictionaryWithObjects:@[
                                                                    [NSMutableArray arrayWithCapacity:1],
                                                                    [NSMutableArray arrayWithCapacity:1],
                                                                    [NSMutableArray arrayWithCapacity:1]
                                                                    ]
                                                          forKeys:@[
                                                                    kSTDeviceTypeIblazrOriginal,
                                                                    kSTDeviceTypeIblazr2,
                                                                    kSTDeviceTypeNewProduct
                                                                    ]];
        
        delegates = [[NSPointerArray alloc] init];
        
        //for iblazr original
        {
            AudioSessionInitialize(NULL, NULL, NULL, NULL);
            AudioSessionSetActive(true);
            
            UIImageView *iblazr = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iblazr_for_shop.png"]];
            iblazr.contentMode=UIViewContentModeCenter;
            
            _iblazrOriginalConnectAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"iblazr?",nil)
                                                                     message:NSLocalizedString(@"if you put iBlazr to your phone - press OK", nil)
                                                                    delegate:self
                                                           cancelButtonTitle:nil
                                                           otherButtonTitles:NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"OK", nil), nil];
            
            [_iblazrOriginalConnectAlert setValue:iblazr forKey:@"accessoryView"];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
            
            if ([self isHeadsetPluggedIn]) {
                [_iblazrOriginalConnectAlert show];
            }
        }
        
        //for iblazr 2
        //for iblazr 2 move to [self scan] method
    }
    return self;
}

#pragma mark - Delegates method

- (void)addDelegate:(id<STDeviceManagerDelegate>)delegate {
    [delegates addPointer: (__bridge void * _Nullable)(delegate)];
}

- (void)removeDelegate: (id<STDeviceManagerDelegate>)delegate {
    for(int i=0; i<delegates.count; i++) {
        if(delegate == [delegates pointerAtIndex: i]) {
            [delegates removePointerAtIndex: i];
            break;
        }
    }
}

#pragma mark - method controlls

- (void)scan {
    
    _btController = [BTController sharedInstance];
    [_btController setDelegate:self];
    [_btController scan:@[[CBUUID UUIDWithString:@"FAFA"]]];
    
    if ([self isHeadsetPluggedIn] && [[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] count] == 0) {
        [_iblazrOriginalConnectAlert show];
    }
}


- (void)addDevice:(STDevice*)device {
    switch (device.type) {
        case STDeviceTypeIblazrOriginal: {
            if ([(NSMutableArray*)[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] count] == 0){
                
                for (id<STDeviceManagerDelegate> delegate in self.delegates) {
                    if ([delegate respondsToSelector:@selector(deviceManager:willConnectDevice:)]) {
                        [delegate deviceManager:self willConnectDevice:device];
                    }
                }
                
                [(NSMutableArray*)[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] addObject:device];
                
                for (id<STDeviceManagerDelegate> delegate in self.delegates) {
                    if ([delegate respondsToSelector:@selector(deviceManager:didConnectDevice:)]) {
                        [delegate deviceManager:self didConnectDevice:device];
                    }
                }
                
            }else{
                NSLog(@"%s Error: dublicate objects",__PRETTY_FUNCTION__);
            }
        } break;
        case STDeviceTypeIblazr2:
            [(NSMutableArray*)[self.devices objectForKey:kSTDeviceTypeIblazr2] addObject:device];
            
            [self performSelector:@selector(updateBatteryInfo:) withObject:device afterDelay:5];
            
            for (id<STDeviceManagerDelegate> delegate in self.delegates) {
                if ([delegate respondsToSelector:@selector(deviceManager:didConnectDevice:)]) {
                    [delegate deviceManager:self didConnectDevice:device];
                }
            }
            
            break;
        case STDeviceTypeNewProduct:
            [(NSMutableArray*)[self.devices objectForKey:kSTDeviceTypeNewProduct] addObject:device];
            break;
        default:
            NSLog(@"%s Error: no key found",__PRETTY_FUNCTION__);
            break;
    }
    
    
}

- (void)removeDevice:(STDevice*)device {
    for (id<STDeviceManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(deviceManager:willDisconnectDevice:)]) {
            [delegate deviceManager:self willDisconnectDevice:device];
        }
    }
    
    switch (device.type) {
        case STDeviceTypeIblazrOriginal:
            [((STDeviceIblazrOriginal*)device).tone stop];
            [[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] removeObject:device];
            break;
        case STDeviceTypeIblazr2:
            [[self.devices objectForKey:kSTDeviceTypeIblazr2] removeObject:device];
            break;
        case STDeviceTypeNewProduct:
            [[self.devices objectForKey:kSTDeviceTypeNewProduct] removeObject:device];
            break;
        default:
            NSLog(@"%s Error: no key found",__PRETTY_FUNCTION__);
            break;
    }
    
    for (id<STDeviceManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(deviceManager:didDisconnectDevice:)]) {
            [delegate deviceManager:self didDisconnectDevice:device];
        }
    }
    
}

-(void)removeDeviceWithType:(STDeviceType)type __deprecated {
    switch (type) {
        case STDeviceTypeIblazr2: {
            
            for (STDevice* device in [self.devices objectForKey:kSTDeviceTypeIblazr2]) {
                for (id<STDeviceManagerDelegate> delegate in self.delegates) {
                    if ([delegate respondsToSelector:@selector(deviceManager:didDisconnectDevice:)]) {
                        [delegate deviceManager:self didDisconnectDevice:device];
                    }
                }
            }
            [[self.devices objectForKey:kSTDeviceTypeIblazr2] removeAllObjects];
            
        } break;
        case STDeviceTypeIblazrOriginal: {
            
            STDevice* device = [[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] firstObject];
            
            for (id<STDeviceManagerDelegate> delegate in self.delegates) {
                if ([delegate respondsToSelector:@selector(deviceManager:didDisconnectDevice:)]) {
                    [delegate deviceManager:self didDisconnectDevice:device];
                }
            }
            [[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] removeAllObjects];
            
        } break;
        case STDeviceTypeNewProduct:
            
            break;
            
        default:
            // remove all objects
            [self removeDeviceWithType:STDeviceTypeIblazrOriginal];
            [self removeDeviceWithType:STDeviceTypeIblazr2];
            break;
    }
}


-(void)shot:(NSInteger)temperature color:(NSInteger)brightness{
    [self configDevicesForCommand:STDeviceManagerComandShot time:300 temperature:temperature*5 power:brightness];
}

-(void)configDevicesForCommand:(NSInteger)command time:(NSInteger)time {
    for (NSString *key in [self.devices allKeys]) {
        for (STDevice *device in [self.devices objectForKey:key]) {
            [self configDevice:device forCommand:command time:time temperature:device.lightTemperature power:device.lightPower];
        }
    }
}

-(void)configDevicesForCommand:(NSInteger)command time:(NSInteger)time temperature:(NSInteger)temperature power:(CGFloat)power {
    
    for (NSString *key in [self.devices allKeys]) {
        for (STDevice *device in [self.devices objectForKey:key]) {
            [self configDevice:device forCommand:command time:time temperature:temperature power:power];
        }
    }
    
}

-(void)configDevice:(STDevice *)device forCommand:(NSInteger)command time:(NSInteger)time {
    NSLog(@"%s Hm....?",__PRETTY_FUNCTION__);
}

-(void)configDevice:(STDevice *)device forCommand:(NSInteger)command time:(NSInteger)time temperature:(NSInteger)temperature power:(CGFloat)power{
    
    switch (device.type) {
        case STDeviceTypeIblazr2: {
            switch (command) {
                case STDeviceManagerComandLight:
                    command = 22;
                    break;
                case STDeviceManagerComandStop:
                case STDeviceManagerComandShot:
                    command = 16;
                    break;
            }
            
            temperature = 25-temperature; // REVERSE VALUES
            
            NSData *data = [self paramsToData:@{@"command":@(command),@"time":@(time/10),@"temperature":@(temperature*5),@"power":@(power)}];
            CBPeripheral* peripheral = device.peripheral;
            CBCharacteristic* characteristic = device.characteristicConfig;
            if (peripheral.state == CBPeripheralStateConnected) {
                @try {
                    [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                }
                @catch (NSException *exception) {
                    NSLog(@"%s PLAK-PLAK",__PRETTY_FUNCTION__);
                }
            }
        } break;
        case STDeviceTypeIblazrOriginal: {
            STDeviceIblazrOriginal *iblazr = (STDeviceIblazrOriginal*)device;
            [iblazr.tone setFrequency:power*500.f+2000.f]; //80 koeficient, 5 - step in slider ((fq is 2000-100000 range)
            switch (command) {
                case STDeviceManagerComandStatus:
                    [iblazr.tone playForDuration:1.f];
                    break;
                case STDeviceManagerComandVideo:
                case STDeviceManagerComandLight:
                    [iblazr.tone play];
                    break;
                case STDeviceManagerComandStop:
                    [iblazr.tone stop];
                    break;
                case STDeviceManagerComandShot:
                default:
                    [iblazr.tone playForDuration:time/1000.f];
                    break;
            }
        }break;
        default:
            break;
    }
    
    
}

-(NSData*)paramsToData:(NSDictionary*)dict{
    const char bytes[] = {(unsigned int)[dict[@"command"] intValue],
        (unsigned int)0,//[dict[@"time"] intValue],
        (unsigned int)[dict[@"time"] intValue],
        (unsigned int)[dict[@"temperature"] intValue],
        (unsigned int)[dict[@"power"] intValue]};
    
    return [[NSData alloc] initWithBytes:&bytes length:sizeof(bytes)];
}

-(void)updateBatteryInfo:(STDevice*)device {
    
    if (((STDeviceIblazr2*)device).batteryCharacteristic != nil) {
        [device.peripheral readValueForCharacteristic:((STDeviceIblazr2*)device).batteryCharacteristic];
    }
    
    [self performSelector:@selector(updateBatteryInfo:) withObject:device afterDelay:5];
}

#pragma mark - BTController

-(void)disconnectDevice:(STDevice*)device {
    switch (device.type) {
        case STDeviceTypeIblazr2:
            [_btController cleanup:device.peripheral];
            break;
        case STDeviceTypeIblazrOriginal:
            [self removeDevice:[(NSMutableArray*)[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] firstObject]];
            break;
        default:
            break;
    }
}

- (void) disconnectDeviceWithType:(STDeviceType)type {
    switch (type) {
        case STDeviceTypeIblazr2: {
            
            [_btController cleanup];
            
        } break;
        case STDeviceTypeIblazrOriginal: {
            [self removeDevice:[(NSMutableArray*)[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] firstObject]];
            
        } break;
        case STDeviceTypeNewProduct:
            [_btController cleanup];
            break;
            
        default:
            // remove all objects
            [_btController cleanup];
            [self removeDevice:[(NSMutableArray*)[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] firstObject]];
            break;
    }
}


-(void)BTController:(BTController*)controller connectPeripheral:(CBPeripheral *)peripheral{
    
    
    // Ok, it's in range - have we already seen it?
    if ([self findDeviceViaPeripheralID:peripheral.identifier] == NULL) {
        NSLog(@"Connecting to peripheral %@: %@", peripheral.name, peripheral);
        [controller centralManagerConnectPeripheral:peripheral];
    }
    
}

-(void)BTController:(BTController*)BTController didConnectPeripheral:(CBPeripheral *)peripheral{
    
    NSMutableDictionary *color = [[NSMutableDictionary alloc] initWithObjects:@[@255,@255,@255] forKeys:@[@"red",@"green",@"blue"]];
    NSMutableDictionary *iblazr_dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:peripheral.identifier.UUIDString,@"id",@"iBlazr²",@"title",@255,@"color",@255,@"brightness",color,@"uicolor",@2,@"version", nil];
    
    STDeviceIblazr2 *device = [[STDeviceIblazr2 alloc] init];
    device.type = STDeviceTypeIblazr2;
    device.name = peripheral.name;
    device.identifier = peripheral.identifier.UUIDString;
    device.params  = iblazr_dict;
    device.peripheral = peripheral;
    
    device.batteryPower = 100; //by default;
    device.lightPower = 16;
    device.lightTemperature = 13;
    
    [self addDevice:device];
}
-(void)BTController:(id)BTController didDisconnectPeripheral:(CBPeripheral *)peripheral{
    [self removeDevice:[self findDeviceViaPeripheralID:peripheral.identifier]];
    NSLog(@"Peripheral Disconnected: %@ with UUID: %@",peripheral.name, peripheral.identifier.UUIDString);
}

-(void)BTController:(BTController *)controller peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service characteristic:(CBCharacteristic*)characteristic{

    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"0x180F"]]) {
        [peripheral readValueForCharacteristic:characteristic];
        if ([characteristic isNotifying]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"0x180A"]]) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0x2A24"]] ||
            [characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0x2A27"]] ||
            [characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0x2A26"]]) {
            [peripheral readValueForCharacteristic:characteristic];
        }
    }
    
    STDeviceIblazr2* device = (STDeviceIblazr2*)[self findDeviceViaPeripheralID:peripheral.identifier];
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"0xFAFA"]]) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0xFAF1"]]) {
            device.characteristicConfig = characteristic;
        }
        
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0xFAF2"]]) {
            device.characteristicReset = characteristic;
            
        }
    }
    
}

-(void)BTController:(BTController *)controller peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic {
    
    /*
     
     0x180A, (Device Information Service)
     0x2A19, 12%, (Battery Level)
     0x2A29, "Rocketmade", (Manufacturer Name String)
     0x2A24, "0.1", (Model Number String)
     0x2A27, "0.1", (Hardware Revision String)
     0x2A26, "0.1", (Firmware Revision String)
     
     */
    
    STDeviceIblazr2* device = (STDeviceIblazr2*)[self findDeviceViaPeripheralID:peripheral.identifier];
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0x2A19"]]){
        device.batteryPower = ((UInt8*)characteristic.value.bytes)[0];
        
        for (id<STDeviceManagerDelegate> delegate in self.delegates) {
            if ([delegate respondsToSelector:@selector(deviceManager:didBatteryInfoUpdated:)]) {
                [delegate deviceManager:self didBatteryInfoUpdated:device];
            }
        }
    }
    
    NSString* str = [[NSString alloc] initWithData:characteristic.value encoding:NSStringEncodingConversionAllowLossy];
        
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0x2A24"]]){
        device.firmwareVersion = str;
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0x2A27"]]){
        device.modelNumber = str;
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0x2A26"]]) {
        device.softwareVersion = str;
    }
    
    // may need to delete this code?
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0xFAF1"]]) {
        device.characteristicConfig = characteristic;
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0xFAF2"]]) {
        device.characteristicReset = characteristic;
    }
    
    for (id<STDeviceManagerDelegate> delegate in self.delegates) {
        if ([delegate respondsToSelector:@selector(deviceManager:didUpdateDevice:)]) {
            [delegate deviceManager:self didUpdateDevice:device];
        }
    }
}




#pragma mark - OTA FW

- (void) updateOAD:(STDevice*)device {
    
    //    if (WHATBOOOL) {
    //
    //        BLEDevice *dev = [[BLEDevice alloc]init];
    //        dev.p = device.peripheral;
    //        dev.manager = _btController.centralManager;
    //
    //        oadProfile = [[BLETIOADProfile alloc]initWithDevice:dev];
    //        [oadProfile setDelegate:self];
    //        oadProfile.progressView = [[BLETIOADProgressViewController alloc]init];
    //        [oadProfile makeConfigurationForProfile];
    //        [oadProfile configureProfile];
    //        oadProfile.view = self.rootView;
    //
    //        NSMutableString *path= [[NSMutableString  alloc] initWithString: [[NSBundle mainBundle] resourcePath]];
    //        [path appendString:@"/"] ;
    //        [path appendString:@"SensorTagImgA.bin"];
    //        [oadProfile validateImage:path];
    //    } else {
    [self eraseFirmwareForDevice:device];
    //WHATBOOOL = YES;
    //}
    
}
//
//-(void)OADProfile:(BLETIOADProfile *)oadProfile didUpdateOADProgress:(NSNumber *)progress withTime:(NSNumber *)time {
//    
//    for (id<STDeviceManagerDelegate> delegate in self.delegates) {
//        if ([delegate respondsToSelector:@selector(deviceManager:didUpdateOADProgress:withTime:)]) {
//            [delegate deviceManager:self didUpdateOADProgress:progress withTime:time];
//        }
//    }
//}

- (void) updateFirmware:(NSString*)peripheralIdentifier completition:(void(^)(bool success))completition{
    if ([self checkFirmware:3.0]) {
        [self eraseFirmware:peripheralIdentifier];
        [self updateFirmwareOTA:peripheralIdentifier completition:^(bool success) {
            if (completition){
                completition(success);
            }
        }];
    }
}

- (BOOL) checkFirmware:(float) version{
    if (version>2.0f) {
        return YES;
    }
    return NO;
}

- (void) eraseFirmware:(NSString*)peripheralIdentifier{
    const char bytes[] = {255};
    
    NSData *d = [[NSData alloc] initWithBytes:&bytes length:sizeof(bytes)];
    
    NSMutableDictionary* dict = [self.devices objectForKey:peripheralIdentifier];
    
    CBPeripheral* peripheral = (CBPeripheral*)[dict objectForKey:@"peripheral"];
    CBCharacteristic* characteristic = dict[@"characteristic_faf2"];
    [peripheral writeValue:d forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    NSLog(@"erase firmware: %@",peripheral.identifier.UUIDString);
    
}


- (void) eraseFirmwareForDevice:(STDevice*)device {
    const char bytes[] = {255};
    
    NSData *d = [[NSData alloc] initWithBytes:&bytes length:sizeof(bytes)];
    
    
    CBPeripheral* peripheral = device.peripheral;
    CBCharacteristic* characteristic = device.characteristicReset;
    
    [peripheral writeValue:d forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    NSLog(@"erase firmware: %@",peripheral.identifier.UUIDString);
}

- (void)updateFirmwareOTA:(NSString *)peripheralIdentifier completition:(void(^)(bool success))completition {
    if (completition){
        completition(YES);
    }
}


#pragma mark - methods for controll iblazr original


- (void) audioRouteChangeListenerCallback:(NSNotification*) notification {
    NSDictionary * interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_iblazrOriginalConnectAlert show];
            });
        } break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            
            
            [self removeDevice:[(NSMutableArray*)[self.devices objectForKey:kSTDeviceTypeIblazrOriginal] firstObject]];
            
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            //hmmm. what???
        default:
            break;
    }
}


#pragma mark - UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView == _iblazrOriginalConnectAlert) {
        switch (buttonIndex) {
            case 1:{
                [self addIblazrOriginal];
            }break;
            default:
                [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
                break;
        }
    }
}

- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route  = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in route.outputs) {
        if ([desc.portType compare:@"Headphones"] != 1){// == AVAudioSessionPortHeadphones) {
            return YES;
        }
    }
    return NO;
}
- (void)addIblazrOriginal {
    if (![self isHeadsetPluggedIn]) {return;}
    
    NSMutableDictionary *color = [[NSMutableDictionary alloc] initWithObjects:@[@255,@255,@255] forKeys:@[@"red",@"green",@"blue"]];
    NSMutableDictionary *iblazr_dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@255,@"color",@255,@"brightness",color,@"uicolor", nil];
    
    STDeviceIblazrOriginal* device = [[STDeviceIblazrOriginal alloc] init];
    device.identifier = @"iblazr3.5";
    device.name = @"iblazr 3.5mm";
    device.type = STDeviceTypeIblazrOriginal;
    device.params = iblazr_dict;
    
    device.lightPower = 16;
    device.lightTemperature = 5;
    
    [self addDevice:device];
}


#pragma mark - ЛЮТЫЙ ТРЭШ А НЕ МЕТОД.
//predicate must have -___-

- (STDevice *)findDeviceViaPeripheralID:(NSUUID *)peripheralID {
    for (STDevice *device in [self.devices objectForKey:kSTDeviceTypeIblazr2]) {
        if ([device.peripheral.identifier isEqual:peripheralID]) {
            return device;
        }
    }
    return NULL;
}

@end