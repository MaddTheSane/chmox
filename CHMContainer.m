//
// Chmox a CHM file viewer for Mac OS X
// Copyright (c) 2004 Stéphane Boisson.
//
// Chmox is free software; you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
//
// Chmox is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with Foobar; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
// $Revision: 1.8 $
//

#include <CommonCrypto/CommonDigest.h>
#import "CHMContainer.h"
#include <CHM/chm_lib.h>

@implementation CHMContainer {
    struct chm_file *_handle;
    fd_reader_ctx readerCtx;
}

#pragma mark Factory

+ (id)containerWithContentsOfFile:(NSString *)chmFilePath
{
    return [[CHMContainer alloc] initWithContentsOfFile:chmFilePath];
}


#pragma mark Lifecycle

- (id)initWithContentsOfFile:(NSString *)chmFilePath
{
    return self = [self initWithContentsOfURL:[NSURL fileURLWithPath:chmFilePath]];
}

- (id)initWithContentsOfURL:(NSURL *)chmFileURL
{
    if( self = [super init] ) {
        if (!fd_reader_init(&readerCtx, [chmFileURL fileSystemRepresentation])) {
            return nil;
        }
        _handle = calloc(1, sizeof(*_handle));
        if (!chm_parse(_handle, fd_reader, &readerCtx)) {
            return nil;
        }
        //_handle = chm_open( [chmFilePath fileSystemRepresentation] );
        //if( !_handle ) {
        //    return nil;
        //}
        
        _url = [chmFileURL copy];
        
        _uniqueId = nil;
        _title = nil;
        _homePath = nil;
        _tocPath = nil;
        _indexPath = nil;
        
        [self loadMetadata];
    }
    
    return self;
}


- (void) dealloc
{
    //NSLog(@"deallocating %@",self);

    if (_handle) {
        chm_close( _handle );
        free(_handle);
    }

    fd_reader_close(&readerCtx);
}


#pragma mark Accessors
@synthesize homePath = _homePath;
@synthesize title = _title;
@synthesize uniqueId = _uniqueId;
@synthesize tocPath = _tocPath;
@synthesize url = _url;

- (NSString *)path
{
    return [_url path];
}

#pragma mark Basic CHM reading operations

static inline unsigned short readShort( NSData *data, off_t offset ) {
    NSRange valueRange = { offset, 2 };
    unsigned short value;
    
    [data getBytes:(void *)&value range:valueRange];
    return CFSwapInt16LittleToHost( value );
}

static inline unsigned int readLong( NSData *data, off_t offset ) {
    NSRange valueRange = { offset, 4 };
    unsigned int value;
    
    [data getBytes:(void *)&value range:valueRange];
    return CFSwapInt32LittleToHost( value );
}

static inline NSString * readString( NSData *data, unsigned long offset ) {
    const char *stringData = (const char *)[data bytes] + offset;
    return @(stringData);
}

static inline NSString * readTrimmedString( NSData *data, unsigned long offset ) {
    const char *stringData = (const char *)[data bytes] + offset;
    return [@(stringData) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark CHM Object loading

typedef NS_ENUM(int, CHMResolveStatus) {
    CHM_RESOLVE_SUCCESS,
    CHM_RESOLVE_FAILURE
};

static CHMResolveStatus chm_resolve_object(chm_file *handle, const char* path, chm_entry *info)
{
    for (int i = 0; i < handle->n_entries; i++) {
        if (strcmp(handle->entries[i]->path, path) == 0) {
            *info = *handle->entries[i];
            return CHM_RESOLVE_SUCCESS;
        }
    }

    return CHM_RESOLVE_FAILURE;
}

- (BOOL)hasObjectWithPath: (NSString *)path
{
    chm_entry info;
    if( chm_resolve_object( _handle, [path UTF8String], &info ) != CHM_RESOLVE_SUCCESS ) {
        return NO;
    }

    return YES;
}

- (NSData *)dataWithContentsOfObject: (NSString *)path
{
    //NSLog( @"dataWithContentsOfObject: %@", path );
    if( !path ) {
		return nil;
    }
    
    if( [path hasPrefix:@"/"] ) {
		// Quick fix
		if( [path hasPrefix:@"///"] ) {
			path = [path substringFromIndex:2];
		}
    }
    else {
		path = [NSString stringWithFormat:@"/%@", path];
    }
    
    chm_entry info;
    if( chm_resolve_object( _handle, [path UTF8String], &info ) != CHM_RESOLVE_SUCCESS ) {
        //NSLog( @"Unable to find %@", path );
        return nil;
    }
    
    //DEBUG_OUTPUT( @"Found object %@ (%qu bytes)", path, (long long)info.length );
    
    void *buffer = malloc( info.length );
    
    if( !buffer ) {
		// Allocation failed
		//NSLog( @"Failed to allocate %qu bytes for %@", (long long)info.length, path );
		return nil;
    }
    
    if( !chm_retrieve_entry( _handle, &info, buffer, 0, info.length ) ) {
		//NSLog( @"Failed to load %qu bytes for %@", (long long)info.length, path );
		free( buffer );
		return nil;
    }
    
    return [NSData dataWithBytesNoCopy:buffer length:info.length];
}

- (NSString *)stringWithContentsOfObject: (NSString *)objectPath
{
    NSData *data = [self dataWithContentsOfObject:objectPath];
    if( data ) {
		// NSUTF8StringEncoding / NSISOLatin1StringEncoding / NSUnicodeStringEncoding
		return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

- (NSData *)dataWithTableOfContents
{
    return [self dataWithContentsOfObject:_tocPath];
}


#pragma mark CHM setup

- (BOOL)loadMetadata {
	BOOL success = NO;
    //--- Start with WINDOWS object ---
    NSData *windowsData = [self dataWithContentsOfObject:@"/#WINDOWS"];
    NSData *stringsData = [self dataWithContentsOfObject:@"/#STRINGS"];
    if( windowsData && stringsData ) {
		[self readWindowsDataFrom:windowsData readStringsDataFrom:stringsData];
    }
    
    //--- Use SYSTEM object ---
    NSData *systemData = [self dataWithContentsOfObject:@"/#SYSTEM"];
    if( systemData != nil ) {
		[self readSystemDataFrom: systemData];
		//--- Compute unique id ---
		[self computeIdFrom:systemData];
		
		// Check for empty string titles
		if ([_title length] == 0) {
			_title = nil;
		}
		
		// Check for lack of index page
		if (!_homePath) {
			_homePath = [self findHomeForPath:@"/"];
			//NSLog( @"Implicit home: %@", _homePath );
		}
		
		success = YES;
    }
    
    return success;
}

//This is a helper method for loadMetadata
- (void)computeIdFrom:(NSData *)systemData
{
	unsigned char digest[ CC_SHA1_DIGEST_LENGTH ];
	CC_SHA1( [systemData bytes], (CC_LONG)[systemData length], digest );
	unsigned int *ptr = (unsigned int *) digest;
	_uniqueId = [[NSString alloc] initWithFormat:@"%x%x%x%x%x", ptr[0], ptr[1], ptr[2], ptr[3], ptr[4]];
	//NSLog( @"UniqueId=%@", _uniqueId );
	
}

//This is a helper method for loadMetadata
- (void)readWindowsDataFrom:(NSData *)windowsData readStringsDataFrom:(NSData *)stringsData
{
	const unsigned int entryCount = readLong( windowsData, 0 );
	const unsigned int entrySize = readLong( windowsData, 4 );
	//NSLog( @"Entries: %u x %u bytes", entryCount, entrySize );
	
	for( int entryIndex = 0; entryIndex < entryCount; ++entryIndex ) {
		unsigned long entryOffset = 8 + ( entryIndex * entrySize );
		
		if( !_title || ( [_title length] == 0 ) ) { 
			_title = readTrimmedString( stringsData, readLong( windowsData, entryOffset + 0x14 ) );
			//NSLog( @"Title: %@", _title );
		}
		
		if( !_tocPath || ( [_tocPath length] == 0 ) ) { 
			_tocPath = readString( stringsData, readLong( windowsData, entryOffset + 0x60 ) );
			//NSLog( @"Table of contents: %@", _tocPath );
		}
		
		if( !_indexPath || ( [_indexPath length] == 0 ) ) { 
			_indexPath = readString( stringsData, readLong( windowsData, entryOffset + 0x64 ) );
			//NSLog( @"Index: %@", _indexPath );
		}
		
		if( !_homePath || ( [_homePath length] == 0 ) ) { 
			_homePath = readString( stringsData, readLong( windowsData, entryOffset + 0x68 ) );
			//NSLog( @"Home: %@", _homePath );
		}
	}
	
}

//This is a helper method for loadMetadata
- (void)readSystemDataFrom:(NSData *)systemData
{
    NSUInteger maxOffset = [systemData length];
    for( NSUInteger offset = 0; offset < maxOffset; offset += readShort( systemData, offset + 2 ) + 4 ) {
		switch( readShort( systemData, offset ) ) {
			case 0:// Table of contents file
				if( !_tocPath || ( [_tocPath length] == 0 ) ) {
					_tocPath = readString( systemData, offset + 4 );
					//NSLog( @"SYSTEM Table of contents: %@", _tocPath );
				}
				break;
			case 1:// Index file
				if( !_indexPath || ( [_indexPath length] == 0 ) ) {
					_indexPath = readString( systemData, offset + 4 );
					//NSLog( @"SYSTEM Index: %@", _indexPath );
				}
				break;
			case 2:// Home page
				if( !_homePath || ( [_homePath length] == 0 ) ) {
					_homePath = readString( systemData, offset + 4 );
					//NSLog( @"SYSTEM Home: %@", _homePath );
				}
				break;
			case 3:// Title
				if( !_title || ( [_title length] == 0 ) ) {
					_title = readTrimmedString( systemData, offset + 4 );
					//NSLog( @"SYSTEM Title: %@", _title );
				}
				break;
			case 6:// Compiled file
				NSLog( @"SYSTEM compiled file: %@", readString( systemData, offset + 4 ) );
				break;
			case 9:// Compiler
				NSLog( @"SYSTEM Compiler: %@", readString( systemData, offset + 4 ) );
				break;
			case 16:// Default font
				NSLog( @"SYSTEM Default font: %@", readString( systemData, offset + 4 ) );
				break;
			default:// Other data not handled
				break;
		}
    }
	
}

- (NSString *)findHomeForPath: (NSString *)basePath
{
    NSString *testPath;
    
    NSString *separator = [basePath hasSuffix:@"/"]? @"" : @"/";
    testPath = [NSString stringWithFormat:@"%@%@index.htm", basePath, separator];
    if( [self hasObjectWithPath:testPath] ) {
        return testPath;
    }

    testPath = [NSString stringWithFormat:@"%@%@default.html", basePath, separator];
    if( [self hasObjectWithPath:testPath] ) {
        return testPath;
    }

    testPath = [NSString stringWithFormat:@"%@%@default.htm", basePath, separator];
    if( [self hasObjectWithPath:testPath] ) {
        return testPath;
    }

    return [NSString stringWithFormat:@"%@%@index.html", basePath, separator];
}


- (BOOL)setupFromSystemObject {
    
    return YES;
}

@end
