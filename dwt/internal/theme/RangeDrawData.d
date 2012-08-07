﻿/*******************************************************************************
 * Copyright (c) 2000, 2006 IBM Corporation and others.
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
module dwt.internal.theme.RangeDrawData;

import dwt.dwthelper.utils;

import dwt.graphics.*;

import dwt.internal.theme.DrawData;

public class RangeDrawData : DrawData {
    public int selection;
    public int minimum;
    public int maximum;

int getSelection(Point position, Rectangle bounds) {
    return 0;
}

}
