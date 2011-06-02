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

#import "MACapture.h"

#import <pcap/pcap.h>

#import "MAWindowController.h"
#import "MAPacket.h"


@implementation MACapture

- (id)init
{
	if(![super init])
		return nil;
	
	return self;
}

- (void)dealloc
{
	[_buffer release];
	[_packets release];
	[_deviceUUID release];
	[super dealloc];
}

#pragma mark -
#pragma mark NSDocument methods

- (void)makeWindowControllers
{
	/* Only create a new window, if we don't have one yet. */
	if([[self windowControllers] count] == 0)
	{
		MAWindowController *winController = [MAWindowController new];
		[self addWindowController:winController];
	}
}

- (BOOL)writeToURL:(NSURL *)absoluteURL
			ofType:(NSString *)typeName
			 error:(NSError **)outError
{
	return NO;
}

- (BOOL)readFromURL:(NSURL *)absoluteURL
			 ofType:(NSString *)typeName
			  error:(NSError **)outError
{
	return NO;
}

#pragma mark -
#pragma mark KVC for buffer (_buffer)

- (NSUInteger)countOfBuffer
{
	return [_buffer count];
}

- (NSEnumerator *)enumeratorOfBuffer
{
	return [_buffer objectEnumerator];
}

- (MAPacket *)memberOfBuffer:(MAPacket *)object
{
	return [_buffer member:object];
}

- (void)addBufferObject:(MAPacket *)object
{
	[_buffer addObject:object];
	[self willChangeValueForKey:@"packetsCaptured"];
	[self willChangeValueForKey:@"bytesCaptured"];
	_packetsCaptured++;
	_bytesCaptured += ((struct pcap_pkthdr *)[object header])->caplen;
	[self didChangeValueForKey:@"bytesCaptured"];
	[self didChangeValueForKey:@"packetsCaptured"];
}

- (void)removeBuffer:(NSSet *)objects
{
	[_buffer minusSet:objects];
}

- (void)intersectBuffer:(NSSet *)objects
{
	[_buffer intersectSet:objects];
}

#pragma mark -
#pragma mark KVC for packets (_packets)

- (NSUInteger)countOfPackets
{
	return [_packets count];
}

- (id)objectInPacketsAtIndex:(NSUInteger)index
{
	return [_packets objectAtIndex:index];
}

- (void)insertObject:(MAPacket *)object inPacketsAtIndex:(NSUInteger)index
{
	[_packets insertObject:object atIndex:index];
}

- (void)insertPackets:(NSArray *)packets atIndexes:(NSIndexSet *)indexes
{
	[_packets insertObjects:packets atIndexes:indexes];
}

- (void)removeObjectFromPacketsAtIndex:(NSUInteger)index
{
	[_packets removeObjectAtIndex:index];
}

#pragma mark -
#pragma mark Accessors

@synthesize deviceType				= _deviceType;
@synthesize deviceUUID				= _deviceUUID;
@synthesize bytesCaptured			= _bytesCaptured;
@synthesize packetsCaptured			= _packetsCaptured;
@synthesize buffer					= _buffer;
@synthesize packets					= _packets;

@end
