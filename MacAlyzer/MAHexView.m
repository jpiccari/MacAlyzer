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


#import "MAHexView.h"


@interface MAHexView (__PRIVATE__)

- (void)fixColumnWidths;

@end

@implementation MAHexView

+ (void)initialize
{
	[self exposeBinding:@"hexData"];
}

- (void)awakeFromNib
{
	[self setDataSource:self];
	[self setDelegate:self];
	
	stringAttributes = [[NSMutableDictionary alloc] init];
	[stringAttributes setObject:[NSFont userFixedPitchFontOfSize:0.0]
						 forKey:NSFontAttributeName];
	
	/* Get the width of our glyphs. */
	glyphSize = [@"0" sizeWithAttributes:stringAttributes].width;
	
	/* Set the width of our address column. */
	[addressColumn setWidth:glyphSize*7.0];
	
	[self setAutoresizingMask:NSViewWidthSizable];
	[self fixColumnWidths];
}

- (Class)valueClassForBinding:(NSString *)binding
{
	if([binding isEqual:@"hexData"])
		return [NSData class];
	
	return nil;
}

- (void)fixColumnWidths
{
	/* Fix column widths. */
	CGFloat new_width = ([[self enclosingScrollView] contentSize].width -
						 [addressColumn width]-9)/3;
	
	[hexColumn setWidth:new_width*2.0];
	[asciiColumn setWidth:new_width*1.0];
	
	[self reloadData];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
	[self fixColumnWidths];
}

- (void)dealloc
{
	[hexData release];
	[stringAttributes release];
	[super dealloc];
}

#pragma mark - Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if(![hexData length])
		return 0;
	
	if(glyphSize == 0)
		[self awakeFromNib];
	
	return ([hexData length]/[self numberOfBytesPerRow])+
	([hexData length]%[self numberOfBytesPerRow] == 0 ? 0 : 1);
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
			row:(NSInteger)row
{
	/* Fill address column. */
	if([tableColumn isEqual:addressColumn])
	{
		NSAttributedString *addr =
		[[NSAttributedString alloc]
		 initWithString:[NSString stringWithFormat:@"0x%04x",
						 [self numberOfBytesPerRow]*row]
		 attributes:stringAttributes];

		return [addr autorelease];
	}
	
	/* Fill hex column. */
	if([tableColumn isEqual:hexColumn])
	{
		int bpr = [self numberOfBytesPerRow];
		NSRange range;
		NSRange temp;
		
		range.location = (row == 0 ? 0 : row*bpr);
		range.length = MIN(bpr, [hexData length]-range.location);
		
		NSMutableAttributedString *str =
		[[NSMutableAttributedString alloc]
				initWithString:[[hexData subdataWithRange:range] MAstringFromHexBytes]
				attributes:stringAttributes];
		
		temp = [self convertRange:range];
			
		if(temp.length > 0)
		{
			temp.location *= 3;
			temp.length = (temp.length*3)-1;
			
			[self setSelectedStyleOnString:str inRange:temp];
		}
		
		return [str autorelease];
	}
	
	/* Fill ascii column. */
	if([tableColumn isEqual:asciiColumn])
	{
		int bpr = [self numberOfBytesPerRow];
		NSRange range;
		NSRange temp;
		
		range.location = (row == 0 ? 0 : row*bpr);
		range.length = MIN(bpr, [hexData length]-range.location);
		
		NSMutableAttributedString *str =
		[[NSMutableAttributedString alloc]
				initWithString:[[hexData subdataWithRange:range] MAstringFromRawASCII]
				attributes:stringAttributes];
		
		temp = [self convertRange:range];
		
		if(temp.length > 0)
			[self setSelectedStyleOnString:str inRange:temp];
		
		return [str autorelease];
	}
	
	return nil;
}

#pragma mark - Help functions

- (uint)numberOfBytesPerRow
{
	uint width = [hexColumn width]/glyphSize;
	uint words = width/((MADATA_WORD_SIZE*2)+1)*MADATA_WORD_SIZE;
	
	return words-(words % MADATA_WORD_SIZE);
}

- (NSRange)convertRange:(NSRange)range
{
	if(selectedBytes.length > 0)
	{
		NSRange temp = selectedBytes;
		
		if(temp.location+temp.length < range.location)
			temp.length = 0;
		else if(temp.location < range.location)
		{
			temp.length -= range.location-temp.location;
			temp.location = range.location;
		}
		
		if(temp.location+temp.length > range.location+range.length)
		{
			if(temp.location >= range.location && range.length >= (temp.location-range.location))
				temp.length = range.length-(temp.location-range.location);
			else
				temp.length = 0;
		}
		
		temp.location -= range.location;
		return temp;
	}
	
	return (NSRange){ NSNotFound, 0 };
}

- (void)setSelectedStyleOnString:(NSMutableAttributedString *)str
						 inRange:(NSRange)range
{
	[str addAttribute:NSForegroundColorAttributeName
				value:[NSColor alternateSelectedControlTextColor]
				range:range];
	[str addAttribute:NSBackgroundColorAttributeName
				value:[NSColor alternateSelectedControlColor]
				range:range];
}

#pragma mark - Accessors

- (NSData *)hexData
{
	return hexData;
}

- (void)setHexData:(NSData *)newData
{
	[newData retain];
	[hexData release];
	hexData = newData;
	[self reloadData];
}


- (NSRange)selectedBytes
{
	return selectedBytes;
}

- (void)setSelectedBytes:(NSRange)range
{
	selectedBytes = range;
	[self reloadData];
}

- (void)setDelegate:(id<NSTableViewDelegate>)delegate
{
	/* Don't let others set our delegate. */
}

#pragma mark - Delegate methods

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	return NO;
}

@end
