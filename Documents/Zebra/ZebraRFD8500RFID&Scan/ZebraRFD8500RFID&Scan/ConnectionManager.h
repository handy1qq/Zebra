//
//  ConnectionManager.h
//  ScanScanWriteDemo
//
//  Created by Vincent Daempfle on 7/28/15.
//  Copyright (c) 2015 Vincent Daempfle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScannerAppEngine.h"

@interface ConnectionManager : NSObject <IScannerAppEngineDevConnectionsDelegate>

+ (ConnectionManager *) sharedConnectionManager;

- (void) initializeConnectionManager;

// establish connection to the scanner sdk
- (void)connectDeviceUsingScannerId:(int)scannerId;

// disconnect from the scanner sdk
- (void) disconnect;

// get connected scanner id
- (int) getConnectedScannerId;

// are we connected?
- (BOOL) isConnected;

@end
