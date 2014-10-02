//
//  SMStatusView.h
//  PlayBar
//
//  Created by Stuart Moore on 8/12/12.
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
//

#import <Cocoa/Cocoa.h>

@protocol SMAppDelegateDelegate

@required

- (BOOL)addURL:(NSURL *)url;
- (BOOL)togglePopover;
- (IBAction)togglePlayPause:(id)sender;

@end

@interface SMStatusView : NSView <NSMenuDelegate, NSDraggingDestination>

@property (nonatomic, weak) id<SMAppDelegateDelegate> delegate;
@property (nonatomic, weak) NSStatusItem *statusItem;
@property (nonatomic, weak) NSImage *image;

@property (nonatomic) BOOL isHighlighted;

- (void)highlight:(BOOL)_isHightlighted;

@end
