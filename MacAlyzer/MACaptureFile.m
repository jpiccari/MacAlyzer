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

#import "MACaptureFile.h"

#import "ConfigurationConstants.h"
#import "MAPacket.h"
#import "MAString.h"


/*
 * Bounce our callback to an Objective-C method.
 */
void
ma_local_pcap_callback(u_char *obj, const struct pcap_pkthdr *hdr,
					   const u_char *data)
{
	[(id)obj sendPacketData:data withHeader:hdr];
}

@implementation MACaptureFile

- (id)initWithFile:(NSURL *)filename
{
	if(![self init])
		return nil;
	
	_fileURL = [filename copy];
	
	/* Generate UUID for device. */
	_uuid = [[[_fileURL absoluteString] md5] copy];
	
	return self;
}

- (void)dealloc
{
	[_fileURL release];
	[_uuid release];
	[super dealloc];
}

#pragma mark -
#pragma mark File Processing


- (void)read
{
	/* Open a new PCAP session for our file. */
	if(!(_fileSession = pcap_open_offline([self.filePath UTF8String], _errbuf)))
		return;
	
	_packetId = 1;
	_fileDataLink = pcap_datalink(_fileSession);
	pcap_loop(_fileSession, -1, ma_local_pcap_callback, (voidPtr)self);
	
	/* Close our PCAP session since the file has ended. */
	pcap_close(_fileSession);
}

- (void)readFile:(NSURL *)filename
{
	[self setFileURL:filename];
	[self read];
}

- (void)sendPacketData:(const u_char *)data
			withHeader:(const struct pcap_pkthdr *)header
{
	if(![_delegate respondsToSelector:@selector(addPacket:)])
		return;
	
	__block MAPacket *newPacket = [[MAPacket alloc] initWithData:data
											  withHeader:header
												  withId:_packetId++
											  fromDevice:self];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[_delegate addPacket:newPacket];
		[newPacket release];
	});
}

#pragma mark -
#pragma mark Accessors

- (NSString *)deviceName
{
	return [self.fileURL absoluteString];
}

- (NSString *)fileName
{
	return [_fileURL lastPathComponent];
}

- (NSString *)filePath
{
	return [_fileURL path];
}

- (BOOL)fileExist
{
	return [[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
}

- (cap_device_t)deviceType
{
	return PCAP_SAVEFILE;
}

@synthesize uuid				= _uuid;
@synthesize fileURL				= _fileURL;
@synthesize dataLink			= _fileDataLink;
@synthesize delegate			= _delegate;

@end
