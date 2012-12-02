/*
 * Copyright (c) 2009 Heriet [http://heriet.info/].
 * 
 * @version 0.511
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
    import flash.display.Bitmap;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    
    /**
     * Class that converts a valid GAL ByteArray into BitmapData and Array of Palette
     * 
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0
     */
    
    public class GALDecoder 
    {
        private static const LAYER_NAME_MAX:int = 80;
        
        private var _frames:Array;
        public function get frames():Array { return _frames; }
        
        private var _frameLength:uint;
        private var _bitDepth:uint;
        
        private var _width:uint;
        public function get width():uint { return _width }
        private var _height:uint;
        public function get height():uint { return _height }
        
        protected var _transparent:uint;
        public function get transparent():uint { return _frames[0].transparent; }
        
        protected var _paletteTable:Array; // RGB Color Table [0x000000, 0xFFFFFF]
        public function get paletteTable():Array { return _paletteTable; }
        
        protected var _paletteTableList:Array; // RGB Color Table [0x000000, 0xFFFFFF]
        public function get paletteTableList():Array { return _paletteTableList; }
        
        /**
         * Decode a palette type GAL ByteArray
         *
         * @param bytes Palette type GAL ByteArray.
         * @throws Error Bytes are invalid or not palette type GAL ByteArray.
        */
        public function decode(bytes:ByteArray):void
        {
            bytes.endian = Endian.LITTLE_ENDIAN;
            
            var header:String = bytes.readMultiByte(7, "us-ascii");
            if (header != 'Gale106') {
                throw(new Error('invalid GAL ByteArray'));
            }
            
            var x1:uint = bytes.readUnsignedInt();
            var x2:uint = bytes.readUnsignedInt();
            
            _width = bytes.readUnsignedInt();
            _height = bytes.readUnsignedInt();
            _bitDepth = bytes.readUnsignedInt();
            
            if (_bitDepth > 8) {
                throw(new Error('RGB Color not supported'));
            }
            
            _frameLength = bytes.readUnsignedInt();
            bytes.readUnsignedInt();
            
            var r1:uint = bytes.readUnsignedByte();
            var g1:uint = bytes.readUnsignedByte();
            var b1:uint = bytes.readUnsignedByte();
            
            bytes.position += 13;
      
            _frames = [];
      _paletteTableList = [];
            for (var i:int = 0; i < _frameLength; i++ ){
                _frames[i] = readFrame(bytes);
            }
      _paletteTable = _paletteTableList[0];
            
        }
        private function readFrame(bytes:ByteArray):FrameData
        {
            var frame:FrameData = new FrameData();
            var nameLength:uint = bytes.readUnsignedInt();
            frame.name = bytes.readMultiByte(nameLength, "shift_jis");
            frame.transparent = bytes.readUnsignedByte(); // transparent index color
            
            var transparentAble:uint;
            transparentAble += bytes.readByte();
            transparentAble += bytes.readByte();
            transparentAble += bytes.readByte();
            frame.isTransparent = (transparentAble == 0);
            
            frame.wait = bytes.readUnsignedInt();
            frame.nextBackgroundType = bytes.readUnsignedByte();
            
            bytes.position += 4;
            
            var layerLength:uint = bytes.readUnsignedInt();
            frame.width = bytes.readUnsignedInt();
            frame.height = bytes.readUnsignedInt();
            frame.bitDepth = bytes.readUnsignedInt();
            
//            trace(frame.name, layerLength, frame.wait, frame.nextBackgroundType, frame.width, frame.bitDepth);
            
            var paletteTable:Array = [];
            var paletteLength:uint = 1 << _bitDepth;
            for (var i:int = 0; i < paletteLength; i++) {
                var color:uint = bytes.readUnsignedInt();
                paletteTable[i] = color;
            }
            frame.paletteTable = paletteTable;
            paletteTableList.push(paletteTable);
      
            bytes.position += 8;
            
            frame.layers = []
            for (i = 0; i < layerLength; i++ ) {
                frame.layers[i] = readLayer(bytes, frame);
            }
            
            frame.display = new Sprite();
            for (i = 0; i < layerLength; i++ ) {
                var layer:LayerData = frame.layers[i];
                if(layer.visible){
                    var bitmap:Bitmap = new Bitmap(layer.image)
                    frame.display.addChild(bitmap);
                }
            }
            
            return frame;
        }
        public function readLayer(bytes:ByteArray, frame:FrameData):LayerData
        {
            var layer:LayerData = new LayerData();
            
            layer.visible = (bytes.readUnsignedByte() == 1);
            layer.transparent = bytes.readUnsignedByte(); // transparent color index
            var transparentAble:uint;
            transparentAble += bytes.readByte();
            transparentAble += bytes.readByte();
            transparentAble += bytes.readByte();
            layer.isTransparent = (transparentAble == 0);
            layer.density = bytes.readUnsignedByte();
            
            bytes.readUnsignedInt();
            
            var nameLength:uint = bytes.readUnsignedInt();
            layer.name = bytes.readMultiByte(nameLength, "shift_jis");
            
            var imageSize:uint = bytes.readUnsignedInt();
//            trace(imageSize, layer.name)
            var image:ByteArray = new ByteArray();
            bytes.readBytes(image, 0, imageSize);
            image.uncompress();
            
            var hasLineMarker:Boolean = image.length > frame.width * frame.height;
            
            var w:int = frame.width;
            var h:int = frame.height;
            
            if (w > 4096) { w = 4096 }
            if (h > 4096) { h = 4096 }
            
            var lineStart:uint, lineEnd:uint;
            var bitmapData:BitmapData = new BitmapData(w, h);
            
            if(frame.bitDepth == 8){
                for (var y:int = 0; y < h; y++ ) {
                    if (hasLineMarker)
                        lineStart = image.readUnsignedByte();
                    for (var x:int = 0; x < w; x++ ) {
                        var index:uint = image.readUnsignedByte();
                        if(layer.transparent != index || !layer.isTransparent) 
                            bitmapData.setPixel(x, y, frame.paletteTable[index])
                        else
                            bitmapData.setPixel32(x, y, frame.paletteTable[index]);
                    }
                    if (hasLineMarker)
                        lineEnd = image.readUnsignedByte();
                }
            }
            else
            {
                var value:uint;
                var position:uint;
                var mask:uint = (1 << frame.bitDepth) - 1;
                
                var n:uint = image.length;
                x = y = 0;
                
                while (image.position < n && y < h) {
                    value <<= position;
                    value += image.readUnsignedByte();
                    position += 8;
                    
                    while (position >= frame.bitDepth) {
                        var shiftMask:uint = mask << (position - frame.bitDepth);
                        index = (value & shiftMask) >> (position - frame.bitDepth);
                        value &= ~shiftMask;
                        position -= frame.bitDepth;
                        layer.transparent != index || !layer.isTransparent ? 
                            bitmapData.setPixel(x, y, frame.paletteTable[index]) : bitmapData.setPixel32(x, y, frame.paletteTable[index]);
                        x++;
                        
                        if (x >= w) {
                            x = 0;
                            y++;
                            if (bytes.position < n && y < h && hasLineMarker) {
                                lineEnd = image.readUnsignedByte();
                            }
                        }
                    }
                }
            }
            
            layer.image = bitmapData;
            
            bytes.readUnsignedInt();
            bytes.readUnsignedInt();
            bytes.readUnsignedInt();
            
            return layer;
        }
    }
}