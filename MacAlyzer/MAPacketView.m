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

#import "MAPacketView.h"


@interface MAPacketView (__PRIVATE__)
- (void)tableViewDidScroll:(NSNotification *)notification;
@end

@implementation MAPacketView

- (void)awakeFromNib
{
	id clipView = [[self enclosingScrollView] contentView];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(tableViewDidScroll:)
												 name:NSViewBoundsDidChangeNotification
											   object:clipView];
}

- (void)keyDown:(NSEvent *)theEvent
{
	unichar key = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	uint flags = [theEvent modifierFlags] & 0xff;
	
	if(key == NSDeleteCharacter && flags == 0)
	{
		if([self selectedRow] != -1)
		{
			[_arrayController
			 removeObjectsAtArrangedObjectIndexes:[self selectedRowIndexes]];
		}
	}
	else
		[super keyDown:theEvent];
}

- (void)tableViewDidScroll:(NSNotification *)notification
{
	NSScrollView *scrollView = [notification object];
	CGFloat currentPosition = NSMaxY([scrollView visibleRect]);
	CGFloat tableViewHeight = [self bounds].size.height;
	
	_isScrolledToBottom = (currentPosition > tableViewHeight-[self rowHeight]);
}

#pragma mark -
#pragma mark Accessors

@synthesize isScrolledToBottom		= _isScrolledToBottom;

@end
