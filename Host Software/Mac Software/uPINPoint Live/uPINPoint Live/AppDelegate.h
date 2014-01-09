//
//  AppDelegate.h
//  uPINPoint Live
//
//  Created by Nicholas Ver Voort on 1/10/13.
//  Copyright (c) 2013 Engaging Computing Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/hid/IOHIDManager.h>
#import "CorePlot.h"

//define uPPT Command Bytes
const static int CMD_READ_ALL = 0x80;
const static int CMD_SET_DATE_TIME = 0x81;
const static int CMD_SET_CALIBRATION = 0x82;
const static int CMD_WRITE_CALIBRATION = 0x83;
const static int CMD_READ_CALIBRATION = 0x84;
const static int CMD_READ_SYSTEM_INFO = 0x70;
const static int CMD_READ_BATTERY_VOLTAGE = 0x71;
const static int CMD_READ_BUTTON = 0x72;
const static int CMD_TEST_LEDS = 0x73;
const static int CMD_CHECK_RTCC = 0x74;
const static int CMD_SCAN_BMP085 = 0x75;
const static int CMD_SCAN_MAX44007 = 0x76;
const static int CMD_SCAN_ADXL345 = 0x77;
const static int CMD_CHECK_SHORTS = 0x78;
const static int CMD_FULL_DIAGNOSTICS = 0x79;

@interface AppDelegate : NSObject <NSApplicationDelegate>

//Connection status field
@property (unsafe_unretained) IBOutlet NSTextField *cStatus;

//Buttons
@property (unsafe_unretained) IBOutlet NSButton *btnDateTime;
@property (unsafe_unretained) IBOutlet NSButton *btnDiagnostics;
@property (unsafe_unretained) IBOutlet NSButton *btnReadInfo;
@property (unsafe_unretained) IBOutlet NSButton *btnBattVolt;
@property (unsafe_unretained) IBOutlet NSButton *btnReadButton;
@property (unsafe_unretained) IBOutlet NSButton *btnTestLEDs;
@property (unsafe_unretained) IBOutlet NSButton *btnCheckRTCC;
@property (unsafe_unretained) IBOutlet NSButton *btnBMP085;
@property (unsafe_unretained) IBOutlet NSButton *btnMAX44007;
@property (unsafe_unretained) IBOutlet NSButton *btnADXL345;
@property (unsafe_unretained) IBOutlet NSButton *btnSetCalibration;
@property (unsafe_unretained) IBOutlet NSButton *btnWriteCalibration;
@property (unsafe_unretained) IBOutlet NSButton *btnReadCalibration;

//Time and date fields
@property (unsafe_unretained) IBOutlet NSTextField *monthField;
@property (unsafe_unretained) IBOutlet NSTextField *dayField;
@property (unsafe_unretained) IBOutlet NSTextField *yearField;
@property (unsafe_unretained) IBOutlet NSTextField *hourField;
@property (unsafe_unretained) IBOutlet NSTextField *minuteField;
@property (unsafe_unretained) IBOutlet NSTextField *secondField;
//Other UI fields
@property (unsafe_unretained) IBOutlet NSTextField *battField;
@property (unsafe_unretained) IBOutlet NSTextField *tempField;
@property (unsafe_unretained) IBOutlet NSTextField *pressureField;
@property (unsafe_unretained) IBOutlet NSTextField *altitudeField;
@property (unsafe_unretained) IBOutlet NSTextField *lightField;
//Acceleration box fields
@property (unsafe_unretained) IBOutlet NSTextField *accelXField;
@property (unsafe_unretained) IBOutlet NSTextField *accelYField;
@property (unsafe_unretained) IBOutlet NSTextField *accelZField;
@property (unsafe_unretained) IBOutlet NSTextField *accelMField;

//Pressure/Temp/Altitude/Light tab views
@property (unsafe_unretained) IBOutlet CPTGraphHostingView *graphPressure;
@property (unsafe_unretained) IBOutlet CPTGraphHostingView *graphTemperature;
@property (unsafe_unretained) IBOutlet CPTGraphHostingView *graphAltitude;
@property (unsafe_unretained) IBOutlet CPTGraphHostingView *graphLight;
@property (unsafe_unretained) IBOutlet CPTGraphHostingView *graphAccel;


//Results Console in Diagnostics tab
@property (unsafe_unretained) IBOutlet NSTextView *resConsole;

@property (assign) IBOutlet NSWindow *window;

//functions for UI button presses
- (IBAction)setTime:(id)sender;
- (IBAction)sendCmdRunDiagnostics:(id)sender;
- (IBAction)sendCmdBattVolt:(id)sender;
- (IBAction)sendCmdSysInfo:(id)sender;
- (IBAction)sendCmdReadButton:(id)sender;
- (IBAction)sendCmdTestLEDs:(id)sender;
- (IBAction)sendCmdCheckRTCC:(id)sender;
- (IBAction)sendCmdScanBmp:(id)sender;
- (IBAction)sendCmdScanMax:(id)sender;
- (IBAction)sendCmdScanAdxl:(id)sender;

- (void) initializeGraphs;

- (void) readData:(uint8_t *)inReport;

- (void)sendGenericCommand:(uint8_t)cmd;

- (void)writeTextToConsole:(NSString*)message;

- (void)showData;

- (void)changeConnectionStatusView:(Boolean)status;
- (void)setButtonsEnabled:(Boolean)status;

//HID Device Callbacks taken from tutorial at http://ontrak.net/xcode.htm
// USB device added callback function
static void Handle_DeviceMatchingCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef);
// USB device removed callback function
static void Handle_DeviceRemovalCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef);
// Counts the number of devices in the device set (includes all USB devices that match our dictionary)
static long USBDeviceCount(IOHIDManagerRef HIDManager);
// Input report reading callback
static void Handle_IOHIDDeviceIOHIDReportCallback(void * inContext, IOReturn inResult, void *inSender, IOHIDReportType inType,
                                                  uint32_t inReportID, uint8_t * inReport, CFIndex inReportLength);

//Data read in from uPPT
@property (nonatomic, assign) int month;
@property (nonatomic, assign) int day;
@property (nonatomic, assign) int year;
@property (nonatomic, assign) int hour;
@property (nonatomic, assign) int minute;
@property (nonatomic, assign) int second;
@property (nonatomic, assign) int battVolt;
@property (nonatomic, assign) int temperature;
@property (nonatomic, assign) int pressure;
@property (nonatomic, assign) int altitude;
@property (nonatomic, assign) int accelX;
@property (nonatomic, assign) int accelY;
@property (nonatomic, assign) int accelZ;
@property (nonatomic, assign) int accelM;
@property (nonatomic, assign) int light;

@end
