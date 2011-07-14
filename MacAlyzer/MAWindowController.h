/*
 * Copyright (c) 2011 Joshua Piccari, All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *
 *	This product includes software developed by Joshua Piccari
 *
 * 4. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>


@class MADocumentController;
@class PCAPController;
@class MACaptureStats;
@class SidebarController;
@class MASplitView;
@class MASourceList;
@class MAPacketView;
@class MAHexView;
@class MACapture;


@interface MAWindowController : NSWindowController
<NSWindowDelegate,NSSplitViewDelegate,NSOutlineViewDelegate> {
@private
	MADocumentController *_docController;
	PCAPController *_pcapController;
	
	id _currentlySelectedItem;
	NSIndexPath *_currentSelection;
	NSMutableDictionary *_sidebarGroups;
	NSMutableArray *_sidebarContents;
	
	BOOL _willSelectNewRecent;
	
	IBOutlet NSTextField *_statusLabel;
	
	IBOutlet NSArrayController *_packetController;
	IBOutlet NSTreeController *_sidebarItemController;
	
	IBOutlet MASplitView *_sidebarSplitView;
	IBOutlet MASplitView *_mainSplitView;
	
	IBOutlet MASourceList *_sidebarView;
	IBOutlet MAPacketView *_packetView;
	IBOutlet NSOutlineView *_detailsView;
	IBOutlet MAHexView	*_hexView;
}


- (IBAction)toggleCapture:(id)sender;
- (IBAction)closeCapture:(id)sender;

- (void)updatePacketStats;


@property (readwrite, copy) NSIndexPath *currentSelection;
@property (readonly) NSMutableArray *sidebarContents;
@property (readonly) NSArrayController *packetController;
@property (readonly) id currentlySelectedItem;

@end
