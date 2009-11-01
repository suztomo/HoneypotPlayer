/*
 * org.partty.mxml.TelnetService
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

import mx.core.IMXMLObject;
import org.partty.Telnet;

public class TelnetService extends Telnet implements IMXMLObject
{
	private var _host:String;
	private var _port:int = 0;

	public function TelnetService():void
	{
		super();
	}

	public function set host(h:String):void
	{
		_host = h;
	}

	public function get host():String
	{
		return _host
	}

	public function set port(p:int):void
	{
		_port = p;
	}

	public function get port():int
	{
		return _port;
	}

	public function initialized(document:Object, id:String):void
	{
		if(_port != 0) {
			connect(_host, _port);
		}
	}
}


}

