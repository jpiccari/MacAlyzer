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

#import "MATreeNode.h"


#import "MAString.h"
#import "MACaptureDevice.h"


@interface MATreeNode ()

- (void)setLeaf:(BOOL)flag;

@end


@implementation MATreeNode

- (id)init
{
	if(![super init])
		return nil;
	
	[self setTitle:@"Untitled TreeNode"];
	[self setChildren:[NSArray array]];
	[self setLeaf:NO];
	[self setIsGroup:NO];
	[self setIsCollapsible:YES];
	
	return self;
}

- (id)initLeaf
{
	if(![self init])
		return nil;
	
	[self setLeaf:YES];
	
	return self;
}

- (id)initGroup
{
	if(![self init])
		return nil;
	
	[self setIsGroup:YES];
	
	return self;
}

- (void)dealloc
{
	[_object release];
	[_title release];
	[_image release];
	[_children release];
	[super dealloc];
}

- (void)addToBadgeCount:(NSInteger)count
{
	_badgeCount += count;
}

#pragma mark - Node Information

- (BOOL)hasImage
{
	return (_image != nil);
}

- (BOOL)hasBadge
{
	return (_badgeCount > 0);
}

#pragma mark - Accessors

- (void)setLeaf:(BOOL)flag
{
	_isLeaf = flag;
	if(_isLeaf)
		[self setChildren:nil];
	else
		[self setChildren:[NSArray array]];
}

- (void)setObject:(id)object
{
	if(object == _object)
		return;
	
	if([object isKindOfClass:[MACaptureDevice class]])
	{
		_uuid = [[object uuid] copy];
	}
	else if([object isKindOfClass:[NSURL class]])
	{
		_uuid = [[[object absoluteString] md5] retain];
	}
	
	[_object release];
	_object = [object retain];
}

- (id)object
{
	return _object;
}

@synthesize title			= _title;
@synthesize image			= _image;
@synthesize badgeCount		= _badgeCount;
@synthesize uuid			= _uuid;
@synthesize children		= _children;

@synthesize isLeaf			= _isLeaf;
@synthesize isGroup			= _isGroup;
@synthesize isCollapsible	= _isCollapsible;

@end
