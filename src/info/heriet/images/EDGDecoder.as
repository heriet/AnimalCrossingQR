/*
 * Copyright (c) 2009 Heriet [http://heriet.info/].
 * 
 * @version 0.61
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
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.geom.Point;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    
    /**
     * Class that converts a valid EDG ByteArray into BitmapData and Array of Palette
     * 
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0
     */
    
    public class EDGDecoder 
    {
        private static const LAYER_NAME_MAX:int = 80;
        
        public var version:uint;
        
        private var _layers:Array;
        public function get layers():Array { return _layers; }
        
        private var _pages:Array;
        public function get pages():Array { return _pages; }
        
        private var _width:uint;
        public function get width():uint { return _width }
        private var _height:uint;
        public function get height():uint { return _height }
        
        protected var _transparent:uint;
        public function get transparent():uint { return _transparent; }
        
        protected var _bitDepth:uint;
        protected var _isEachPalette:Boolean; // ページ毎にパレット指定
        protected var _basePosition:int; // ページ座標基準
        
        protected var _paletteTable:Array; // RGB Color Table [0x000000, 0xFFFFFF]
        public function get paletteTable():Array { return _paletteTable; }
        
        protected var _paletteTableList:Array; // RGB Color Table [0x000000, 0xFFFFFF]
        public function get paletteTableList():Array { return _paletteTableList; }
        
        /**
         * Decode a palette type EDG ByteArray
         *
         * @param bytes Palette type EDG ByteArray.
         * @throws Error Bytes are invalid or not palette type EDG ByteArray.
        */
        public function decode(bytes:ByteArray, isLite:Boolean = false):void
        {
            bytes.endian = Endian.LITTLE_ENDIAN;
            
            var header:uint = bytes.readUnsignedInt();
            
            if (header != 0x45474445){ // EDGE
                throw(new Error('invalid EDG ByteArray'));
            }
            var v:uint = bytes.readUnsignedByte();
            
            if (v == 0) {
                version = 1;
                readEdge1(bytes);
            }
            else if (v == 50) {
                version = 2;
                readEdge2(bytes, isLite);
            }
            else {
                throw(new Error('invalid EDG ByteArray'));
            }
            
        }
        private function readEdge2(bytes:ByteArray, isLite:Boolean = false):void
        {
            bytes.position += 7;
            var dat:ByteArray = new ByteArray();
            bytes.readBytes(dat);
            dat.uncompress();
            dat.endian = Endian.LITTLE_ENDIAN;
            
            _pages = [];
            _paletteTableList = [];
            var pageIndex:int = 0;
            var paletteTableIndex:int = 0;
            var pageImageTable:Array = [];
            
            var n:int = dat.length;
            while (dat.position < n) {
                var id:uint = dat.readUnsignedShort();
                var length:uint = dat.readUnsignedInt();
                
                if (id == 1000) {
                    _bitDepth = dat.readUnsignedByte();
                }
                else if (id == 1006) {
                    readHeaderID1006(readSubDat(dat, length));
                }
                else if (id == 2003) {
                    pageImageTable[pageIndex] = [];
                    _pages[pageIndex] = readPage(readSubDat(dat, length), pageImageTable[pageIndex]);
                    pageIndex++;
                }
                else if (id == 3001) {
                    var paletteTableLength:int = dat.readUnsignedShort();
                }
                else if (id == 3001) {
                    var paletteLength:int = dat.readUnsignedInt();
                }
                else if (id == 3003) {
                    _paletteTableList[paletteTableIndex] = readPalette2(readSubDat(dat, length));
                    paletteTableIndex++;
                }
                else if (id == 3008) {
                    readHeaderID3008(readSubDat(dat, length));
                }
                else {
                    dat.position += length;
                }
            }
            
      
            var pageLength:uint = _pages.length;
            
            if(isLite){
                for (var i:int = 0; i < pageLength; i++ ) {
                    var page:PageData = _pages[i];
                    if (!page.isAbailable) {
                        _pages.splice(i, 1);
                        pageImageTable.splice(i, 1);
                        i--;
                        pageLength = _pages.length;
                    }
                    
                }
            }
            var maxWidth:int = 0;
            var maxHeight:int = 0;

            for (i = 0; i < pageLength; i++ ) {
                page = _pages[i];
                var paletteIndex:int = _isEachPalette ? page.paletteTableIndex : 0;
                var m:int = page.layers.length;
                var sprite:Sprite = new Sprite();
                var pagePaletteTable:Array = _paletteTableList[paletteIndex];
                
                for (var j:int = m -1 ; j >= 0; j--) {
                    var layer:LayerData = page.layers[j];
                    
                    var bitmapData:BitmapData = new BitmapData(page.width, page.height);
                    var image:ByteArray = pageImageTable[i][j];
                    for (var y:int = 0; y < page.height; y++ ) {
                        for (var x:int = 0; x < page.width; x++ ) {
                            var index:uint = image.readUnsignedByte();
                            index != transparent ? bitmapData.setPixel(x, y, pagePaletteTable[index]) : bitmapData.setPixel32(x, y, pagePaletteTable[index]) ; 
                        }
                    }
                    
                    layer.image = bitmapData;
                    if(layer.visible)
                        sprite.addChild(new Bitmap(layer.image));
                }
                page.display = sprite;
                
                if(page.width > maxWidth)
                    maxWidth = page.width;
                if(page.height > maxHeight)
                    maxHeight = page.height;
            }
            
            _width = maxWidth;
            _height = maxHeight;
        }
        private function readSubDat(bytes:ByteArray, length:uint):ByteArray
        {
            var dat:ByteArray = new ByteArray();
            bytes.readBytes(dat, 0, length);
            dat.endian = Endian.LITTLE_ENDIAN;
            return dat;
        }
        private function drawPalette(bitmapData:BitmapData, paletteTable:Array):void
        {
            var n:int = paletteTable.length;
            var p:Point = new Point();
            for (var i:int = 0; i < n; i++ ) {
                if(i != _transparent){
                    bitmapData.threshold(bitmapData, bitmapData.rect, p, '==', (0xFF << 24) + i, (0xFF << 24) + paletteTable[i])
                }
                else {
                    bitmapData.threshold(bitmapData, bitmapData.rect, p, '==', (0xFF << 24) + i, paletteTable[i]);
                }
            }
            
        }
        private function readHeaderID1006(bytes:ByteArray):void
        {
            var n:int = bytes.length;
            while (bytes.position < n) {
                var id:uint = bytes.readUnsignedShort();
                var length:uint = bytes.readUnsignedInt();
                
                if (id == 1000) {
                    _basePosition = bytes.readUnsignedShort();
                }
                else {
                    bytes.position += length;
                }
            }
        }
        private function readHeaderID3008(bytes:ByteArray):void
        {
            var n:int = bytes.length;
            while (bytes.position < n) {
                var id:uint = bytes.readUnsignedShort();
                var length:uint = bytes.readUnsignedInt();
                
                if (id == 1000) {
                    _transparent = bytes.readUnsignedByte();
                }
                else {
                    bytes.position += length;
                }
            }
        }
        private function readPage(bytes:ByteArray, layerIamgeTable:Array):PageData
        {
            var page:PageData = new PageData();
            
            var n:int = bytes.length;
            var pageLayers:Array = [];
            var layerIndex:int;
            
            while (bytes.position < n) {
                var id:uint = bytes.readUnsignedShort();
                var length:uint = bytes.readUnsignedInt();
                
                if (id == 1000) {
                    page.name = bytes.readMultiByte(length, "shift_jis");
                }
                else if (id == 1005) {
                    page.width = bytes.readUnsignedShort();
                }
                else if (id == 1006) {
                    page.height = bytes.readUnsignedShort();
                }
                else if (id == 1007) {
                    page.paletteTableIndex = bytes.readUnsignedInt();
                }
                else if (id == 1008) {
                    page.paletteTableIndex = bytes.readUnsignedInt();
                }
                else if (id == 2001) {
                    var layerLength:int = bytes.readUnsignedInt();
                }
                else if (id == 2003) {
                    pageLayers[layerIndex] = readLayer(readSubDat(bytes, length), layerIamgeTable, layerIndex);
                    layerIndex++;
                }
                else if (id == 3000) {
                    page.wait = bytes.readUnsignedInt() / 100 * 17;
                }
                else if (id == 3001) {
                    page.isTransparent = bytes.readBoolean();
                }
                else if (id == 3002) {
                    page.nextBackgroundType = bytes.readByte();
                }
                else if (id == 3003) {
                    page.x = bytes.readInt();
                    page.isRelativeX = bytes.readBoolean();
                }
                else if (id == 3004) {
                    page.y = bytes.readInt();
                    page.isRelativeY = bytes.readBoolean();
                }
                else if (id == 3005) {
                    page.isAbailable = bytes.readBoolean();
                }
                else {
                    bytes.position += length;
                }
            }
            
            page.layers = pageLayers;
            
            return page;
        }
        private function readLayer(bytes:ByteArray, layerImageTable:Array, layerIndex:int):LayerData
        {
            var layer:LayerData = new LayerData();
            
            var n:int = bytes.length;
            var pageLayers:Array = [];
            var layerIndex:int;
            
            while (bytes.position < n) {
                var id:uint = bytes.readUnsignedShort();
                var length:uint = bytes.readUnsignedInt();
                
                if (id == 1000) {
                    layer.name = bytes.readMultiByte(length, "shift_jis");
                }
                else if (id == 1002) {
                    layer.isChild = bytes.readBoolean();
                }
                else if (id == 1005) {
                    layer.visible = bytes.readBoolean();
                }
                else if (id == 1006) {
                    layerImageTable[layerIndex] = readSubDat(bytes, length);
                }
                else if (id == 1007) {
                    layer.isLocked = bytes.readBoolean();
                }
                else {
                    bytes.position += length;
                }
            }
            
            /*
            var nameLength:int = bytes.readUnsignedInt();
            layer.name = bytes.readMultiByte(nameLength, "shift_jis");
            
            bytes.position += 16;
            layer.isChild = bytes.readBoolean();
            bytes.position += 20;
            
            layer.visible = bytes.readByte() != 0;
            
            var layerWidth:int = page.width, layerHeight:int = page.height;
            
            bytes.position += 6;
            
            
            var bitmapData:BitmapData = new BitmapData(layerWidth, layerHeight);
            
            if(_bitDepth == 8){
                for (var y:int = 0; y < layerHeight; y++ ) {
                    for (var x:int = 0; x < layerWidth; x++ ) {
                        bitmapData.setPixel(x, y, bytes.readUnsignedByte());
                    }
                }
            }
            else {
                var value:uint, position:uint, index:uint;
                var mask:uint = (1 << _bitDepth) - 1;
                
                x = y = 0;
                
                while (y < layerHeight) {
                    value <<= position;
                    value += bytes.readUnsignedByte();
                    position += 8;
                    
                    while (position >= _bitDepth) {
                        var shiftMask:uint = mask << (position - _bitDepth);
                        index = (value & shiftMask) >> (position - _bitDepth);
                        value &= ~shiftMask;
                        position -= _bitDepth;
                        bitmapData.setPixel(x, y, index);
                        x++;
                        
                        if (x >= layerWidth) {
                            x = 0;
                            y++;
                        }
                    }
                }
            }
            
            layer.image = bitmapData;
            
            // 62
            bytes.position += 6;
            layer.isLocked = !bytes.readBoolean();
            
            bytes.position += 47;
            bytes.position += 8;
            //bytes.position += 7;
            */
            return layer;
        }
        private function readPalette2(bytes:ByteArray):Array
        {
            var n:int = bytes.length;
            var paletteTable:Array = [];
            
            while (bytes.position < n) {
                var id:uint = bytes.readUnsignedShort();
                var length:uint = bytes.readUnsignedInt();
                
                if (id == 1005) {
                    var paletteLength:uint = length / 3;
                    for (var j:int = 0; j < paletteLength; j++ ) {
                        var blue:uint = bytes.readUnsignedByte();
                        var green:uint = bytes.readUnsignedByte();
                        var red:uint = bytes.readUnsignedByte();
                        
                        var color:uint = (red << 16) + (green << 8) + blue;
                        paletteTable[j] = color;
                    }
                    
                    return paletteTable;
                }
                else {
                    bytes.position += length;
                }
            }
            
            return paletteTable;
        }
        private function readEdge1(bytes:ByteArray):void
        {
            _layers = [];
            bytes.position += 5;
            
            _width = bytes.readUnsignedInt();
            _height = bytes.readUnsignedInt();
            
            var layerNum:int = bytes.readUnsignedShort();
            var transparent:int = bytes.readUnsignedByte();
      _transparent = transparent;
            _paletteTable = readPalette(bytes);
            
            var size:int = _width * _height;
            
            for (var i:int = 0; i < layerNum; i++ ) {
                var layer:LayerData = new LayerData();
                
                layer.name = bytes.readMultiByte(LAYER_NAME_MAX, "shift_jis");
                layer.visible = bytes.readByte() == 1 ? true : false;
                var layerImage:BitmapData = new BitmapData(_width, _height, true)
                
                var imageData:Array = [];
                readImage(bytes, imageData, size);
                
                var j:int = 0;
                for (var y:int = 0; y < _height; y++ ) {
                    for (var x:int = 0; x < _width; x++ ) {
                        var index:int = imageData[j];
                        index != transparent ? layerImage.setPixel(x,y,_paletteTable[index]) : layerImage.setPixel32(x,y,_paletteTable[index]);
                        j++;
                    }
                }
                layer.image = layerImage;
                _layers[i] = layer;
            }
            
            var display:Sprite = new Sprite();
            for (i = layerNum - 1; i >= 0; i-- ) {
                layer = _layers[i];
                if (layer.visible) {
                    var layerDisplay:Bitmap = new Bitmap(layer.image);
                    display.addChild(layerDisplay);
                }
            }
            
            var page:PageData = new PageData();
            page.display = display;
      page.layers = _layers;
            _pages = [page];
        }
        private function readPalette(bytes:ByteArray):Array
        {
            var myPaletteList:Array = [];
            for (var i:int = 0; i < 256; i++ ) {
                myPaletteList[i] = readRGB(bytes);
            }
            return myPaletteList;
        }
        private function readImage(bytes:ByteArray, imageData:Array, imageSize:int):void
        {
            var compressMax:uint = bytes.readUnsignedInt();
            var positions:Array = [];
            var lengths:Array = [];
            var values:Array = [];
            
            for (var i:int = 0; i < compressMax; i++ ) {
                var position:uint = bytes.readUnsignedInt();
                positions[i] = position;
                var length:uint = bytes.readUnsignedInt();
                lengths[i] = length;
                var value:uint = bytes.readUnsignedByte();
                values[i] = value;
            }
            
            var srcMax:uint = bytes.readUnsignedInt();
            var comp:int = 0;
            var dest:int = 0;
            
            for (i = 0; i <= srcMax; i++ ) {
                if (comp < compressMax && i == positions[comp]) {
                    for (var j:int = 0; j < lengths[comp]; j++ ) {
                        if (dest + j < imageSize) {
                            imageData[dest + j] = values[comp];
                        }
                    }
                    dest += lengths[comp];
                    comp++;
                    i--;
                    continue;
                }
                if (i < srcMax) {
                    imageData[dest] = bytes.readUnsignedByte();
                    dest++;
                }
            }
        }
        private function readRGB(bytes:ByteArray):uint
        {
            return (bytes.readUnsignedByte() << 16) + (bytes.readUnsignedByte() << 8) + bytes.readUnsignedByte();
        }
    }
}