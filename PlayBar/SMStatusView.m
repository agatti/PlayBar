//
//  SMStatusView.m
//  PlayBar
//
//  Created by Stuart Moore on 8/12/12.
//  Copyright (c) 2012-2013 Stuart Moore. This file is part of PlayBar.

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
//

#import "SMStatusView.h"

#import <AVFoundation/AVFoundation.h>

@interface SMStatusView ()

- (NSArray *)urlsFromDragOperation:(id <NSDraggingInfo>)sender;

@end

@implementation SMStatusView

@synthesize isHighlighted;

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self registerForDraggedTypes:@[NSFilenamesPboardType,
                NSURLPboardType,
                NSStringPboardType]];
    }

    return self;
}

#pragma mark - Drag & Drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    for (NSURL *url in [self urlsFromDragOperation:sender]) {
        if (![AVURLAsset URLAssetWithURL:url options:nil].playable)
            return NSDragOperationNone;
    }

    [self highlight:YES];
    return NSDragOperationCopy;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    [self highlight:NO];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    [self highlight:NO];

    NSArray *fileURLs = [self urlsFromDragOperation:sender];
    for (NSURL *url in [self urlsFromDragOperation:sender]) {
        [self.delegate addURL:url];
    }

    return fileURLs.count > 0;
}

- (NSArray *)urlsFromDragOperation:(id <NSDraggingInfo>)sender {
    NSMutableArray *urls = [NSMutableArray new];

    for (NSPasteboardItem *item in sender.draggingPasteboard.pasteboardItems) {
        if ([item.types containsObject:@"public.url"]) {
            [urls addObject:[NSURL URLWithString:[item stringForType:@"public.url"]]];
            continue;
        }

        if ([item.types containsObject:@"public.file-url"]) {
            [urls addObject:[NSURL URLWithString:[item stringForType:@"public.file-url"]]];
            continue;
        }

        if ([item.types containsObject:@"public.utf8-plain-text"]) {
            [urls addObject:[NSURL URLWithString:[item stringForType:@"public.utf8-plain-text"]]];
            continue;
        }
    }

    return urls;
}

#pragma mark - Click, Control Click, & Alt Click

- (void)mouseDown:(NSEvent *)event {
    if (event.modifierFlags & NSControlKeyMask)
        [self rightMouseDown:nil];
    else if (event.modifierFlags & NSAlternateKeyMask)
        [self otherMouseDown:nil];
    else
        [self highlight:[self.delegate togglePopover]];
}

- (void)mouseUp:(NSEvent *)event {
    if (event.modifierFlags & NSAlternateKeyMask)
        [self otherMouseUp:nil];
}

#pragma mark - Right Click

- (void)rightMouseDown:(NSEvent *)event {
    if (isHighlighted)
        [self.delegate togglePopover];

    [self.statusItem.menu setDelegate:self];
    [self.statusItem popUpStatusItemMenu:self.statusItem.menu];
}

- (void)menuWillOpen:(NSMenu *)menu {
    [self highlight:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    [self highlight:NO];
    [self.statusItem.menu setDelegate:nil];
}

#pragma mark - Middle Click

- (void)otherMouseDown:(NSEvent *)event {
    if (event.buttonNumber == 2 || event == nil) {
        [self.delegate togglePlayPause:nil];

        if (isHighlighted)
            [self.delegate togglePopover];

        [self highlight:YES];
    }
}

- (void)otherMouseUp:(NSEvent *)theEvent {
    [self highlight:NO];
}

#pragma mark - Draw

- (void)highlight:(BOOL)_isHightlighted {
    isHighlighted = _isHightlighted;
    [self setNeedsDisplay:YES];
}

- (void)setImage:(NSImage *)image {
    _image = image;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
    [self.statusItem drawStatusBarBackgroundInRect:self.bounds withHighlight:isHighlighted];

    NSImage *image = isHighlighted ? [NSImage imageNamed:@"statusBarIcon-click"] : self.image;
    [image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
}

@end
