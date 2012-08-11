//
//  SMAppDelegate.h
//  PlayBar
//
//  Created by Stuart Moore on 8/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface SMAppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;

@property (strong, nonatomic) IBOutlet NSPanel *popover;
@property (strong, nonatomic) IBOutlet NSTextField *timeElapsedLabel, *timeRemainingLabel;
@property (strong, nonatomic) IBOutlet NSTextField *titleLabel, *albumLabel, *artistLabel;
@property (strong, nonatomic) IBOutlet NSSlider *seekbar;
@property (strong, nonatomic) IBOutlet NSImageView *albumArtView;
@property (strong, nonatomic) IBOutlet NSButton *playPauseButton;

@property (strong, nonatomic) QTMovie *player;
@property (strong, nonatomic) NSTimer *timer;

- (void)movieRateChanged:(NSNotification*)notification;

- (IBAction)openFile:(id)sender;
- (IBAction)togglePlayPause:(id)sender;

@end
