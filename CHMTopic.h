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
// $Revision: 1.2 $
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHMTopic : NSObject <NSCopying> {
    NSString *_name;
    NSURL *_location;
    NSMutableArray<CHMTopic*> *_subTopics;
}

- (instancetype)initWithName:(NSString *)topicName location:(nullable NSURL *)topicLocation;

@property (copy) NSString *name;
@property (nullable, strong) NSURL *location;
@property (readonly) NSInteger countOfSubTopics;
- (nullable CHMTopic *)objectInSubTopicsAtIndex:(NSInteger)index;

- (void)addObject:(CHMTopic *)topic;
- (void)insertObject:(CHMTopic *)topic inSubTopicsAtIndex:(NSInteger)index;
- (void)removeObjectFromSubTopicsAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
