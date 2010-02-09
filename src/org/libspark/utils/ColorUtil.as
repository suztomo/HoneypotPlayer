/*
 * Copyright(c) 2006-2008 the Spark project.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
 * either express or implied. See the License for the specific language
 * governing permissions and limitations under the License.
 */


package org.libspark.utils
{
	import flash.errors.IllegalOperationError;
    import flash.geom.ColorTransform;
	
	/**
	 * 色情報を扱うユーティリティクラスです
	 */
	public class ColorUtil
	{
		
        /**
         * @private
         */
		function ColorUtil()
		{
			throw new IllegalOperationError("Error #2012: ColorUtil class cannot be instantiated.");
		}
		
        /**
         * RGB 情報から ColorTransform インスタンスを作成します。
         * 
         * @param	rgb RGBを示す整数値 (0x000000 - 0xFFFFFF)
         * @param	amount 塗りの適応値 (0.0 - 1.0)
         * @param	alpha 透明度 (0.0 - 1.0)
         * @return 新しい ColorTransform インスタンス
		 * @author  michi at seyself.com
         */
        public static function colorTransform( rgb:uint=0, amount:Number=1.0, alpha:Number=1.0 ):ColorTransform
        {
            amount = ( amount > 1 ) ? 1 : ( amount < 0 ) ? 0 : amount;
            alpha  = ( alpha  > 1 ) ? 1 : ( alpha  < 0 ) ? 0 : alpha;
            var r:Number = ( ( rgb >> 16 ) & 0xff ) * amount;
            var g:Number = ( ( rgb >> 8  ) & 0xff ) * amount;
            var b:Number = (   rgb         & 0xff ) * amount;
            var a:Number = 1-amount;
            return new ColorTransform( a, a, a, alpha, r , g , b, 0 );
        }
        
		/**
		* 減算. <br />
		* ２つのRGBを示す数値（ 0x000000 から 0xFFFFFF まで）から減算した数値を返します.
		* 
		* @param col1	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @param col2	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @return	減算混色値
		* @author  michi at seyself.com
		*/
		public static function subtract( col1:uint , col2:uint ):uint
		{
			var colA:Array = toRGB( col1 );
			var colB:Array = toRGB( col2 );
			var r:uint = Math.max( Math.max( colB[0]-(256-colA[0]) , colA[0]-(256-colB[0]) ) , 0 );
			var g:uint = Math.max( Math.max( colB[1]-(256-colA[1]) , colA[1]-(256-colB[1]) ) , 0 );
			var b:uint = Math.max( Math.max( colB[2]-(256-colA[2]) , colA[2]-(256-colB[2]) ) , 0 );
			return r << 16 | g << 8 | b;
		}
		
		/**
		* 加法混色. <br />
		* ２つのRGBを示す数値（ 0x000000 から 0xFFFFFF まで）から加法混色した数値を返します.
		* 
		* @param col1	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @param col2	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @return	加法混色値
		* @author  michi at seyself.com
		*/
		public static function sum( col1:uint , col2:uint ):uint
		{
			var c1:Array = toRGB( col1 );
			var c2:Array = toRGB( col2 );
			var r:uint = Math.min( c1[0]+c2[0] , 255 );
			var g:uint = Math.min( c1[1]+c2[1] , 255 );
			var b:uint = Math.min( c1[2]+c2[2] , 255 );
			return r << 16 | g << 8 | b;
		}
		
		/**
		* 減法混色. <br />
		* 2つのRGBを示す数値（ 0x000000 から 0xFFFFFF まで）から減法混色した数値を返します.
		* 
		* @param col1	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @param col2	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @return	減法混色値
		* @author  michi at seyself.com
		*/
		public static function sub( col1:uint , col2:uint ):uint
		{
			var c1:Array = toRGB( col1 );
			var c2:Array = toRGB( col2 );
			var r:uint = Math.max( c1[0]-c2[0] , 0 );
			var g:uint = Math.max( c1[1]-c2[1] , 0 );
			var b:uint = Math.max( c1[2]-c2[2] , 0 );
			return r << 16 | g << 8 | b;
		}
		
		/**
		* 比較（暗）. <br />
		* 2つのRGBを示す数値（ 0x000000 から 0xFFFFFF まで）から比較して、RGBそれぞれ数値の低い方を合わせた数値を返します.
		* 
		* @param col1	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @param col2	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @return	比較（暗）値
		* @author  michi at seyself.com
		*/
		public static function min( col1:uint , col2:uint ):uint
		{
			var c1:Array = toRGB( col1 );
			var c2:Array = toRGB( col2 );
			var r:uint = Math.min( c1[0] , c2[0] );
			var g:uint = Math.min( c1[1] , c2[1] );
			var b:uint = Math.min( c1[2] , c2[2] );
			return r << 16 | g << 8 | b;
		}
		
		/**
		* 比較（明）. <br />
		* 2つのRGBを示す数値（ 0x000000 から 0xFFFFFF まで）から比較して、RGBそれぞれ数値の高い方を合わせた数値を返します.
		* 
		* @param col1	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @param col2	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @return	比較（明）値
		* @author  michi at seyself.com
		*/
		public static function max( col1:uint , col2:uint ):uint
		{
			var c1:Array = toRGB( col1 );
			var c2:Array = toRGB( col2 );
			var r:uint = Math.max( c1[0] , c2[0] );
			var g:uint = Math.max( c1[1] , c2[1] );
			var b:uint = Math.max( c1[2] , c2[2] );
			return r << 16 | g << 8 | b;
		}
		
		/**
		 * RGB それぞれの数値から RGB カラー値を求めます。
		 * 
		 * @param r	赤（R）を示す数値（ 0 から 255 まで）
		 * @param g	緑（G）を示す数値（ 0 から 255 まで）
		 * @param b	青（B）を示す数値（ 0 から 255 まで）
		 * @return 各色の値から求められたRGBを示す数値
		 * @author  michi at seyself.com
		 */
		public static function rgb(r:uint, g:uint, b:uint):uint
		{
			return r << 16 | g << 8 | b;
		}
		
		/**
		 * HSV それぞれの数値から RGB カラー値を求めます。
		 * 
		 * @param	h 色相（Hue）を示す数値（ 0 から 360 まで）
		 * @param   s 彩度（Saturation）を示す数値（ 0.0 から 1.0 まで）
		 * @param   v 明度（Value）を示す数値（ 0.0 から 1.0 まで）
		 * @return 各色の値から求められたRGBを示す数値
		 * @author  michi at seyself.com
		 */
		public static function hsv(h:int, s:Number, v:Number):uint
		{
			return rgb.apply( null, HSVtoRGB(h, s, v));
		}
		
		/**
		* RGBを示す数値（ 0x000000 から 0xFFFFFF まで）を
		* R, G, B それぞれ 0 から 255 までの数値に分割した配列を返します.
		* 
		* @param rgb	RGBを示す数値（ 0x000000 から 0xFFFFFF まで）
		* @return	各色の値を示す配列 [ R , G , B ] 
		* @author  michi at seyself.com
		*/
		public static function toRGB( rgb:uint ):Array
		{
			var r:uint = rgb >> 16 & 0xFF;
			var g:uint = rgb >> 8  & 0xFF;
			var b:uint = rgb       & 0xFF;
			return [r,g,b];
		}
		
		/**
		* RGBそれぞれの数値から、HSV に換算した配列を返します.
		* RGB の値はそれぞれ以下の通りです.
		*     R - 0 から 255 までの数値
		*     G - 0 から 255 までの数値
		*     B - 0 から 255 までの数値
		* 
		* HSV の値はそれぞれ以下の通りです.
		*     H - 0 から 360 までの数値
		*     S - 0 から 1.0 までの数値
		*     V - 0 から 1.0 までの数値
		* 
		* アルファを含めた計算はできません.
		* 
		* @param r	赤（R）を示す数値（ 0x00 から 0xFF まで）
		* @param g	緑（G）を示す数値（ 0x00 から 0xFF まで）
		* @param b	青（B）を示す数値（ 0x00 から 0xFF まで）
		* @return	HSVに変換した値の配列 [ H, S, V ] 
		* @author  michi at seyself.com
		*/
		public static function RGBtoHSV( r:Number, g:Number, b:Number ):Array
		{
            r/=255; g/=255; b/=255;
            var h:Number=0, s:Number=0, v:Number=0;
            var x:Number, y:Number;
            if(r>=g) x=r; else x=g; if(b>x) x=b;
            if(r<=g) y=r; else y=g; if(b<y) y=b;
            v=x; 
            var c:Number=x-y;
            if(x==0) s=0; else s=c/x;
            if(s!=0){
                if(r==x){
                    h=(g-b)/c;
                } else {
                    if(g==x){
                        h=2+(b-r)/c;
                    } else {
                        if(b==x){
                            h=4+(r-g)/c;
                        }
                    }
                }
                h=h*60;
                if(h<0) h=h+360;
            }
            return [ h, s, v ];
		}
		
		/**
		* HSVそれぞれの数値からRGBを割り出して配列として返します.
		* RGB の値はそれぞれ以下の通りです.
		*     R - 0 から 255 までの数値
		*     G - 0 から 255 までの数値
		*     B - 0 から 255 までの数値
		* 
		* HSV の値はそれぞれ以下の通りです.
		*     H - 0 から 360 までの数値
		*     S - 0 から 1.0 までの数値
		*     V - 0 から 1.0 までの数値
		* 
		* Hが上記範囲外の場合 0 から 360 の範囲内に相当する数値に置き換えられます.
		* アルファを含めた計算はできません.
		* 
		* @param h	色相（Hue）を示す数値（ 0 から 360 まで）
		* @param s	彩度（Saturation）を示す数値（ 0.0 から 1.0 まで）
		* @param v	明度（Value）を示す数値（ 0.0 から 1.0 まで）
		* @return	RGBに変換した値の配列 [ R, G, B ] 
		* @author  michi at seyself.com
		*/
		public static function HSVtoRGB( h:Number, s:Number, v:Number ):Array
		{
			var r:Number=0, g:Number=0, b:Number=0;
			var i:Number, x:Number, y:Number, z:Number;
			if(s<0) s=0; if(s>1) s=1; if(v<0) v=0; if(v>1) v=1;
			h = h % 360; if (h < 0) h += 360; h /= 60;
			i = h >> 0;
			x = v * (1 - s); y = v * (1 - s * (h - i)); z = v * (1 - s * (1 - h + i));
			switch(i){
				case 0 : r=v; g=z; b=x; break;
				case 1 : r=y; g=v; b=x; break;
				case 2 : r=x; g=v; b=z; break;
				case 3 : r=x; g=y; b=v; break;
				case 4 : r=z; g=x; b=v; break;
				case 5 : r=v; g=x; b=y; break;
			}
			return [ r*255>>0, g*255>>0, b*255>>0 ];
		}
		
	}
}

