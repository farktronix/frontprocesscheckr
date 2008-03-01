//
//  FPCheckrController.h
//  FrontProcessCheckr
//
//  Created by Jacob Farkas on 2/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl-WithInstaller/GrowlApplicationBridge.h>

@interface FPCheckrController : NSObject <GrowlApplicationBridgeDelegate> {
    IBOutlet NSTextField *_statusText;
    IBOutlet NSButton *_monitorButton;
    
    NSTimer *_checkFrontProcessTimer;
    BOOL _monitoring;
    ProcessSerialNumber _lastFrontProcess;
}

- (IBAction) toggleMonitoring:(id)sender;

@end
