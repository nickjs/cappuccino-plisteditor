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

@import "CheckBox.j"
@import "InlineEditor.j"
@import "TextView.j"


var AddToolbarItem      = @"AddToolbarItem",
    AddChildToolbarItem = @"AddChildToolbarItem",
    DeleteToolbarItem   = @"DeleteToolbarItem",
    UndoToolbarItem     = @"UndoToolbarItem",
    RedoToolbarItem     = @"RedoToolbarItem",
    FormatToolbarItem   = @"FormatToolbarItem";


@implementation AppController : CPObject
{
    CPView          _inputView;
    CPView          _editorView;
    CPAlert         _installAlert;
    CPToolbar       _toolbar;
    
    CPTextField     _label;
    TextView        _stringField;
    CPCollectionView _collection;
    
    CPString        _plistString;
    int             _plistType;
    id              _plist;
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
    
    _stringField = [[TextView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 250.0)];
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

- (void)traversePlist:(id)theObject key:(CPString)aKey parent:(id)theParent rowIndex:(int)rowIndex
{
    var aux = [CPDictionary dictionary];
    [aux setObject:theParent forKey:@"parent"];
    [aux setObject:rowIndex forKey:@"rowIndex"];
    [aux setObject:YES forKey:@"keyEditable"];
    
    if(!aKey)
    {
        [aux setObject:NO forKey:@"keyEditable"];
        
        if(theParent && [theParent class] == CPArray)
            aKey = @"Item " + [theParent indexOfObjectIdenticalTo:theObject];
        else
            aKey = @"Root";
    }
    
    [_keyArray addObject:aKey];
    [_valueArray addObject:theObject];
    [_auxArray addObject:aux];
    
    var className = [theObject class];
    if(className == CPDictionary)
    {
        var keys = [theObject allKeys],
            count = [keys count];
            
        for(var i = 0; i < count; i++)
            [self traversePlist:[theObject objectForKey:keys[i]] key:keys[i] parent:theObject rowIndex:rowIndex + 1];
    }
    else if(className == CPArray)
    {
        var count = [theObject count];
        
        for(var i = 0; i < count; i++)
            [self traversePlist:theObject[i] key:nil parent:theObject rowIndex:rowIndex + 1];
    }
}

- (void)resetUI
{
    [_toolbar setVisible:NO];
    
    [_inputView setHidden:NO];
    [_editorView setHidden:YES];
    [_collection setContent:nil];
    
    [_label setStringValue:@"Plist String (or blank):"];
    [_label setTextColor:[CPColor blackColor]];
    [_stringField setStringValue:@""];
    
    [CPMenu setMenuBarTitle:@"CPlist Editor"];
}

- (void)newDocument:(id)sender
{
    [self resetUI];
    
    _keyArray = nil;
    _valueArray = nil;
    _auxArray = nil;
    _plist = nil;
    _plistString = nil;
}

- (void)openDocument:(id)sender
{
    [self newDocument:self];
    
    BrowserPlus.init(function(r){
        if(r.success)
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
        else
        {
            if(!_installAlert)
            {
                _installAlert = [[CPAlert alloc] init];
                [_installAlert setMessageText:@"This feature requires the simple plugin, Yahoo! BrowserPlus."];
                [_installAlert addButtonWithTitle:@"Install!"];
                [_installAlert addButtonWithTitle:@"Cancel"];
                [_installAlert setDelegate:self];
            }
            
            [_installAlert runModal];
        }
    });
}

- (void)saveDocument:(id)sender
{
    [self resetUI];
    
    var data = [CPPropertyListSerialization dataFromPropertyList:_plist format:_plistType errorDescription:@""];
    [_stringField setStringValue:[data string]];
    
    window.open('data:text/html;charset=utf-8,'+encodeURIComponent([data string]));
}

- (void)submit:(id)sender
{
    _plistString = [_stringField stringValue];
    _plist = nil;
    
    if([_plistString length] == 0)
    {
        _plist = [CPDictionary dictionary];
    }
    else
    {
        var data;
        if(_plistString)
            data = [CPData dataWithString:_plistString];
    
        if(data)
            _plist = [CPPropertyListSerialization propertyListFromData:data format:nil errorDescription:@""];
    }
        
    if(_plist)
    {
        _keyArray = [CPArray array];
        _valueArray = [CPArray array];
        _auxArray = [CPArray array];
        
        [CPMenu setMenuBarTitle:@"Plist From String"];
        
        [self traversePlist:_plist key:nil parent:nil rowIndex:0];
        
        var array = [CPArray array],
            count = [_keyArray count];
            
        for(var i=0; i < count; i++)
            array[i] = i;
            
        [_collection setContent:array];
        
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

- (void)addItem:(id)sender
{
    
}

- (void)addChild:(id)sender
{
    
}

- (void)deleteItem:(id)sender
{
    
}

- (void)undo:(id)sender
{
    
}

- (void)redo:(id)sender
{
    
}

- (void)setFormat:(id)sender
{
    _plistType = [[sender selectedItem] tag];
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
        [[popup itemAtIndex:0] setTag:CPPropertyListOpenStepFormat];
        [[popup itemAtIndex:1] setTag:CPPropertyListXMLFormat_v1_0];
        [[popup itemAtIndex:2] setTag:CPPropertyList280NorthFormat_v1_0];
        [popup selectItemAtIndex:2];
        
        _plistType = [[popup itemAtIndex:2] tag];
        
        item = [[CPToolbarItem alloc] initWithItemIdentifier:FormatToolbarItem];
        [item setMinSize:CGSizeMake(150.0, 20.0)];
        [item setMaxSize:CGSizeMake(150.0, 20.0)];
        [item setView:popup];
        [item setTarget:self];
        [item setAction:@selector(setFormat:)]
        [item setLabel:@"Format"];
    }
    
    return item;
}

- (void)alertDidEnd:(CPAlert)anAlert returnCode:(int)returnCode
{
    if(returnCode == 0)
        window.open(@"http://browserplus.yahoo.com/install/");
}

@end


var grayColor = nil;
var keyExistsAlert = nil;

@implementation RowView : CPView
{
    CPTextField     _keyField;
    CPTextField     _valueField;
    CPPopUpButton   _typeField;
    CPView          _divider;
    CPView          _border;
    
    CPString        _key;
    id              _value;
    id              _parent;
    int             _rowIndex;
    int             index;
}

+ (void)initialize
{
    grayColor = [CPColor colorWithHexString:@"CCCCCC"];

    keyExistsAlert = [[CPAlert alloc] init];
    [keyExistsAlert setMessageText:@"Key already exists in this parent! Please choose a different key."];
    [keyExistsAlert addButtonWithTitle:@"I'm Sorry"];
}

- (void)setRepresentedObject:(int)theIndex
{
    index = theIndex;
    _key = _keyArray[index];
    _value = _valueArray[index];
    
    _parent = [_auxArray[index] objectForKey:@"parent"];
    _rowIndex = [_auxArray[index] objectForKey:@"rowIndex"];
    
    var x = _rowIndex * 20.0;
    
    if(_divider)
    {
        [_divider removeFromSuperview];
        _divider = nil;
    }
    
    if(x > 0 && !_divider)
    {
        _divider = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, x, 20.0)];
        [self addSubview:_divider];
        
        for(var i = 0; i < _rowIndex; i++)
        {
            var view = [[CPView alloc] initWithFrame:CGRectMake(10.0 + i * 20.0, 0.0, 1.0, 20.0)];
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
    
    if(_keyField)
    {
        [_keyField removeFromSuperview];
        _keyField = nil;
    }
    
    if(!_keyField)
    {
        _keyField = [[InlineEditor alloc] initWithFrame:CGRectMake(x, 0.0, 200.0 - x, 20.0)];
        [_keyField setEditTarget:self];
        [self addSubview:_keyField];
    }
    
    if(!_typeField)
    {
        _typeField = [[CPPopUpButton alloc] initWithFrame:CGRectMake(218.0, 0.0, 100.0, 20.0)];
        [_typeField addItemsWithTitles:[@"Array", @"Dictionary", @"String", @"Data", @"Date", @"Number", @"Boolean"]];
        [[_typeField itemAtIndex:0] setTag:[CPArray class]];
        [[_typeField itemAtIndex:1] setTag:[CPDictionary class]];
        [[_typeField itemAtIndex:2] setTag:[CPString class]];
        [[_typeField itemAtIndex:3] setTag:[CPData class]];
        [[_typeField itemAtIndex:4] setTag:[CPDate class]];
        [[_typeField itemAtIndex:5] setTag:[CPNumber class]];
        [[_typeField itemAtIndex:6] setTag:@"BOOL"];
        [[_typeField menu] insertItem:[CPMenuItem separatorItem] atIndex:2];
        [_typeField setBordered:NO];
        [_typeField setTarget:self];
        [_typeField setAction:@selector(setType:)];
        [self addSubview:_typeField];
    }
    
    if(!_valueField)
    {
        _valueField = [[InlineEditor alloc] initWithFrame:CGRectMake(320.0, 0.0, 500.0, 20.0)];
        [self addSubview:_valueField];
    }
    
    [self updateValues];
}

- (void)updateValues
{
    [_keyField setStringValue:_key];
    [_typeField selectItemWithTag:[_value class]];
    
    var editable = [_auxArray[index] objectForKey:@"keyEditable"];
    [_keyField setInlineEditable:editable];
    [_keyField setEditAction:@selector(setKey:)];
    [_keyField setTextColor:editable ? [CPColor blackColor] : [CPColor grayColor]];
    
    editable = [_value respondsToSelector:@selector(count)];
    var className = [_value class];
    
    if(editable || className == CPData || className == CPDate)
    {
        if(editable)
            [_valueField setStringValue:@"(" + [_value count] + " items)"];
        else
            [_valueField setStringValue:[_value string]];
        
        [_valueField setInlineEditable:NO];
        [_valueField setTextColor:[CPColor grayColor]];
    }
    else
    {
        [_valueField setStringValue:_value];
        [_valueField setInlineEditable:YES];
        [_valueField setTextColor:[CPColor blackColor]];
    }
}

- (void)setSelected:(BOOL)flag
{
    if(flag)
    {
        [self setBackgroundColor:[CPColor colorWithHexString:@"B5D5FF"]];
    }
    else
    {
        [self setBackgroundColor:nil];
    }
}

- (void)setKey:(id)sender
{
    var newValue = [sender stringValue];
    
    if(_parent && [_parent objectForKey:newValue])
        [keyExistsAlert runModal];
    else
    {
        if(_parent)
        {
            [_parent removeObjectForKey:_key]
            [_parent setObject:_value forKey:newValue];
        }
        
        _keyArray[index] = [sender stringValue];
        _key = _keyArray[index];
    }
    
    [self updateValues];
    console.log([_parent allKeys])
}

- (void)setType:(id)sender
{
    var oldClass = [_value class],
        newClass = [[sender selectedItem] tag];

    if(newClass == CPString)
    {
        if(oldClass == CPNumber)
            _value = [_value stringValue];
    }
    else if(newClass == CPNumber)
    {
        if(oldClass == CPString)
            _value = [_value floatValue];
    }
    
    [self updateValues];
}

@end