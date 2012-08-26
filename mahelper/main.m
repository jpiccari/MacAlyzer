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

#import "MAPCAPHelper.h"

#import "ConfigurationConstants.h"


int
main(int argc, const char **argv)
{
	if(argc == 0)
		return EXIT_FAILURE;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	MAPCAPHelper *pcap = [[MAPCAPHelper alloc] init];
	NSConnection *conn = [NSConnection new];
	NSString *controllerKey = [[NSString alloc] initWithUTF8String:argv[1]];
	
	[pcap setPipeName:(char *)argv[2]];
	[pcap setControllerKey:controllerKey];
	
	[conn setRootObject:pcap];
	if([conn registerName:[pcap pcapHelperKey]])
		[pcap startRunLoop];
	else
		NSLog(@"Couldn't register for connection name: %@", [pcap pcapHelperKey]);
	
	[controllerKey release];
	[conn release];
	[pcap release];
	[pool drain];
	
	return EXIT_SUCCESS;
}