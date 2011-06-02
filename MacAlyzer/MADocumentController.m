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

#import "MADocumentController.h"

#import "ConfigurationConstants.h"

#import "MAWindowController.h"
#import "MASavePanel.h"


@interface MADocumentController (__PRIVATE__)

- (void)windowWillClose:(NSNotification *)notification;

@end

@implementation MADocumentController

- (id)init
{
	if(![super init])
		return nil;
	
	[NSApp setDelegate:self];
	_windowStore = [NSMutableSet new];
	
	/* XXX Need to figure this one out... */
	//interfaceImage = [NSImage imageNamed:NSImageNameNetwork];
	NSImage *interfaceImage = [NSImage imageNamed:@"network"];
	[interfaceImage setSize:NSMakeSize(16, 16)];
	
	NSImage *savefileImage = [[NSWorkspace sharedWorkspace] iconForFileType:
							  NSFileTypeForHFSTypeCode(kRecentItemsIcon)];
	[savefileImage setSize:NSMakeSize(16, 16)];
	
	_imageStore = [[NSDictionary alloc] initWithObjectsAndKeys:
				   interfaceImage, MAImageInterfaceKey,
				   savefileImage, MAImageRecentSaveFileKey,
				   [NSImage imageNamed:@"Start"], MAImageToolbarStartKey,
				   [NSImage imageNamed:@"Pause"], MAImageToolbarPauseKey, nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(windowWillClose:)
												 name:NSWindowWillCloseNotification
											   object:nil];
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_windowStore release];
	[_imageStore release];
	[super dealloc];
}

- (IBAction)newWindow:(id)sender
{
	MAWindowController *winController = [MAWindowController new];
	[winController showWindow:self];
	
	[_windowStore addObject:[winController window]];
}

#pragma mark - NSDocumentController overrides

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel
					  forTypes:(NSArray *)extensions
{
	/* Get main window or create it. */
	if([_windowStore count] == 0)
		[self newWindow:self];
	
	return [openPanel runSheetModalForWindow:[NSApp mainWindow]];
}

#pragma mark - Notification methods

- (void)windowWillClose:(NSNotification *)notification
{
	[_windowStore removeObject:[notification object]];
}

#pragma mark - Application Delegate methods

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	/* Don't open a new document, but create a new window. */
	[self newWindow:self];
	return NO;
}

#pragma mark - Accessors

@synthesize imageStore			= _imageStore;

@end
