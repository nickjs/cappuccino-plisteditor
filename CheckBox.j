/*
 * CheckBox.j
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

@import <AppKit/CPButton.j>


var checkboxImage,
    checkboxAlternateImage,
    checkboxCheckedImage,
    checkboxCheckedAlternateImage;

@implementation CheckBox : CPButton
{
    BOOL    _isChecked;
}

+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:[self class]];
    
    checkboxImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CheckBox/CheckBox.png"] size:CGSizeMake(14.0, 15.0)],
    checkboxAlternateImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CheckBox/CheckBoxH.png"] size:CGSizeMake(14.0, 15.0)],
    checkboxCheckedImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Checkbox/CheckBoxChecked.png"] size:CGSizeMake(14.0, 15.0)],
    checkboxCheckedAlternateImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"CheckBox/CheckBoxCheckedH.png"] size:CGSizeMake(14.0, 15.0)];
}

- (id)initWithFrame:(CPRect)frame
{
    self = [super initWithFrame: frame];
    
    _isChecked = false;
    
    [self setTitle:@"_"];
    [self setBordered:NO];
    
    // FIXME: No!
    [_imageAndTitleView._titleField setLineBreakMode: CPLineBreakByWordWrapping];
    [self setImage: checkboxImage];
    [self setAlternateImage: checkboxAlternateImage];

    [self setImagePosition: CPImageLeft];
    [self setAlignment:CPLeftTextAlignment];
    
    return self;
}

- (void)mouseUp:(CPEvent)anEvent
{
    [super mouseUp: anEvent];
    
    [self setChecked: !_isChecked];
}

- (BOOL)isChecked
{
    return _isChecked;
}

- (void)setChecked:(BOOL)flag
{
    _isChecked = flag;
    
    if(_isChecked)
    {
        [self setImage: checkboxCheckedImage];
        [self setAlternateImage: checkboxCheckedAlternateImage];
    }
    else
    {
        [self setImage: checkboxImage];
        [self setAlternateImage: checkboxAlternateImage];
    }
}

@end