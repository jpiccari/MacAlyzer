/*
 * Copyright (c) 2012 Joshua Piccari, All rights reserved.
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

#import "PCAPController.h"
#import "MAWindowController.h"
#import "MACaptureDevice.h"
#import "MASavePanel.h"
#import "MAPacket.h"
#import "MACapture.h"
#import "MAString.h"


@interface MADocumentController (__PRIVATE__)

- (void)windowWillClose:(NSNotification *)notification;

@end

@implementation MADocumentController

- (id)init
{
	if(!(self =[super init]))
		return nil;
	
	[NSApp setDelegate:self];
	[[PCAPController sharedPCAPController] setDelegate:self];
	
	_windowStore = [NSMutableSet new];
	_documentsWithUpdates = [NSMutableSet new];
	_deviceDocuments = [NSMutableDictionary new];
	
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
	
	[[NSNotificationCenter defaultCenter]
	  addObserver:self
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

#pragma mark - Nil-targeted actions

- (IBAction)newWindow:(id)sender
{
	MAWindowController *winController = [MAWindowController new];
	[winController showWindow:self];
	
	[_windowStore addObject:winController];
	[winController release];
}

#pragma mark - Misc

- (void)addPacket:(MAPacket *)packet
{
	[[_deviceDocuments objectForKey:[packet deviceUUID]]
	 addBufferObject:packet];
}

- (void)toggleCaptureDevice:(MACaptureDevice *)device
{
	/* Start device. */
	if(![device isCapturing])
	{
		_timerCount++;
		/* XXX Temporary options. */
		[device setReadDelay:200];
		[device setMaxPacketSize:65535];
		[device setPromiscuousMode:YES];
		
		[device startCapture];
	}
	
	/* Stop device. */
	else
	{
		if(_timerCount > 0)
			_timerCount--;
		[device stopCapture];
	}
	
	if(!_deviceTimer && _timerCount > 0)
	{
		_deviceTimer =
		[NSTimer scheduledTimerWithTimeInterval:MACaptureUpdateInterval
										 target:self
									   selector:@selector(updateCaptures:)
									   userInfo:nil
										repeats:YES];
	}
	else if(_timerCount == 0 && _deviceTimer)
	{
		[_deviceTimer invalidate];
		_deviceTimer = nil;
		
		/* Set a temp timer to catch any late arriving packets. */
		[NSTimer scheduledTimerWithTimeInterval:MACaptureUpdateInterval
										 target:self
									   selector:@selector(updateCaptures:)
									   userInfo:nil
										repeats:NO];
	}
}

- (void)updateCaptures:(NSTimer	*)timer
{
	NSArray *sortDescriptors;
	
	if([_deviceDocuments count] > 0)
	{
		sortDescriptors =
		[NSArray arrayWithObject:[NSSortDescriptor
								  sortDescriptorWithKey:@"number"
								  ascending:YES]];
		
		for(MACapture *doc in [_deviceDocuments objectEnumerator])
			[doc updatePacketsWithSortDescriptors:sortDescriptors];
	}
	if([_documentsWithUpdates count] > 0)
	{
		sortDescriptors =
		[NSArray arrayWithObject:[NSSortDescriptor
								  sortDescriptorWithKey:@"number"
											  ascending:YES]];
		
		for(MACapture *doc in _documentsWithUpdates)
			[doc updatePacketsWithSortDescriptors:sortDescriptors];
		
		[_documentsWithUpdates removeAllObjects];
	}
	
	/* If this is a timer for a file, invalidate it. */
	if(_fileTimer != nil && [timer isEqual:_fileTimer])
	{
		[_fileTimer invalidate];
		_fileTimer = nil;
	}
}

- (void)requestFileTimerUpdate:(id)sender
{
	if(sender == nil)
		return;
	
	[_documentsWithUpdates addObject:sender];
	
	if(_fileTimer == nil)
	{
		_fileTimer =
		[NSTimer scheduledTimerWithTimeInterval:MASaveFileUpdateInterval
										 target:self
									   selector:@selector(updateCaptures:)
									   userInfo:nil
										repeats:NO];
	}
}

#pragma mark - NSDocumentController Override methods

- (id)openDocumentWithContentsOfURL:(NSURL *)absoluteURL
							display:(BOOL)displayDocument
							  error:(NSError **)outError
{
	for(NSDocument *doc in [self documents])
	{
		if([[doc fileURL] isEqual:absoluteURL])
		{
			[doc makeWindowControllers];
			[doc showWindows];
			return doc;
		}
	}
	
	return [super openDocumentWithContentsOfURL:absoluteURL
										display:displayDocument
										  error:outError];
}

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel
					  forTypes:(NSArray *)extensions
{
	/* Get main window or create it. */
	if([_windowStore count] == 0)
		[self newWindow:self];
	
	return [openPanel runSheetModalForWindow:[NSApp mainWindow]];
}

- (NSString *)typeForContentsOfURL:(NSURL *)inAbsoluteURL
							 error:(NSError **)outError
{
	if([[inAbsoluteURL scheme] isEqualToString:@"device"])
		return MADocumentTypePCAPDevice;
	
	return [super typeForContentsOfURL:inAbsoluteURL error:outError];
}

#pragma mark - Notification methods

- (void)windowWillClose:(NSNotification *)notification
{
	id windowController = [[notification object] windowController];
	if([windowController isKindOfClass:[NSWindowController class]])
		[_windowStore removeObject:windowController];
}

#pragma mark - Application Delegate methods

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	/* Don't open a new document, but create a new window. */
	[self newWindow:self];
	return NO;
}

#pragma mark - Accessors

@synthesize imageStore				= _imageStore;
@synthesize deviceDocuments			= _deviceDocuments;

@end
