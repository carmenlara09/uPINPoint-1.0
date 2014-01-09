//
//  MDataSource.h
//  uPINPoint Live
//
//  Created by Nicholas Ver Voort on 3/22/13.
//  Copyright (c) 2013 Engaging Computing Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CorePlot.h"

NSArray* myDataArray;

@interface MDataSource : NSObject<CPTPlotDataSource>

-(void)setDataArray:(NSArray*)dataArray;

@end
