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
// $Revision: 1.3 $
//

#import <Foundation/Foundation.h>

struct chmFile;

NS_ASSUME_NONNULL_BEGIN

@interface CHMContainer : NSObject {
    NSString *_uniqueId;
    
    NSString *_path;
    NSString *_title;
    NSString *_homePath;
    NSString *_tocPath;
    NSString *_indexPath;
}

+ (nullable instancetype)containerWithContentsOfFile:(NSString *)path;

- (nullable instancetype)initWithContentsOfFile:(NSString *)path;

- (BOOL)hasObjectWithPath: (NSString *)path;
- (nullable NSData *)dataWithContentsOfObject: (nullable NSString *)objectPath;
- (nullable NSString *)stringWithContentsOfObject: (nullable NSString *)objectPath;
@property (readonly, copy, nullable) NSData *dataWithTableOfContents;

- (BOOL)loadMetadata;
- (void)computeIdFrom:(NSData *)systemData;
- (void)readWindowsDataFrom:(NSData *)windowsData readStringsDataFrom:(NSData *)stringsData;
- (void)readSystemDataFrom:(NSData *)systemData;

- (NSString *)findHomeForPath: (NSString *)basePath;

@property (nullable, readonly, copy) NSString *title;
@property (readonly, copy) NSString *uniqueId;
@property (nullable, readonly, copy) NSString *tocPath;
@property (nullable, readonly, copy) NSString *homePath;
@property (readonly, copy) NSString *path;

@end

NS_ASSUME_NONNULL_END
