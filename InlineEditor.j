/*
 * InlineEditor.j
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
 
@import <AppKit/CPTextField.j>


@implementation InlineEditor : CPTextField
{
    BOOL    _inlineEditable @accessors(property=inlineEditable);
    id      _editTarget     @accessors(property=editTarget);
    SEL     _editAction     @accessors(property=editAction);
}

- (void)mouseDown:(CPEvent)anEvent
{
    [[self superview] mouseDown:anEvent];
    
    if(_inlineEditable && [anEvent clickCount] > 1)
    {
        [self setEditable:YES];
        [self setBordered:YES];
        [self setBezeled:YES];
        [self setBezelStyle:CPTextFieldSquareBezel];
        
        [super mouseDown:anEvent];
        
        [[self window] makeFirstResponder:self];
        
        // FIXME: Breaks Safari?
        // [self selectText:self];
    }
}

- (BOOL)resignFirstResponder
{
    [self setEditable:NO];
    [self setBordered:NO];
    [self setBezeled:NO];
    
    if([_editTarget respondsToSelector:_editAction])
        objj_msgSend(_editTarget, _editAction, self);
    
    return [super resignFirstResponder];
}

@end
