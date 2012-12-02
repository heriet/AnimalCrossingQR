/*
 * Copyright (c) 2009 Heriet [http://heriet.info/].
 * 
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


package info.heriet.images 
{
    import flash.display.BitmapData;
    import flash.display.Sprite;
    
    public class FrameData implements IFrameData
    {
        public function get name():String {return _name}
        public function get width():uint {return _width}
        public function get height():uint {return _height}
        public function get bitDepth():uint {return _bitDepth}
        public function get isTransparent():Boolean {return _isTransparent}
        public function get isAbailable():Boolean {return _isAbailable}
        public function get transparent():uint {return _transparent}
        public function get wait():uint {return _wait}
        public function get nextBackgroundType():uint {return _nextBackgroundType}
        public function get paletteTable():Array {return _paletteTable}
        public function get layers():Array {return _layers}
        public function get display():Sprite {return _display}
        
        public function set name(value:String):void { _name = value }
        public function set width(value:uint):void { _width = value }
        public function set height(value:uint):void { _height = value }
        public function set bitDepth(value:uint):void { _bitDepth = value }
        public function set isTransparent(value:Boolean):void { _isTransparent = value }
        public function set isAbailable(value:Boolean):void { _isAbailable = value }
        public function set transparent(value:uint):void { _transparent = value }
        public function set wait(value:uint):void { _wait = value }
        public function set nextBackgroundType(value:uint):void { _nextBackgroundType = value }
        public function set paletteTable(value:Array):void { _paletteTable = value }
        public function set layers(value:Array):void { _layers = value }
        public function set display(value:Sprite):void { _display = value }
        
        private var _name:String;
        private var _width:uint;
        private var _height:uint;
        private var _bitDepth:uint;
        private var _isTransparent:Boolean;
        private var _isAbailable:Boolean = true;
        private var _transparent:uint;
        private var _wait:uint;
        private var _nextBackgroundType:uint;
        private var _paletteTable:Array;
        private var _layers:Array;
        private var _display:Sprite;
        
    }
    
}