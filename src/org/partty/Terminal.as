/*
 * org.partty.Terminal
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

package org.partty
{

import flash.events.*;
import flash.utils.ByteArray;
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.BitmapData;
import flash.display.Bitmap;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.utils.IDataOutput;
import org.partty.WcWidth;

public class Terminal extends Sprite implements IDataOutput
{
	// XXX embed font
	//[Embed(source='M+2VM+IPAG-circle.ttf', fontName='mplus-ipa')]
	//private static const mPlusIPA:Class

	private var _screen:Array;  // Array of Array of TextCell

	private var curattr:uint = 0x70;  // current attribute

	private var cols:int = 0;       // cols by single character wide
	private var rows:int = 0;       // rows by single character wide
	private var ccol:int = 0;       // current col by single character wide
	private var crow:int = 0;       // current row by single character wide
	private var saved_col:int = 0;
	private var saved_row:int = 0;
	private var scrolltop:int;
	private var scrollbottom:int;

	private var _lineDirty:Array;      // Array of Boolean
	private var cursorDirty:Boolean;

	private var escapeSequence:ByteArray;
	private var escaped:Boolean = false;
	private var graphmode:Boolean = false;

	private var _drawBuffer:ByteArray;

	private var _decoderBuffer:ByteArray;

	private var ansiForegroundColors:Array;    // Array of RGB, length must be 7
	private var ansiBackgroundColors:Array;    // Array of RGB, length must be 7
	private var displayTextFormat:TextFormat;
	private var lineHeight:uint;
	private var cursorWidth:uint;
	private var calibrateFontWidth:uint;
	private var calibrateFontHeight:uint;
	private var lineGapFilling:uint;

	private var _fieldArray:Array;     // Array of TextField
	private var background:Bitmap;    // background bitmap
	private var cursorCanvas:Shape;   // canvas for drawing cursor

	private const ESCAPED_TEXT_MAX:uint = 128;
	private const MAX_CSI_ES_PARAMS:uint = 32;

	private var _wcwidth:WcWidth = new WcWidth();

	// IDataOutput interface
	private var _middleBuffer:ByteArray;

	/**
	 * Character code of input stream.
	 */
	public var charSet:String;

	/**
	 * Constructor.
	 * @param cols  Number of columns
	 * @param rows  Number of rows
	 */
	public function Terminal(col:uint = 80, row:uint = 20):void
	{
		super();

		_screen = new Array();
		_lineDirty = new Array();
		escapeSequence = new ByteArray();

		// default color setting
		ansiForegroundColors = [
				0x000000,  // black
				0xFF3214,  // red
				0x00FF00,  // green
				0xFFFF00,  // yellow
				0x6E6EFF,  // blue
				0xFF00FF,  // magenta
				0x00FFFF,  // cyan
				0xF0F0F0,  // normal
			];
		ansiBackgroundColors = [
				//0x1F1F1F,  // normal
				0x000000,  // normal
				0xFF3214,  // red
				0x00FF00,  // green
				0xFFFF00,  // yellow
				0x6E6EFF,  // blue
				0xFF00FF,  // magenta
				0x00FFFF,  // cyan
				0xFFFFFF,  // white
			];

		_fieldArray = new Array();
		background = new Bitmap();
		this.addChild(background);
		cursorCanvas = new Shape();   // cursorCanvas must be above background
		this.addChild(cursorCanvas);

		charSet = "utf-8";  // default charset
		lineGapFilling = 3; // FIXME

		displayTextFormat = new TextFormat();
		//displayTextFormat.font = "mplus-ipa";  // XXX embed font
		displayTextFormat.font = "_typewriter";
		displayTextFormat.kerning = false;
		displayTextFormat.size = 12;
		fontCalibration();

		_drawBuffer = new ByteArray();
		_decoderBuffer = new ByteArray();
		_middleBuffer = new ByteArray();

		resize(col, row);
	}

	/**
	 * Set console text format.
	 * @param format  The text format. <i>color</i> parameter is ignored.
	 *                Use setForegroundColors or setForegroundColor method instead.
	 */
	public function set textFormat(format:TextFormat):void
	{
		displayTextFormat = format;
		fontCalibration();
		adjustDisplay();
	}

	/**
	 * Get font size.
	 */
	public function get fontSize():Object
	{
		return displayTextFormat.size;
	}

	/**
	 * Set font size.
	 */
	public function set fontSize(value:Object):void
	{
		displayTextFormat.size = value;
		textFormat = displayTextFormat;
	}

	/**
	 * Get font family.
	 */
	public function get font():String
	{
		return displayTextFormat.font;
	}

	/**
	 * Set font family.
	 */
	public function set font(value:String):void
	{
		displayTextFormat.font = value;
		textFormat = displayTextFormat;
	}

	/**
	 * Set ANSI text colors.
	 * @param color8  Array of RGB color code whose length is 8
	 */
	public function set foregroundColors(color8:Array):void
	{
		ansiForegroundColors = color8;
	}

	/**
	 * Set ANSI background colors.
	 * @param color8  Array of RGB color code whose length is 8
	 */
	public function set backgroundColors(color8:Array):void
	{
		ansiBackgroundColors = color8;
	}

	/**
	 * Get ANSI text color.
	 * @param n      ANSI color code
	 */
	public function getForegroundColor(n:uint):uint
	{
		return ansiForegroundColors[n];
	}

	/**
	 * Set ANSI text color.
	 * @param n      ANSI color code
	 * @param color  RGB color code
	 */
	public function setForegroundColor(n:uint, color:uint):void
	{
		ansiForegroundColors[n] = color;
		refresh(true);  // force refresh
	}

	/**
	 * Get ANSI background color.
	 * @param n      ANSI color code
	 */
	public function getBackgroundColor(n:uint):uint
	{
		return ansiBackgroundColors[n];
	}

	/**
	 * Set ANSI background color.
	 * @param n      ANSI color code
	 * @param color  RGB color code
	 */
	public function setBackgroundColor(n:uint, color:uint):void
	{
		ansiBackgroundColors[n] = color;
		refresh(true);  // force refresh
	}

	/**
	 * Get number of columns
	 */
	public function get col():uint
	{
		return cols;
	}

	/**
	 * Set number of columns
	 */
	public function set col(n:uint):void
	{
		resize(n, rows);
	}

	/**
	 * Get number of rows
	 */
	public function get row():uint
	{
		return rows;
	}

	/**
	 * Set number of rows
	 */
	public function set row(n:uint):void
	{
		resize(cols, n);
	}

	/**
	 * Clear whole screen
	 */
	public function clear():void
	{
		var screen:Array = _screen;
		var lineDirty:Array = _lineDirty;
		curattr = attrReset();
		for(var r:uint = 0; r < rows; ++r) {
			lineDirty[r] = true;
			clearScreenRow(screen[r], curattr);
			
		}
		ccol = 0;
		crow = 0;
	}

	/**
	 * Resize the console size.
	 * @param newcols  Number of columns
	 * @param newrows  Number of rows
	 */
	public function resize(newcols:uint, newrows:uint):void
	{
		if( newcols <= 1 ) { newcols = 1; }
		if( newrows <= 1 ) { newrows = 1; }

		var screen:Array = _screen;
		var lineDirty:Array = _lineDirty;
		var fieldArray:Array = _fieldArray;

		screen.length = newrows;
		lineDirty.length = newrows;

		var r:int;
		var c:int;
		var tf:TextField;
		var sc:Array;

		if( rows < newrows ) {
			fieldArray.length = newrows;
			// expand rows
			for(r = rows; r < newrows; ++r) {
				sc = screen[r] = new Array();
				sc.length = cols;   // FIXME cols < newcols ? cols : newcols
				for(c = 0; c < cols; ++c) {
					sc[c] = new TextCell();
				}
				tf = fieldArray[r] = new TextField();
				tf.autoSize = TextFieldAutoSize.LEFT;
				tf.defaultTextFormat = displayTextFormat;
				tf.selectable = true;
				//tf.embedFonts = true;  // XXX embed font
				tf.x = 0;
				// tf.y will be set at adjustDisplay()
				addChild(tf);
			}
		} else if( rows > newrows ) {
			// reduce rows
			var redto:int = numChildren - (rows - newrows);
			for(r = numChildren-1; r >= redto; --r) {
				removeChildAt(r);
			}
		}

		if( cols < newcols ) {
			// expand cols
			for(r = 0; r < newrows; ++r) {
				sc = screen[r];
				sc.length = newcols;
				for(c = cols; c < newcols; ++c) {
					sc[c] = new TextCell();
				}
			}
		} else if( cols > newcols ) {
			// reduce cols
			for(r = 0; rows < newrows; ++r) {
				screen[r].length = newcols;
				// FIXME cut fieldArray[r] short?
			}
		}

		cols = newcols;
		rows = newrows;

		if( ccol >= cols ) { ccol = cols - 1; }
		if( crow >= rows ) { crow = rows - 1; }

		// FIXME
		scrolltop = 0;
		scrollbottom = rows - 1;

		adjustDisplay();
	}

	private function fontCalibration():void
	{
		var tf:TextField = new TextField();
		tf.width = 0;
		tf.height = 0;
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.defaultTextFormat = displayTextFormat;
		tf.text = "hj";
		calibrateFontWidth  = tf.width / 2 - 2;
		calibrateFontHeight = tf.height;
		lineHeight = tf.height - lineGapFilling;
	}

	private function adjustDisplay():void
	{
		var dwidth:Number  = calibrateFontWidth  * cols;
		var dheight:Number = lineHeight * rows + lineGapFilling;
		background.bitmapData = new BitmapData(
				dwidth,
				dheight,
				false,   // no transparent
				ansiBackgroundColors[0]  // fill with normal background color
				);
		//cursorCanvas.width = dwidth;
		//cursorCanvas.height = dheight;
		//this.width = dwidth;
		//this.height = dheight;
		var fieldArray:Array = _fieldArray;
		for(var r:uint = 0; r < rows; ++r) {
			fieldArray[r].y = lineHeight * r;
		}
		refresh(true);  // force refresh
	}


	/**
	 * refresh the console
	 * @param force  force redraw whole screen
	 */
	public function refresh(force:Boolean = false):void
	{
		var screen:Array = _screen;
		var lineDirty:Array = _lineDirty;
		var fieldArray:Array = _fieldArray;
		var drawBuffer:ByteArray = _drawBuffer;

		if(force) {
			for(var f:uint = 0; f < rows; ++f) {
				lineDirty[f] = true;
			}
		}

		var field:TextField;
		var attr:uint = screen[0][0];
		var attrStart:uint;

		drawBuffer.length = 0;
		for(var r:uint = 0; r < rows; ++r) {
			if( !lineDirty[r] ) { continue; }  // redraw only dirty lines
			lineDirty[r] = false;
			field = fieldArray[r];
			field.text = "";
			field.width = 0;
			attrStart = 0;
			for(var c:uint = 0; c < cols; ++c) {
				if( attr != screen[r][c].attr ) {
					attrStart += appendText(field, drawBuffer, attr, attrStart);
					attr = screen[r][c].attr;
				}
				drawBuffer.writeMultiByte(screen[r][c].text, "utf-8");
				if( screen[r][c].wide ) {
					++c;
				}
			}
			if( drawBuffer.length > 0 ) {
				appendText(field, drawBuffer, attr, attrStart);
			}
		}

		// draw cursor
		if( cursorDirty || force ) {
			cursorDirty = false;
			cursorCanvas.graphics.clear();
			// FIXME  cursor color
			var drow:int;
			var dcol:int;
			if( ccol >= cols ) {
				drow = (crow+1 < rows ? crow+1 : rows - 1);
				dcol = 0;
			} else {
				drow = crow;
				dcol = ccol;
			}
			cursorCanvas.graphics.beginFill(ansiForegroundColors[7], 1.0);
			cursorCanvas.graphics.drawRect(
					(this.width / cols - 0.01) * dcol + 2,
					lineHeight * drow + lineGapFilling,
					( screen[drow][dcol].wide ?
					  calibrateFontWidth * 2 - 2 :  // wide width
					  calibrateFontWidth ),
					lineHeight );
		}
	}

	private function appendText(field:TextField, buf:ByteArray, attr:uint, attrStart:uint):uint
	{
		buf.position = 0;
		var str:String = buf.readMultiByte(buf.length, "utf-8");
		buf.length = 0;

		if(str.length == 0) { return 0; }
	
		var textStart:Number = field.width;
	
		// FIXME copy?
		//var format:TextFormat = new TextFormat(displayTextFormat);
		var format:TextFormat = displayTextFormat;
		format.color = ansiForegroundColors[ attrForeground(attr) ];
	
		field.appendText(str);
		field.setTextFormat(format, attrStart, attrStart + str.length);
	
		var textEnd:Number = field.width;
	
		// draw background color
		background.bitmapData.fillRect(
				new Rectangle(
					textStart - 2,
					field.y + lineGapFilling,
					textEnd - textStart + 1,
					lineHeight
					),
				ansiBackgroundColors[ attrBackground(attr) ]
				);
	
		return str.length;
	}

	/**
	 * Writes the specified byte array to the console.
	 */
	public function writeBytes(bytes:ByteArray, offset:uint = 0, length:uint = 0):void
	{
		var decoder:ByteArray = _decoderBuffer;
		var c:String;
		var len:uint = (length != 0 ? length : bytes.length);
		for(var n:uint = 0; n < len; ++n) {
			var b:uint = bytes[n];
			if( escaped ) {
				// escape sequence
				escapeSequence.writeByte(b);
				tryInterpretEscapeSequence();
			} else if( decoder.length == 0 ) {
				if( b >= 1 && b <= 31 ) {
					// control character
					handleControlChar(b);
				} else if( b <= 0x7F ) {
					// single byte character
					if( b != 0 ) {  // ignore NULL
						c = String.fromCharCode(b); // FIXME
						// TODO: graphmode
						putNormalCharacter(c);
					}
				} else {
					// first byte of multibyte character
					decoder.writeByte(b);
				}
			} else {
				decoder.position = decoder.length;
				decoder.writeByte(b);
				try {
					decoder.position = 0;
					c = decoder.readMultiByte(decoder.length, charSet);
					if( c.length > 0 ) {
						// complete multibyte character
						decoder.length = 0;
						putNormalCharacter(c);
					}
				} catch (e:Error) {
					// insufficient data to complete multibyte character
				}
			}
		}
	}

	private function cursorLineDown():void
	{
		crow++;
		cursorDirty = true;
		if( crow <= scrollbottom ) { return; }

		var screen:Array = _screen;

		// must scroll the scrolling region up by 1 line, and put cursor on
		// last line of it
		crow = scrollbottom;

		var line:Array;
		// splice back of scroll bottom
		var outpos:Array = screen.splice(scrollbottom + 1);
		// splice scroll region
		var region:Array = screen.splice(scrolltop + 1);
		// pop scroll top
		var clearbuf:Array = screen.pop();
		// concat scroll region
		screen = _screen = screen.concat(region); // FIXME which is faster?
		//for each(line in region) { screen.push(line); }
		// push empty line
		clearScreenRow(clearbuf, 0);
		screen.push(clearbuf);
		// concat back of scroll bottom
		//screen = _screen = screen.concat(outpos); // FIXME which is faster?
		for each(line in outpos) { screen.push(line);}

		var lineDirty:Array = _lineDirty;
		for(var i:int = scrolltop; i <= scrollbottom; ++i) {
			lineDirty[i] = true;
		}
	}

	private function cursorLineUp():void
	{
		crow--;  // crow must be signed int
		cursorDirty = true;
		if( crow >= scrolltop ) { return; }

		var screen:Array = _screen;

		// must scroll the scrolling region up by 1 line, and put cursor on
		// first line of it
		crow = scrolltop;

		var line:Array;
		// splice back of scroll bottom
		var outpos:Array = screen.splice(scrollbottom + 1);
		// pop scroll bottom
		var clearbuf:Array = screen.pop();
		// splice scroll region
		var region:Array = screen.splice(scrolltop);
		// push empty line
		clearScreenRow(clearbuf, 0);
		screen.push(clearbuf);
		// concat back of scroll region
		screen = _screen = screen.concat(region); // FIXME which is faster?
		//for each(line in region) { screen.push(line); }
		// concat back of scroll bottom
		//screen = _screen = screen.concat(outpos); // FIXME which is faster?
		for each(line in outpos) { screen.push(line); }

		var lineDirty:Array = _lineDirty;
		for(var i:int = scrolltop; i <= scrollbottom; ++i) {
			lineDirty[i] = true;
		}
	}

	private function putNormalCharacter(c:String):void
	{
		var screen:Array = _screen;
		var wide:Boolean = isWideCharacter(c);
		if( ccol >= cols ) {
			cursorLineDown();
			screen = _screen;
			ccol = 0;
		} else if( wide && ccol+1 >= cols ) {
			screen[crow][ccol].wide = false;
			screen[crow][ccol].text = " ";
			cursorLineDown();
			screen = _screen;
			ccol = 0;
		}
		screen[crow][ccol].text = c;
		screen[crow][ccol].attr = curattr;
		_lineDirty[crow] = true;
		if( ccol > 0 && screen[crow][ccol-1].wide ) {
			screen[crow][ccol-1].wide = false;
			screen[crow][ccol-1].text = " ";
		}
		if( wide ) {
			screen[crow][ccol].wide = true;
			screen[crow][ccol+1].wide = false;
			//screen[crow][ccol+1].text = " ";
			ccol += 2;
		} else {
			if( screen[crow][ccol].wide ) {
				screen[crow][ccol].wide = false;
				screen[crow][ccol+1].wide = false;
			}
			ccol++;
		}
		cursorDirty = true;
	}


	// TODO
	private function putGraphmodeCharacter(c:String):void
	{
		// TODO
		putNormalCharacter(c);
	}

	private function handleControlChar(c:uint):void
	{
		switch (c) {
		case 0x0d:  // carriage return
			//trace("carriage return");
			ccol = 0;
			cursorDirty = true;
			return;
		case 0x0a:  // line feed
			trace("line feed");
			cursorLineDown();

			ccol = 0; // ?

			break;
		case 0x08:  // backspace
			if(ccol > 0) { ccol--; }
			cursorDirty = true;
			break;
		case 0x09:  // tab
			var t:uint = 8 - ccol % 8;
			if( t == 0 ) { t = 8; }
			while( t > 0 ) {
				putNormalCharacter(' ');
				--t;
			}
			break;
		case 0x1B:  // begin escape sequence (aborting previous one if any)
			newEscapeSequence();
			break;
		case 0x0E:  // enter graphical character mode
			graphmode = true;
			break;
		case 0x0F: // exit graphical character mode
			graphmode = false;
			break;
		case 0x9B:  // CSI character. Equivalent to ESC [
			newEscapeSequence();
			escapeSequence.writeByte(0x5b);  // '['
			break;
		case 0x18:  // these interrupt escape sequences
		case 0x1A:
			cancelEscapeSequence();
			break;
		case 0x07:  // bell
			// FIXME visual bell?
			break;
		default:
			trace("Unrecognized control char: " + c);
		}
	}

	private function tryInterpretEscapeSequence():void
	{
		var firstchar:uint = escapeSequence[0];
		var lastchar:uint = escapeSequence[escapeSequence.length-1];
		if( firstchar == 0x5b ) {  // '['
			// CSI escape sequence
			if(	(lastchar >= 0x61 && lastchar <= 0x7a) ||  // 'a' 'z'
					(lastchar >= 0x41 && lastchar <= 0x5a) ||  // 'A' 'Z'
					lastchar == 0x40 || lastchar == 0x60 ) {  // '@' '`'
				interpretCSI();
				cancelEscapeSequence();
			} else {
				// could not yet be parsed
				return;
			}
		} else if( firstchar == 0x5d ) {  // ']'
			// XTerm escape sequence
			if(lastchar == 0x07) {
				// TODO
				//trace("Ignoreing XTerm ES: " + escapeSequence.toString());
				cancelEscapeSequence();
			} else {
				// could not yet be parsed
				return;
			}
		} else {
//			trace("Unrecognized ES: " + escapeSequence.toString());
			cancelEscapeSequence();
		}
	}

	private function newEscapeSequence():void
	{
		escaped = true
		escapeSequence.length = 0;
	}

	private function cancelEscapeSequence():void
	{
		escaped = false;
		escapeSequence.length = 0;
	}

	private function interpretCSI():void
	{
		if( escapeSequence[1] == 0x3f ) {  // '?'
			/* private-mode CSI */
			trace("Ignoreing private-mode CSI");
			return;
		}

		var csiparam:Array = new Array();
		var len:uint = escapeSequence.length;

		// parse numeric parameters
		for(var n:uint = 1; n < len - 1; ++n) {
			var b:uint = escapeSequence[n];
			if( b == 0x3b ) {  // ';'
				if(csiparam.length >= MAX_CSI_ES_PARAMS) { return; }  // too long!
				csiparam.push(0);
			} else if( b >= 0x30 && b <= 0x39 ) {  // '0' '9'
				if( csiparam.length == 0 ) { csiparam.push(0); }
				csiparam.push( csiparam.pop() * 10 + b - 0x30 );  // '0'
			} else {
				break;
			}
		}
//		trace("csi " + escapeSequence + ": " + csiparam);

		var verb:uint = escapeSequence[escapeSequence.length-1];

		switch(verb) {
		case 0x6d:  // 'm'  it's a 'set attribute' sequence
			interpretCSI_SGR(csiparam);
			break;
		case 0x4a:  // 'J'  it's an 'erase display' sequence
			interpretCSI_ED(csiparam);
			break;
		case 0x48:  // 'H'  it's a 'move cursor' sequence
		case 0x66:  // 'f'
			interpretCSI_CUP(csiparam);
			break;
		case 0x41:  // 'A'  it is a 'relative move'
		case 0x42:  // 'B'
		case 0x43:  // 'C'
		case 0x44:  // 'D'
		case 0x45:  // 'E'
		case 0x46:  // 'F'
		case 0x47:  // 'G'
		case 0x65:  // 'e'
		case 0x61:  // 'a'
		case 0x64:  // 'd'
		case 0x60:  // '`'
			interpretCSI_C(verb, csiparam);
			break;
		case 0x4b:  // 'K'  erase line
			interpretCSI_EL(csiparam);
			break;
		case 0x40:  // '@'  insert characters
			interpretCSI_ICH(csiparam);
			break;
		case 0x50:  // 'P'  delete characters
			interpretCSI_DCH(csiparam);
			break;
		case 0x4c:  // 'L'  insert lines
			interpretCSI_IL(csiparam);
			break;
		case 0x4d:  // 'M'  delete lines
			interpretCSI_DL(csiparam);
			break;
		case 0x58:  // 'X'  erase characters
			interpretCSI_ECH(csiparam);
			break;
		case 0x72:  // 'r'  set scrolling region
			interpretCSI_DECSTBM(csiparam);
			break;
		case 0x73:  // 's'  save cursor location
			interpretCSI_SAVECUR(csiparam);
			break;
		case 0x75:  // 'u'  restore cursor location
			interpretCSI_RESTORECUR(csiparam);
			break;
		default:
			trace("Unrecognized CSI");
		}
	}

	// interprets a 'set attribute' (SGR) CSI escape sequence
	private function interpretCSI_SGR(param:Array):void
	{
		if(param.length == 0) {
			// special case: reset attributes
			curattr = attrReset();
			return;
		}

		// From http://vt100.net/docs/vt510-rm/SGR table 5-16
		// 0 	All attributes off
		// 1 	Bold
		// 4 	Underline
		// 5 	Blinking
		// 7 	Negative image
		// 8 	Invisible image
		// 10 	The ASCII character set is the current 7-bit
		//	display character set (default) - SCO Console only.
		// 11 	Map Hex 00-7F of the PC character set codes
		//	to the current 7-bit display character set
		//	- SCO Console only.
		// 12 	Map Hex 80-FF of the current character set to
		//	the current 7-bit display character set - SCO
		//	Console only.
		// 22 	Bold off
		// 24 	Underline off
		// 25 	Blinking off
		// 27 	Negative image off
		// 28 	Invisible image off
	
		var len:uint = param.length;
		for each(var p:uint in param) {
			if(p == 0) {  // reset
				curattr = attrReset();
			} else if( p == 1 || p == 2 || p == 4 ) {  // set bold
				curattr = attrModifyBold(curattr, true);
			} else if( p == 5 ) {  // set blink
				curattr = attrModifyBlink(curattr, true);
			} else if( p == 7 || p == 27 ) {  // reverse video
				var bg:uint = attrBackground(curattr);
				var fg:uint = attrForeground(curattr);
				curattr = attrModifyBackground(curattr, fg);
				curattr = attrModifyForeground(curattr, bg);
			} else if( p == 8 ) {  // invisible
				curattr = 0x0;  // FIXME
			} else if( p == 22 || p == 24 ) {  // bold off
				curattr = attrModifyBold(curattr, false);
			} else if( p == 25 ) {  // blink off
				curattr = attrModifyBlink(curattr, false);
			} else if( p == 28 ) {  // invisible off
				curattr = attrReset();
			} else if( p >= 30 && p <= 37 ) {  // set fg
				curattr = attrModifyForeground(curattr, p - 30);
			} else if( p == 38 ) {
				// TODO 256 background color
			} else if( p >= 40 && p <= 47 ) {  // set bg
				curattr = attrModifyBackground(curattr, p - 40);
			} else if( p == 38 ) {
				// TODO 256 background color
			} else if( p == 39 ) {  // reset foreground to default
				curattr = attrModifyForeground(curattr, 7);
			} else if( p == 49 ) {  // reset backspace to default
				curattr = attrModifyBackground(curattr, 0);
			}
		}
	}

	// interprets an 'erase display' (ED) escape sequence
	private function interpretCSI_ED(param:Array):void
	{
		var screen:Array = _screen;
		var lineDirty:Array = _lineDirty;
		var r:uint;
		var c:uint;
		var dcol:int;
		if( param.length > 0 && param[0] == 2 ) {
			// clear whole screen
			for(r = 0; r < rows; ++r) {
				lineDirty[r] = true;
				clearScreenRow(screen[r], curattr);
			}
		} else if( param.length > 0 && param[0] == 1 ) {
			// clear from origin to current cursor position
			for(r = 0; r < crow; ++r) {
				lineDirty[r] = true;
				clearScreenRow(screen[r], curattr);
			}
			lineDirty[crow] = true;
			dcol = (ccol < cols ? ccol : cols - 1);
			for(c = 0; c <= dcol; ++c) {
				screen[crow][c].clear(curattr);
			}
		} else {
			// clear from current cursor position to the end
			lineDirty[crow] = true;
			dcol = (ccol < cols ? ccol : cols - 1);
			for(c = 0; c <= dcol; ++c) {
				screen[crow][c].clear(curattr);
			}
			for(r = crow + 1; r < rows; ++r) {
				lineDirty[r] = true;
				clearScreenRow(screen[r], curattr);
			}
		}
	}

	// interprets a 'move cursor' (CUP) escape sequence
	private function interpretCSI_CUP(param:Array):void
	{
		if( param.length == 0 ) {
			// special case
			crow = ccol = 0;
			cursorDirty = true;
			return;
		} else if( param.length < 2 ) {  // malformed
			return;
		}
	
		crow = param[0] - 1;  // convert from 1-based to 0-based
		ccol = param[1] - 1;  // convert from 1-based to 0-based
	
		if( crow < 0 ) { crow = 0; }
		if( ccol < 0 ) { ccol = 0; }
		if( crow >= rows ) { crow = rows - 1; }
		if( ccol >= cols ) { ccol = cols - 1; }

		cursorDirty = true;
	}
	
	// Interpret the 'relative mode' sequences: CUU, CUD, CUF, CUB, CNL,
	// CPL, CHA, HPR, VPA, VPR, HPA
	private function interpretCSI_C(verb:uint, param:Array):void
	{
		var n:int = (param.length > 0 && param[0] > 0) ? param[0] : 1;
		switch(verb) {
		case 0x41:  // 'A'
			crow -= n;
			if( crow < 0 ) { crow = 0; }
			break;
		case 0x42:  // 'B'
		case 0x65:  // 'e'
			crow += n;
			if( crow >= rows ) { crow = rows - 1; }
			break;
		case 0x43:  // 'C'
		case 0x61:  // 'a'
			ccol += n;
			if( ccol >= cols ) { ccol = cols - 1; }
			break;
		case 0x44:  // 'D'
			ccol -= n;
			if( ccol < 0 ) { ccol = 0; }
			break;
		case 0x45:  // 'E'
			crow += n;
			ccol = 0;
			if( crow >= rows ) { crow = rows - 1; }
			break;
		case 0x46:  // 'F'
			crow -= n;
			ccol = 0;
			if( crow < 0 ) { crow = 0; }
			break;
		case 0x47:  // 'G'
		case 0x60:  // '`'
			ccol = param[0] - 1;
			if( ccol < 0 ) { ccol = 0; }
			if( ccol >= cols ) { ccol = cols - 1; }
			break;
		case 0x64: // 'd'
			crow = param[0] - 1;
			if( crow < 0 ) { crow = 0; }
			if( crow >= rows ) { crow = rows - 1; }
			break;
		}
	
		cursorDirty = true;
	}

	// Interpret the 'erase line' escape sequence
	private function interpretCSI_EL(param:Array):void
	{
		var screen:Array = _screen;
		var cmd:int = param.length > 0 ? param[0] : 0;
		var c:int;
		switch(cmd) {
		case 1:
			var dcol:int = (ccol < cols ? ccol : cols - 1);
			for(c = 0; c <= dcol; ++c) {
				screen[crow][c].clear(curattr);
			}
			break;
		case 2:
			clearScreenRow(screen[crow], curattr);
			break;
		default:
			for(c = ccol; c < cols; ++c) {  // FIXME dcol?
				screen[crow][c].clear(curattr);
			}
			break;
		}
		_lineDirty[crow] = true;
	}
	
	// Interpret the 'insert blanks' sequence (ICH)
	private function interpretCSI_ICH(param:Array):void
	{
		var screen:Array = _screen;

		var n:int = (param.length > 0 && param[0] > 0) ? param[0] : 1;
		var c:int;
		var dcol:int = (ccol < cols ? ccol : cols - 1);

		var poped:Array = screen[crow].splice(dcol + n);
		var range:Array = screen[crow].splice(dcol);
		for each(var cell:TextCell in poped) { cell.clear(); }
		screen[crow] = screen[crow].concat(poped);
		screen[crow] = screen[crow].concat(range);

		_lineDirty[crow] = true;
	}
	
	// Interpret the 'delete chars' sequence (DCH)
	private function interpretCSI_DCH(param:Array):void
	{
		var screen:Array = _screen;
		var dcol:int = (ccol < cols ? ccol : cols - 1);

		var n:int = (param.length > 0 && param[0] > 0) ? param[0] : 1;
		var range:Array = screen[crow].splice(cols - n);
		var poped:Array = screen[crow].splice(dcol);
		for each(var cell:TextCell in poped) { cell.clear(); }
		screen[crow] = screen[crow].concat(poped);
		screen[crow] = screen[crow].concat(range);

		var c:int;
		for(c = dcol; c < cols - n; ++c) {
			screen[crow][c].copy( screen[crow][c + n] );
		}
		for(c = cols - n; c < cols; ++c) {
			screen[crow][c].clear(curattr);
		}
		_lineDirty[crow] = true;
	}
	
	// Interpret an 'insert line' sequence (IL)
	private function interpretCSI_IL(param:Array):void
	{
		var screen:Array = _screen;

		var n:int = (param.length > 0 && param[0] > 0) ? param[0] : 1;
	
		var line:Array;
		// splice back of scroll bottom
		var outpos:Array = screen.splice(scrollbottom + 1);
		// pop n lines
		var poped:Array = screen.splice(scrollbottom - n + 1);
		// splice crow and back of crow
		var post:Array = screen.splice(crow);
		// insert n lines
		for each(line in poped) {  // clear the lines
			for each(var cell:TextCell in line) {
				cell.clear(curattr);
			}
		}
		for each(line in poped) { screen.push(line); }
		// concat back of crow
		screen = _screen = screen.concat(post); // FIXME which is faster?
		//for each(line in post) { screen.push(line); }
		// concat back of scroll bottom
		//screen = _screen = screen.concat(outpos); // FIXME which is faster?
		for each(line in outpos) { screen.push(line); }
	
		var lineDirty:Array = _lineDirty;
		for(var r:int = crow; r <= scrollbottom; ++r) {
			lineDirty[r] = true;
		}
	}
	
	// Interpret a 'delete line' sequence (DL)
	private function interpretCSI_DL(param:Array):void
	{
		var screen:Array = _screen;

		var n:int = (param.length > 0 && param[0] > 0) ? param[0] : 1;
	
		var line:Array;
		// splice back of scroll bottom
		var outpos:Array = screen.splice(scrollbottom + 1);
		// splice back of n lines
		var region:Array = screen.splice(crow + n);
		// pop n lines
		var poped:Array = screen.splice(crow);
		// concat back of n lines
		screen = _screen = screen.concat(region); // FIXME which is faster?
		//for each(line in region) { screen.push(line); }
		// insert n empty lines
		for each(line in poped) {  // clear the lines
			for each(var c:TextCell in line) {
				c.clear(curattr);
			}
		}
		screen = _screen = screen.concat(poped); // FIXME which is faster?
		//for each(line in poped) { screen.push(line); }
		// concat back of scroll bottom
		//screen = _screen = screen.concat(outpos); // FIXME which is faster?
		for each(line in outpos) { screen.push(line); }
	
		var lineDirty:Array = _lineDirty;
		for(var r:int = crow; r <= scrollbottom; ++r) {
			lineDirty[r] = true;
		}
	}
	
	// Interpret an 'erase characters' (ECH) sequence
	private function interpretCSI_ECH(param:Array):void
	{
		var screen:Array = _screen;

		var n:int = (param.length > 0 && param[0] > 0) ? param[0] : 1;
		for(var c:int = ccol; c < ccol + n && c < cols; ++c) {
			screen[crow][c].clear(curattr);
		}
		_lineDirty[crow] = true;
	}
	
	// Interpret a 'set scrolling region' (DECSTBM) sequence
	private function interpretCSI_DECSTBM(param:Array):void
	{
		var newtop:int;
		var newbottom:int;
	
		if( param.length == 0 ) {
			newtop = 0;
			newbottom = rows - 1;
		} else if( param.length < 2 ) {  // malformed
			return;
		} else {
			newtop = param[0] - 1;
			newbottom = param[1] - 1;
		}
	
		// clamp to bounds
		if (newtop < 0) { newtop = 0; }
		if (newtop >= rows) { newtop = rows - 1; }
		if (newbottom < 0) { newbottom = 0; }
		if (newbottom >= rows) { newbottom = rows - 1; }
	
		// check for range validity
		if( newtop > newbottom ) { return; }
		scrolltop = newtop;
		scrollbottom = newbottom;
	}
	
	private function interpretCSI_SAVECUR(param:Array):void
	{
		saved_col = ccol;
		saved_row = crow;
	}
	
	private function interpretCSI_RESTORECUR(param:Array):void
	{
		ccol = saved_col;
		crow = saved_row;
		cursorDirty = true;
	}


	private function isWideCharacter(c:String):Boolean
	{
		return WcWidth.mk_wcwidth_cjk(c.charCodeAt(0)) >= 2;
	}


	private static function clearScreenRow(row:Array, fillattr:uint = 0):void
	{
		for each(var r:TextCell in row) {
			r.clear(fillattr);
		}
	}
	
	private static function attrModifyBackground(attr:uint, newbg:uint):uint
	{
		attr &= 0xF8;
		attr |= newbg;
		return attr;
	}
	private static function attrModifyForeground(attr:uint, newfg:uint):uint
	{
		attr &= 0x8F;
		attr |= (newfg << 4);
		return attr;
	}
	private static function attrModifyBold(attr:uint, enable:Boolean):uint
	{
		attr &= 0x7F;
		if(enable) { attr |= 0x80; }
		return attr;
	}
	private static function attrModifyBlink(attr:uint, enable:Boolean):uint
	{
		attr &= 0xF7;
		if(enable) { attr |= 0x08; }
		return attr;
	}
	private static function attrReset():uint
	{
		return 0x70;
	}
	private static function attrBackground(attr:uint):uint
	{
		return (attr & 0x07);
	}
	private static function attrForeground(attr:uint):uint
	{
		return ((attr & 0x70) >> 4);
	}
	private static function attrIsBold(attr:uint):Boolean
	{
		return (attr & 0x80) != 0;
	}
	private static function attrIsBlink(attr:uint):Boolean
	{
		return (attr & 0x08) != 0;
	}



	/**
	 * IDataOutput interface
	 */
	public function set objectEncoding(value:uint):void
	{
		_middleBuffer.objectEncoding = value;
	}
	public function get objectEncoding():uint
	{
		return _middleBuffer.objectEncoding;
	}

	public function set endian(value:String):void
	{
		_middleBuffer.endian = value;
	}
	public function get endian():String
	{
		return _middleBuffer.endian;
	}

	public function writeBoolean(value:Boolean):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeBoolean(value);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeByte(value:int):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeByte(value);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeDouble(value:Number):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeDouble(value);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeFloat(value:Number):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeFloat(value);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeInt(value:int):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeInt(value);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeMultiByte(value:String, charSet:String):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeMultiByte(value, charSet);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeObject(object:*):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeObject(object);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeShort(value:int):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeShort(value);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeUnsignedInt(value:uint):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeUnsignedInt(value);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeUTF(value:String):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeUTF(value);
		writeBytes(buffer);
		buffer.length = 0;
	}

	public function writeUTFBytes(value:String):void
	{
		var buffer:ByteArray = _middleBuffer;
		buffer.writeUTFBytes(value);
		writeBytes(buffer);
		buffer.length = 0;
	}

}


}  // package


import flash.utils.ByteArray;

class TextCell {
	public var text:String;   // single multibyte character
	public var buffer:ByteArray;   // multibyte character construction buffer

	public var attr:uint = 0x70;      // text color
	public var flags:uint = 0;     // multibyte flags
	public var wide:Boolean;

	public function TextCell():void
	{
		text = " ";
		wide = false;
		buffer = new ByteArray();
	}

	public function clear(fillattr:uint = 0):void
	{
		text = " ";
		wide = false;
		buffer.length = 0;
		attr = fillattr;
		flags = 0;
	}

	public function copy(other:TextCell):void
	{
		text = other.text;      // text does not need deep-copy
		wide = other.wide;      // wide is also
		buffer.length = 0;      // buffer needs deep copy
		for(var c:uint; c < other.buffer.length; ++c) {
			buffer.writeByte( other.buffer[c] );
		}
		attr = other.attr;
		flags = other.attr;
	}
}

