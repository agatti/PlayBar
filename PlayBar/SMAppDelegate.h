//
//  SMAppDelegate.h
//  PlayBar
//
//  Created by Stuart Moore on 8/10/12.
//  Copyright (c) 2012-2013 Stuart Moore.
//  Copyright (c) 2014 Alessandro Gatti.
//  This file is part of PlayBar.

//  PlayBar is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  PlayBar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with PlayBar.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "SMStatusView.h"

@interface SMAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource, AVAudioPlayerDelegate, SMAppDelegateDelegate>

@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) IBOutlet NSPanel *popover;
@property (strong, nonatomic) IBOutlet NSTextField *timeLabel;
@property (strong, nonatomic) IBOutlet NSSlider *seekbar;
@property (strong, nonatomic) IBOutlet NSButton *playPauseButton;
@property (strong, nonatomic) IBOutlet NSTableView *episodeList;
@property (strong, nonatomic) IBOutlet NSWindow *openURLWindow;
@property (strong, nonatomic) IBOutlet NSTextField *URLField;
@property (strong, nonatomic) IBOutlet NSWindow *preferencesWindow;

@property (strong, nonatomic) NSString *album;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *artist;
@property (strong, nonatomic) NSImage *cover;

- (IBAction)togglePlayPause:(id)sender;
- (IBAction)slideSeekbar:(id)sender;
- (IBAction)nextEpisode:(id)sender;
- (IBAction)toggleList:(id)sender;
- (IBAction)openFileDialog:(id)sender;
- (IBAction)openURLDialog:(id)sender;
- (IBAction)closeURLDialog:(NSButton *)sender;
- (IBAction)showAboutWindow:(id)sender;
- (IBAction)showPreferenceWindow:(id)sender;
- (IBAction)quit:(id)sender;

@end
