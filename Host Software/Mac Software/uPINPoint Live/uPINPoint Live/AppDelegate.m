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
#import "CorePlot.h"
#import "MDataSource.h"

@implementation AppDelegate

//Variables for data read from the READ ALL command
@synthesize year, month, day, hour, minute, second, battVolt, temperature, pressure, altitude, accelX, accelY, accelZ, accelM, light;

id selfRef;
NSColor *colorRed, *colorGreen, *colorWhite;
IOHIDDeviceRef uPPT;

//Graph objects
CPTXYGraph *graphP, *graphT, *graphA, *graphL, *graphAc;
CPTXYPlotSpace *plotSpaceP,*plotSpaceT, *plotSpaceA, *plotSpaceL, *plotSpaceAc;
CPTMutableLineStyle *lineStyle;

//Array objects to hold recent data, for graphing
int tickNumber = 0;
NSMutableArray *pressureArray, *temperatureArray, *altitudeArray, *lightArray, *xArray, *yArray, *zArray;
MDataSource *dataSourceP, *dataSourceT, *dataSourceA, *dataSourceL, *dataSourceX, *dataSourceY, *dataSourceZ;

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
    
    //Initialize data sources for first tab graphs
    pressureArray = [[NSMutableArray alloc] init];
    dataSourceP = [[MDataSource alloc] init];
    temperatureArray = [[NSMutableArray alloc] init];
    dataSourceT = [[MDataSource alloc] init];
    altitudeArray = [[NSMutableArray alloc] init];
    dataSourceA = [[MDataSource alloc] init];
    lightArray = [[NSMutableArray alloc] init];
    dataSourceL = [[MDataSource alloc] init];
    
    //initialize data sources for accelerometer graph
    xArray = [[NSMutableArray alloc] init];
    dataSourceX = [[MDataSource alloc] init];
    yArray = [[NSMutableArray alloc] init];
    dataSourceY = [[MDataSource alloc] init];
    zArray = [[NSMutableArray alloc] init];
    dataSourceZ = [[MDataSource alloc] init];
    
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
    
    [self initializeGraphs];
}

- (void) initializeGraphs {
    
    CPTTheme *theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    CPTMutableTextStyle *axisTitleTextStyle = [[CPTMutableTextStyle alloc] init];
    axisTitleTextStyle.fontName = @"Helvetica";
    axisTitleTextStyle.fontSize = 14.0;
    CPTMutableTextStyle *axisLabelTextStyle = [[CPTMutableTextStyle alloc] init];
    axisLabelTextStyle.fontName = @"Helvetica";
    axisLabelTextStyle.fontSize = 10.0;
    
    //Set up the line style
    lineStyle = [[CPTMutableLineStyle alloc] init];
    lineStyle.lineWidth = 1.5f;
    lineStyle.lineColor = [CPTColor blueColor];
    
    //Set up the gradient for the area under the graph
    CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:[CPTColor redColor]
                                                          endingColor:[CPTColor clearColor]];
    areaGradient.angle = -70.0f;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    
    //Set up the pressure graph
    graphP = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    graphP.title = @"Pressure";
    [graphP applyTheme:theme];
    graphP.paddingLeft = 10.0;
    graphP.paddingRight = 10.0;
    graphP.plotAreaFrame.paddingTop    = 10.0;
    graphP.plotAreaFrame.paddingBottom = 20.0;
    graphP.plotAreaFrame.paddingLeft   = 50.0;
    graphP.plotAreaFrame.paddingRight  = 20.0;
    graphP.plotAreaFrame.borderLineStyle = nil;
    graphP.titleTextStyle = axisTitleTextStyle;
    CPTXYAxisSet *axisSetP = (CPTXYAxisSet *)graphP.axisSet;
    plotSpaceP = (CPTXYPlotSpace *)graphP.defaultPlotSpace;
    plotSpaceP.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                     length:CPTDecimalFromFloat(50)];
    plotSpaceP.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                     length:CPTDecimalFromFloat(110)];
    CPTXYAxis *xP = axisSetP.xAxis;
    xP.majorIntervalLength = CPTDecimalFromFloat(10);
    xP.minorTicksPerInterval = 4;
    xP.labelTextStyle = axisLabelTextStyle;
    xP.titleTextStyle = axisLabelTextStyle;
    
    CPTXYAxis *yP = axisSetP.yAxis;
    yP.majorIntervalLength = CPTDecimalFromFloat(20);
    yP.minorTicksPerInterval = 5;
    yP.title = @"Pressure (kPa)";
    yP.labelTextStyle = axisLabelTextStyle;
    yP.titleTextStyle = axisLabelTextStyle;
    yP.labelOffset = -5.0;
    yP.labelRotation = -370;
    yP.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    
    CPTScatterPlot *pressureScatter = [[CPTScatterPlot alloc] init];
    pressureScatter.dataSource = dataSourceP;
    
    [pressureScatter setDataLineStyle:lineStyle];
    [pressureScatter setAreaFill:areaGradientFill];
    [pressureScatter setAreaBaseValue:CPTDecimalFromFloat(0.0)];
    
    [graphP addPlot:pressureScatter toPlotSpace:plotSpaceP];
    self.graphPressure.hostedGraph = graphP;
    
    //Set up the temperature graph
    graphT = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    graphT.title = @"Temperature";
    [graphT applyTheme:theme];
    graphT.paddingLeft = 10.0;
    graphT.paddingRight = 10.0;
    graphT.plotAreaFrame.paddingTop    = 10.0;
    graphT.plotAreaFrame.paddingBottom = 20.0;
    graphT.plotAreaFrame.paddingLeft   = 50.0;
    graphT.plotAreaFrame.paddingRight  = 20.0;
    graphT.plotAreaFrame.borderLineStyle = nil;
    graphT.titleTextStyle = axisTitleTextStyle;
    CPTXYAxisSet *axisSetT = (CPTXYAxisSet *)graphT.axisSet;
    plotSpaceT = (CPTXYPlotSpace *)graphT.defaultPlotSpace;
    plotSpaceT.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                     length:CPTDecimalFromFloat(50)];
    plotSpaceT.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-25)
                                                     length:CPTDecimalFromFloat(75)];
    CPTXYAxis *xT = axisSetT.xAxis;
    xT.majorIntervalLength = CPTDecimalFromFloat(10);
    xT.minorTicksPerInterval = 4;
    xT.labelTextStyle = axisLabelTextStyle;
    xT.titleTextStyle = axisLabelTextStyle;
    
    CPTXYAxis *yT = axisSetT.yAxis;
    yT.majorIntervalLength = CPTDecimalFromFloat(15);
    yT.minorTicksPerInterval = 4;
    yT.title = @"Temperature (ºC)";
    yT.labelTextStyle = axisLabelTextStyle;
    yT.titleTextStyle = axisLabelTextStyle;
    yT.labelOffset = -5.0;
    yT.labelRotation = -370;
    yT.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    
    CPTScatterPlot *temperatureScatter = [[CPTScatterPlot alloc] init];
    temperatureScatter.dataSource = dataSourceL;
    
    [temperatureScatter setDataLineStyle:lineStyle];
    [temperatureScatter setAreaFill:areaGradientFill];
    [temperatureScatter setAreaBaseValue:CPTDecimalFromFloat(0.0)];
    
    [graphT addPlot:temperatureScatter toPlotSpace:plotSpaceT];
    self.graphTemperature.hostedGraph = graphT;
    
    //Set up the altitude graph
    graphA = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    graphA.title = @"Altitude";
    [graphA applyTheme:theme];
    graphA.paddingLeft = 10.0;
    graphA.paddingRight = 10.0;
    graphA.plotAreaFrame.paddingTop    = 10.0;
    graphA.plotAreaFrame.paddingBottom = 20.0;
    graphA.plotAreaFrame.paddingLeft   = 50.0;
    graphA.plotAreaFrame.paddingRight  = 20.0;
    graphA.plotAreaFrame.borderLineStyle = nil;
    graphA.titleTextStyle = axisTitleTextStyle;
    CPTXYAxisSet *axisSetA = (CPTXYAxisSet *)graphA.axisSet;
    plotSpaceA = (CPTXYPlotSpace *)graphA.defaultPlotSpace;
    plotSpaceA.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                     length:CPTDecimalFromFloat(50)];
    plotSpaceA.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                     length:CPTDecimalFromFloat(500)];
    CPTXYAxis *xA = axisSetA.xAxis;
    xA.majorIntervalLength = CPTDecimalFromFloat(10);
    xA.minorTicksPerInterval = 4;
    xA.labelTextStyle = axisLabelTextStyle;
    xA.titleTextStyle = axisLabelTextStyle;
    
    CPTXYAxis *yA = axisSetA.yAxis;
    yA.majorIntervalLength = CPTDecimalFromFloat(100);
    yA.minorTicksPerInterval = 4;
    yA.title = @"Altitiude (m)";
    yA.labelTextStyle = axisLabelTextStyle;
    yA.titleTextStyle = axisLabelTextStyle;
    yA.labelOffset = -5.0;
    yA.labelRotation = -370;
    yA.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    
    CPTScatterPlot *altitudeScatter = [[CPTScatterPlot alloc] init];
    altitudeScatter.dataSource = dataSourceA;
    
    [altitudeScatter setDataLineStyle:lineStyle];
    [altitudeScatter setAreaFill:areaGradientFill];
    [altitudeScatter setAreaBaseValue:CPTDecimalFromFloat(0.0)];
    
    [graphA addPlot:altitudeScatter toPlotSpace:plotSpaceA];
    self.graphAltitude.hostedGraph = graphA;
    
    //Set up the light graph
    graphL = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    graphL.title = @"Light";
    [graphL applyTheme:theme];
    graphL.paddingLeft = 10.0;
    graphL.paddingRight = 10.0;
    graphL.plotAreaFrame.paddingTop    = 10.0;
    graphL.plotAreaFrame.paddingBottom = 20.0;
    graphL.plotAreaFrame.paddingLeft   = 50.0;
    graphL.plotAreaFrame.paddingRight  = 20.0;
    graphL.plotAreaFrame.borderLineStyle = nil;
    graphL.titleTextStyle = axisTitleTextStyle;
    CPTXYAxisSet *axisSetL = (CPTXYAxisSet *)graphL.axisSet;
    plotSpaceL = (CPTXYPlotSpace *)graphL.defaultPlotSpace;
    plotSpaceL.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                     length:CPTDecimalFromFloat(50)];
    plotSpaceL.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                     length:CPTDecimalFromFloat(8000)];
    CPTXYAxis *xL = axisSetL.xAxis;
    xL.majorIntervalLength = CPTDecimalFromFloat(10);
    xL.minorTicksPerInterval = 4;
    xL.labelTextStyle = axisLabelTextStyle;
    xL.titleTextStyle = axisLabelTextStyle;

    CPTXYAxis *yL = axisSetL.yAxis;
    yL.majorIntervalLength = CPTDecimalFromFloat(1000);
    yL.minorTicksPerInterval = 4;
    yL.title = @"Light (lux)";
    yL.labelTextStyle = axisLabelTextStyle;
    yL.titleTextStyle = axisLabelTextStyle;
    yL.labelOffset = -5.0;
    yL.labelRotation = -370;
    yL.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    
    CPTScatterPlot *lightScatter = [[CPTScatterPlot alloc] init];
    lightScatter.dataSource = dataSourceL;

    [lightScatter setDataLineStyle:lineStyle];
    [lightScatter setAreaFill:areaGradientFill];
    [lightScatter setAreaBaseValue:CPTDecimalFromFloat(0.0)];
    
    [graphL addPlot:lightScatter toPlotSpace:plotSpaceL];
    self.graphLight.hostedGraph = graphL;
    
    //Set up acceleration graph (there are multiple plots on this graph)
    //Set up the line styles
    CPTMutableLineStyle *lineStyleX = [[CPTMutableLineStyle alloc] init];
    lineStyleX.lineWidth = 3.0f;
    lineStyleX.lineColor = [CPTColor redColor];
    CPTMutableLineStyle *lineStyleY = [[CPTMutableLineStyle alloc] init];
    lineStyleY.lineWidth = 3.0f;
    lineStyleY.lineColor = [CPTColor greenColor];
    CPTMutableLineStyle *lineStyleZ = [[CPTMutableLineStyle alloc] init];
    lineStyleZ.lineWidth = 3.0f;
    lineStyleZ.lineColor = [CPTColor blueColor];
    
    graphAc = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
    graphAc.title = @"Acceleration";
    [graphAc applyTheme:theme];
    graphAc.paddingLeft = 10.0;
    graphAc.paddingRight = 10.0;
    graphAc.plotAreaFrame.paddingTop    = 10.0;
    graphAc.plotAreaFrame.paddingBottom = 20.0;
    graphAc.plotAreaFrame.paddingLeft   = 50.0;
    graphAc.plotAreaFrame.paddingRight  = 20.0;
    graphAc.plotAreaFrame.borderLineStyle = nil;
    graphAc.titleTextStyle = axisTitleTextStyle;
    CPTXYAxisSet *axisSetAc = (CPTXYAxisSet *)graphAc.axisSet;
    plotSpaceAc = (CPTXYPlotSpace *)graphAc.defaultPlotSpace;
    plotSpaceAc.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0)
                                                     length:CPTDecimalFromFloat(50)];
    plotSpaceAc.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-12)
                                                     length:CPTDecimalFromFloat(24)];
    CPTXYAxis *xAc = axisSetAc.xAxis;
    xAc.majorIntervalLength = CPTDecimalFromFloat(10);
    xAc.minorTicksPerInterval = 4;
    xAc.labelTextStyle = axisLabelTextStyle;
    xAc.titleTextStyle = axisLabelTextStyle;
    
    CPTXYAxis *yAc = axisSetAc.yAxis;
    yAc.majorIntervalLength = CPTDecimalFromFloat(4);
    yAc.minorTicksPerInterval = 2;
    yAc.title = [NSString stringWithUTF8String:"Acceleration (m/s\u00b2)"];
    yAc.labelTextStyle = axisLabelTextStyle;
    yAc.titleTextStyle = axisLabelTextStyle;
    yAc.labelOffset = -5.0;
    yAc.labelRotation = -370;
    yAc.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    
    CPTScatterPlot *xScatter = [[CPTScatterPlot alloc] init];
    xScatter.dataSource = dataSourceX;
    xScatter.title = @"Accel X";
    [xScatter setDataLineStyle:lineStyleX];
    [graphAc addPlot:xScatter];
    
    CPTScatterPlot *yScatter = [[CPTScatterPlot alloc] init];
    yScatter.dataSource = dataSourceY;
    yScatter.title = @"Accel Y";
    [yScatter setDataLineStyle:lineStyleY];
    [graphAc addPlot:yScatter];
    
    CPTScatterPlot *zScatter = [[CPTScatterPlot alloc] init];
    zScatter.dataSource = dataSourceZ;
    zScatter.title = @"Accel Z";
    [zScatter setDataLineStyle:lineStyleZ];
    [graphAc addPlot:zScatter];
    
    graphAc.legend = [CPTLegend legendWithGraph:graphAc];
    graphAc.legend.numberOfRows = 1;
    self.graphAccel.hostedGraph = graphAc;
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

//Enables or disables all the buttons that interact with the PINPoint
- (void)setButtonsEnabled:(Boolean)status {
    [self.btnDateTime setEnabled:status];
    [self.btnDiagnostics setEnabled:status];
    [self.btnReadInfo setEnabled:status];
    [self.btnBattVolt setEnabled:status];
    [self.btnReadButton setEnabled:status];
    [self.btnTestLEDs setEnabled:status];
    [self.btnCheckRTCC setEnabled:status];
    [self.btnBMP085 setEnabled:status];
    [self.btnMAX44007 setEnabled:status];
    [self.btnADXL345 setEnabled:status];
    [self.btnSetCalibration setEnabled:status];
    [self.btnWriteCalibration setEnabled:status];
    [self.btnReadCalibration setEnabled:status];
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
//Called when the Run Full Diagnostics button is pressed
- (IBAction)sendCmdRunDiagnostics:(id)sender {
    [self writeTextToConsole:@"Running full diagnostics...\r\n"];
    [self sendGenericCommand:CMD_FULL_DIAGNOSTICS];
}
//Called when the Read Battery Voltage button is pressed
- (IBAction)sendCmdBattVolt:(id)sender {
    [self sendGenericCommand:CMD_READ_BATTERY_VOLTAGE];
}
//Called when the Read System Info button is pressed
- (IBAction)sendCmdSysInfo:(id)sender {
    [self sendGenericCommand:CMD_READ_SYSTEM_INFO];
}
//Called when the Read Button button is pressed
- (IBAction)sendCmdReadButton:(id)sender {
    [self sendGenericCommand:CMD_READ_BUTTON];
}
//Called when the Test LEDs button is pressed
- (IBAction)sendCmdTestLEDs:(id)sender {
    [self sendGenericCommand:CMD_TEST_LEDS];
}
//Called when the Check RTCC button is pressed
- (IBAction)sendCmdCheckRTCC:(id)sender {
    [self sendGenericCommand:CMD_CHECK_RTCC];
}
//Called when the Scan BMP085 button is pressed
- (IBAction)sendCmdScanBmp:(id)sender {
    [self sendGenericCommand:CMD_SCAN_BMP085];
}
//Called when the Scan Max44007 button is pressed
- (IBAction)sendCmdScanMax:(id)sender {
    [self sendGenericCommand:CMD_SCAN_MAX44007];
}
//Called when the Scan ADXL345 button is pressed
- (IBAction)sendCmdScanAdxl:(id)sender {
    [self sendGenericCommand:CMD_SCAN_ADXL345];
}

//Sends a generic single-byte command to the uPPT
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
    NSRange mRange = NSMakeRange([[self.resConsole string] length], 0);
    [self.resConsole replaceCharactersInRange:mRange withString:message];
    [self.resConsole scrollRangeToVisible:NSMakeRange([[self.resConsole string] length], 0)];
    [self.resConsole display];
}

//Displays data from the PPT's "CMD_READ_ALL" in the appropriate fields in the UI
- (void)showData {
    [self.dayField setStringValue:[NSString stringWithFormat:@"%d", day]];
    [self.monthField setStringValue:[NSString stringWithFormat:@"%d", month]];
    [self.yearField setStringValue:[NSString stringWithFormat:@"%d", year]];
    [self.hourField setStringValue:[NSString stringWithFormat:@"%d", hour]];
    [self.minuteField setStringValue:[NSString stringWithFormat:@"%02d", minute]];
    [self.secondField setStringValue:[NSString stringWithFormat:@"%02d", second]];
    
    [self.battField setStringValue:[NSString stringWithFormat:@"%.2f", ((double)battVolt/100.0)]];
    [self.tempField setStringValue:[NSString stringWithFormat:@"%.1f", ((double)temperature/10.0)]];
    [self.pressureField setStringValue:[NSString stringWithFormat:@"%.3f", ((double)pressure/1000.0)]];
    [self.altitudeField setStringValue:[NSString stringWithFormat:@"%d", altitude]];
    
    [self.accelXField setStringValue:[NSString stringWithFormat:@"%.2f", ((double)accelX/100.0)]];
    [self.accelYField setStringValue:[NSString stringWithFormat:@"%.2f", ((double)accelY/100.0)]];
    [self.accelZField setStringValue:[NSString stringWithFormat:@"%.2f", ((double)accelZ/100.0)]];
    [self.accelMField setStringValue:[NSString stringWithFormat:@"%.2f", ((double)accelM/100.0)]];
    
    [self.lightField setStringValue:[NSString stringWithFormat:@"%.1f", ((double)light/10.0)]];
    
    //Update the arrays for graphing
    NSNumber *currTick = [NSNumber numberWithFloat:(float)tickNumber];
    
    //Update Pressure Graph
    NSNumber *tempPressure = [NSNumber numberWithDouble:((double)pressure/1000.0)];
    if([pressureArray count] > 50) {
        [pressureArray removeObjectAtIndex:0];
        plotSpaceP.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(tickNumber - 50)
                                                         length:CPTDecimalFromFloat(50)];
    }
    //Build an array with an X and Y of the current tick number and current pressure value
    NSMutableArray *tempPressurePoint = [[NSMutableArray alloc] init];
    [tempPressurePoint addObject:currTick];
    [tempPressurePoint addObject:tempPressure];
    [pressureArray addObject:tempPressurePoint]; //Add that array to the data set
    [dataSourceP setDataArray:pressureArray]; //Set that array into the Pressure Graph data source
    [graphP reloadData];
    
    //Update Temperature Graph
    NSNumber *tempTemp = [NSNumber numberWithDouble:((double)temperature/10.0)];
    if([temperatureArray count] > 50) {
        [temperatureArray removeObjectAtIndex:0];
        plotSpaceT.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(tickNumber - 50)
                                                         length:CPTDecimalFromFloat(50)];
    }
    //Build an array with an X and Y of the current tick number and current temperature value
    NSMutableArray *tempTempPoint = [[NSMutableArray alloc] init];
    [tempTempPoint addObject:currTick];
    [tempTempPoint addObject:tempTemp];
    [temperatureArray addObject:tempTempPoint]; //Add that array to the data set
    [dataSourceT setDataArray:temperatureArray]; //Set that array into the Temperature Graph data source
    [graphT reloadData];
    
    //Update Altitude Graph
    NSNumber *tempAlt = [NSNumber numberWithDouble:(altitude)];
    if([altitudeArray count] > 50) {
        [altitudeArray removeObjectAtIndex:0];
        plotSpaceA.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(tickNumber - 50)
                                                         length:CPTDecimalFromFloat(50)];
    }
    //Build an array with an X and Y of the current tick number and current altitude value
    NSMutableArray *tempAltPoint = [[NSMutableArray alloc] init];
    [tempAltPoint addObject:currTick];
    [tempAltPoint addObject:tempAlt];
    [altitudeArray addObject:tempAltPoint]; //Add that array to the data set
    [dataSourceA setDataArray:altitudeArray]; //Set that array into the Altitude Graph data source
    [graphA reloadData];

    //Update Light Graph
    NSNumber *tempLight = [NSNumber numberWithDouble:((double)light/10.0)];
    if([lightArray count] > 50) {
        [lightArray removeObjectAtIndex:0];
        plotSpaceL.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(tickNumber - 50)
                                                         length:CPTDecimalFromFloat(50)];
    }
    //Build an array with an X and Y of the current tick number and current light value
    NSMutableArray *tempLightPoint = [[NSMutableArray alloc] init];
    [tempLightPoint addObject:currTick];
    [tempLightPoint addObject:tempLight];
    [lightArray addObject:tempLightPoint]; //Add that array to the data set
    [dataSourceL setDataArray:lightArray]; //Set that array into the Light Graph data source
    [graphL reloadData];
    
    //Update Accel Graph
    NSNumber *tempX = [NSNumber numberWithDouble:((double)accelX/100.0)];
    NSNumber *tempY = [NSNumber numberWithDouble:((double)accelY/100.0)];
    NSNumber *tempZ = [NSNumber numberWithDouble:((double)accelZ/100.0)];
    if(tickNumber > 50) {
        [xArray removeObjectAtIndex:0];
        [yArray removeObjectAtIndex:0];
        [zArray removeObjectAtIndex:0];
        plotSpaceAc.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(tickNumber - 50)
                                                         length:CPTDecimalFromFloat(50)];
    }
    //Build an array with an X and Y of the current tick number and current acceleration values
    NSMutableArray *tempXPoint = [[NSMutableArray alloc] init];
    [tempXPoint addObject:currTick];
    [tempXPoint addObject:tempX];
    [xArray addObject:tempXPoint]; //Add that array to the data set
    [dataSourceX setDataArray:xArray]; //Set that array into the Accel Graph data source
    [[graphAc plotAtIndex:0] reloadData];
    NSMutableArray *tempYPoint = [[NSMutableArray alloc] init];
    [tempYPoint addObject:currTick];
    [tempYPoint addObject:tempY];
    [yArray addObject:tempYPoint]; //Add that array to the data set
    [dataSourceY setDataArray:yArray]; //Set that array into the Accel Graph data source
    [[graphAc plotAtIndex:1] reloadData];
    NSMutableArray *tempZPoint = [[NSMutableArray alloc] init];
    [tempZPoint addObject:currTick];
    [tempZPoint addObject:tempZ];
    [zArray addObject:tempZPoint]; //Add that array to the data set
    [dataSourceZ setDataArray:zArray]; //Set that array into the Accel Graph data source
    [[graphAc plotAtIndex:2] reloadData];

    tickNumber ++;
}

//Called when a new uPPT is plugged in
static void Handle_DeviceMatchingCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef){
    if(USBDeviceCount(inSender) == 1) {
        CFIndex reportSize = IOHIDDeviceGetProperty(inIOHIDDeviceRef, CFSTR(kIOHIDMaxInputReportSizeKey));
        uint8_t* mReport = (uint8_t*) malloc(reportSize * sizeof(uint8_t));
        
        uPPT = inIOHIDDeviceRef;
        [selfRef changeConnectionStatusView:true];
        [selfRef setButtonsEnabled:true];

        //Register a callback for Input HID Reports
        IOHIDDeviceRegisterInputReportCallback(inIOHIDDeviceRef, mReport, reportSize, Handle_IOHIDDeviceIOHIDReportCallback, NULL);
    }
}

//Called when a uPPT is removed
static void Handle_DeviceRemovalCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef){
    if(USBDeviceCount(inSender) == 0) {
        [selfRef changeConnectionStatusView:false];
        [selfRef setButtonsEnabled:false];
        uPPT = NULL;
        //Deregister the callback for Input HID Reports
        IOHIDDeviceRegisterInputReportCallback(inIOHIDDeviceRef, NULL, NULL, NULL, NULL);
    }
}

static long USBDeviceCount(IOHIDManagerRef HIDManager) {
    CFSetRef devSet = IOHIDManagerCopyDevices (HIDManager);
    if( devSet ) {
        return CFSetGetCount(devSet);
    }
    return 0;
}

static void Handle_IOHIDDeviceIOHIDReportCallback(void *          inContext,          //context from IOHIDDeviceRegisterInputReportCallback
                                                  IOReturn        inResult,           //completion result for the input report operation
                                                  void *          inSender,           //IOHIDDeviceRef of the device this report is from
                                                  IOHIDReportType inType,             //the report type
                                                  uint32_t        inReportID,         //the report ID
                                                  uint8_t *       inReport,           //pointer to the report data
                                                  CFIndex         inReportLength)     //the actual size of the input report
{
    if(inResult == kIOReturnSuccess) {
        [selfRef readData:inReport];
    }
}

- (void) readData:(uint8_t *)inReport {
    int temporary; //temporary storage for values
    unsigned utemp; //unsigned temporary storage
    
    //inReport[0] is the command, or response code
    //inReport[1-63] vary by type
    switch( inReport[0] ) {
        case CMD_READ_ALL: {
            year = [[NSString stringWithFormat:@"%02x",inReport[1]] intValue] + 2000;
            month = [[NSString stringWithFormat:@"%02x",inReport[2]] intValue];
            day = [[NSString stringWithFormat:@"%02x",inReport[3]] intValue];
            hour = [[NSString stringWithFormat:@"%02x",inReport[5]] intValue];
            minute = [[NSString stringWithFormat:@"%02x",inReport[6]] intValue];
            second = [[NSString stringWithFormat:@"%02x",inReport[7]] intValue];
            
            battVolt = ((uint32)inReport[8] << 24) + ((uint32)inReport[9] << 16) + ((uint32)inReport[10] << 8) + (uint32)inReport[11];
            temperature = ((uint32)inReport[12] << 24) + ((uint32)inReport[13] << 16) + ((uint32)inReport[14] << 8) + (uint32)inReport[15];
            
            pressure = ((uint32)inReport[16] << 24) + ((uint32)inReport[17] << 16) + ((uint32)inReport[18] << 8) + (uint32)inReport[19];
            altitude = ((uint32)inReport[20] << 24) + ((uint32)inReport[21] << 16) + ((uint32)inReport[22] << 8) + (uint32)inReport[23];
            
            accelX = ((uint32)inReport[24] << 24) + ((uint32)inReport[25] << 16) + ((uint32)inReport[26] << 8) + (uint32)inReport[27];
            accelY = ((uint32)inReport[28] << 24) + ((uint32)inReport[29] << 16) + ((uint32)inReport[30] << 8) + (uint32)inReport[31];
            accelZ = ((uint32)inReport[32] << 24) + ((uint32)inReport[33] << 16) + ((uint32)inReport[34] << 8) + (uint32)inReport[35];
            accelM = ((uint32)inReport[36] << 24) + ((uint32)inReport[37] << 16) + ((uint32)inReport[38] << 8) + (uint32)inReport[39];
            
            light = ((uint32)inReport[40] << 24) + ((uint32)inReport[41] << 16) + ((uint32)inReport[42] << 8) + (uint32)inReport[43];
            
            [selfRef showData];
            
            break;
        }
        case CMD_READ_SYSTEM_INFO: {
            NSMutableString *message = [NSMutableString stringWithString:@"System Info:\r\n"];
            [message appendString:[NSString stringWithFormat:@"--Firmware version: 0x%.2x%.2x\r\n", inReport[1], inReport[2]]];
            utemp = ((uint32)inReport[3] << 24) + ((uint32)inReport[4] << 16) + ((uint32)inReport[5] << 8) + (uint32)inReport[6];
            [message appendString:[NSString stringWithFormat:@"--Serial Number: #%u\r\n", utemp]];
            temporary = ((uint32)inReport[7] << 24) + ((uint32)inReport[8] << 16) + ((uint32)inReport[9] << 8) + (uint32)inReport[10];
            [message appendString:[NSString stringWithFormat:@"--Temperature Offset: %d\r\n", temporary]];
            temporary = ((uint32)inReport[11] << 24) + ((uint32)inReport[12] << 16) + ((uint32)inReport[13] << 8) + (uint32)inReport[14];
            [message appendString:[NSString stringWithFormat:@"--Pressure Offset: %d\r\n", temporary]];
            temporary = ((uint32)inReport[15] << 24) + ((uint32)inReport[16] << 16) + ((uint32)inReport[17] << 8) + (uint32)inReport[18];
            [message appendString:[NSString stringWithFormat:@"--Accel X Offset: %d\r\n", temporary]];
            temporary = ((uint32)inReport[19] << 24) + ((uint32)inReport[20] << 16) + ((uint32)inReport[21] << 8) + (uint32)inReport[22];
            [message appendString:[NSString stringWithFormat:@"--Accel Y Offset: %d\r\n", temporary]];
            temporary = ((uint32)inReport[23] << 24) + ((uint32)inReport[24] << 16) + ((uint32)inReport[25] << 8) + (uint32)inReport[26];
            [message appendString:[NSString stringWithFormat:@"--Accel Z Offset: %d\r\n", temporary]];
            temporary = ((uint32)inReport[27] << 24) + ((uint32)inReport[28] << 16) + ((uint32)inReport[29] << 8) + (uint32)inReport[30];
            [message appendString:[NSString stringWithFormat:@"--Light Offset: %d\r\n", temporary]];
            
            [selfRef writeTextToConsole:message];
            break;
        }
        case CMD_READ_BATTERY_VOLTAGE: {
            temporary = ((uint32)inReport[1] << 24) + ((uint32)inReport[2] << 16) + ((uint32)inReport[3] << 8) + (uint32)inReport[4];
            NSMutableString *message = [NSString stringWithFormat:@"Read battery voltage:  %.2f V\r\n", ((double)temporary/100.0)];
            [selfRef writeTextToConsole:message];
            break;
        }
        case CMD_READ_BUTTON:{
            NSMutableString *message = [NSMutableString stringWithString:@"Read button: "];
            
            if (inReport[1] == 0) {
                [message appendString:@"Button is DOWN\r\n"];
            } else {
                [message appendString:@"Button is UP\r\n"];
            }
            
            [selfRef writeTextToConsole:message];
            
            break;
        }
        case CMD_TEST_LEDS:{
            [selfRef writeTextToConsole:@"Test LEDs: Did they both come on?\r\n"];
            break;
        }
        case CMD_CHECK_RTCC: {
            NSMutableString *message = [NSMutableString stringWithString:@"Check RTCC: "];
            
            if (inReport[1] == 0) {
                [message appendString:@"PASS, RTCC is running\r\n"];
            } else {
                [message appendString:@"FAIL, RTCC does not seem to be running\r\n"];
            }
            
            [selfRef writeTextToConsole:message];
            
            break;
        }
        case CMD_SCAN_BMP085: {
            NSMutableString *message = [NSMutableString stringWithString:@"Scan BMP085: "];
            
            if (inReport[1] == 0) {
                [message appendString:@"PASS, device responded to inquiry - "];
            } else {
                [message appendString:@"FAIL, no response from device - "];
            }
            
            [message appendString:[NSString stringWithFormat:@"0x%.2x%.2x\r\n", inReport[2], inReport[3]]];
            
            [selfRef writeTextToConsole:message];
            
            break;
        }
        case CMD_SCAN_MAX44007: {
            NSMutableString *message = [NSMutableString stringWithString:@"Scan MAX44007: "];
            
            if (inReport[1] == 0) {
                [message appendString:@"PASS, device responded to inquiry - "];
            } else {
                [message appendString:@"FAIL, no response from device - "];
            }
            
            [message appendString:[NSString stringWithFormat:@"0x%.2x%.2x\r\n", inReport[2], inReport[3]]];
            
            [selfRef writeTextToConsole:message];
            
            break;
        }
        case CMD_SCAN_ADXL345: {
            NSMutableString *message = [NSMutableString stringWithString:@"Scan ADXL345: "];
            
            if (inReport[1] == 0) {
                [message appendString:@"PASS, device responded to inquiry - "];
            } else {
                [message appendString:@"FAIL, no response from device - "];
            }
            
            [message appendString:[NSString stringWithFormat:@"0x%.2x%.2x\r\n", inReport[2], inReport[3]]];
            
            [selfRef writeTextToConsole:message];
            
            break;
        }
        case CMD_FULL_DIAGNOSTICS: {
            NSMutableString *message = [NSMutableString stringWithFormat:@"Full Diagnostics:\r\n--Firmware version: 0x%.2x%.2x\r\n",
                                        inReport[1], inReport[2]];
            temporary = ((uint32)inReport[3] << 24) + ((uint32)inReport[4] << 16) + ((uint32)inReport[5] << 8) + (uint32)inReport[6];
            if(temporary < 40) {
                [message appendString:
                 [NSString stringWithFormat:@"--Battery: FAIL, is the battery installed? - %.2fV\r\n", ((double)temporary/100.0)]];
            } else {
                [message appendString:[NSString stringWithFormat:@"--Battery: PASS - %.2fV\r\n", ((double)temporary/100.0)]];
            }
            if(inReport[7] == 0) {
                [message appendString:@"--Button: Read as DOWN, is this correct?\r\n"];
            } else {
                [message appendString:@"--Button: Read as UP, is this correct?\r\n"];
            }
            [message appendString:@"--LEDs: Did they both come on?\r\n"];
            if(inReport[8] == 0) {
                [message appendString:@"--RTCC: PASS, RTCC is running\r\n"];
            } else {
                [message appendString:@"--RTCC: FAIL, RTCC does not appear to be running\r\n"];
            }
            if(inReport[9] == 0) {
                [message appendString:
                 [NSString stringWithFormat:@"--BMP085: PASS, device responded to inquiry - 0x%.2x%.2x\r\n", inReport[10], inReport[11]]];
            } else {
                [message appendString:
                 [NSString stringWithFormat:@"--BMP085: FAIL, no response from device - 0x%.2x%.2x\r\n", inReport[10], inReport[11]]];
            }
            if(inReport[12] == 0) {
                [message appendString:
                 [NSString stringWithFormat:@"--MAX44007: PASS, device responded to inquiry - 0x%.2x%.2x\r\n", inReport[13], inReport[14]]];
            } else {
                [message appendString:
                 [NSString stringWithFormat:@"--MAX44007: FAIL, no response from device - 0x%.2x%.2x\r\n", inReport[13], inReport[14]]];
            }
            if(inReport[15] == 0) {
                [message appendString:
                 [NSString stringWithFormat:@"--ADXL345: PASS, device responded to inquiry - 0x%.2x%.2x\r\n", inReport[16], inReport[17]]];
            } else {
                [message appendString:
                 [NSString stringWithFormat:@"--ADXL345: FAIL, no response from device - 0x%.2x%.2x\r\n", inReport[16], inReport[17]]];
            }
            
            
            [selfRef writeTextToConsole:message];
        }
        default: {
            break;
        }
    }
}
@end
