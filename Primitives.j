/*
 * Primitives.j
 * CPlist Editor
 *
 * Created by Nicholas Small.
 * Copyright 2009, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <Foundation/CPNumber.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>


@implementation CPString (CastingHelpers)

- (CPNumber)numberValue
{
    return [CPNumber numberWithString:self];
}

- (CPBoolean)booleanValue
{
    return [CPBoolean booleanWithString:self];
}

@end

@implementation CPNumber (CastingHelpers)

+ (CPNumber)numberWithString:(CPString)aString
{
    return [[CPNumber alloc] initWithString:aString];
}

- (CPNumber)initWithString:(CPString)aString
{
    var number = [aString doubleValue];
    
    if(number)
        return [CPNumber numberWithDouble:number];
    else
        return [CPNumber numberWithDouble:0];
}

- (CPBoolean)booleanValue
{
    return [CPBoolean booleanWithNumber:self];
}

@end

@implementation CPBoolean : CPObject
{
    BOOL    _bool;
}

+ (CPBoolean)booleanWithBoolean:(BOOL)aBool
{
    return [[CPBoolean alloc] initWithBoolean:aBool];
}

+ (CPBoolean)booleanWithNumber:(CPNumber)aNumber
{
    return [[CPBoolean alloc] initWithNumber:aNumber];
}

+ (CPBoolean)booleanWithString:(CPString)aString
{
    return [[CPBoolean alloc] initWithString:aString];
}

- (CPBoolean)init
{
    self = [super init];
    
    if(self)
        _bool = false;
    
    return self;
}

- (CPBoolean)initWithBoolean:(BOOL)aBool
{
    self = [self init];
    
    if(self)
        _bool = aBool;
    
    return self;
}

- (CPBoolean)initWithNumber:(CPNumber)aNumber
{
    self = [self init];
    
    if(self)
        _bool = (aNumber < 1) ? false : true;
    
    return self;
}

- (CPBoolean)initWithString:(CPString)aString
{
    self = [self init];
    
    if(self)
        _bool = ([aString lowercaseString] == @"true") ? true : false;
    
    return self;
}

- (id)value
{
    return [self boolValue];
}

- (BOOL)boolValue
{
    return _bool;
}

- (CPNumber)numberValue
{
    return _bool ? [CPNumber numberWithInt:1] : [CPNumber numberWithInt:0]
}

- (CPString)stringValue
{
    return _bool ? [CPString stringWithString:@"true"] : [CPString stringWithString:@"false"]
}

@end