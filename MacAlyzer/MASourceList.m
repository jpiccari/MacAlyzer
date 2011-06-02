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

#import "MASourceList.h"
#import "MATreeNode.h"


#define MAGroupMinX			7.0
#define MADisclosureWidth	5.0

#define MARowMarginRight	5.0
#define MARowMarginLeft		0.0

#define MAImageWidth		16.0
#define MAImageHeight		16.0
#define MAImageSpacing		2.0

#define MABadgeMargin		5.0
#define MABadgeMinWidth		22.0
#define MABadgeHeight		14.0


/* Private methods. */
@interface MASourceList ()

- (CGFloat)badgeWidthForRow:(NSInteger)row;
- (void)drawBadgeForRow:(NSInteger)row inRect:(NSRect)frame;

@end


@implementation MASourceList

static NSFont *MABadgeTextFont = nil;
static NSColor *MABadgeTextSelectedColor = nil;
static NSColor *MABadgeTextSelectedUnfocusedColor = nil;
static NSColor *MABadgeTextSelectedHiddenColor = nil;
static NSColor *MABadgeBackgroundColor = nil;
static NSColor *MABadgeBackgroundHiddenColor = nil;

- (void)awakeFromNib
{
	if(MABadgeTextFont == nil)
		MABadgeTextFont = [[[NSFontManager sharedFontManager] convertFont:
						   [NSFont userFontOfSize:11] toHaveTrait:NSBoldFontMask] retain];
	if(MABadgeTextSelectedColor == nil)
		MABadgeTextSelectedColor = [[NSColor keyboardFocusIndicatorColor] retain];
	if(MABadgeTextSelectedUnfocusedColor == nil)
		MABadgeTextSelectedUnfocusedColor = [[NSColor
											 colorWithCalibratedRed:(153/255.0)
											 green:(169/255.0)
											 blue:(203/255.0)
											 alpha:1] retain];
	if(MABadgeTextSelectedHiddenColor == nil)
		MABadgeTextSelectedHiddenColor = [[NSColor
										  colorWithCalibratedWhite:(170/255.0)
										  alpha:1] retain];
	if(MABadgeBackgroundColor == nil)
		MABadgeBackgroundColor = [[NSColor colorWithCalibratedRed:(152/255.0)
														   green:(169/255.0)
															blue:(199/255.0)
														   alpha:1] retain];
	if(MABadgeBackgroundHiddenColor == nil)
		MABadgeBackgroundHiddenColor = [[NSColor colorWithDeviceWhite:(180/255.0)
															   alpha:1] retain];
	
	[super awakeFromNib];
}

#pragma mark - Generic Overrides

- (NSTableViewSelectionHighlightStyle)selectionHighlightStyle
{
	return NSTableViewSelectionHighlightStyleSourceList;
}

/*
 * Here we won't exactly "refuse" First Responder, we simply suggest
 * an alternate First Responder...
 */
- (BOOL)becomeFirstResponder
{
	[[self window] makeFirstResponder:[[self window] initialFirstResponder]];
	return YES;
}

#pragma mark - Cell Layout

- (NSRect)frameOfOutlineCellAtRow:(NSInteger)row
{
	if(![[[self itemAtRow:row] representedObject] isCollapsible])
		return NSZeroRect;
	
	return [super frameOfOutlineCellAtRow:row];
}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{
	id item = [[self itemAtRow:row] representedObject];
	
	NSCell *cell = [self preparedCellAtColumn:column row:row];
	NSSize cellSize = [cell cellSize];
	NSRect cellFrame = [super frameOfCellAtColumn:column row:row];
	NSRect rowFrame = [self rectOfRow:row];
	
	if([item isGroup])
	{
		CGFloat x = NSMinX(cellFrame);
		if(![item isCollapsible])
			x = MAGroupMinX;
		
		return NSMakeRect(x,
						  NSMidY(cellFrame)-(cellSize.height/2.0),
						  NSWidth(rowFrame)-x,
						  cellSize.height);
	}
	else
	{
		CGFloat indentLeft = [self indentationPerLevel]*[self levelForRow:row]
							+MADisclosureWidth;
		CGFloat indentRight = [self badgeWidthForRow:row]+MARowMarginRight;
		
		if([item hasImage])
			indentLeft += MAImageWidth+(MAImageSpacing*2);
		
		return NSMakeRect(indentLeft,
						  NSMidY(rowFrame)-(cellSize.height/2.0),
						  NSWidth(rowFrame)-indentRight-indentLeft,
						  cellSize.height);
	}
}

/* Determine how wide our badge will be. */
- (CGFloat)badgeWidthForRow:(NSInteger)row
{
	id item = [[self itemAtRow:row] representedObject];
	
	if(![item hasBadge])
		return 0.0;
	
	NSString *count = [NSString stringWithFormat:@"%u", [item badgeCount]];
	NSSize stringSize = [count sizeWithAttributes:
						 [NSDictionary dictionaryWithObject:MABadgeTextFont
													 forKey:NSFontAttributeName]];
	
	CGFloat width = stringSize.width+(MABadgeMargin*2);
	if(width < MABadgeMinWidth)
		width = MABadgeMinWidth;
	
	return width;
}

#pragma mark - Drawing

- (void)drawRow:(NSInteger)row clipRect:(NSRect)clipRect
{
	[super drawRow:row clipRect:clipRect];
	
	id item = [[self itemAtRow:row] representedObject];
	
	/* Draw any image associated with the item. */
	if(![item isGroup] && [item hasImage])
	{
		NSRect cellFrame = [self frameOfCellAtColumn:0 row:row];
		NSSize imageSize = NSMakeSize(MAImageWidth, MAImageHeight);
		NSRect imageFrame = NSMakeRect(NSMinX(cellFrame)-imageSize.width-MAImageSpacing,
									   NSMidY(cellFrame)-(imageSize.width/2.0f),
									   imageSize.width, imageSize.height);
		
		NSImage *image = [item image];
		NSSize imageActualSize = [image size];
		if(imageActualSize.width < imageSize.width ||
		   imageActualSize.height < imageSize.height)
		{
			imageFrame = NSMakeRect(NSMidX(imageFrame)-(imageActualSize.width/2.0f),
									NSMidY(imageFrame)-(imageActualSize.height/2.0f),
									imageActualSize.width, imageActualSize.height);
		}
		
		[image setFlipped:YES];
		[image drawInRect:imageFrame fromRect:NSZeroRect
				operation:NSCompositeSourceOver fraction:1];
	}
	
	/* Draw unread badge associated with item. */
	if([item hasBadge])
	{
		NSRect rowFrame = [self rectOfRow:row];
		NSSize badgeSize = NSMakeSize([self badgeWidthForRow:row], MABadgeHeight);
		NSRect badgeFrame =
			NSMakeRect(NSMaxX(rowFrame)-badgeSize.width-MARowMarginRight,
					   NSMidY(rowFrame)-(badgeSize.height/2.0),
					   badgeSize.width, badgeSize.height);
		
		[self drawBadgeForRow:row inRect:badgeFrame];
	}
}

- (void)drawBadgeForRow:(NSInteger)row inRect:(NSRect)frame
{
	id item = [[self itemAtRow:row] representedObject];
	
	NSBezierPath *bezierPath = [NSBezierPath
								bezierPathWithRoundedRect:frame
								xRadius:(MABadgeHeight/2.0)
								yRadius:(MABadgeHeight/2.0)];
	
	BOOL isVisible = [[NSApp mainWindow] isVisible];
	BOOL isFirstResponder = [[[self window] firstResponder] isEqual:self];
	
	NSDictionary *attr;
	NSColor *bgColor;
	NSColor *textColor;
	
	if([[self selectedRowIndexes] containsIndex:row])
	{
		bgColor = [NSColor whiteColor];
		
		if(isVisible && isFirstResponder)
			textColor = MABadgeTextSelectedColor;
		else if(isVisible && !isFirstResponder)
			textColor = MABadgeTextSelectedUnfocusedColor;
		else
			textColor = MABadgeTextSelectedHiddenColor;
	}
	else
	{
		textColor = [NSColor whiteColor];
		
		if(isVisible)
			bgColor = MABadgeBackgroundColor;
		else
			bgColor = MABadgeBackgroundHiddenColor;
	}
	
	[bgColor set];
	[bezierPath fill];
	
	attr = [NSDictionary dictionaryWithObjectsAndKeys:
			textColor, NSForegroundColorAttributeName,
			MABadgeTextFont, NSFontAttributeName, nil];
	NSAttributedString *text = [[NSAttributedString alloc]
								initWithString:[NSString stringWithFormat:@"%u",
												[item badgeCount]] attributes:attr];
	
	NSSize textSize = [text size];
	NSPoint textPoint = NSMakePoint(NSMidX(frame)-(textSize.width/2.0),
									NSMidY(frame)-(textSize.height/2.0));
	
	[text drawAtPoint:textPoint];
	
	[text release];
}

@end
