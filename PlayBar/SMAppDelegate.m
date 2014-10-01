//
//  SMAppDelegate.m
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

#import "SMAppDelegate.h"

static NSString * const kFirstRunDonePreferenceKey = @"FirstRunDone";
static NSString * const kExitWhenDonePreferenceKey = @"ExitWhenDone";

@interface SMAppDelegate ()

- (void)startTimerUpdate;
- (void)stopTimerUpdate;
- (void)updateMetadataFromURL:(NSURL *)url;

- (void)addURL:(NSURL *)url;
- (void)playURL:(NSURL *)url;
- (void)doubleClickOnTableView:(NSTableView *)tableView;

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) NSMutableArray *episodes;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation SMAppDelegate

+ (void)initialize
{
    [super initialize];

    [SMAppDelegate setupDefaults];
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification
{
    self.episodes = [NSMutableArray new];
    
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (BOOL)application:(NSApplication*)application openFile:(NSString*)filename
{
    [self addURL:[NSURL fileURLWithPath:filename]];
    
    return YES;
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlString];
    [self addURL:url];
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    [self.episodeList setDoubleAction:@selector(doubleClickOnTableView:)];
    
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setHighlightMode:YES];

    NSImage *statusBarIcon = [NSImage imageNamed:@"statusBarIcon"];
    
    self.statusItem.image = statusBarIcon;
    self.statusItem.menu = self.statusMenu;
    
    [self.statusItem setTarget:self];

    SMStatusView *statusView = [[SMStatusView alloc] initWithFrame:NSMakeRect(0, 0, 22, NSStatusBar.systemStatusBar.thickness)];
    statusView.image = statusBarIcon;
    statusView.statusItem = self.statusItem;
    statusView.delegate = self;
    self.statusItem.view = statusView;

    NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    defaultsController.appliesImmediately = YES;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isFirstRun = [defaults boolForKey:kFirstRunDonePreferenceKey];
    if (!isFirstRun) {
        [defaults setBool:YES forKey:kFirstRunDonePreferenceKey];
        [defaults synchronize];
        [self.preferencesWindow makeKeyAndOrderFront:self];
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self nextEpisode:nil];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{

}

#pragma mark - Timer updates

- (void)startTimerUpdate
{
    self.playPauseButton.image = [NSImage imageNamed:@"button-pause"];
    SMStatusView *statusView = (SMStatusView*)self.statusItem.view;
    statusView.image = [NSImage imageNamed:@"statusBarIcon-playing"];

    [self.timer invalidate];
    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateSlider:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:(NSString*)kCFRunLoopCommonModes];
}

- (void)stopTimerUpdate
{
    self.playPauseButton.image = [NSImage imageNamed:@"button-play"];
    SMStatusView *statusView = (SMStatusView*)self.statusItem.view;
    statusView.image = [NSImage imageNamed:@"statusBarIcon"];

    [self.timer invalidate];
}

- (void)updateSlider:(id)timer
{
    NSTimeInterval currentTime = self.audioPlayer.currentTime;
    NSTimeInterval duration = self.audioPlayer.duration;

    self.seekbar.minValue = 0;
    self.seekbar.floatValue = currentTime;
    self.seekbar.maxValue = duration;
    
    float timeRemaining = duration-currentTime;
    int hours = timeRemaining / 60 / 60;
    int minutes = timeRemaining / 60 - 60 * hours;
    int seconds = timeRemaining - 60 * minutes - 60 * 60 * hours;
    self.timeLabel.stringValue = [NSString stringWithFormat:@"%0.1d:%0.2d:%0.2d", hours, minutes, seconds];
}

#pragma mark - Open Files

- (IBAction)openFileDialog:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:YES];
    [panel setResolvesAliases:YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"mp3"]]; // TODO: get all audio extensions
    
    [panel beginSheetModalForWindow:self.popover completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            [panel.URLs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [self addURL:(NSURL *)obj];
            }];
        }
    }];
}

- (IBAction)openURLDialog:(id)sender
{
    [NSApp beginSheet:self.openURLWindow
       modalForWindow:self.popover
        modalDelegate:self
       didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
          contextInfo:nil];
}

- (IBAction)closeURLDialog:(NSButton*)sender
{
    if([sender.title isEqualToString:@"Cancel"])
        [NSApp endSheet:self.openURLWindow returnCode:0];
    else if([sender.title isEqualToString:@"Open"])
        [NSApp endSheet:self.openURLWindow returnCode:1];
}

- (void)didEndSheet:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
    [sheet orderOut:self];

    if(returnCode == 1)
        [self addURL:[NSURL URLWithString:self.URLField.stringValue]];
}

#pragma mark - Menu callbacks

- (IBAction)showAboutWindow:(id)sender
{
}

- (IBAction)showPreferenceWindow:(id)sender
{
    [self.preferencesWindow makeKeyAndOrderFront:self];
}

#pragma mark - Add and Play

- (void)addURL:(NSURL*)url
{
    AVAsset *asset = [AVURLAsset URLAssetWithURL:url
                                         options:@{
                                                   AVURLAssetPreferPreciseDurationAndTimingKey: @YES,
                                                   AVURLAssetReferenceRestrictionsKey: @(AVAssetReferenceRestrictionForbidNone)
                                                   }];
    if (!asset.playable)
        return;

    if (self.episodes.count == 0)
        [self playURL:url];
    
    // if is directory, recurse.
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@", url];
    NSArray *array = [self.episodes filteredArrayUsingPredicate:predicate];
    
    if (array.count == 0)
    {
        NSDictionary *episodeDictionary = @{
                                            @"title" : url.lastPathComponent,
                                            @"album" : url.host ?: @"",
                                            @"url" : url
                                            };
        [self.episodes addObject:episodeDictionary];
        [self.episodeList reloadData];
    }
}

- (void)updateMetadataFromURL:(NSURL *)url {
    self.titleLabel.stringValue = @"";
    self.albumLabel.stringValue = @"";
    self.artistLabel.stringValue = @"";
    self.statusItem.toolTip = @"";

    self.seekbar.minValue = 0;
    self.seekbar.maxValue = 0;
    self.seekbar.floatValue = 0;

    self.albumArtView.image = nil;

    NSString *title;
    NSString *artist = @"";
    NSString *album;

    [self updateSlider:nil];

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url
                                            options:nil];

    for (NSString *format in asset.availableMetadataFormats) {
        for (AVMetadataItem *item in [asset metadataForFormat:format]) {
            if ([item.commonKey isEqualToString:AVMetadataCommonKeyTitle]) {
                title = item.stringValue;
                continue;
            }

            if ([item.commonKey isEqualToString:AVMetadataCommonKeyAlbumName]) {
                album = item.stringValue;
                continue;
            }

            if ([item.commonKey isEqualToString:AVMetadataCommonKeyArtist]) {
                artist = item.stringValue;
                continue;
            }

            if ([item.commonKey isEqualToString:AVMetadataCommonKeyArtwork]) {
                if ([item.keySpace isEqualToString:AVMetadataKeySpaceID3]) {
                    NSDictionary *id3 = [item.value copyWithZone:nil];
                    self.albumArtView.image = [[NSImage alloc] initWithData:id3[@"data"]];
                    continue;
                }

                if ([item.keySpace isEqualToString:AVMetadataKeySpaceiTunes]) {
                    self.albumArtView.image = [[NSImage alloc] initWithData:[item.value copyWithZone:nil]];
                }
            }
        }
    }

    title = title ?: url.lastPathComponent;
    album = album ?: url.host;

    self.titleLabel.stringValue = title;
    ((SMStatusView*) self.statusItem.view).toolTip = [NSString stringWithFormat:@"PlayBar - %@", title];
    self.albumLabel.stringValue = album;
    self.artistLabel.stringValue = artist;

    NSInteger rowIndex = 0;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@", url];
    NSArray *array = [self.episodes filteredArrayUsingPredicate:predicate];

    if(array.count > 0)
    {
        NSString *show = [album isEqualToString:@""] ? artist : album;
        NSDictionary *episodeDictionary = @{
                                            @"title" : title,
                                            @"album" : show,
                                            @"url" : array[0][@"url"]
                                            };

        rowIndex = [self.episodes indexOfObject:array[0]];
        [self.episodes replaceObjectAtIndex:rowIndex withObject:episodeDictionary];
        
        [self.episodeList reloadData];
    }
}

- (void)playURL:(NSURL*)url
{
    [self updateMetadataFromURL:url];

    NSTimeInterval savedTime = [[NSUserDefaults.standardUserDefaults objectForKey:url.absoluteString] doubleValue];
    NSError *error;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url
                                                              error:&error];
    if (![self.audioPlayer prepareToPlay]) {
        return;
    }
    self.audioPlayer.delegate = self;

    self.audioPlayer.currentTime = savedTime;
    [self.audioPlayer play];

    [self startTimerUpdate];
}

#pragma mark - Actions

- (IBAction)togglePlayPause:(id)sender
{
    if (self.audioPlayer.playing) {
        [self.audioPlayer stop];
        [self stopTimerUpdate];
    } else {
        [self.audioPlayer play];
        [self startTimerUpdate];
    }
}

- (IBAction)slideSeekbar:(id)sender
{
    self.audioPlayer.currentTime = self.seekbar.floatValue;

    [self updateSlider:nil];
}

- (IBAction)nextEpisode:(id)sender
{
    if(sender)
        [self saveState];

    NSURL *playingURL = self.audioPlayer.url;
    NSInteger rowIndex = 0;
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@", playingURL];
    NSArray *array = [self.episodes filteredArrayUsingPredicate:predicate];
    
    if(array.count > 0)
    {
        rowIndex = [self.episodes indexOfObject:array[0]];
        rowIndex++;
    }
    
    if(!sender && rowIndex >= self.episodes.count)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL shouldExit = [defaults boolForKey:kExitWhenDonePreferenceKey];
        if (shouldExit)
            [self quit:nil];
    }
    
    if(rowIndex >= self.episodes.count)
        rowIndex = 0;
        
    NSURL *url = self.episodes[rowIndex][@"url"];
    [self playURL:url];
    
    [self.episodeList reloadData];
}

- (IBAction)toggleList:(id)sender
{
    NSSize screenSize = [[self.popover screen] frame].size;
    NSRect frame = self.popover.frame;
    
    if(frame.size.height > self.popover.minSize.height)
        frame.size.height = self.popover.minSize.height;
    else
        frame.size.height += 200;
    
    frame.origin.y = screenSize.height - 22 - frame.size.height;
    
    [self.popover setFrame:frame display:YES animate:YES];
}

#pragma mark - Helpers

- (void)saveState
{
    if (!self.audioPlayer.url)
        return;

    NSTimeInterval currentTime = self.audioPlayer.currentTime;
    NSTimeInterval duration = self.audioPlayer.duration;

    if (currentTime > (duration * 0.8f)) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:self.audioPlayer.url.absoluteString];
    } else {
        [NSUserDefaults.standardUserDefaults setObject:@(currentTime) forKey:self.audioPlayer.url.absoluteString];
    }

    [NSUserDefaults.standardUserDefaults synchronize];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView*)tableView
{
    return self.episodes.count;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)rowIndex
{
    if ([tableColumn.identifier isEqualToString:@"title"])
    {
        return self.episodes[rowIndex][@"title"];
    }

    if ([tableColumn.identifier isEqualToString:@"album"])
    {
        return self.episodes[rowIndex][@"album"];
    }

    if ([tableColumn.identifier isEqualToString:@"isPlaying"])
    {
        NSURL *url = self.episodes[rowIndex][@"url"];
        NSURL *playingURL = self.audioPlayer.url;

        if ([url isEqualTo:playingURL])
            return @"✓";
    }
    
    return nil;
}

- (void)doubleClickOnTableView:(NSTableView*)tableView
{
    [self saveState];
    
    NSURL *url = self.episodes[tableView.clickedRow][@"url"];
    [self playURL:url];
    
    [self.episodeList reloadData];
}

#pragma mark - Window

- (BOOL)togglePopover
{
    NSRect frame = [NSApp currentEvent].window.frame;
    NSSize screenSize = self.popover.screen.frame.size;
    
    if(self.popover.isVisible)
    {
        [self.popover close];
        [NSApp deactivate];
    }
    else
    {
        frame.origin.y -= self.popover.frame.size.height;
        frame.origin.x += (frame.size.width - self.popover.frame.size.width)/2;
        
        if (screenSize.width < frame.origin.x + self.popover.frame.size.width)
            frame.origin.x = screenSize.width - self.popover.frame.size.width - 10;
        
        [self.popover setFrameOrigin:frame.origin];
        
        [NSApp activateIgnoringOtherApps:YES];
        [self.popover setIsVisible:YES];
        [self.popover makeKeyAndOrderFront:self];
    }
    
    return self.popover.isVisible;
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self.popover close];
    [((SMStatusView*)self.statusItem.view) highlight:NO];
}

#pragma mark - Kill

- (void)quit:(id)sender
{
    [self.audioPlayer stop];
    [NSApplication.sharedApplication terminate:self];
}

- (void)applicationWillTerminate:(NSNotification*)notification
{
    [self saveState];
}

#pragma mark - Preferences

+ (void)setupDefaults
{
    NSString *userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
    NSDictionary *userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
    NSArray *resettableUserDefaultsKeys = @[ kExitWhenDonePreferenceKey ];
    NSDictionary *initialValuesDict = [userDefaultsValuesDict dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
}

@end
