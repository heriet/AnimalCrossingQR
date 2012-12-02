/*
 * Copyright (c) 2009 Heriet [http://heriet.info/].
 * 
 * @version 0.1
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
    import flash.utils.ByteArray;
    
    /**
     * Class that converts a valid PNG ByteArray into BitmapData and Array of Palette
     * 
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0
     */    
    
    public class PNGDecoder extends PNGPaletteDecoder
    {
        // Image [IDAT]
        private var _image:BitmapData;
        public function get image():BitmapData { return _image; }
        
        // Bit depth [sBIT]
        private var _bitRed:uint;
        private var _bitGreen:uint;
        private var _bitBlue:uint;
        private var _bitAlpha:uint;
        private var _bitGray:uint;
        
        // CRC
        private var _crcTableComputed:Boolean;
        private var _crcTable:Array;
        
        /**
         * Decode a valid PNG ByteArray
         *
         * @param bytes PNG ByteArray.
         * @throws Error bytes are invalid PNG ByteArray.
        */
        
        override public function decode(bytes:ByteArray):void
        {
            _paletteTable = [];
            _transparentTable = [];
            
            var header:ByteArray = new ByteArray();
            bytes.readBytes(header, 0, 8);
            
            if (!checkHeader(header)){
                throw(new Error('invalid PNG ByteArray'));
            }
            
            var dat:ByteArray = new ByteArray();
            
            while (bytes.bytesAvailable > 12) {
                var length:uint = bytes.readUnsignedInt();
                var p:uint = bytes.position;
                var chunkType:String = bytes.readMultiByte(4, "us-ascii");
                bytes.position = p;
                var chunkData:ByteArray = new ByteArray();
                bytes.readBytes(chunkData,0,length + 4);
                var crc:uint = bytes.readUnsignedInt();
                
                chunkData.position = 0;
                if (crc != getCRC(chunkData))
                    throw(new Error('invalid PNG ByteArray'));
                
                chunkData.position = 4;
                
                switch(chunkType)
                {
                    case 'IHDR':
                        readHeader(chunkData);
                        break;
                    case 'sBIT':
                        readBitDepth(chunkData);
                        break;
                    case 'PLTE':
                        readPalette(chunkData);
                        break;
                    case 'IDAT':
                        readDat(chunkData, dat);
                        break;
                    case 'tRNS':
                        readTransparent(chunkData);
                        break;
                    case 'bKGD':
                        readBackground(chunkData);
                        break;
                    default:
                        break;
                }
            }
            
            createImage(dat);
            
            _crcTable = null;
            _crcTableComputed = false;
        }
        protected function createImage(dat:ByteArray):void
        {
            if (_width == 0 || _height == 0)
                return;
            
            dat.uncompress();
            
            _image = new BitmapData(_width, _height, true);
            
            switch(_colorType) {
                case 2:
                    createImageRGB(dat);
                    break;
                case 3:
                    createImagePalette(dat);
                    break;
                case 6:
                    createImageRGBA(dat);
                default:
                    break;
            }
        }
        protected function createImageRGB(dat:ByteArray):void
        {
            var x:int, y:int, c:uint, filterType:uint, prevColor:uint, currentColor:uint;
            var aboveColors:Array = [];
            var currentColors:Array = [];
            
            if (_hasBackground) {
                for (y = 0; y < _height; y++) {
                    filterType = dat.readByte();
                    if(filterType == 0){
                        for (x = 0; x < _width; x++ ) {
                            c = readRGB(dat);
                            c != _background ? _image.setPixel(x, y, c) : _image.setPixel32(x, y, c);
                            currentColors[x] = c;
                        }
                    }
                    else if (filterType == 1) {
                        c = readRGB(dat);
                        c != _background ? _image.setPixel(x, y, c) : _image.setPixel32(x, y, c);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = readRGB(dat);
                            currentColor = c + prevColor;
                            currentColor != _background ? _image.setPixel(x, y, currentColor) : _image.setPixel32(x, y, currentColor);
                            currentColors[x] = currentColor;
                            prevColor = c;
                        }
                    }
                    else if (filterType == 2) {
                        for (x = 0; x < _width; x++ ) {
                            c = readRGB(dat);
                            currentColor = c + aboveColors[x];
                            currentColor != _background ? _image.setPixel(x, y, currentColor) : _image.setPixel32(x, y, currentColor);
                            currentColors[x] = currentColor;
                        }
                    }
                    else if (filterType == 3) {
                        c = readRGB(dat);
                        c != _background ? _image.setPixel(x, y, c) : _image.setPixel32(x, y, c);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = readRGB(dat);
                            currentColor = c + (prevColor + aboveColors[x]) /2;
                            currentColor != _background ? _image.setPixel(x, y, currentColor) : _image.setPixel32(x, y, currentColor);
                            prevColor = c;
                            currentColors[x] = currentColor;
                        }
                    }
                    else if (filterType == 4) {
                        c = readRGB(dat);
                        c != _background ? _image.setPixel(x, y, c) : _image.setPixel32(x, y, c);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = readRGB(dat);
                            currentColor = c + getPaethPredictor(prevColor, aboveColors[x], aboveColors[x-1]);
                            currentColor != _background ? _image.setPixel(x, y, currentColor) : _image.setPixel32(x, y, currentColor);
                            prevColor = c;
                            currentColors[x] = currentColor;
                        }
                    }
                    aboveColors = currentColors;
                    currentColors = [];
                }
            }
            else {
                for (y = 0; y < _height; y++) {
                    filterType = dat.readByte();
                    if(filterType == 0){
                        for (x = 0; x < _width; x++ ) {
                            c = readRGB(dat);
                            _image.setPixel(x, y, c);
                            currentColors[x] = c;
                        }
                    }
                    else if (filterType == 1) {
                        c = readRGB(dat);
                        _image.setPixel(x, y, c);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = readRGB(dat);
                            currentColor = c + prevColor;
                            _image.setPixel(x, y, currentColor);
                            currentColors[x] = currentColor;
                            prevColor = c;
                        }
                    }
                    else if (filterType == 2) {
                        for (x = 0; x < _width; x++ ) {
                            c = readRGB(dat);
                            currentColor = c + aboveColors[x];
                            _image.setPixel(x, y, currentColor);
                            currentColors[x] = currentColor;
                        }
                    }
                    else if (filterType == 3) {
                        c = readRGB(dat);
                        _image.setPixel(x, y, c);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = readRGB(dat);
                            currentColor = c + (prevColor + aboveColors[x]) /2;
                            _image.setPixel(x, y, currentColor);
                            prevColor = c;
                            currentColors[x] = currentColor;
                        }
                    }
                    else if (filterType == 4) {
                        c = readRGB(dat);
                        _image.setPixel(x, y, c);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = readRGB(dat);
                            currentColor = c + getPaethPredictor(prevColor, aboveColors[x], aboveColors[x-1]);
                            _image.setPixel(x, y, currentColor);
                            prevColor = c;
                            currentColors[x] = currentColor;
                        }
                    }
                    aboveColors = currentColors;
                    currentColors = [];
                }
            }
        }
        protected function createImagePalette(dat:ByteArray):void
        {
            var paletteColors:Array = [];
            var n:int = _paletteTable.length;
            for (var i:int = 0; i < n; i++ ) {
                paletteColors[i] = _paletteTable[i];
                paletteColors[i] += (_transparentTable != null && i in _transparentTable) ? (_transparentTable[i] << 24) : (0xFF << 24)
            }
            
            var x:int, y:int, c:uint;
            
            if(_bitDepth == 8){
                for (y = 0; y < _height; y++) {
                    dat.readByte()
                    for (x = 0; x < _width; x++ ) {
                        c = paletteColors[dat.readUnsignedByte()];
                        _image.setPixel32(x, y, c);
                    }
                }
            }
            else
            {
                var value:uint;
                var index:uint;
                var position:uint;
                var mask:uint = (1 << _bitDepth) - 1;
                
                n = dat.length;
                x = y = 0;
                dat.readByte();
                
                while (dat.position < n && y < _height) {
                    value <<= position;
                    value += dat.readUnsignedByte();
                    position += 8;
                    
                    while (position >= _bitDepth) {
                        var shiftMask:uint = mask << (position - _bitDepth);
                        index = (value & shiftMask) >> (position - _bitDepth);
                        value &= ~shiftMask;
                        position -= _bitDepth; 
                        c = paletteColors[index];
                        _image.setPixel32(x, y, c);
                        x++;
                        
                        if (x >= _width) {
                            x = 0;
                            y++;
                            if(dat.position < n && y < _height)
                                dat.readByte();
                        }
                    }
                }
            }
        }
        protected function createImageRGBA(dat:ByteArray):void
        {
            var x:int, y:int, c:uint, filterType:uint, prevColor:uint, currentColor:uint;
            var aboveColors:Array = [];
            var currentColors:Array = [];
            
            if (_hasBackground) {
                for (y = 0; y < _height; y++) {
                    filterType = dat.readByte();
                    if(filterType == 0){
                        for (x = 0; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            (c & 0xFFFFFF) != _background ? _image.setPixel32(x, y, c) : _image.setPixel32(x, y, c & 0xFFFFFF);
                            currentColors[x] = c;
                        }
                    }
                    else if (filterType == 1) {
                        c = dat.readUnsignedInt();
                        c = (c >> 8) + ((c & 0xFF) << 24);
                        (c & 0xFFFFFF) != _background ? _image.setPixel32(x, y, c) : _image.setPixel32(x, y, c & 0xFFFFFF);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            currentColor = c + prevColor;
                            (currentColor & 0xFFFFFF) != _background ? _image.setPixel32(x, y, currentColor) : _image.setPixel32(x, y, currentColor & 0xFFFFFF);
                            currentColors[x] = currentColor;
                            prevColor = c;
                        }
                    }
                    else if (filterType == 2) {
                        for (x = 0; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            currentColor = c + aboveColors[x];
                            (currentColor & 0xFFFFFF) != _background ? _image.setPixel32(x, y, currentColor) : _image.setPixel32(x, y, currentColor & 0xFFFFFF);
                            currentColors[x] = currentColor;
                        }
                    }
                    else if (filterType == 3) {
                        c = dat.readUnsignedInt();
                        c = (c >> 8) + ((c & 0xFF) << 24);
                        (c & 0xFFFFFF) != _background ? _image.setPixel32(x, y, c) : _image.setPixel32(x, y, c & 0xFFFFFF);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            currentColor = c + (prevColor + aboveColors[x]) /2;
                            (currentColor & 0xFFFFFF) != _background ? _image.setPixel32(x, y, currentColor) : _image.setPixel32(x, y, currentColor & 0xFFFFFF);
                            prevColor = c;
                            currentColors[x] = currentColor;
                        }
                    }
                    else if (filterType == 4) {
                        c = dat.readUnsignedInt();
                        c = (c >> 8) + ((c & 0xFF) << 24);
                        (c & 0xFFFFFF) != _background ? _image.setPixel32(x, y, c) : _image.setPixel32(x, y, c & 0xFFFFFF);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            currentColor = c + getPaethPredictor(prevColor, aboveColors[x], aboveColors[x-1]);
                            (currentColor & 0xFFFFFF) != _background ? _image.setPixel32(x, y, currentColor) : _image.setPixel32(x, y, currentColor & 0xFFFFFF);
                            prevColor = c;
                            currentColors[x] = currentColor;
                        }
                    }
                    aboveColors = currentColors;
                    currentColors = [];
                }
            }
            else {
                for (y = 0; y < _height; y++) {
                    filterType = dat.readByte();
                    if(filterType == 0){
                        for (x = 0; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            _image.setPixel32(x, y, c);
                            currentColors[x] = c;
                        }
                    }
                    else if (filterType == 1) {
                        c = dat.readUnsignedInt();
                        c = (c >> 8) + ((c & 0xFF) << 24);
                        _image.setPixel32(x, y, c);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            currentColor = c + prevColor;
                            _image.setPixel32(x, y, currentColor);
                            currentColors[x] = currentColor;
                            prevColor = c;
                        }
                    }
                    else if (filterType == 2) {
                        for (x = 0; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            currentColor = c + aboveColors[x];
                            _image.setPixel32(x, y, currentColor);
                            currentColors[x] = currentColor;
                        }
                    }
                    else if (filterType == 3) {
                        c = dat.readUnsignedInt();
                        c = (c >> 8) + ((c & 0xFF) << 24);
                        _image.setPixel32(x, y, c);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            currentColor = c + (prevColor + aboveColors[x]) /2;
                            _image.setPixel32(x, y, currentColor);
                            prevColor = c;
                            currentColors[x] = currentColor;
                        }
                    }
                    else if (filterType == 4) {
                        c = dat.readUnsignedInt();
                        c = (c >> 8) + ((c & 0xFF) << 24);
                        _image.setPixel32(x, y, c);
                        prevColor = c;
                        for (x = 1; x < _width; x++ ) {
                            c = dat.readUnsignedInt();
                            c = (c >> 8) + ((c & 0xFF) << 24);
                            currentColor = c + getPaethPredictor(prevColor, aboveColors[x], aboveColors[x-1]);
                            _image.setPixel32(x, y, currentColor);
                            prevColor = c;
                            currentColors[x] = currentColor;
                        }
                    }
                    aboveColors = currentColors;
                    currentColors = [];
                }
            }
        }
        protected function getPaethPredictor(left:uint, above:uint, upperLeft:uint):uint
        {
            var p:uint, pLeft:uint, pAbove:uint, pUpperLeft:uint;
            p = left + above - upperLeft;
            pLeft = distance(p, left);
            pAbove = distance(p, above);
            pUpperLeft = distance(p, upperLeft);
            
            if (pLeft <= pAbove && pLeft <= pUpperLeft)
                return left;
            else if (pAbove <= pUpperLeft)
                return above;
            else
                return upperLeft;
            
            function distance(a:uint, b:uint):uint {
                return a < b ? b - a : a - b;
            }
        }
        protected function readBitDepth(data:ByteArray):void
        {
            switch(_colorType) {
                case 0:
                    _bitGray = data.readUnsignedByte();
                    break;
                case 2:
                    _bitRed = data.readUnsignedByte();
                    _bitGreen = data.readUnsignedByte();
                    _bitBlue = data.readUnsignedByte();
                    break;
                case 3:
                    _bitRed = data.readUnsignedByte();
                    _bitGreen = data.readUnsignedByte();
                    _bitBlue = data.readUnsignedByte();
                    break;
                case 4:
                    _bitGray = data.readUnsignedByte();
                    _bitAlpha = data.readUnsignedByte();
                    break;
                case 6:
                    _bitRed = data.readUnsignedByte();
                    _bitGreen = data.readUnsignedByte();
                    _bitBlue = data.readUnsignedByte();
                    _bitAlpha = data.readUnsignedByte();
                    break;
                default:
                    break;
            }
        }
        override protected function readBackground(data:ByteArray):void 
        {
            if(_colorType == 3) {
                _background = data.readUnsignedByte();
            }
            else if (_colorType == 0 || _colorType == 4) {
                _background = data.readUnsignedShort();
            }
            else if (_colorType == 2 || _colorType == 6) {
                var red:uint = data.readUnsignedShort();
                var green:uint = data.readUnsignedShort();
                var blue:uint = data.readUnsignedShort();
                
                _background = (red << 16) + (green << 8) + blue;
            }
            _hasBackground = true;
        }
        protected function readDat(data:ByteArray, dat:ByteArray):void
        {
            data.readBytes(dat);
        }
        protected function makeCRCTable():void
        {
            _crcTable = [];
            
            for (var n:int = 0; n < 256; n++)
            {
                var c:uint = n;
                for (var k:int = 0; k < 8; k++)
                {
                    if (c & 1)
                        c = 0xedb88320 ^ (c >>> 1);
                    else
                        c = c >>> 1;
                }
                _crcTable[n] = c;
            }
            _crcTableComputed = true;
        }
        protected function updateCRC(crc:uint, buf:ByteArray):uint
        {
            var c:uint = crc;
            
            if (!_crcTableComputed)
                makeCRCTable();
            var n:int = buf.length;
            for (var i:int = buf.position; i < n; i++) {
                c = _crcTable[(c ^ buf.readUnsignedByte()) & 0xFF] ^ (c >>> 8)
            }
            return c;
        }
        protected function getCRC(buf:ByteArray):uint
        {
            return updateCRC(0xFFFFFFFF, buf) ^ 0xFFFFFFFF;
        }
    }    
}