﻿/*******************************************************************************
 * Copyright (c) 2000, 2009 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *
 * Port to the D programming language:
 *     Jacob Carlborg <doob@me.com>
 *******************************************************************************/
module dwt.widgets.List;

import dwt.dwthelper.utils;






import tango.text.convert.Format;

import cocoa = dwt.internal.cocoa.id;

import dwt.DWT;
import dwt.accessibility.ACC;
import dwt.dwthelper.System;
import dwt.internal.cocoa.NSString;
import dwt.internal.cocoa.NSSize;
import dwt.internal.cocoa.NSFont;
import dwt.internal.cocoa.NSEvent;
import dwt.internal.cocoa.NSCell;
import dwt.internal.cocoa.NSRect;
import dwt.internal.cocoa.NSPoint;
import dwt.internal.cocoa.NSIndexSet;
import dwt.internal.cocoa.NSTableView;
import dwt.internal.cocoa.NSTableColumn;
import dwt.internal.cocoa.NSScrollView;
import dwt.internal.cocoa.NSRange;
import dwt.internal.cocoa.NSColor;
import dwt.internal.cocoa.NSMutableIndexSet;
import dwt.internal.cocoa.NSAttributedString;
import dwt.internal.cocoa.SWTScrollView;
import dwt.internal.cocoa.SWTTableView;
import dwt.internal.cocoa.OS;
import Carbon = dwt.internal.c.Carbon;
import dwt.internal.objc.cocoa.Cocoa;
import objc = dwt.internal.objc.runtime;
import dwt.widgets.Composite;
import dwt.widgets.Scrollable;
import dwt.widgets.TypedListener;
import dwt.graphics.Color;
import dwt.graphics.Point;
import dwt.graphics.Font;
import dwt.graphics.Rectangle;
import dwt.events.SelectionListener;

/**
 * Instances of this class represent a selectable user interface
 * object that displays a list of strings and issues notification
 * when a string is selected.  A list may be single or multi select.
 * <p>
 * <dl>
 * <dt><b>Styles:</b></dt>
 * <dd>SINGLE, MULTI</dd>
 * <dt><b>Events:</b></dt>
 * <dd>Selection, DefaultSelection</dd>
 * </dl>
 * <p>
 * Note: Only one of SINGLE and MULTI may be specified.
 * </p><p>
 * IMPORTANT: This class is <em>not</em> intended to be subclassed.
 * </p>
 *
 * @see <a href="http://www.eclipse.org/swt/snippets/#list">List snippets</a>
 * @see <a href="http://www.eclipse.org/swt/examples.php">DWT Example: ControlExample</a>
 * @see <a href="http://www.eclipse.org/swt/">Sample code and further information</a>
 * @noextend This class is not intended to be subclassed by clients.
 */
public class List : Scrollable {

    alias Scrollable.computeSize computeSize;
    alias Scrollable.dragDetect dragDetect;
    alias Scrollable.setBackground setBackground;
    alias Scrollable.setBounds setBounds;
    alias Scrollable.setFont setFont;

    NSTableColumn column;
    String [] items;
    int itemCount;
    bool ignoreSelect;

    static int NEXT_ID;

    static final int CELL_GAP = 1;

/**
 * Constructs a new instance of this class given its parent
 * and a style value describing its behavior and appearance.
 * <p>
 * The style value is either one of the style constants defined in
 * class <code>DWT</code> which is applicable to instances of this
 * class, or must be built by <em>bitwise OR</em>'ing together
 * (that is, using the <code>int</code> "|" operator) two or more
 * of those <code>DWT</code> style constants. The class description
 * lists the style constants that are applicable to the class.
 * Style bits are also inherited from superclasses.
 * </p>
 *
 * @param parent a composite control which will be the parent of the new instance (cannot be null)
 * @param style the style of control to construct
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the parent is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the parent</li>
 *    <li>ERROR_INVALID_SUBCLASS - if this class is not an allowed subclass</li>
 * </ul>
 *
 * @see DWT#SINGLE
 * @see DWT#MULTI
 * @see Widget#checkSubclass
 * @see Widget#getStyle
 */
public this (Composite parent, int style) {
    super (parent, checkStyle (style));
}

objc.id accessibilityAttributeValue (objc.id id, objc.SEL sel, objc.id arg0) {

    if (accessible !is null) {
        NSString attribute = new NSString(arg0);
        cocoa.id returnValue = accessible.internal_accessibilityAttributeValue(attribute, ACC.CHILDID_SELF);
        if (returnValue !is null) return returnValue.id;
    }

    NSString attributeName = new NSString(arg0);

    // Accessibility Verifier queries for a title or description.  NSOutlineView doesn't
    // seem to return either, so we return a default description value here.
    if (attributeName.isEqualToString (OS.NSAccessibilityDescriptionAttribute)) {
        return NSString.stringWith("").id;
    }

    //  if (attributeName.isEqualToString(OS.NSAccessibilityHeaderAttribute)) {
    //      /*
    //      * Bug in the Macintosh.  Even when the header is not visible,
    //      * VoiceOver still reports each column header's role for every row.
    //      * This is confusing and overly verbose.  The fix is to return
    //      * "no header" when the screen reader asks for the header, by
    //      * returning noErr without setting the event parameter.
    //      */
    //      return 0;
    //  }

    return super.accessibilityAttributeValue(id, sel, arg0);
}

/**
 * Adds the argument to the end of the receiver's list.
 *
 * @param string the new item
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 *
 * @see #add(String,int)
 */
public void add (String string) {
    checkWidget();
    // DWT extension: allow null for zero length string
    //if (string is null) error (DWT.ERROR_NULL_ARGUMENT);
    if (itemCount is items.length) {
        String [] newItems = new String [itemCount + 4];
        System.arraycopy (items, 0, newItems, 0, items.length);
        items = newItems;
    }
    items [itemCount++] = string;
    (cast(NSTableView)view).noteNumberOfRowsChanged ();
    setScrollWidth(string);
}

/**
 * Adds the argument to the receiver's list at the given
 * zero-relative index.
 * <p>
 * Note: To add an item at the end of the list, use the
 * result of calling <code>getItemCount()</code> as the
 * index or use <code>add(String)</code>.
 * </p>
 *
 * @param string the new item
 * @param index the index for the item
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
 *    <li>ERROR_INVALID_RANGE - if the index is not between 0 and the number of elements in the list (inclusive)</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 *
 * @see #add(String)
 */
public void add (String string, int index) {
    checkWidget();
    // DWT extension: allow null for zero length string
    //if (string is null) error (DWT.ERROR_NULL_ARGUMENT);
    if (!(0 <= index && index <= itemCount)) error (DWT.ERROR_INVALID_RANGE);
    if (itemCount is items.length) {
        String [] newItems = new String [itemCount + 4];
        System.arraycopy (items, 0, newItems, 0, items.length);
        items = newItems;
    }
    System.arraycopy (items, index, items, index + 1, itemCount++ - index);
    items [index] = string;
    (cast(NSTableView)view).noteNumberOfRowsChanged ();
    if (index !is itemCount) fixSelection (index, true);
    setScrollWidth(string);
}

/**
 * Adds the listener to the collection of listeners who will
 * be notified when the user changes the receiver's selection, by sending
 * it one of the messages defined in the <code>SelectionListener</code>
 * interface.
 * <p>
 * <code>widgetSelected</code> is called when the selection changes.
 * <code>widgetDefaultSelected</code> is typically called when an item is double-clicked.
 * </p>
 *
 * @param listener the listener which should be notified when the user changes the receiver's selection
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the listener is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 *
 * @see SelectionListener
 * @see #removeSelectionListener
 * @see SelectionEvent
 */
public void addSelectionListener(SelectionListener listener) {
    checkWidget();
    if (listener is null) error (DWT.ERROR_NULL_ARGUMENT);
    TypedListener typedListener = new TypedListener(listener);
    addListener(DWT.Selection,typedListener);
    addListener(DWT.DefaultSelection,typedListener);
}

static int checkStyle (int style) {
    return checkBits (style, DWT.SINGLE, DWT.MULTI, 0, 0, 0, 0);
}

public Point computeSize (int wHint, int hHint, bool changed) {
    checkWidget();
    int width = 0;
    if (wHint is DWT.DEFAULT) {
        NSCell cell = column.dataCell ();
        Font font = this.font !is null ? this.font : defaultFont ();
        cell.setFont (font.handle);
        for (int i = 0; i < items.length; i++) {
            if (items[i] !is null) {
                cell.setTitle (NSString.stringWith (items[i]));
                NSSize size = cell.cellSize ();
                width = Math.max (width, cast(int)Math.ceil (size.width));
            }
        }
        width += CELL_GAP;
    } else {
        width = wHint;
    }
    if (width <= 0) width = DEFAULT_WIDTH;
    int height = 0;
    if (hHint is DWT.DEFAULT) {
        int itemHeight = getItemHeight () + CELL_GAP;
        height = itemCount * itemHeight;
    } else {
        height = hHint;
    }
    if (height <= 0) height = DEFAULT_HEIGHT;
    Rectangle rect = computeTrim (0, 0, width, height);
    return new Point (rect.width, rect.height);
}

void createHandle () {
    NSScrollView scrollWidget = cast(NSScrollView)(new SWTScrollView()).alloc();
    scrollWidget.init();
    if ((style & DWT.H_SCROLL) !is 0) scrollWidget.setHasHorizontalScroller(true);
    if ((style & DWT.V_SCROLL) !is 0) scrollWidget.setHasVerticalScroller(true);
    scrollWidget.setAutohidesScrollers(true);
    scrollWidget.setBorderType(cast(NSBorderType)((style & DWT.BORDER) !is 0 ? OS.NSBezelBorder : OS.NSNoBorder));

    NSTableView widget = cast(NSTableView)(new SWTTableView()).alloc();
    widget.init();
    widget.setAllowsMultipleSelection((style & DWT.MULTI) !is 0);
    widget.setDataSource(widget);
    widget.setHeaderView(null);
    widget.setDelegate(widget);
    if ((style & DWT.H_SCROLL) !is 0) {
        widget.setColumnAutoresizingStyle (OS.NSTableViewNoColumnAutoresizing);
    }
    NSSize spacing = NSSize();
    spacing.width = spacing.height = CELL_GAP;
    widget.setIntercellSpacing(spacing);
    widget.setDoubleAction(OS.sel_sendDoubleSelection);
    if (!hasBorder()) widget.setFocusRingType(OS.NSFocusRingTypeNone);

    column = cast(NSTableColumn)(new NSTableColumn()).alloc();
    column = column.initWithIdentifier(NSString.stringWith(Format("{}",++NEXT_ID)));
    column.setWidth(0);
    widget.addTableColumn (column);

    scrollView = scrollWidget;
    view = widget;
}

void createWidget () {
    super.createWidget ();
    items = new String [4];
}

Color defaultBackground () {
    return display.getWidgetColor (DWT.COLOR_LIST_BACKGROUND);
}

NSFont defaultNSFont () {
    return display.tableViewFont;
}

Color defaultForeground () {
    return display.getWidgetColor (DWT.COLOR_LIST_FOREGROUND);
}

/**
 * Deselects the item at the given zero-relative index in the receiver.
 * If the item at the index was already deselected, it remains
 * deselected. Indices that are out of range are ignored.
 *
 * @param index the index of the item to deselect
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void deselect (int index) {
    checkWidget();
    if (0 <= index && index < itemCount) {
        NSTableView widget = cast(NSTableView)view;
        ignoreSelect = true;
        widget.deselectRow (index);
        ignoreSelect = false;
    }
}

/**
 * Deselects the items at the given zero-relative indices in the receiver.
 * If the item at the given zero-relative index in the receiver
 * is selected, it is deselected.  If the item at the index
 * was not selected, it remains deselected.  The range of the
 * indices is inclusive. Indices that are out of range are ignored.
 *
 * @param start the start index of the items to deselect
 * @param end the end index of the items to deselect
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void deselect (int start, int end) {
    checkWidget();
    if (start > end) return;
    if (end < 0 || start >= itemCount) return;
    start = Math.max (0, start);
    end = Math.min (itemCount - 1, end);
    if (start is 0 && end is itemCount - 1) {
        deselectAll ();
    } else {
        NSTableView widget = cast(NSTableView)view;
        ignoreSelect = true;
        for (int i=start; i<=end; i++) {
            widget.deselectRow (i);
        }
        ignoreSelect = false;
    }
}

/**
 * Deselects the items at the given zero-relative indices in the receiver.
 * If the item at the given zero-relative index in the receiver
 * is selected, it is deselected.  If the item at the index
 * was not selected, it remains deselected. Indices that are out
 * of range and duplicate indices are ignored.
 *
 * @param indices the array of indices for the items to deselect
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the set of indices is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void deselect (int [] indices) {
    checkWidget();
    if (indices is null) error (DWT.ERROR_NULL_ARGUMENT);
    NSTableView widget = cast(NSTableView)view;
    ignoreSelect = true;
    for (int i=0; i<indices.length; i++) {
        widget.deselectRow (indices [i]);
    }
    ignoreSelect = false;
}

/**
 * Deselects all selected items in the receiver.
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void deselectAll () {
    checkWidget ();
    NSTableView widget = cast(NSTableView)view;
    ignoreSelect = true;
    widget.deselectAll(null);
    ignoreSelect = false;
}

bool dragDetect(int x, int y, bool filter, bool[] consume) {
    NSTableView widget = cast(NSTableView)view;
    NSPoint pt = NSPoint();
    pt.x = x;
    pt.y = y;
    NSInteger row = widget.rowAtPoint(pt);
    if (row is -1) return false;
    bool dragging = super.dragDetect(x, y, filter, consume);
    if (dragging) {
        if (!widget.isRowSelected(row)) {
            //TODO expand current selection when Shift, Command key pressed??
            NSIndexSet set = cast(NSIndexSet)(new NSIndexSet()).alloc();
            set = set.initWithIndex(row);
            widget.selectRowIndexes (set, false);
            set.release();
        }
    }
    consume[0] = dragging;
    return dragging;
}

void fixSelection (int index, bool add) {
    int [] selection = getSelectionIndices ();
    if (selection.length is 0) return;
    int newCount = 0;
    bool fix = false;
    for (int i = 0; i < selection.length; i++) {
        if (!add && selection [i] is index) {
            fix = true;
        } else {
            int newIndex = newCount++;
            selection [newIndex] = selection [i];
            if (selection [newIndex] >= index) {
                selection [newIndex] += add ? 1 : -1;
                fix = true;
            }
        }
    }
    if (fix) select (selection, newCount, true);
}

/**
 * Returns the zero-relative index of the item which currently
 * has the focus in the receiver, or -1 if no item has focus.
 *
 * @return the index of the selected item
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public int getFocusIndex () {
    checkWidget();
    return cast(int)/*64*/(cast(NSTableView)view).selectedRow();
}

/**
 * Returns the item at the given, zero-relative index in the
 * receiver. Throws an exception if the index is out of range.
 *
 * @param index the index of the item to return
 * @return the item at the given index
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_INVALID_RANGE - if the index is not between 0 and the number of elements in the list minus 1 (inclusive)</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public String getItem (int index) {
    checkWidget();
    if (!(0 <= index && index < itemCount)) error (DWT.ERROR_INVALID_RANGE);
    return items [index];
}

/**
 * Returns the number of items contained in the receiver.
 *
 * @return the number of items
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public int getItemCount () {
    checkWidget();
    return itemCount;
}

/**
 * Returns the height of the area which would be used to
 * display <em>one</em> of the items in the list.
 *
 * @return the height of one item
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public int getItemHeight () {
    checkWidget ();
    return cast(int)(cast(NSTableView)view).rowHeight();
}

/**
 * Returns a (possibly empty) array of <code>String</code>s which
 * are the items in the receiver.
 * <p>
 * Note: This is not the actual structure used by the receiver
 * to maintain its list of items, so modifying the array will
 * not affect the receiver.
 * </p>
 *
 * @return the items in the receiver's list
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public String [] getItems () {
    checkWidget();
    String [] result = new String [itemCount];
    System.arraycopy (items, 0, result, 0, itemCount);
    return result;
}

/**
 * Returns an array of <code>String</code>s that are currently
 * selected in the receiver.  The order of the items is unspecified.
 * An empty array indicates that no items are selected.
 * <p>
 * Note: This is not the actual structure used by the receiver
 * to maintain its selection, so modifying the array will
 * not affect the receiver.
 * </p>
 * @return an array representing the selection
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public String [] getSelection () {
    checkWidget ();
    NSTableView widget = cast(NSTableView)view;
    if (widget.numberOfSelectedRows() is 0) {
        return new String [0];
    }
    NSIndexSet selection = widget.selectedRowIndexes();
    NSUInteger count = selection.count();
    NSUInteger [] indexBuffer = new NSUInteger [count];
    selection.getIndexes(indexBuffer.ptr, count, null);
    String [] result = new String  [count];
    for (NSUInteger i=0; i<count; i++) {
        result [i] = items [indexBuffer [i]];
    }
    return result;
}

/**
 * Returns the number of selected items contained in the receiver.
 *
 * @return the number of selected items
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public int getSelectionCount () {
    checkWidget ();
    return cast(int)/*64*/(cast(NSTableView)view).numberOfSelectedRows();
}

/**
 * Returns the zero-relative index of the item which is currently
 * selected in the receiver, or -1 if no item is selected.
 *
 * @return the index of the selected item or -1
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public int getSelectionIndex () {
    checkWidget();
    NSTableView widget = cast(NSTableView)view;
    if (widget.numberOfSelectedRows() is 0) {
        return -1;
    }
    NSIndexSet selection = widget.selectedRowIndexes();
    NSUInteger count = selection.count();
    NSUInteger [] result = new NSUInteger [count];
    selection.getIndexes(result.ptr, count, null);
    return cast(int) result [0];
}

/**
 * Returns the zero-relative indices of the items which are currently
 * selected in the receiver.  The order of the indices is unspecified.
 * The array is empty if no items are selected.
 * <p>
 * Note: This is not the actual structure used by the receiver
 * to maintain its selection, so modifying the array will
 * not affect the receiver.
 * </p>
 * @return the array of indices of the selected items
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public int [] getSelectionIndices () {
    checkWidget ();
    NSTableView widget = cast(NSTableView)view;
    if (widget.numberOfSelectedRows() is 0) {
        return new int [0];
    }
    NSIndexSet selection = widget.selectedRowIndexes();
    NSUInteger count = selection.count();
    NSUInteger [] indices = new NSUInteger [count];
    selection.getIndexes(indices.ptr, count, null);
    NSUInteger [] result = new NSUInteger [count];
    for (NSUInteger i = 0; i < result.length; i++) {
        result [i] = indices [i];
    }
    return cast(int[]) result;
}

/**
 * Returns the zero-relative index of the item which is currently
 * at the top of the receiver. This index can change when items are
 * scrolled or new items are added or removed.
 *
 * @return the index of the top item
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public int getTopIndex () {
    checkWidget();
    //TODO - partial item at the top
    NSRect rect = scrollView.documentVisibleRect();
    NSPoint point = NSPoint();
    point.x = rect.x;
    point.y = rect.y;
    int result = cast(int)/*64*/(cast(NSTableView)view).rowAtPoint(point);
    if (result is -1) result = 0;
    return result;
}

/**
 * Gets the index of an item.
 * <p>
 * The list is searched starting at 0 until an
 * item is found that is equal to the search item.
 * If no item is found, -1 is returned.  Indexing
 * is zero based.
 *
 * @param string the search item
 * @return the index of the item
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public int indexOf (String item) {
    checkWidget();
    // DWT extension: allow null for zero length string
    //if (item is null) error (DWT.ERROR_NULL_ARGUMENT);
    for (int i=0; i<itemCount; i++) {
        if (items [i] == item) return i;
    }
    return -1;
}

/**
 * Searches the receiver's list starting at the given,
 * zero-relative index until an item is found that is equal
 * to the argument, and returns the index of that item. If
 * no item is found or the starting index is out of range,
 * returns -1.
 *
 * @param string the search item
 * @param start the zero-relative index at which to start the search
 * @return the index of the item
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public int indexOf (String string, int start) {
    checkWidget();
    // DWT extension: allow null for zero length string
    //if (string is null) error (DWT.ERROR_NULL_ARGUMENT);
    for (int i=start; i<itemCount; i++) {
        if (items [i] == string) return i;
    }
    return -1;
}

/**
 * Returns <code>true</code> if the item is selected,
 * and <code>false</code> otherwise.  Indices out of
 * range are ignored.
 *
 * @param index the index of the item
 * @return the selection state of the item at the index
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public bool isSelected (int index) {
    checkWidget();
    if (!(0 <= index && index < itemCount)) return false;
    return (cast(NSTableView)view).isRowSelected(index);
}

/*
 * Feature in Cocoa: Table views do not change the selection when the user
 * right-clicks or control-clicks on an NSTableView or its subclasses. Fix is to select the
 * clicked-on row ourselves.
 */
objc.id menuForEvent(objc.id id, objc.SEL sel, objc.id theEvent) {
    NSEvent event = new NSEvent(theEvent);
    NSTableView table = cast(NSTableView)view;

    // get the current selections for the outline view.
    NSIndexSet selectedRowIndexes = table.selectedRowIndexes();

    // select the row that was clicked before showing the menu for the event
    NSPoint mousePoint = view.convertPoint_fromView_(event.locationInWindow(), null);
    NSInteger row = table.rowAtPoint(mousePoint);

    // figure out if the row that was just clicked on is currently selected
    if (selectedRowIndexes.containsIndex(row) is false) {
        NSIndexSet set = cast(NSIndexSet)(new NSIndexSet()).alloc();
        set = set.initWithIndex(row);
        table.selectRowIndexes (set, false);
        set.release();
    }
    // else that row is currently selected, so don't change anything.

    return super.menuForEvent(id, sel, theEvent);
}

/*
 * Feature in Cocoa: Table views do not change the selection when the user
 * right-clicks or control-clicks on an NSTableView or its subclasses. Fix is to select the
 * clicked-on row ourselves.
 */
objc.id menuForEvent(objc.id id, objc.SEL sel, objc.id theEvent) {
    NSEvent event = new NSEvent(theEvent);
    NSTableView table = cast(NSTableView)view;

    // get the current selections for the outline view.
    NSIndexSet selectedRowIndexes = table.selectedRowIndexes();

    // select the row that was clicked before showing the menu for the event
    NSPoint mousePoint = view.convertPoint_fromView_(event.locationInWindow(), null);
    NSInteger row = table.rowAtPoint(mousePoint);

    // figure out if the row that was just clicked on is currently selected
    if (selectedRowIndexes.containsIndex(row) is false) {
        NSIndexSet set = cast(NSIndexSet)(new NSIndexSet()).alloc();
        set = set.initWithIndex(row);
        table.selectRowIndexes (set, false);
        set.release();
    }
    // else that row is currently selected, so don't change anything.

    return super.menuForEvent(id, sel, theEvent);
}

int numberOfRowsInTableView(objc.id id, objc.SEL sel, objc.id aTableView) {
    return itemCount;
}

void releaseHandle () {
    super.releaseHandle ();
    if (column !is null) column.release();
    column = null;
}

void releaseWidget () {
    super.releaseWidget ();
    items = null;
}

/**
 * Removes the item from the receiver at the given
 * zero-relative index.
 *
 * @param index the index for the item
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_INVALID_RANGE - if the index is not between 0 and the number of elements in the list minus 1 (inclusive)</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void remove (int index) {
    checkWidget();
    if (!(0 <= index && index < itemCount)) error (DWT.ERROR_INVALID_RANGE);
    remove(index, true);
}

void remove (int index, bool fixScroll) {
    if (index !is itemCount - 1) fixSelection (index, false);
    System.arraycopy (items, index + 1, items, index, --itemCount - index);
    items [itemCount] = null;
    (cast(NSTableView)view).noteNumberOfRowsChanged();
    if (fixScroll) setScrollWidth();
}

/**
 * Removes the items from the receiver which are
 * between the given zero-relative start and end
 * indices (inclusive).
 *
 * @param start the start of the range
 * @param end the end of the range
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_INVALID_RANGE - if either the start or end are not between 0 and the number of elements in the list minus 1 (inclusive)</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void remove (int start, int end) {
    checkWidget();
    if (start > end) return;
    if (!(0 <= start && start <= end && end < itemCount)) {
        error (DWT.ERROR_INVALID_RANGE);
    }
    int length = end - start + 1;
    for (int i=0; i<length; i++) remove (start, false);
    setScrollWidth();
}

/**
 * Searches the receiver's list starting at the first item
 * until an item is found that is equal to the argument,
 * and removes that item from the list.
 *
 * @param string the item to remove
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
 *    <li>ERROR_INVALID_ARGUMENT - if the string is not found in the list</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void remove (String string) {
    checkWidget();
    // DWT extension: allow null for zero length string
    //if (string is null) error (DWT.ERROR_NULL_ARGUMENT);
    int index = indexOf (string, 0);
    if (index is -1) error (DWT.ERROR_INVALID_ARGUMENT);
    remove (index);
}

/**
 * Removes the items from the receiver at the given
 * zero-relative indices.
 *
 * @param indices the array of indices of the items
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_INVALID_RANGE - if the index is not between 0 and the number of elements in the list minus 1 (inclusive)</li>
 *    <li>ERROR_NULL_ARGUMENT - if the indices array is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void remove (int [] indices) {
    checkWidget ();
    if (indices is null) error (DWT.ERROR_NULL_ARGUMENT);
    if (indices.length is 0) return;
    int [] newIndices = new int [indices.length];
    System.arraycopy (indices, 0, newIndices, 0, indices.length);
    sort (newIndices);
    int start = newIndices [newIndices.length - 1], end = newIndices [0];
    int count = getItemCount ();
    if (!(0 <= start && start <= end && end < count)) {
        error (DWT.ERROR_INVALID_RANGE);
    }
    int last = -1;
    for (int i=0; i<newIndices.length; i++) {
        int index = newIndices [i];
        if (index !is last) {
            remove (index, false);
            last = index;
        }
    }
    setScrollWidth();
}

/**
 * Removes all of the items from the receiver.
 * <p>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void removeAll () {
    checkWidget();
    items = new String [4];
    itemCount = 0;
    (cast(NSTableView)view).noteNumberOfRowsChanged();
    setScrollWidth();
}

/**
 * Removes the listener from the collection of listeners who will
 * be notified when the user changes the receiver's selection.
 *
 * @param listener the listener which should no longer be notified
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the listener is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 *
 * @see SelectionListener
 * @see #addSelectionListener
 */
public void removeSelectionListener(SelectionListener listener) {
    checkWidget();
    if (listener is null) error (DWT.ERROR_NULL_ARGUMENT);
    if (eventTable is null) return;
    eventTable.unhook(DWT.Selection, listener);
    eventTable.unhook(DWT.DefaultSelection,listener);
}

/**
 * Selects the item at the given zero-relative index in the receiver's
 * list.  If the item at the index was already selected, it remains
 * selected. Indices that are out of range are ignored.
 *
 * @param index the index of the item to select
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void select (int index) {
    checkWidget();
    if (0 <= index && index < itemCount) {
        NSIndexSet set = cast(NSIndexSet)(new NSIndexSet()).alloc();
        set = set.initWithIndex(index);
        NSTableView widget = cast(NSTableView)view;
        ignoreSelect = true;
        widget.selectRowIndexes(set, (style & DWT.MULTI) !is 0);
        ignoreSelect = false;
        set.release();
    }
}

/**
 * Selects the items in the range specified by the given zero-relative
 * indices in the receiver. The range of indices is inclusive.
 * The current selection is not cleared before the new items are selected.
 * <p>
 * If an item in the given range is not selected, it is selected.
 * If an item in the given range was already selected, it remains selected.
 * Indices that are out of range are ignored and no items will be selected
 * if start is greater than end.
 * If the receiver is single-select and there is more than one item in the
 * given range, then all indices are ignored.
 *
 * @param start the start of the range
 * @param end the end of the range
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 *
 * @see List#setSelection(int,int)
 */
public void select (int start, int end) {
    checkWidget ();
    if (end < 0 || start > end || ((style & DWT.SINGLE) !is 0 && start !is end)) return;
    if (itemCount is 0 || start >= itemCount) return;
    if (start is 0 && end is itemCount - 1) {
        selectAll ();
    } else {
        start = Math.max (0, start);
        end = Math.min (end, itemCount - 1);
        NSRange range = NSRange();
        range.location = start;
        range.length = end - start + 1;
        NSIndexSet set = cast(NSIndexSet)(new NSIndexSet()).alloc();
        set = set.initWithIndexesInRange(range);
        NSTableView widget = cast(NSTableView)view;
        ignoreSelect = true;
        widget.selectRowIndexes(set, (style & DWT.MULTI) !is 0);
        ignoreSelect = false;
        set.release();
    }
}

/**
 * Selects the items at the given zero-relative indices in the receiver.
 * The current selection is not cleared before the new items are selected.
 * <p>
 * If the item at a given index is not selected, it is selected.
 * If the item at a given index was already selected, it remains selected.
 * Indices that are out of range and duplicate indices are ignored.
 * If the receiver is single-select and multiple indices are specified,
 * then all indices are ignored.
 *
 * @param indices the array of indices for the items to select
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the array of indices is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 *
 * @see List#setSelection(int[])
 */
public void select (int [] indices) {
    checkWidget ();
    if (indices is null) error (DWT.ERROR_NULL_ARGUMENT);
    int length = indices.length;
    if (length is 0 || ((style & DWT.SINGLE) !is 0 && length > 1)) return;
    int count = 0;
    NSMutableIndexSet set = cast(NSMutableIndexSet)(new NSMutableIndexSet()).alloc().init();
    for (int i=0; i<length; i++) {
        int index = indices [i];
        if (index >= 0 && index < itemCount) {
            set.addIndex (indices [i]);
            count++;
        }
    }
    if (count > 0) {
        NSTableView widget = cast(NSTableView)view;
        ignoreSelect = true;
        widget.selectRowIndexes(set, (style & DWT.MULTI) !is 0);
        ignoreSelect = false;
    }
    set.release();
}

void select (int [] indices, int count, bool clear) {
    NSMutableIndexSet set = cast(NSMutableIndexSet)(new NSMutableIndexSet()).alloc().init();
    for (int i=0; i<count; i++) set.addIndex (indices [i]);
    NSTableView widget = cast(NSTableView)view;
    ignoreSelect = true;
    widget.selectRowIndexes(set, !clear);
    ignoreSelect = false;
    set.release();
}

/**
 * Selects all of the items in the receiver.
 * <p>
 * If the receiver is single-select, do nothing.
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void selectAll () {
    checkWidget ();
    if ((style & DWT.SINGLE) !is 0) return;
    NSTableView widget = cast(NSTableView)view;
    ignoreSelect = true;
    widget.selectAll(null);
    ignoreSelect = false;
}

void sendDoubleSelection() {
    if ((cast(NSTableView)view).clickedRow () !is -1) {
        postEvent (DWT.DefaultSelection);
    }
}

bool sendKeyEvent (NSEvent nsEvent, int type) {
    bool result = super.sendKeyEvent (nsEvent, type);
    if (!result) return result;
    if (type !is DWT.KeyDown) return result;
    ushort keyCode = nsEvent.keyCode ();
    switch (keyCode) {
        case 76: /* KP Enter */
        case 36: { /* Return */
            postEvent (DWT.DefaultSelection);
            break;
        }
        default:
    }
    return result;
}

void updateBackground () {
    NSColor nsColor = null;
    if (backgroundImage !is null) {
        nsColor = NSColor.colorWithPatternImage(backgroundImage.handle);
    } else if (background !is null) {
        nsColor = NSColor.colorWithDeviceRed(background[0], background[1], background[2], background[3]);
    }
    (cast(NSTableView) view).setBackgroundColor (nsColor);
}

void setFont (NSFont font) {
    super.setFont (font);
    Carbon.CGFloat ascent = font.ascender ();
    Carbon.CGFloat descent = -font.descender () + font.leading ();
    (cast(NSTableView)view).setRowHeight (cast(int)Math.ceil (ascent + descent) + 1);
    setScrollWidth();
}

/**
 * Sets the text of the item in the receiver's list at the given
 * zero-relative index to the string argument.
 *
 * @param index the index for the item
 * @param string the new text for the item
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_INVALID_RANGE - if the index is not between 0 and the number of elements in the list minus 1 (inclusive)</li>
 *    <li>ERROR_NULL_ARGUMENT - if the string is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void setItem (int index, String string) {
    checkWidget();
    // DWT extension: allow null for zero length string
    //if (string is null) error (DWT.ERROR_NULL_ARGUMENT);
    if (!(0 <= index && index < itemCount)) error (DWT.ERROR_INVALID_RANGE);
    items [index] = string;
    NSTableView tableView = cast(NSTableView)view;
    NSRect rect = tableView.rectOfRow (index);
    tableView.setNeedsDisplayInRect (rect);
    setScrollWidth(string);
}

/**
 * Sets the receiver's items to be the given array of items.
 *
 * @param items the array of items
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the items array is null</li>
 *    <li>ERROR_INVALID_ARGUMENT - if an item in the items array is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void setItems (String [] items) {
    checkWidget();
    if (items is null) error (DWT.ERROR_NULL_ARGUMENT);
    for (int i=0; i<items.length; i++) {
        if (items [i] is null) error (DWT.ERROR_INVALID_ARGUMENT);
    }
    this.items = new String [items.length];
    System.arraycopy (items, 0, this.items, 0, items.length);
    itemCount = items.length;
    (cast(NSTableView)view).reloadData();
    setScrollWidth();
}

bool setScrollWidth (String item) {
    if ((style & DWT.H_SCROLL) is 0) return false;
    NSCell cell = column.dataCell ();
    Font font = this.font !is null ? this.font : defaultFont ();
    cell.setFont (font.handle);
    cell.setTitle (NSString.stringWith (item));
    NSSize size = cell.cellSize ();
    Cocoa.CGFloat oldWidth = column.width ();
    if (oldWidth < size.width) {
        column.setWidth (size.width);
        return true;
    }
    return false;
}

bool setScrollWidth () {
    if ((style & DWT.H_SCROLL) is 0) return false;
    if (items is null) return false;
    NSCell cell = column.dataCell ();
    Font font = this.font !is null ? this.font : defaultFont ();
    cell.setFont (font.handle);
    Cocoa.CGFloat width = 0;
    for (int i = 0; i < itemCount; i++) {
        cell.setTitle (NSString.stringWith (items[i]));
        NSSize size = cell.cellSize ();
        width = Math.max (width, size.width);
    }
    column.setWidth (width);
    return true;
}

/**
 * Selects the item at the given zero-relative index in the receiver.
 * If the item at the index was already selected, it remains selected.
 * The current selection is first cleared, then the new item is selected.
 * Indices that are out of range are ignored.
 *
 * @param index the index of the item to select
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 * @see List#deselectAll()
 * @see List#select(int)
 */
public void setSelection (int index) {
    checkWidget();
    deselectAll ();
    if (0 <= index && index < itemCount) {
        NSIndexSet set = cast(NSIndexSet)(new NSIndexSet()).alloc();
        set = set.initWithIndex(index);
        NSTableView widget = cast(NSTableView)view;
        ignoreSelect = true;
        widget.selectRowIndexes(set, false);
        ignoreSelect = false;
        set.release();
        showIndex (index);
    }
}

/**
 * Selects the items in the range specified by the given zero-relative
 * indices in the receiver. The range of indices is inclusive.
 * The current selection is cleared before the new items are selected.
 * <p>
 * Indices that are out of range are ignored and no items will be selected
 * if start is greater than end.
 * If the receiver is single-select and there is more than one item in the
 * given range, then all indices are ignored.
 *
 * @param start the start index of the items to select
 * @param end the end index of the items to select
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 *
 * @see List#deselectAll()
 * @see List#select(int,int)
 */
public void setSelection (int start, int end) {
    checkWidget ();
    deselectAll ();
    if (end < 0 || start > end || ((style & DWT.SINGLE) !is 0 && start !is end)) return;
    if (itemCount is 0 || start >= itemCount) return;
    start = Math.max (0, start);
    end = Math.min (end, itemCount - 1);
    NSRange range = NSRange();
    range.location = start;
    range.length = end - start + 1;
    NSIndexSet set = cast(NSIndexSet)(new NSIndexSet()).alloc();
    set = set.initWithIndexesInRange(range);
    NSTableView widget = cast(NSTableView)view;
    ignoreSelect = true;
    widget.selectRowIndexes(set, false);
    ignoreSelect = false;
    set.release();
    showIndex(end);
}

/**
 * Selects the items at the given zero-relative indices in the receiver.
 * The current selection is cleared before the new items are selected.
 * <p>
 * Indices that are out of range and duplicate indices are ignored.
 * If the receiver is single-select and multiple indices are specified,
 * then all indices are ignored.
 *
 * @param indices the indices of the items to select
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the array of indices is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 *
 * @see List#deselectAll()
 * @see List#select(int[])
 */
public void setSelection (int [] indices) {
    checkWidget ();
    if (indices is null) error (DWT.ERROR_NULL_ARGUMENT);
    deselectAll ();
    int length_ = indices.length;
    if (length_ is 0 || ((style & DWT.SINGLE) !is 0 && length_ > 1)) return;
    int [] newIndices = new int [length_];
    int count = 0;
    for (int i=0; i<length_; i++) {
        int index = indices [length_ - i - 1];
        if (index >= 0 && index < itemCount) {
            newIndices [count++] = index;
        }
    }
    if (count > 0) {
        select (newIndices, count, true);
        showIndex (newIndices [0]);
    }
}

/**
 * Sets the receiver's selection to be the given array of items.
 * The current selection is cleared before the new items are selected.
 * <p>
 * Items that are not in the receiver are ignored.
 * If the receiver is single-select and multiple items are specified,
 * then all items are ignored.
 *
 * @param items the array of items
 *
 * @exception IllegalArgumentException <ul>
 *    <li>ERROR_NULL_ARGUMENT - if the array of items is null</li>
 * </ul>
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 *
 * @see List#deselectAll()
 * @see List#select(int[])
 * @see List#setSelection(int[])
 */
public void setSelection (String [] items) {
    checkWidget ();
    if (items is null) error (DWT.ERROR_NULL_ARGUMENT);
    deselectAll ();
    int length_ = items.length;
    if (length_ is 0 || ((style & DWT.SINGLE) !is 0 && length_ > 1)) return;
    int count = 0;
    int [] indices = new int [length_];
    for (int i=0; i<length_; i++) {
        String string = items [length_ - i - 1];
        if ((style & DWT.SINGLE) !is 0) {
            int index = indexOf (string, 0);
            if (index !is -1) {
                count = 1;
                indices = [index];
            }
        } else {
            int index = 0;
            while ((index = indexOf (string, index)) !is -1) {
                if (count is indices.length) {
                    int [] newIds = new int [indices.length + 4];
                    System.arraycopy (indices, 0, newIds, 0, indices.length);
                    indices = newIds;
                }
                indices [count++] = index;
                index++;
            }
        }
    }
    if (count > 0) {
        select (indices, count, true);
        showIndex (indices [0]);
    }
}

/**
 * Sets the zero-relative index of the item which is currently
 * at the top of the receiver. This index can change when items
 * are scrolled or new items are added and removed.
 *
 * @param index the index of the top item
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void setTopIndex (int index) {
    checkWidget();
    NSTableView widget = cast(NSTableView) view;
    int row = Math.max(0, Math.min(index, itemCount));
    NSPoint pt = NSPoint();
    pt.x = scrollView.contentView().bounds().x;
    pt.y = widget.frameOfCellAtColumn(0, row).y;
    view.scrollPoint(pt);
}

void showIndex (int index) {
    if (0 <= index && index < itemCount) {
        (cast(NSTableView)view).scrollRowToVisible(index);
    }
}

/**
 * Shows the selection.  If the selection is already showing in the receiver,
 * this method simply returns.  Otherwise, the items are scrolled until
 * the selection is visible.
 *
 * @exception DWTException <ul>
 *    <li>ERROR_WIDGET_DISPOSED - if the receiver has been disposed</li>
 *    <li>ERROR_THREAD_INVALID_ACCESS - if not called from the thread that created the receiver</li>
 * </ul>
 */
public void showSelection () {
    checkWidget();
    int index = getSelectionIndex ();
    if (index >= 0) showIndex (index);
}

void tableViewSelectionDidChange (objc.id id, objc.SEL sel, objc.id aNotification) {
    if (ignoreSelect) return;
    postEvent (DWT.Selection);
}

bool tableView_shouldEditTableColumn_row(objc.id id, objc.SEL sel, objc.id aTableView, objc.id aTableColumn, objc.id rowIndex) {
    return false;
}

objc.id tableView_objectValueForTableColumn_row(objc.id id, objc.SEL sel, objc.id aTableView, objc.id aTableColumn, objc.id rowIndex) {
    NSAttributedString attribStr = createString(items[cast(size_t)rowIndex], null, foreground, 0, true, false);
    return attribStr.id;
}

}
