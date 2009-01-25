/*
 * AppController.j
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

@import <Foundation/CPObject.j>
@import <AppKit/CPView.j>
@import "CPTextView.j"

var AddToolbarItem      = @"AddToolbarItem",
    AddChildToolbarItem = @"AddChildToolbarItem",
    DeleteToolbarItem   = @"DeleteToolbarItem",
    UndoToolbarItem     = @"UndoToolbarItem",
    RedoToolbarItem     = @"RedoToolbarItem",
    FormatToolbarItem   = @"FormatToolbarItem",
    AddItemImage        = nil,
    AddChildItemImage   = nil;


@implementation AppController : CPObject
{
    CPView          _inputView;
    CPView          _editorView;
    CPTextView      _stringField;
    CPToolbar       _toolbar;
    CPTextField     _label;
    CPPopUpButton   _plistType;
    
    CPString        _plistString;
    id              _plist;
    CPArray         _plistArray;
}

+ (void)initialize
{
    AddItemImage = [[CPImage alloc] initWithContentsOfFile:@"Resources/AddItem.png" size:CGSizeMake(32.0, 32.0)];
    AddChildItemImage = [[CPImage alloc] initWithContentsOfFile:@"Resources/AddChildItem.png" size:CGSizeMake(32.0, 32.0)];
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        bounds = [contentView bounds];
    
    [theWindow orderFront:self];
    
    [CPMenu setMenuBarVisible:YES];
    [CPMenu setMenuBarIconImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/Icon.png" size:CGSizeMake(16.0, 16.0)]];
    
    _inputView = [[CPView alloc] initWithFrame:CGRectMakeCopy(bounds)];
    _editorView = [[CPView alloc] initWithFrame:CGRectMakeCopy(bounds)];
    [_inputView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_editorView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_editorView setHidden:YES];
    [_inputView setBackgroundColor:[CPColor redColor]];
    [_editorView setBackgroundColor:[CPColor greenColor]];
    [contentView addSubview:_inputView];
    [contentView addSubview:_editorView];
    
    
    // INPUT VIEW
    
    _label = [[CPTextField alloc] initWithFrame:CGRectMake(CGRectGetWidth(bounds)/2 - 200.0, 30.0, 400.0, 30.0)];
    [_label setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
    [_label setFont:[CPFont boldSystemFontOfSize:12.0]];
    [_inputView addSubview:_label];
    
    var stringScroll = [[CPScrollView alloc] initWithFrame:CGRectMake(CGRectGetWidth(bounds)/2 - 200.0, 60.0, 400.0, 250.0)];
    [stringScroll setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
    [stringScroll setAutohidesScrollers:YES];
    [_inputView addSubview:stringScroll];
    
    _stringField = [[CPTextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 250.0)];
    [stringScroll setDocumentView:_stringField];
    
    var submit = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(bounds)/2 + 100.0, 325.0, 100.0, 18.0)];
    [submit setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin];
    [submit setTarget:self];
    [submit setAction:@selector(submit:)];
    [submit setTitle:@"Submit"];
    [_inputView addSubview:submit];
    
    
    // EDITOR VIEW
    
    var _toolbar = [[CPToolbar alloc] initWithIdentifier:@"Toolbar"];
    [_toolbar setDelegate:self];
    // [_toolbar setVisible:NO];
    [theWindow setToolbar:_toolbar];
    
    var collectionScroll = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetMaxX(bounds), CGRectGetMaxY(bounds) - 88.0)];
    [collectionScroll setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [collectionScroll setAutohidesScrollers:YES];
    [_editorView addSubview:collectionScroll];
    
    _collection = [[CPCollectionView alloc] initWithFrame:CGRectMakeCopy([collectionScroll bounds])];
    [_collection setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_collection setAllowsMultipleSelection:NO];
    [_collection setMaxNumberOfColumns:1];
    [_collection setMinItemSize:CGSizeMake(100.0, 21.0)];
    [_collection setMaxItemSize:CGSizeMake(2000.0, 21.0)];
    [_collection setVerticalMargin:0.0];
    
    var itemPrototype = [[CPCollectionViewItem alloc] init],
        rowView = [[RowView alloc] initWithFrame:CGRectMakeZero()];
    [itemPrototype setView:rowView];
    [_collection setItemPrototype:itemPrototype];
    
    [collectionScroll setDocumentView:_collection];
    
    [self newDocument:self];
}

- (void)submit:(id)sender
{
    _plistString = [_stringField stringValue];
    
    if([_plistString length] == 0)
    {
        var root = [CPDictionary dictionary];
        _plistString = [[CPPropertyListSerialization dataFromPropertyList:root format:CPPropertyList280NorthFormat_v1_0 errorDescription:@""] string];
    }
    
    var data;
    if(_plistString)
        data = [CPData dataWithString:_plistString];
    
    if(data)
        _plist = [CPPropertyListSerialization propertyListFromData:data format:nil errorDescription:@""];
    else
        _plist = nil;
        
    if(_plist)
    {
        [CPMenu setMenuBarTitle:@"Plist From String"];
        
        _plistArray = [CPArray array];
        [self createRowWithObject:_plist key:@"Root" atIndex:0 keyEditable:NO];
        [_collection setContent:_plistArray];
        
        [_inputView setHidden:YES];
        [_editorView setHidden:NO];
        [_toolbar setVisible:YES];
    }
    else
    {
        [_label setStringValue:@"Plist is Invalid!"];
        [_label setTextColor:[CPColor redColor]];
    }
}

- (void)createRowWithObject:(id)anObject key:(CPString)key atIndex:(int)rowIndex keyEditable:(BOOL)editable
{
    var arrayIndex = [_plistArray count],
        className = [anObject class];
    
    _plistArray[arrayIndex] = [rowIndex, key, anObject, editable];
    
    if(className == CPDictionary)
    {
        var keys = [anObject allKeys];
        for(var i = 0; i < keys.length; i++)
            [self createRowWithObject:[anObject objectForKey:keys[i]] key:keys[i] atIndex:rowIndex + 1 keyEditable:YES];
    }
    else if(className == CPArray)
    {
        for(var i = 0; i < anObject.length; i++)
            [self createRowWithObject:anObject[i] key:@"Item " + i atIndex:rowIndex + 1 keyEditable:NO];
    }
}

- (void)resetUI
{
    [_toolbar setVisible:NO];
    
    // var bounds = 
    // [_inputView setFrame:CGRectMake(0.0, 0.0, )]
    
    [_inputView setHidden:NO];
    [_editorView setHidden:YES];
    [_collection setContent:nil];
    
    [_label setStringValue:@"Plist String (or blank):"];
    [_label setTextColor:[CPColor blackColor]];
    [_stringField setStringValue:@""];
    [_plistType selectItemAtIndex:2];
    
    [CPMenu setMenuBarTitle:@"CPlist Editor"];
}

- (void)newDocument:(id)sender
{
    [self resetUI];
}

- (void)openDocument:(id)sender
{
    [self newDocument:self];
    
    BPTool.Installer.show({}, function(){
        BrowserPlus.require({
            services: [{service: 'FileAccess', version: "1"},{service: 'FileBrowse'}]},
            function(res){
                if(res.success)
                {
                    BrowserPlus.FileBrowse.OpenBrowseDialog({},function(args){
                        if(args && args.value)
                            var file = args.value[0];
                        if(file)
                        {
                            BrowserPlus.FileAccess.Read({file:file},function(args){
                                [_stringField setStringValue:args.value];
                                // [self submit:self];
                            })
                        }
                    });
                }
            });
    });
}

- (void)saveDocument:(id)sender
{
    [self resetUI];
    
    var data = [CPPropertyListSerialization dataFromPropertyList:_plist format:CPPropertyList280NorthFormat_v1_0 errorDescription:@""];
    [_stringField setStringValue:[data string]];
}

- (void)addItem:(id)sender
{
    
}

- (void)addChild:(id)sender
{
    
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    return [AddToolbarItem, AddChildToolbarItem, DeleteToolbarItem, CPToolbarSeparatorItemIdentifier, UndoToolbarItem, RedoToolbarItem, CPToolbarSeparatorItemIdentifier, FormatToolbarItem];
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return [AddToolbarItem, AddChildToolbarItem, DeleteToolbarItem, UndoToolbarItem, RedoToolbarItem, FormatToolbarItem, CPToolbarSeparatorItemIdentifier];
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    var item;
    
    if(anIdentifier == AddToolbarItem)
    {
        item = [[CPToolbarItem alloc] initWithItemIdentifier:AddToolbarItem];
        [item setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/AddItem.png" size:CGSizeMake(32.0, 32.0)]];
        [item setLabel:@"Add Item"];
        [item setTarget:self];
        [item setAction:@selector(addItem:)];
    }
    else if(anIdentifier == AddChildToolbarItem)
    {
        item = [[CPToolbarItem alloc] initWithItemIdentifier:AddChildToolbarItem];
        [item setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/AddChild.png" size:CGSizeMake(32.0, 32.0)]];
        [item setLabel:@"Add Child"];
        [item setTarget:self];
        [item setAction:@selector(addChild:)];
    }
    else if(anIdentifier == DeleteToolbarItem)
    {
        item = [[CPToolbarItem alloc] initWithItemIdentifier:DeleteToolbarItem];
        [item setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/DeleteItem.png" size:CGSizeMake(32.0, 32.0)]];
        [item setLabel:@"Delete Item"];
        [item setTarget:self];
        [item setAction:@selector(deleteItem:)];
    }
    else if(anIdentifier == UndoToolbarItem)
    {
        item = [[CPToolbarItem alloc] initWithItemIdentifier:UndoToolbarItem];
        [item setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/Undo.png" size:CGSizeMake(32.0, 32.0)]];
        [item setLabel:@"Undo"];
        [item setTarget:self];
        [item setAction:@selector(undo:)];
    }
    else if(anIdentifier == RedoToolbarItem)
    {
        item = [[CPToolbarItem alloc] initWithItemIdentifier:RedoToolbarItem];
        [item setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/Redo.png" size:CGSizeMake(32.0, 32.0)]];
        [item setLabel:@"Redo"];
        [item setTarget:self];
        [item setAction:@selector(redo:)];
    }
    else if(anIdentifier == FormatToolbarItem)
    {
        var popup = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 150.0, 20.0) pullsDown:NO];
        [popup addItemsWithTitles:[@"OpenStep Format", @"XML Format", @"280North Format"]];
        [[popup itemAtIndex:0] setTag:kCFPropertyListOpenStepFormat];
        [[popup itemAtIndex:1] setTag:kCFPropertyListXMLFormat_v1_0];
        [[popup itemAtIndex:2] setTag:kCFPropertyList280NorthFormat_v1_0];
        [popup selectItemAtIndex:2];
        
        item = [[CPToolbarItem alloc] initWithItemIdentifier:FormatToolbarItem];
        [item setMinSize:CGSizeMake(150.0, 20.0)];
        [item setMaxSize:CGSizeMake(150.0, 20.0)];
        [item setView:popup];
        [item setTarget:nil];
        [item setLabel:@"Format"];
    }
    
    return item;
}

@end

@implementation RowView : CPView
{
    CPTextField     _key;
    CPTextField     _value;
    CPPopUpButton   _type;
    CPView          _divider;
    CPView          _border;
    
    id              _object;
}

- (void)setRepresentedObject:(id)anObject
{
    var x = anObject[0] * 20.0,
        grayColor = [CPColor colorWithHexString:@"CCCCCC"];
    _object = anObject;
    
    if(_divider)
    {
        [_divider removeFromSuperview];
        _divider = nil;
    }
    
    if(x > 0 && !_divider)
    {
        _divider = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, x, 20.0)];
        [self addSubview:_divider];
        
        for(var i = 0; i < anObject[0]; i++)
        {
            var view = [[CPView alloc] initWithFrame:CGRectMake(10 + i * 20.0, 0.0, 1.0, 20.0)];
            [view setBackgroundColor:grayColor];
            [_divider addSubview:view];
        }
    }
    
    if(!_border)
    {
        _border = [[CPView alloc] initWithFrame:CGRectMake(0.0, 20.0, CGRectGetWidth([self bounds]), 1.0)];
        [_border setBackgroundColor:grayColor];
        [_border setAutoresizingMask:CPViewWidthSizable];
        [self addSubview:_border];
        
        _border = [[CPView alloc] initWithFrame:CGRectMake(209.0, 0.0, 1.0, 20.0)];
        [_border setBackgroundColor:grayColor];
        [self addSubview:_border];
        
        _border = [[CPView alloc] initWithFrame:CGRectMake(319.0, 0.0, 1.0, 20.0)];
        [_border setBackgroundColor:grayColor];
        [self addSubview:_border];
    }
    
    if(_key)
    {
        [_key removeFromSuperview];
        _key = nil;
    }
    
    if(!_key)
    {
        _key = [[TextField alloc] initWithFrame:CGRectMake(x, 0.0, 200.0 - x, 20.0)];
        [self addSubview:_key];
    }
    
    if(!_type)
    {
        _type = [[CPPopUpButton alloc] initWithFrame:CGRectMake(218.0, 0.0, 100.0, 20.0)];
        [_type addItemsWithTitles:[@"Array", @"Dictionary", @"String", @"Data", @"Date", @"Number", @"Boolean"]];
        [[_type itemAtIndex:0] setTag:@"CPArray"];
        [[_type itemAtIndex:1] setTag:@"CPDictionary"];
        [[_type itemAtIndex:2] setTag:@"CPString"];
        [[_type itemAtIndex:3] setTag:@"CPData"];
        [[_type itemAtIndex:4] setTag:@"CPDate"];
        [[_type itemAtIndex:5] setTag:@"CPNumber"];
        [[_type itemAtIndex:6] setTag:@"BOOL"];
        [[_type menu] insertItem:[CPMenuItem separatorItem] atIndex:2];
        [_type setBordered:NO];
        [self addSubview:_type];
    }
    
    if(!_value)
    {
        _value = [[TextField alloc] initWithFrame:CGRectMake(320.0, 0.0, 500.0, 20.0)];
        [self addSubview:_value];
    }
    
    [_key setStringValue:anObject[1]];
    [_type selectItemWithTag:[anObject[2] className]];
    
    [_key setInlineEditable:anObject[3]];
    [_key setTextColor:anObject[3] ? [CPColor blackColor] : [CPColor grayColor]];
    
    if([anObject[2] respondsToSelector:@selector(count)])
    {
        [_value setStringValue:@"(" + [anObject[2] count] + " items)"];
        [_value setInlineEditable:NO];
        [_value setTextColor:[CPColor grayColor]];
    }
    else
    {
        [_value setStringValue:anObject[2]];
        [_value setInlineEditable:YES];
        [_value setTextColor:[CPColor blackColor]];
    }
}

- (void)setSelected:(BOOL)flag
{
    if(flag)
    {
        [self setBackgroundColor:[CPColor colorWithHexString:@"B5D5FF"]];
        if([_object[2] respondsToSelector:@selector(count)])
        {
            var item = [[[self window] toolbar] items][0];
            [item setLabel:@"Add Child"];
            [item setImage:AddChildItemImage];
        }
        else
        {
            var item = [[[self window] toolbar] items][0];
            [item setLabel:@"Add Item"];
            [item setImage:AddItemImage];
        }
    }
    else
    {
        [self setBackgroundColor:nil];
    }
}

@end

@implementation TextField : CPTextField
{
    BOOL    _inlineEditable @accessors(property=inlineEditable);
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
        
        [self selectText:self];
    }
}

- (BOOL)resignFirstResponder
{
    [self setEditable:NO];
    [self setBordered:NO];
    [self setBezeled:NO];
    
    return [super resignFirstResponder];
}

@end