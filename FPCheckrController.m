//
//  FPCheckrController.m
//  FrontProcessCheckr
//
//  Created by Jacob Farkas on 2/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FPCheckrController.h"

@implementation FPCheckrController

- (void) _displayProcessChangedNotification:(NSString *)newProcessName lastProcessName:(NSString *)oldProcessName iconData:(NSData *)icon
{
    NSString *oldString = [NSString stringWithFormat:@"Old front process: %@", oldProcessName];
    NSString *newString = [NSString stringWithFormat:@"New front process: %@", newProcessName];
    NSLog(@"%@", oldString);
    NSLog(@"%@", newString);
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = newString;
    notification.subtitle = oldString;
    [center deliverNotification: notification];
//    [GrowlApplicationBridge
//        notifyWithTitle:@"Front Process Changed"
//        description:newProcessName
//        notificationName:@"Front Process Changed"
//        iconData:icon
//        priority:0
//        isSticky:NO
//        clickContext:nil];
}

- (NSData *) _iconForProcess:(ProcessSerialNumber *)psn
{
    NSData *icon = nil;
    CFDictionaryRef processInfoDict = ProcessInformationCopyDictionary(psn, kProcessDictionaryIncludeAllInformationMask);
    if (processInfoDict) {
        CFStringRef bundlePath = CFDictionaryGetValue(processInfoDict, CFSTR("BundlePath"));
        if (bundlePath) {
            NSBundle *appBundle = [NSBundle bundleWithPath:(NSString *)bundlePath];
            NSString *iconName = [[appBundle infoDictionary] objectForKey:@"CFBundleIconFile"];
            NSString *iconPath = [appBundle pathForResource:iconName ofType:@"icns"];
            // Some apps specify the icon with an extension, some don't. Check for both.
            if (iconPath == nil) {
                iconName = [iconName stringByDeletingPathExtension];
                iconPath = [appBundle pathForResource:iconName ofType:@"icns"];
            }
            if (iconPath) 
                icon = [NSData dataWithContentsOfFile:iconPath];
        }
        CFRelease(processInfoDict);
    }
    return icon;
}

- (void) _checkFrontProcess
{
    ProcessSerialNumber frontProcess;
    Boolean sameProcess = false;
    
    GetFrontProcess(&frontProcess);
    SameProcess(&frontProcess, &_lastFrontProcess, &sameProcess);
    if (sameProcess == false) {
        memcpy(&_lastFrontProcess, &frontProcess, sizeof(ProcessSerialNumber));
        CFStringRef processName = NULL;
        CopyProcessName(&frontProcess, &processName);

        [self _displayProcessChangedNotification:(NSString *)processName lastProcessName:(NSString *)_lastProcessName iconData:[self _iconForProcess:&frontProcess]];

        if (_lastProcessName) { [_lastProcessName release]; }
        _lastProcessName = [[NSString alloc] initWithString: (NSString *)processName];
        if (processName) CFRelease(processName);
    }
}

- (void) _disableTimer
{
    [_checkFrontProcessTimer invalidate];
    [_checkFrontProcessTimer release];
    _checkFrontProcessTimer = nil;
}

- (void) _startTimer
{
    if (_checkFrontProcessTimer == nil) {
        _checkFrontProcessTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1.0 target:self selector:@selector(_checkFrontProcess) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_checkFrontProcessTimer forMode:NSDefaultRunLoopMode];
    }
}

- (id) init
{
    if ((self = [super init])) {
        _monitoring = NO;
    }
    return self;
}

- (void) dealloc
{
    [self _disableTimer];
    [_lastProcessName release];
    _lastProcessName = nil;
    [super dealloc];
}

- (void) awakeFromNib
{
    [GrowlApplicationBridge setGrowlDelegate:self];
    [self toggleMonitoring:self];
}

- (IBAction) toggleMonitoring:(id)sender
{
    if (_monitoring == NO) {
        _monitoring = YES;
        _monitorButton.title = @"Stop monitoring";
        _statusText.stringValue = @"ON";
        [self _startTimer];
    } else {    
        _monitoring = NO;
        _monitorButton.title = @"Start monitoring";
        _statusText.stringValue = @"OFF";
        [self _disableTimer];
    }
}

@end
