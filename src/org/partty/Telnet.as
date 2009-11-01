/*
 * org.partty.Telnet
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
import flash.net.Socket;
import flash.utils.ByteArray;
import flash.utils.IDataOutput;

public class Telnet extends EventDispatcher implements IDataOutput
{
	private var _socket:Socket;
	private var _buffer:ByteArray;
	private var _active:Boolean = false;

	private static const IAC:uint  = 255;  // interrupt as command
	private static const WILL:uint = 251;  // I will use option
	private static const WONT:uint = 252;  // I won't use option
	private static const DO:uint   = 253;  // please, you use option
	private static const DONT:uint = 254;  // you are not to use option
	private static const SB:uint   = 250;  // interrupt as subnegotiation
	private static const SE:uint   = 240;  // end subnegotiation

	private static const SB_MAX_LENGTH:uint = 1024;  // FIXME

	private var _istate:Function;

	private var _partnerOptionHandler:Array;
	private var _myOptionHandler:Array;
	private var _sbHandler:Array;
	private var _waitingWill:WaitingFlags;
	private var _waitingDo:WaitingFlags;
	private var _sbCommand:uint;
	private var _sbBuffer:ByteArray;

	// IDataOutput interface
	private var _middleBuffer:ByteArray;

	public function Telnet()
	{
		_buffer = new ByteArray();
		_middleBuffer = new ByteArray();

		_partnerOptionHandler = new Array();
		_partnerOptionHandler.length = 256;
		_myOptionHandler = new Array();
		_myOptionHandler.length = 256;
		_sbHandler = new Array();
		_sbHandler.length = 256;
		_waitingWill = new WaitingFlags();
		_waitingDo = new WaitingFlags();
		_sbBuffer = new ByteArray();
		_sbBuffer.endian = "bigEndian";

		_istate = istateNormal;

		_socket = new Socket();
		_socket.addEventListener(Event.CONNECT, connectHandler);
		_socket.addEventListener(Event.CLOSE, closeHandler);
		_socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		_socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);

		// local/remote SGA, remote ECHO and local/remote BINARY option are supoprted by default
		setPartnerOptionHandler(OPT_SGA, optionPassThroughHandler);
		setMyOptionHandler(OPT_SGA, optionPassThroughHandler);
		setPartnerOptionHandler(OPT_ECHO, optionPassThroughHandler);
		setMyOptionHandler(OPT_BINARY, optionPassThroughHandler);
		setPartnerOptionHandler(OPT_BINARY, optionPassThroughHandler);
	}

	public function connect(host:String, port:int):void
	{
		try {
			_socket.connect(host, port);
			_active = true;
		} catch (error:Error) {
			_socket.close();
			var event:IOErrorEvent = new IOErrorEvent(
					IOErrorEvent.IO_ERROR,
					false,
					false,
					"failed connect to " + host + ":" + port
					);
			dispatchEvent(event);
		}
	}

	public function close():void
	{
		_socket.close();
		_active = false;
	}

	public function get bytesAvailable():uint
	{
		return _buffer.length;
	}

	public function readBytes(bytes:ByteArray, offset:uint = 0):void
	{
		var buffer:ByteArray = _buffer;
		buffer.position = 0;
		buffer.readBytes(bytes, offset, 0);
		buffer.length = 0;
	}


	public function writeByte(value:int):void
	{
		if( !_active ) { return; }
		if( value == IAC ) {
			_socket.writeByte(value);
			_socket.writeByte(value);
		} else {
			_socket.writeByte(value);
		}
		_socket.flush();
	}

	public function writeBytes(bytes:ByteArray, offset:uint = 0, length:uint = 0):void {
		if( !_active ) { return; }
		_socket.writeBytes(bytes, offset, length);
		_socket.flush();
		// FIXME convert IAC to IAC IAC
	}

	/**
	 * @param handler  handler(cmd:uint, sw:Boolean, telnet:Telnet):void
	 */
	public function setPartnerOptionHandler(cmd:uint, handler:Function):void
	{
		_partnerOptionHandler[cmd] = handler;
	}

	/**
	 * @param handler  handler(cmd:uint, sw:Boolean, telnet:Telnet):void
	 */
	public function setMyOptionHandler(cmd:uint, handler:Function):void
	{
		_myOptionHandler[cmd] = handler;
	}

	/**
	 * @param handler  handler(cmd:uint, args:ByteArray, telnet:Telnet):void
	 */
	public function setSbHandler(cmd:uint, handler:Function):void
	{
		_sbHandler[cmd] = handler;
	}


	private function connectHandler(event:Event):void
	{
		dispatchEvent(event);
	}

	private function closeHandler(event:Event):void
	{
		close();
		dispatchEvent(event);
	}

	private function ioErrorHandler(event:IOErrorEvent):void
	{
		close();
		dispatchEvent(event);
	}

	private function securityErrorHandler(event:SecurityErrorEvent):void
	{
		close();
		dispatchEvent(event);
	}


	private function socketDataHandler(event:ProgressEvent):void
	{
		var socket:Socket = _socket;
		var beforeLength:uint = _buffer.length;

		var n:int = socket.bytesAvailable;
		while(--n >= 0) { 
			_istate(socket.readUnsignedByte());
		}

		var ev:Event = new ProgressEvent(
				ProgressEvent.PROGRESS,
				false,
				false,
				_buffer.length - beforeLength,
				_buffer.length
				);
		dispatchEvent(ev);
	}

	private function istateNormal(c:uint):void
	{
		switch(c) {
		case IAC:
			_istate = istateIAC;
			break;
		default:
			_buffer.writeByte(c);
			break;
		}
	}

	private function istateIAC(c:uint):void
	{
		switch(c) {
		case IAC:
			// IAC-escaped IAC. write one IAC
			_buffer.writeByte(IAC);
			_istate = istateNormal;
			break;
		case WILL:
			_istate = istateWill;
			break;
		case WONT:
			_istate = istateWont;
			break;
		case DO:
			_istate = istateDo;
			break;
		case DONT:
			_istate = istateDont;
			break;
		case SB:
			// subnegotiation
			_istate = istateSb;
			break;
		// FIXME there are many other telnet commands ...
		//       NO, DM, AYT, ...
		default:
			// broken or non-supported protocol
			_buffer.writeByte(IAC);
			_buffer.writeByte(c);
			_istate = istateNormal;
			break;
		}
	}


	private function istateWill(c:uint):void
	{
		trace("will " + c);
		if( _waitingWill.test(c) ) {
			// do (or maybe dont) is sent and receive will
			// the partner can use the option
			_waitingWill.reset(c);
			if( _partnerOptionHandler[c] ) {
				_partnerOptionHandler[c](c, true, this);
			}
		} else {
			// the partner wants to use the option
			if( _partnerOptionHandler[c] ) {
				// the option is acceptable
				// the partner can use the option
				// reply DO
				_partnerOptionHandler[c](c, true, this);
				owrite3(IAC, DO, c);
			} else {
				// the option is not acceptable
				// reply DONT
				owrite3(IAC, DONT, c);
			}
		}
		_istate = istateNormal;
	}

	private function istateWont(c:uint):void
	{
		trace("wont " + c);
		if( _waitingWill.test(c) ) {
			// do or dont is sent and receive wont
			// the partner can't use the option
			_waitingWill.reset(c);
		} else {
			// I am required not to use the option
			// I can't use the option
			// reply wont
			if( _partnerOptionHandler[c] ) {
				_partnerOptionHandler[c](c, false, this);
			}
			owrite3(IAC, WONT, c);
		}
		_istate = istateNormal;
	}

	private function istateDo(c:uint):void
	{
		trace("do " + c);
		if( _waitingDo.test(c) ) {
			// will (or maybe wont) is sent and receive do
			// I can use the option
			_waitingDo.reset(c);
			if( _myOptionHandler[c] ) {
				_myOptionHandler[c](c, true, this);
			}
		} else {
			// I am required to use use the option
			if( _myOptionHandler[c] ) {
				// I support the option
				// I can use the option
				// reply will
				_myOptionHandler[c](c, true, this);
				owrite3(IAC, WILL, c);
			} else {
				// I don't support the option
				// reply wont
				owrite3(IAC, WONT, c);
			}
		}
		_istate = istateNormal;
	}

	private function istateDont(c:uint):void
	{
		trace("dont " + c);
		if( _waitingDo.test(c) ) {
			// will is sent and receive dont
			// I can't use the option
			_waitingDo.reset(c);
			if( _myOptionHandler[c] ) {
				_myOptionHandler[c](c, false, this);
			}
		} else {
			// the partner wants not to use the option
			// the partner can't use the option
			// reply dont
			if( _myOptionHandler[c] ) {
				_myOptionHandler[c](c, false, this);
			}
			owrite3(IAC, WONT, c);
		}
		_istate = istateNormal;
	}

	public function istateSb(c:uint):void
	{
		trace("sb " + c);
		_sbCommand = c;
		_sbBuffer.length = 0;
		_istate = istateSbMessage;
	}

	public function istateSbMessage(c:uint):void
	{
		if( c == IAC ) {
			_istate = istateSbMeessageIAC;
		} else {
			if( _sbBuffer.length > SB_MAX_LENGTH ) {
				// subnegotiation is too long
				_istate = istateNormal;
			} else {
				_sbBuffer.writeByte(c);
			}
		}
	}

	public function istateSbMeessageIAC(c:uint):void
	{
		if( c == IAC ) {
			// IAC-escaped IAC. write one IAC
			if( _sbBuffer.length > SB_MAX_LENGTH ) {
				// subnegotiation is too long
				_istate = istateNormal;
			} else {
				_buffer.writeByte(c);
				_istate = istateSbMessage;
			}
		} else if( c == SE ) {
			// end of subnegotiation
			if( _sbHandler[_sbCommand] ) {
				_sbBuffer.position = 0;
				_sbHandler[_sbCommand](
						_sbCommand,
						_sbBuffer,
						this );
			}
			_istate = istateNormal;
		}
	}

	private function owrite1(c1:uint):void
	{
		_socket.writeByte(c1);
	}
	private function owrite2(c1:uint, c2:uint):void
	{
		_socket.writeByte(c1);
		_socket.writeByte(c2);
	}
	private function owrite3(c1:uint, c2:uint, c3:uint):void
	{
		_socket.writeByte(c1);
		_socket.writeByte(c2);
		_socket.writeByte(c3);
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


	private static function optionPassThroughHandler(cmd:uint, sw:Boolean, telnet:Telnet):void
	{ }

	public static const GA:uint		= 249;  // you may reverse the line
	public static const EL:uint		= 248;  // erase the current line
	public static const EC:uint		= 247;  // erase the current byteacter
	public static const AYT:uint		= 246;  // are you there
	public static const AO:uint		= 245;  // abort output--but let prog finish
	public static const IP:uint		= 244;  // interrupt process--permanently
	public static const BREAK:uint		= 243;  // break
	public static const DM:uint		= 242;  // data mark--for connect. cleaning
	public static const NOP:uint		= 241;  // nop
	public static const EOR:uint		= 239;  // end of record (transparent mode)
	public static const ABORT:uint		= 238;  // Abort process
	public static const SUSP:uint		= 237;  // Suspend process
	public static const xEOF:uint		= 236;  // End of file: EOF is already used...

	public static const OPT_BINARY:uint	=   0;  // 8-bit data path
	public static const OPT_ECHO:uint	=   1;  // echo
	public static const OPT_RCP:uint	=   2;  // prepare to reconnect
	public static const OPT_SGA:uint	=   3;  // suppress go ahead
	public static const OPT_NAMS:uint	=   4;  // approximate message size
	public static const OPT_STATUS:uint	=   5;  // give status
	public static const OPT_TM:uint		=   6;  // timing mark
	public static const OPT_RCTE:uint	=   7;  // remote controlled transmission and echo
	public static const OPT_NAOL:uint	=   8;  // negotiate about output line width
	public static const OPT_NAOP:uint 	=   9;  // negotiate about output page size
	public static const OPT_NAOCRD:uint	=  10;  // negotiate about CR disposition
	public static const OPT_NAOHTS:uint	=  11;  // negotiate about horizontal tabstops
	public static const OPT_NAOHTD:uint	=  12;  // negotiate about horizontal tab disposition
	public static const OPT_NAOFFD:uint	=  13;  // negotiate about formfeed disposition
	public static const OPT_NAOVTS:uint	=  14;  // negotiate about vertical tab stops
	public static const OPT_NAOVTD:uint	=  15;  // negotiate about vertical tab disposition
	public static const OPT_NAOLFD:uint	=  16;  // negotiate about output LF disposition
	public static const OPT_XASCII:uint	=  17;  // extended ascic byteacter set
	public static const OPT_LOGOUT:uint	=  18;  // force logout
	public static const OPT_BM:uint		=  19;  // byte macro
	public static const OPT_DET:uint	=  20;  // data entry terminal
	public static const OPT_SUPDUP:uint	=  21;  // supdup protocol
	public static const OPT_SUPDUPOUTPUT:uint = 22;  // supdup output
	public static const OPT_SNDLOC:uint	=  23;  // send location
	public static const OPT_TTYPE:uint	=  24;  // terminal type
	public static const OPT_EOR:uint	=  25;  // end or record
	public static const OPT_TUID:uint	=  26;  // TACACS user identification
	public static const OPT_OUTMRK:uint	=  27;  // output marking
	public static const OPT_TTYLOC:uint	=  28;  // terminal location number
	public static const OPT_3270REGIME:uint	=  29;  // 3270 regime
	public static const OPT_X3PAD:uint	=  30;  // X.3 PAD
	public static const OPT_NAWS:uint	=  31;  // window size
	public static const OPT_TSPEED:uint	=  32;  // terminal speed
	public static const OPT_LFLOW:uint	=  33;  // remote flow control
	public static const OPT_LINEMODE:uint	=  34;  // Linemode option
	public static const OPT_XDISPLOC:uint	=  35;  // X Display Location
	public static const OPT_OLD_ENVIRON:uint= 36;  // Old - Environment variables
	public static const OPT_AUTHENTICATION:uint = 37;  //  Authenticate
	public static const OPT_ENCRYPT:uint	=  38;  // Encryption option
	public static const OPT_NEW_ENVIRON:uint= 39;  // New - Environment variables
	public static const OPT_TN3270E:uint	=  40;  // TN3270 enhancements
	public static const OPT_XAUTH:uint	=  41;  // 
	public static const OPT_byteSET:uint	=  42;  // byteacter set
	public static const OPT_RSP:uint	=  43;  // Remote serial port
	public static const OPT_COM_PORT_OPTION:uint = 44;  //  Com port control
	public static const OPT_SLE:uint	=  45;  // Suppress local echo
	public static const OPT_STARTTLS:uint	=  46;  // Start TLS
	public static const OPT_KERMIT:uint	=  47;  // Automatic Kermit file transfer
	public static const OPT_SEND_URL:uint	=  48;
	public static const OPT_FORWARD_X:uint	=  49;
	public static const OPT_PRAGMA_LOGON:uint = 138;
	public static const OPT_SSPI_LOGON:uint	= 139;
	public static const OPT_EXOPL:uint	= 255;  // extended-options-list
	public static const OPT_PRAGMA_HEARTBEAT:uint = 140;

}

}


import flash.utils.ByteArray;
class WaitingFlags {
	private var _array:ByteArray;
	public function WaitingFlags():void {
		_array = new ByteArray();
		_array.length = 256;
	}
	public function test(i:uint):Boolean {
		return _array[i] != 0;
	}
	public function reset(i:uint):void {
		_array[i] = 0;
	}
	public function set(i:uint):void {
		_array[i] = 1;
	}
}

