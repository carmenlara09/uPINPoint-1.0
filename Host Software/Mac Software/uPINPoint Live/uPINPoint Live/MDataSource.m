//
//  MDataSource.m
//  uPINPoint Live
//
//  Created by Nicholas Ver Voort on 3/22/13.
//  Copyright (c) 2013 Engaging Computing Group. All rights reserved.
//

#import "MDataSource.h"
#import "CorePlot.h"

@implementation MDataSource

-(void)setDataArray:(NSArray*)dataArray {
    myDataArray = dataArray;
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return [myDataArray count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    NSArray *subpoint = [myDataArray objectAtIndex:index];
    
    // FieldEnum determines if we return an X or Y value.
    if ( fieldEnum == CPTScatterPlotFieldX )
    {
        return [NSNumber numberWithFloat:[[subpoint objectAtIndex:0] floatValue]];
    }
    else    // Y-Axis
    {
        return [NSNumber numberWithFloat:[[subpoint objectAtIndex:1] floatValue]];
    }
}

@end
