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

#import <Foundation/Foundation.h>
#import <pcap/pcap.h>

#import "MAProtocols.h"


#define readall(fd,buf,size)											\
	{																	\
		ssize_t req_size = size;										\
		ssize_t cur_size = 0;											\
		ssize_t temp;													\
		while(cur_size < req_size)										\
		{																\
			if((temp = read(fd, buf+cur_size, size-cur_size)) == -1)	\
			{															\
				switch(errno)											\
				{														\
					/* XXX error checking */							\
				}														\
			}															\
			cur_size += temp;											\
		}																\
	}


@class SFAuthorization;
@class SidebarController;
@class MACaptureFile;
@class MACaptureStats;


@interface PCAPController : NSObject <PCAPControllerProtocol> {
	SidebarController *_sidebarController;
	id _delegate;
	SFAuthorization *_auth;
	dispatch_queue_t _dispatchQueue;
	dispatch_source_t _dispatchSource;
	
	id _pcapProxy;
	int _pcapPipe;
	char *_pcapPipeName;
	NSString *_rootProxyKey;
	NSConnection *_conn;
	BOOL _isConnected;
	
	NSDictionary *_deviceList;
	
	MACaptureFile *_captureFile;
	char _errbuf[PCAP_ERRBUF_SIZE];
}

+ (id)sharedPCAPController;

- (BOOL)createPCAPHelper;
- (NSDictionary *)deviceList;
- (BOOL)openFile:(NSURL *)path;
- (NSString *)currentFile;
- (void)shutdown;

- (BOOL)setupDispatchQueue;
- (void)closeDispatchQueue;


@property (readwrite, assign) id delegate;
@property (readonly) BOOL isConnected;
@property (readonly) MACaptureFile *captureFile;
@property (readonly) NSDictionary *deviceList;

@end
