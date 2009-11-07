/*
 * org.partty.mxml.Terminal
 *
 * Copyright (C) 2007-2008 FURUHASHI Sadayuki
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.partty.mxml
{

import flash.utils.ByteArray;
import flash.utils.IDataOutput;
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.text.TextFormat;
import mx.core.UIComponent;
import mx.events.*;
import org.partty.Terminal;

public class Terminal extends UIComponent implements IDataOutput
{
	private var _term:org.partty.Terminal;
	private var _dataProvider:Object;
	private var _buffer:ByteArray;

	public function Terminal():void
	{
		super();
		_buffer = new ByteArray();
		_term = new org.partty.Terminal();
		this.width = _term.width;
		this.height = _term.height;
		addChild(_term);
	}

	public function set dataProvider(object:Object):void
	{
		if(_dataProvider) {
			_dataProvider.removeEventListner(
					ProgressEvent.PROGRESS, dataHandler);
		}
		object.addEventListener(ProgressEvent.PROGRESS, dataHandler);
		_dataProvider = object;
	}

	private function dataHandler(event:ProgressEvent):void
	{
		trace("ProgressEvent Now!");
		var buffer:ByteArray = _buffer;
		event.target.readBytes(buffer);
		writeBytes(buffer);
		refresh();
		buffer.length = 0;
	}

	private function changed():void
	{
		var event:Event = new Event(flash.events.Event.CHANGE);
		dispatchEvent(event);
	}

	private function resized():void
	{
		this.width = _term.width;
		this.height = _term.height;
	}

	public function clear():void
	{
		_term.clear();
		refresh();
	}

	[Bindable]
	public function get charSet():String
		{ return _term.charSet; }
	public function set charSet(charset:String):void
		{ _term.charSet = charset; }

	public function set textFormat(format:TextFormat):void
		{ _term.textFormat = format; resized(); }

	[Bindable]
	public function get fontSize():Number
		{ return Number(_term.fontSize); }
	public function set fontSize(value:Number):void
		{ _term.fontSize = value as Object; resized(); }

	[Bindable]
	public function get font():String
		{ return _term.font; }
	public function set font(value:String):void
		{ _term.font= value; resized(); }

	public function set foregroundColors(color8:Array):void
		{ _term.foregroundColors = color8; }
	public function set backgroundColors(color8:Array):void
		{ _term.backgroundColors = color8; }
	public function setForegroundColor(n:uint, color:uint):void
		{ _term.setForegroundColor(n, color); }
	public function setBackgroundColor(n:uint, color:uint):void
		{ _term.setBackgroundColor(n, color); }

	[Bindable]
	public function get ansiForegroundBlack():uint
		{ return _term.getForegroundColor(0); }
	[Bindable]
	public function get ansiForegroundRed():uint
		{ return _term.getForegroundColor(1); }
	[Bindable]
	public function get ansiForegroundGreen():uint
		{ return _term.getForegroundColor(2); }
	[Bindable]
	public function get ansiForegroundYellow():uint
		{ return _term.getForegroundColor(3); }
	[Bindable]
	public function get ansiForegroundBlue():uint
		{ return _term.getForegroundColor(4); }
	[Bindable]
	public function get ansiForegroundMagenta():uint
		{ return _term.getForegroundColor(5); }
	[Bindable]
	public function get ansiForegroundCyan():uint
		{ return _term.getForegroundColor(6); }
	[Bindable]
	public function get ansiForegroundNormal():uint
		{ return _term.getForegroundColor(7); }

	public function set ansiForegroundBlack(color:uint):void
		{ _term.setForegroundColor(0, color); changed(); }
	public function set ansiForegroundRed(color:uint):void
		{ _term.setForegroundColor(1, color); changed(); }
	public function set ansiForegroundGreen(color:uint):void
		{ _term.setForegroundColor(2, color); changed(); }
	public function set ansiForegroundYellow(color:uint):void
		{ _term.setForegroundColor(3, color); changed(); }
	public function set ansiForegroundBlue(color:uint):void
		{ _term.setForegroundColor(4, color); changed(); }
	public function set ansiForegroundMagenta(color:uint):void
		{ _term.setForegroundColor(5, color); changed(); }
	public function set ansiForegroundCyan(color:uint):void
		{ _term.setForegroundColor(6, color); changed(); }
	public function set ansiForegroundNormal(color:uint):void
		{ _term.setForegroundColor(7, color); changed(); }

	[Bindable]
	public function get ansiBackgroundNormal():uint
		{ return _term.getBackgroundColor(0); }
	[Bindable]
	public function get ansiBackgroundRed():uint
		{ return _term.getBackgroundColor(1); }
	[Bindable]
	public function get ansiBackgroundGreen():uint
		{ return _term.getBackgroundColor(2); }
	[Bindable]
	public function get ansiBackgroundYellow():uint
		{ return _term.getBackgroundColor(3); }
	[Bindable]
	public function get ansiBackgroundBlue():uint
		{ return _term.getBackgroundColor(4); }
	[Bindable]
	public function get ansiBackgroundMagenta():uint
		{ return _term.getBackgroundColor(5); }
	[Bindable]
	public function get ansiBackgroundCyan():uint
		{ return _term.getBackgroundColor(6); }
	[Bindable]
	public function get ansiBackgroundWhite():uint
		{ return _term.getBackgroundColor(7); }

	public function set ansiBackgroundNormal(color:uint):void
		{ _term.setBackgroundColor(0, color); changed(); }
	public function set ansiBackgroundRed(color:uint):void
		{ _term.setBackgroundColor(1, color); changed(); }
	public function set ansiBackgroundGreen(color:uint):void
		{ _term.setBackgroundColor(2, color); changed(); }
	public function set ansiBackgroundYellow(color:uint):void
		{ _term.setBackgroundColor(3, color); changed(); }
	public function set ansiBackgroundBlue(color:uint):void
		{ _term.setBackgroundColor(4, color); changed(); }
	public function set ansiBackgroundMagenta(color:uint):void
		{ _term.setBackgroundColor(5, color); changed(); }
	public function set ansiBackgroundCyan(color:uint):void
		{ _term.setBackgroundColor(6, color); changed(); }
	public function set ansiBackgroundWhite(color:uint):void
		{ _term.setBackgroundColor(7, color); changed(); }

	public function resize(cols:uint, rows:uint):void
		{ _term.resize(cols, rows); changed(); resized(); }

	[Bindable]
	public function get col():uint
		{ return _term.col; }
	public function set col(n:uint):void
		{ _term.col = n; changed(); resized(); }

	[Bindable]
	public function get row():uint
		{ return _term.row; }
	public function set row(n:uint):void
		{ _term.row = n; changed(); resized(); }

	public function refresh(force:Boolean = false):void
		{ _term.refresh(force); changed(); }

	public function set objectEncoding(value:uint):void
		{ _term.objectEncoding = value; }
	public function get objectEncoding():uint
		{ return _term.objectEncoding }

	public function set endian(value:String):void
		{ _term.endian = value; }
	public function get endian():String
		{ return _term.endian; }

	public function writeBytes(bytes:ByteArray, offset:uint = 0, length:uint = 0):void
		{ _term.writeBytes(bytes, offset, length); }
	public function writeBoolean(value:Boolean):void
		{ _term.writeBoolean(value); }
	public function writeByte(value:int):void
		{ _term.writeByte(value); }
	public function writeDouble(value:Number):void
		{ _term.writeDouble(value); }
	public function writeFloat(value:Number):void
		{ _term.writeFloat(value); }
	public function writeInt(value:int):void
		{ _term.writeInt(value); }
	public function writeMultiByte(value:String, charSet:String):void
		{ _term.writeMultiByte(value, charSet); }
	public function writeObject(object:*):void
		{ _term.writeObject(object); }
	public function writeShort(value:int):void
		{ _term.writeShort(value); }
	public function writeUnsignedInt(value:uint):void
		{ _term.writeUnsignedInt(value); }
	public function writeUTF(value:String):void
		{ _term.writeUTF(value); }
	public function writeUTFBytes(value:String):void
		{ _term.writeUTFBytes(value); }
}


}

