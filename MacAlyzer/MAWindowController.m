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

#import "MAWindowController.h"

#import <objc/message.h>

#import "ConfigurationConstants.h"

#import "MADocumentController.h"
#import "PCAPController.h"
#import "MASplitView.h"
#import "MASourceList.h"
#import "MAPacketView.h"
#import "MAHexView.h"
#import "MATreeNode.h"
#import "MACapture.h"
#import "MACaptureDevice.h"
#import "MAPacket.h"


@interface MAWindowController (__PRIVATE__)

- (void)newRecentCapture:(NSNotification *)notification;
- (void)newPacketsDidArrive:(NSNotification *)notification;
- (void)populateSidebar;
- (void)populateDevices;
- (void)populateRecent;
- (void)pcapReady:(NSNotification *)notification;
- (void)addGroup:(NSString *)groupName;
- (void)addChild:(id)object
	  withParent:(MATreeNode *)parent
	 atIndexPath:(NSIndexPath *)indexPath;
- (void)addChild:(id)object
	  withParent:(MATreeNode *)parent
	selectParent:(BOOL)yn;
- (void)selectParentFromSelection;
- (void)removeChildrenOfParent:(NSTreeNode *)parent;

@end


@implementation MAWindowController

- (id)init
{
	return [self initWithWindowNibName:MACaptureWindowNibName];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self name:MANewPacketNotificationKey object:nil];
	[_sidebarGroups release];
	[_sidebarContents release];
	[super dealloc];
}

- (void)awakeFromNib
{
	_sidebarGroups = [NSMutableDictionary new];
	_sidebarContents = [NSMutableArray new];
	
	_docController = [MADocumentController sharedDocumentController];
	_pcapController = [PCAPController sharedPCAPController];
	
	[[_statusLabel cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[_hexView bind:@"hexData" toObject:_packetController
	   withKeyPath:@"selection.data" options:nil];
	
	[[self window] setTitle:MAWindowTitle];
	[self populateSidebar];
	
	[[NSNotificationCenter defaultCenter]
	  addObserver:self
		 selector:@selector(newRecentCapture:)
			 name:MARecentCapNotificationKey
		   object:_docController];
	
	[[NSNotificationCenter defaultCenter]
	  addObserver:self
		 selector:@selector(newPacketsDidArrive:)
			 name:MANewPacketNotificationKey
		   object:nil];
}

#pragma mark - NSWindowController Override methods

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
	return [NSString stringWithFormat:@"%@ — MacAlyzer", displayName];
}

#pragma mark - Toolbar Action methods

- (IBAction)toggleCapture:(id)sender
{
	id object = self.currentlySelectedItem;
	if(object == nil || ![object isKindOfClass:[MACaptureDevice class]])
		return;
	
	[_docController toggleCaptureDevice:object];
}

#pragma mark - Nil-Targeted Action methods

- (IBAction)closeCapture:(id)sender
{
	/* XXX Needs lots of polish. */
	MACapture *doc = [self document];
	NSWindow *window = [self window];
	
	[doc removeWindowController:self];
	[doc close];
	
	[window setTitle:MAWindowTitle];
	[[window standardWindowButton:NSWindowDocumentIconButton] setImage:nil];
	
	[self updatePacketStats];
	[_sidebarItemController setSelectionIndexPath:nil];
	_currentSelection = nil;
	_currentlySelectedItem = nil;
}

- (IBAction)toggleSidebar:(id)sender
{
	[_sidebarSplitView animateSubview:[_sidebarView enclosingScrollView]];
}

- (IBAction)togglePacketDump:(id)sender
{
	[_mainSplitView animateSubview:[_hexView enclosingScrollView]];
}

#pragma mark - General Notification methods

- (void)newRecentCapture:(NSNotification *)notification
{
	NSURL *newURL = [[notification userInfo] objectForKey:@"URL"];
	NSIndexPath *parentIndexPath = [NSIndexPath indexPathWithIndex:1];
	NSIndexPath *childIndexpath = [parentIndexPath indexPathByAddingIndex:0];
	NSTreeNode *nodeToMove = nil;
	
	for(NSTreeNode *node in [[[_sidebarItemController arrangedObjects]
							 descendantNodeAtIndexPath:parentIndexPath]
							 childNodes])
	{
		if([[[node representedObject] object] isEqual:newURL])
		{
			nodeToMove = node;
			break;
		}
	}
	
	if(nodeToMove == nil)
	{
		if(_willSelectNewRecent)
		{
			if(self.currentSelection == nil)
				self.currentSelection = childIndexpath;
			
			else
			{
				self.currentSelection =
				[parentIndexPath indexPathByAddingIndex:
				 [self.currentSelection indexAtPosition:1]+1];
			}
			[_sidebarItemController
			 setSelectionIndexPath:self.currentSelection];
		}
		
		[self addChild:newURL
			withParent:[_sidebarGroups objectForKey:MARecentCapturesKey]
		   atIndexPath:childIndexpath];
	}
	else
	{
		/* Select the already created node. */
		if(_willSelectNewRecent)
		{
			self.currentSelection = [nodeToMove indexPath];
			[_sidebarItemController
			 setSelectionIndexPath:self.currentSelection];
		}
	}
	
	_willSelectNewRecent = NO;
}

- (void)newPacketsDidArrive:(NSNotification *)notification
{
	MACapture *capture = [notification object];
	
	if(capture != [self document])
	{
		NSDictionary *userInfo = [notification userInfo];
		NSNumber *newPackets = [userInfo objectForKey:MANewPacketCountKey];
		
		NSTreeNode *devices = [[[_sidebarItemController arrangedObjects]
								childNodes] objectAtIndex:0];
		
		for(NSTreeNode *item in [devices childNodes])
		{
			MATreeNode *node = [item representedObject];
			if([[node uuid] isEqual:[capture deviceUUID]])
			{
				[node addToBadgeCount:[newPackets unsignedIntegerValue]];
				[_sidebarView reloadItem:item];
				break;
			}
		}
	}
}

#pragma mark - NSSplitView Delegates

- (BOOL)splitView:(NSSplitView *)splitView
shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
	return YES;
}

- (BOOL)splitView:(NSSplitView *)sv shouldAdjustSizeOfSubview:(NSView *)v
{
	/* Allow adjustment of right pane of sidebarSplitView. */
	if([sv isEqual:_sidebarSplitView] && ![_sidebarView isDescendantOf:v])
		return YES;
	
	/* Allow adjustment of key view in mainSplitView. */
	if([sv isEqual:_mainSplitView])
	{
		id key = [[self window] firstResponder];
		if([key isKindOfClass:[NSView class]])
			return [key isDescendantOf:v];
	}
	
	return NO;
}

- (CGFloat)splitView:(NSSplitView *)sv
constrainMinCoordinate:(CGFloat)proposedMin
		 ofSubviewAt:(NSInteger)offset
{
	/* Constrain the sidebar to a minimum width. */
	if(sv == _sidebarSplitView && offset == 0)
		return MASidebarMinWidth;
	
	/* Constrain the top pane to a minimum height. */
	if(sv == _mainSplitView && offset == 0)
		return MAPacketViewMinWidth;
	
	/* All others can have any size they want. */
	return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)sv
constrainMaxCoordinate:(CGFloat)proposedMax
		 ofSubviewAt:(NSInteger)offset
{
	/* Constrain the sidebar to a maximum width. */
	if([sv isEqual:_sidebarSplitView] && offset == 0)
		return MASidebarMaxWidth;
	
	/* All others can have any size they want. */
	return proposedMax;
}

#pragma mark - NSOutlineView Delegate methods

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	/* Restore our preserved selection. */
	[_sidebarItemController setSelectionIndexPath:self.currentSelection];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	id selectedArray = [_sidebarItemController selectedNodes];
	if([selectedArray count] == 0)
		return;
	
	id selectedItem = [selectedArray objectAtIndex:0];
	id selectedNode = [selectedItem representedObject];
	id selectedObject = [selectedNode object];
	
	/* Preserve our selection, but only if we selected a non-group node. */
	if(![selectedNode isGroup])
	{
		NSURL *documentURL;
		
		[_packetView scrollPoint:NSZeroPoint];
		
		/* If we are opening a file use its NSURL. */
		if([selectedObject isKindOfClass:[NSURL class]])
			documentURL = selectedObject;
		
		/* If we are opening a device create an NSURL for it. */
		else
		{
			[selectedNode setBadgeCount:0];
			[_sidebarView reloadItem:selectedItem];
			
			documentURL = [NSURL URLWithString:
						   [NSString stringWithFormat:@"device:///dev/%@",
							[selectedObject deviceName]]];
		}
			
		[_docController openDocumentWithContentsOfURL:documentURL
											  display:YES
												error:nil];
		self.currentSelection = [selectedItem indexPath];
		_currentlySelectedItem = selectedObject;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
	if([item representedObject] == [_sidebarGroups
									objectForKey:MAInterfacesKey] &&
	   ![[PCAPController sharedPCAPController] createPCAPHelper])
	{
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
			selector:@selector(pcapReady:)
				name:MAPCAPReadyNotificationKey
			  object:nil];
		return NO;
	}
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
	return [[item representedObject] isGroup];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if(![[item representedObject] isGroup])
		return YES;
	
	return NO;
}

#pragma mark - Sidebar Populate methods

- (void)populateSidebar
{
	[_sidebarItemController setSelectsInsertedObjects:NO];
	
	[self addGroup:MAInterfacesKey];
	if(_pcapController.deviceList != nil)
		[self populateDevices];
	
	[self addGroup:MARecentCapturesKey];
	[self populateRecent];
	
	/* Remove any preconceived selection. */
	[self setCurrentSelection:nil];
	[_sidebarItemController setSelectionIndexPath:nil];
	
	/* Expand recent list. */
	id recentNode = [[[_sidebarItemController arrangedObjects] childNodes]
					 objectAtIndex:1];
	[_sidebarView expandItem:recentNode];
}

- (void)populateDevices
{
	NSDictionary *devices = _pcapController.deviceList;
	
	for(NSString *key in
		[[devices allKeys]
		 sortedArrayUsingSelector:@selector(localizedCompare:)])
	{
		MACaptureDevice *device = [devices objectForKey:key];
		[self addChild:device
			withParent:[_sidebarGroups objectForKey:MAInterfacesKey]
		  selectParent:NO];
	}
	
	/* XXX Maybe make this a bit less static? */
	[_sidebarView expandItem:[[[_sidebarItemController arrangedObjects]
							   childNodes] objectAtIndex:0]];
}

- (void)populateRecent
{
	NSArray *files = [_docController recentDocumentURLs];
	
	if([files count] > 0)
	{
		for(NSURL *url in files)
		{
			[self addChild:url
				withParent:[_sidebarGroups objectForKey:MARecentCapturesKey]
			  selectParent:NO];
		}
	}
}

- (void)pcapReady:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter]
	  removeObserver:self
				name:MAPCAPReadyNotificationKey
			  object:nil];
	[self populateDevices];
}

- (void)addGroup:(NSString *)groupName
{
	NSIndexPath *indexPath = [NSIndexPath
							  indexPathWithIndex:[_sidebarContents count]];
	MATreeNode *node = [[MATreeNode alloc] initGroup];
	
	[_sidebarGroups setObject:node forKey:groupName];
	
	[node setTitle:groupName];
	[_sidebarItemController insertObject:node
			   atArrangedObjectIndexPath:indexPath];
	
	[node release];
}

- (void)addChild:(id)object
	  withParent:(MATreeNode *)parent
	 atIndexPath:(NSIndexPath *)indexPath
{
	MATreeNode *node = [[MATreeNode alloc] initLeaf];
	
	[node setObject:object];
	
	if([object isKindOfClass:[MACaptureDevice class]])
	{
		[node setTitle:[object deviceName]];
		[node setImage:[_docController.imageStore
						objectForKey:MAImageInterfaceKey]];
	}
	else if([object isKindOfClass:[NSURL class]])
	{
		[node setTitle:[object lastPathComponent]];
		[node setImage:[_docController.imageStore
						objectForKey:MAImageRecentSaveFileKey]];
	}
	
	[_sidebarItemController insertObject:node
			   atArrangedObjectIndexPath:indexPath];
	
	[node release];
}

- (void)addChild:(id)object
	  withParent:(MATreeNode *)parent
	selectParent:(BOOL)yn
{
	NSIndexPath *indexPath;
	
	if(parent == nil)
		return;
	
	/* Select our parent class. */
	indexPath = [[NSIndexPath alloc]
				 initWithIndex:[_sidebarContents indexOfObject:parent]];
	
	[self addChild:object
		withParent:parent
	   atIndexPath:[indexPath indexPathByAddingIndex:[[parent children]
													  count]]];
	
	[indexPath release];
	
	if(yn)
		[self selectParentFromSelection];
}

- (void)selectParentFromSelection
{
	if([[_sidebarItemController selectedObjects] count] > 0)
	{
		NSTreeNode *firstNode = [[_sidebarItemController selectedNodes]
								 objectAtIndex:0];
		NSTreeNode *parentNode = [firstNode parentNode];
		if(parentNode)
		{
			NSIndexPath *parentIndex = [parentNode indexPath];
			[_sidebarItemController setSelectionIndexPath:parentIndex];
		}
		else
		{
			NSArray *selectionPaths = [_sidebarItemController
									   selectionIndexPaths];
			[_sidebarItemController removeSelectionIndexPaths:selectionPaths];
		}
	}
}

- (void)removeChildrenOfParent:(NSTreeNode *)parent
{
	NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
	
	for(NSTreeNode *child in [parent childNodes])
		[indexPaths addObject:[child indexPath]];
	
	[_sidebarItemController removeObjectsAtArrangedObjectIndexPaths:indexPaths];
	[indexPaths release];
}

#pragma mark - Validation methods

- (SEL)canSelectorForAction:(SEL)action
{
	NSString *actionString = NSStringFromSelector(action);
	NSString *actionStringFirst = [actionString substringToIndex:1];
	NSString *actionStringBody = [actionString substringWithRange:
								  NSMakeRange(1, [actionString length] - 2)];
    
    NSString *canString =
	[[@"can" stringByAppendingString:[actionStringFirst uppercaseString]]
	 stringByAppendingString:actionStringBody];
    
    return NSSelectorFromString(canString);
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL itemAction = [menuItem action];
	
	if(itemAction == @selector(toggleSidebar:))
	{
		if([_sidebarSplitView isSubviewCollapsed:
			[_sidebarView enclosingScrollView]])
			[menuItem setTitle:MAShowSidebarText];
		else
			[menuItem setTitle:MAHideSidebarText];
	}
	else if(itemAction == @selector(togglePacketDump:))
	{
		if([_mainSplitView isSubviewCollapsed:[_hexView enclosingScrollView]])
			[menuItem setTitle:MAShowPacketDumpText];
		else
			[menuItem setTitle:MAHidePacketDumpText];
	}
	
	if(itemAction != Nil)
	{
		if([self respondsToSelector:itemAction])
		{
			SEL canAction = [self canSelectorForAction:itemAction];
			
			if(canAction != nil && [self respondsToSelector:canAction])
				return (BOOL)objc_msgSend(self, canAction);
		}
	}
	
	return YES;
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	if([[theItem itemIdentifier] isEqualToString:MAToolbarStartKey])
	{
		NSDictionary *images = _docController.imageStore;
		id object = self.currentlySelectedItem;
		if([object isKindOfClass:[MACaptureDevice class]])
		{
			if(![object isCapturing])
			{
				[theItem setImage:[images objectForKey:MAImageToolbarStartKey]];
				[theItem setLabel:MAToolbarCaptureStart];
			}
			else
			{
				[theItem setImage:[images objectForKey:MAImageToolbarPauseKey]];
				[theItem setLabel:MAToolbarCapturePause];
			}
			return YES;
		}
		[theItem setImage:[images objectForKey:MAImageToolbarStartKey]];
		[theItem setLabel:MAToolbarCaptureStart];
	}
	
	return NO;
}

#pragma mark - Misc Private methods

- (void)updatePacketStats
{
	NSString *temp;
	MACapture *capture = [self document];
	
	if(capture)
	{
		float floatSize = capture.bytesCaptured;
		NSUInteger packetCount = capture.packetsCaptured;
		
		/* Bytes */
		if(floatSize < 1024)
			temp = [[NSString alloc] initWithFormat:@"%lu packets, %lu bytes",
					packetCount, (NSUInteger)floatSize];
		
		/* Kibibytes */
		else if(floatSize < 1048576)
			temp = [[NSString alloc] initWithFormat:@"%lu packets, %1.1f KiB",
					packetCount, floatSize/1024];
		
		/* Mebibytes */
		else if(floatSize < 1073741824)
			temp = [[NSString alloc] initWithFormat:@"%lu packets, %1.1f MiB",
					packetCount, floatSize/1048576];
		
		/* Gibibytes */
		else if(floatSize < 1099511627776)
			temp = [[NSString alloc] initWithFormat:@"%lu packets, %1.1f GiB",
					packetCount, floatSize/1073741824];
		
		/* Tebibytes or larger (hope we don't have to use this code) */
		else
			temp = [[NSString alloc] initWithFormat:@"%lu packets, %1.1f TiB",
					packetCount, floatSize/1099511627776];
	}
	else
		temp = [[NSString alloc] initWithString:@"0 packets, 0 bytes"];
	
	[_statusLabel setStringValue:temp];
	[temp release];
}

#pragma mark - Accessors

@synthesize packetController			= _packetController;
@synthesize sidebarContents				= _sidebarContents;
@synthesize currentSelection			= _currentSelection;
@synthesize currentlySelectedItem		= _currentlySelectedItem;

@end
