/*******************************************************************************
 * Copyright (c) 2007, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *******************************************************************************/

module dwt.internal.cocoa.CGPathElement;

import dwt.dwthelper.utils;
import dwt.internal.cocoa.CGPoint;
import dwt.internal.objc.cocoa.Cocoa;

public struct CGPathElement {
    /** @field cast=(CGPathElementType) */
    public CGPathElementType type;
    /** @field cast=(CGPoint *) */
    public CGPoint* points;
    //public static final int sizeof = OS.CGPathElement_sizeof();
}
