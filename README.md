## iblazrSDK
iOS iblazr SDK for communicating with the iblazr 2 via Bluetooth and iblazr original via 3.5mm audio jack http://iblazr.com
## Overview
This SDK provides an Objective-C interface for access to iblazr 2 via CoreBluetooth and iblazr original via AudioToolbox. All the following code tested on iPhone 4s and up, iPod 4 and up, iPads and up, and both devices with iOS 8 and iOS 9

`NOTE:` not working in simulator

`P.S.:` current version was taken from our [Shotlight App](https://itunes.apple.com/us/app/shotlight-manual-photo-video/id982905457?mt=8) as is, if you don’t understand anything, don’t hesitate to contact us (see at [feedback](https://github.com/concepterhqinc/iblazr-sdk-ios#Feedback) section)
## How To Get Started
* [Download iblazrSDK](https://github.com/concepterhqinc/iblazr-sdk-ios/archive/master.zip) and try out the included iPhone example app
* Read the "[Getting Started](https://github.com/concepterhqinc/iblazr-sdk-ios#Documentation)" guide

### Installation
Drag files (with iblazrSDK directory) into your project ;)<br>
![drag files](https://shop.concepter.co/wp-content/uploads/2015/11/drag_files.png)
### import header and setting delegate
```objective-c
#import "STDeviceManager.h"

@interface ViewController : UIViewController <STDeviceManagerDelegate>
```
### Device parameters
Check `STDevice.h`,`STDeviceIblazr2.h` and `STDeviceIblazrOriginal.h` for get available parametrs.<br>
`float lightPower` - value can be in range 0-16<br>
`float lightTemperature;` - value can be in range 0-125<br>
NOTE:  `lightTemperature` in current version you can set 25 as maximum value. In `STDeviceManager.m` line:290 it be multiply with 5.


### Start using
Simple setup
```objective-c
STDeviceManager *deviceManager = [STDeviceManager sharedInstance];
[deviceManager addDelegate:self];
[deviceManager scan];
```

Make flash
```objective-c
// setup custom time (miliseconds)
NSInteger time = 300;
[deviceManager configDevicesForCommand:STDeviceManagerComandShot time:time];
```

Send check notification to iblazr flash. You can manualy setup this effect. (Works with iblazr 2. Read additional documentation)
```objective-c
// setup custom time (miliseconds)
NSInteger time = 2000;
STDevice *device = {device}
[deviceManager configDevice:device forCommand:STDeviceManagerComandStatus time:time temperature:lightTemperature power:lightPower];
```

Make constant light
```objective-c
// setup custom time (miliseconds)  or set 0 for infinite
NSInteger time = 2000;
STDevice *device = {device}
[deviceManager configDevice:device STDeviceManagerComandLight time:time temperature:lightTemperature power:lightPower];
```
And Stop
```objective-c
// setup zero time
NSInteger time = 0;
STDevice *device = {device}
[deviceManager configDevice:device STDeviceManagerComandStop time:time temperature:lightTemperature power:lightPower];
```

## Additional Resources
You can find additional protocol information here:
* iblazr 2 documentation at *LINK*
* iblazr original documentation at *LINK*

## License
iblazrSDK is licensed under the MIT License. See LICENSE for details.

## Feedback
Contact the developer support team by sending an email to support@concepter.co