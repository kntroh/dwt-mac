﻿/*******************************************************************************
 * Copyright (c) 2000, 2009 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *    IBM Corporation - initial API and implementation
 *
 * Port to the D programming language:
 *    Jacob Carlborg <doob@me.com>
 *******************************************************************************/
module dwt.internal.cocoa.NSTabViewItem;

import dwt.dwthelper.utils;
import cocoa = dwt.internal.cocoa.id;
import dwt.internal.cocoa.NSObject;
import dwt.internal.cocoa.NSString;
import dwt.internal.cocoa.NSView;
import dwt.internal.cocoa.OS;
import objc = dwt.internal.objc.runtime;

public class NSTabViewItem : NSObject {

public this() {
    super();
}

public this(objc.id id) {
    super(id);
}

public this(cocoa.id id) {
    super(id);
}

public cocoa.id initWithIdentifier(cocoa.id identifier) {
    objc.id result = OS.objc_msgSend(this.id, OS.sel_initWithIdentifier_, identifier !is null ? identifier.id : null);
    return result !is null ? new cocoa.id(result) : null;
}

public void setLabel(NSString label) {
    OS.objc_msgSend(this.id, OS.sel_setLabel_, label !is null ? label.id : null);
}

public void setView(NSView view) {
    OS.objc_msgSend(this.id, OS.sel_setView_, view !is null ? view.id : null);
}

}
