//
//  AppDelegate.m
//  uPINPoint Live
//
//  Created by Nicholas Ver Voort on 1/10/13.
//  Copyright (c) 2013 Engaging Computing Group. All rights reserved.
//

#import "AppDelegate.h"
#import <IOKit/Hid/IOHIDManager.h>
#import <CoreFoundation/CFSet.h>
#import "uPINPoint.h"

@implementation AppDelegate

id selfRef;
NSColor *colorRed, *colorGreen, *colorWhite;
IOHIDDeviceRef uPPT;
uPINPoint *pinMan;

//Quit the application when there are no open windows
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    selfRef = self;
    colorRed =  [NSColor colorWithCalibratedRed:0.7f green:0.0f blue:0.0f alpha:1.0f];
    colorGreen = [NSColor colorWithCalibratedRed:0.0f green:0.7f blue:0.0f alpha:1.0f];
    colorWhite = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    
    pinMan = [[uPINPoint alloc] init];
    
    [self.resConsole setFont:[NSFont fontWithName:@"Courier" size:12]];
    
    int vendorID = 0x04D8;
    int productID = 0x0054;
    //Create a HID Manager
    IOHIDManagerRef hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    
    //Create a dictionary and limit it to the uPPT
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable (kCFAllocatorDefault, 2, &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(dict, CFSTR(kIOHIDVendorIDKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vendorID));
    CFDictionarySetValue(dict, CFSTR(kIOHIDProductIDKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &productID));
    IOHIDManagerSetDeviceMatching(hidManager, dict);
    
    //Register a callback for USB detection
    IOHIDManagerRegisterDeviceMatchingCallback(hidManager, &Handle_DeviceMatchingCallback, NULL);
    //Register a callback for USB detection
    IOHIDManagerRegisterDeviceRemovalCallback(hidManager, &Handle_DeviceRemovalCallback, NULL);
    //Register the HID Manager on our app's run loop
    IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    
    //Open the HID Manager
    IOReturn IOReturn = IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);
    if(IOReturn) NSLog(@"IOHIDManagerOpen failed."); //Couldn't open the HID Manager!
    
}

//Changes the connection status field in the UI
- (void)changeConnectionStatusView:(Boolean)status {
    if(status) {
        [self.cStatus setStringValue:@"Connected"];
        [self.cStatus setBackgroundColor:(colorGreen)];
        [self.cStatus setTextColor:(colorWhite)];
    } else {
        [self.cStatus setStringValue:@"Disconnected"];
        [self.cStatus setBackgroundColor:(colorRed)];
        [self.cStatus setTextColor:(colorWhite)];
    }
}

//Called when the Set Date/Time button is pressed. Sends the new date/time to the uPPT
- (IBAction)setTime:(id)sender {
    CFIndex reportSize = 64;
    uint8_t *report = malloc(reportSize * sizeof(uint8_t));
    
    //unitFlags to tell the NSDateComponents which components we're interested in
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit |
                         NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSWeekdayCalendarUnit;
    NSDate *now = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:now];
    
    report[0] = CMD_SET_DATE_TIME;
    //Convert to BCD for the device
    report[1] = (uint8) (((([components year] - 2000)/10) << 4) | (([components year] - 2000) % 10));
    report[2] = (uint8) ((([components month] / 10) << 4) | ([components month] % 10));
    report[3] = (uint8) ((([components day] / 10) << 4) | ([components day] % 10));
    report[4] = (uint8) [components weekday];
    
    report[5] = (uint8) ((([components hour] / 10) << 4) | ([components hour] % 10));
    report[6] = (uint8) ((([components minute] / 10) << 4) | ([components minute] % 10));
    report[7] = (uint8) ((([components second] / 10) << 4) | ([components second] % 10));
    
    for(int i = 8; i < 64; i++) { //Initialize unused bytes of report to 0xFF
        report[i] = 0xFF;         //For lower power consumption on USB bus
    }
    
    //Send the built report to the uPPT
    IOHIDDeviceSetReport(uPPT, kIOHIDReportTypeOutput, 0, report, reportSize);
}

- (IBAction)sendCmdReadButton:(id)sender {
    [self sendGenericCommand:CMD_READ_BUTTON];
}

//Called when the Test LEDs button is pressed
- (IBAction)sendCmdTestLEDs:(id)sender {
    [self sendGenericCommand:CMD_TEST_LEDS];
}

//Sends one of the generic single-byte command to the uPPT
- (void)sendGenericCommand:(uint8_t)cmd {
    CFIndex reportSize = 64;
    uint8_t *report = malloc(reportSize * sizeof(uint8_t));

    report[0] = cmd;              //Sets the first byte to the command to be sent
    for(int i = 1; i < 64; i++) { //Initialize unused bytes of report to 0xFF
        report[i] = 0xFF;         //For lower power consumption on USB bus
    }
    
    //Send the built report to the uPPT
    IOHIDDeviceSetReport(uPPT, kIOHIDReportTypeOutput, 0, report, reportSize);
}

//Writes a message to the console under the Diagnostics tab
- (void)writeTextToConsole:(NSString*)message {
    NSRange mRange;
    mRange = NSMakeRange([[self.resConsole string] length], 0);
    [self.resConsole replaceCharactersInRange:mRange withString:message];
    [self.resConsole scrollRangeToVisible:mRange];
    [self.resConsole display];
}

//Displays data from the PPT's "CMD_READ_ALL" in the appropriate fields in the UI
- (void)showData {
    [self.dayField setStringValue:[NSString stringWithFormat:@"%d", [pinMan day]]];
    [self.monthField setStringValue:[NSString stringWithFormat:@"%d", [pinMan month]]];
    [self.yearField setStringValue:[NSString stringWithFormat:@"%d", [pinMan year]]];
    [self.hourField setStringValue:[NSString stringWithFormat:@"%d", [pinMan hour]]];
    [self.minuteField setStringValue:[NSString stringWithFormat:@"%02d", [pinMan minute]]];
    [self.secondField setStringValue:[NSString stringWithFormat:@"%02d", [pinMan second]]];
    
    [self.battField setStringValue:[NSString stringWithFormat:@"%.2f", ((double)[pinMan battVolt]/100.0)]];
    [self.tempField setStringValue:[NSString stringWithFormat:@"%.1f", ((double)[pinMan temperature]/10.0)]];
}

//Called when a new uPPT is plugged in
static void Handle_DeviceMatchingCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef){
    if(USBDeviceCount(inSender) == 1) {
        [selfRef changeConnectionStatusView:true];
        uPPT = inIOHIDDeviceRef;
        [pinMan init:uPPT];
    }
}

//Called when a uPPT is removed
static void Handle_DeviceRemovalCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef){
    if(USBDeviceCount(inSender) == 0) {
        [selfRef changeConnectionStatusView:false];
        [pinMan deinit];
        uPPT = NULL;
    }
}

static long USBDeviceCount(IOHIDManagerRef HIDManager) {
    CFSetRef devSet = IOHIDManagerCopyDevices (HIDManager);
    if( devSet ) {
        return CFSetGetCount(devSet);
    }
    return 0;
}
@end
