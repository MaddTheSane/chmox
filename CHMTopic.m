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
// $Revision: 1.4 $
//

#import "CHMTopic.h"

@implementation CHMTopic
@synthesize name = _name;
@synthesize location = _location;

#pragma mark Lifecycle

- (id)initWithName:(NSString *)topicName location:(NSURL *)topicLocation
{
	if (self = [super init]) {
		_name = [topicName copy];
		_location = topicLocation;
		_subTopics = nil;
	}

	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	CHMTopic *other = [[CHMTopic alloc] initWithName:_name location:_location];

	if (_subTopics) {
		other->_subTopics = [_subTopics mutableCopy];
	}

	return other;
}

#pragma mark Accessors

- (NSString *)description
{
	return [NSString stringWithFormat:@"<CHMTopic:'%@',%@>", _name, _location];
}

- (NSInteger)countOfSubTopics
{
	return _subTopics ? [_subTopics count] : 0;
}

- (CHMTopic *)objectInSubTopicsAtIndex:(NSInteger)theIndex
{
	return _subTopics ? [_subTopics objectAtIndex:theIndex] : nil;
}

#pragma mark Mutators

- (void)addObject:(CHMTopic *)topic
{
	if (!_subTopics) {
		_subTopics = [[NSMutableArray alloc] init];
	}

	[_subTopics addObject:topic];
}

- (void)insertObject:(CHMTopic *)topic inSubTopicsAtIndex:(NSInteger)theIndex
{
	if (!_subTopics) {
		_subTopics = [[NSMutableArray alloc] init];
	}

	[_subTopics insertObject:topic atIndex:theIndex];
}

- (void)removeObjectFromSubTopicsAtIndex:(NSInteger)theIndex
{
	if (_subTopics) {
		[_subTopics removeObjectAtIndex:theIndex];
	}
}

@end
