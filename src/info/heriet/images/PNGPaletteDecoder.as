/*
 * Copyright (c) 2008-2009 Heriet [http://heriet.info/].
 * 
 * @version 1.0
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
    import flash.utils.ByteArray;
    
    /**
     * Class that converts a palette type PNG ByteArray into Array of Palette
     * 
     * @langversion ActionScript 3.0
     * @playerversion Flash 9.0
     */    
    
    public class PNGPaletteDecoder
    {
        protected static const CONTENT_TYPE:String = 'image/png';
        public function get contentType():String { return CONTENT_TYPE; }
        
        // Header [IHDR]
        protected var _width:uint;
        protected var _height:uint;
        protected var _bitDepth:uint;
        protected var _colorType:uint;
        protected var _compressionMethod:uint;
        protected var _filterMethod:uint;
        protected var _interlaceMethod:uint;
        public function get colorType():uint { return _colorType }
        
        // Background [bKGD]
        /*
         * if _colorType == 3 then _background is palette index of background
         * else _background is color of background
        */
        protected var _background:uint;
        public function get background():uint { return _background; }
        protected var _hasBackground:Boolean;
        public function get hasBackground():Boolean { return _hasBackground; }
        
        // Transparent [tRNS]
        protected var _transparent:uint; // Transparent Table [0x00, 0xFF]
        public function get transparent():uint { return _transparent; }
        protected var _transparentTable:Array;
        public function get transparentTable():Array { return _transparentTable; }
        
        // RGB Palette [PLTE]
        protected var _paletteTable:Array; // RGB Color Table [0x000000, 0xFFFFFF]
        public function get paletteTable():Array { return _paletteTable; }
        
        /**
         * Decode a palette type PNG ByteArray
         *
         * @param bytes Palette type PNG ByteArray.
         * @throws Error Bytes are invalid or not palette type PNG ByteArray.
        */
        public function decode(bytes:ByteArray):void
        {
            _paletteTable = [];
            _transparentTable = [];
            
            var header:ByteArray = new ByteArray();
            bytes.readBytes(header, 0, 8);
            
            if (!checkHeader(header)){
                throw(new Error('invalid PNG ByteArray'));
            }
            
            while (bytes.bytesAvailable > 12) {
                var chunk:ByteArray = new ByteArray();
                var length:uint = bytes.readUnsignedInt();
                var chunkType:String = bytes.readMultiByte(4, "us-ascii");
                var chunkData:ByteArray = new ByteArray();
                bytes.readBytes(chunkData,0,length);
                var crc:uint = bytes.readUnsignedInt();
                
                switch(chunkType)
                {
                    case 'IHDR':
                        readHeader(chunkData);
                        break;
                    case 'PLTE':
                        readPalette(chunkData);
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
                
                if (chunkType == 'IHDR' && _colorType != 3){
                    throw(new Error("Color type is not palette"));
                }
                
            }
        }
        protected function readHeader(data:ByteArray ):void
        {
            _width = data.readUnsignedInt();
            _height = data.readUnsignedInt();
            _bitDepth = data.readUnsignedByte();
            _colorType = data.readUnsignedByte();
            _compressionMethod = data.readUnsignedByte();
            _filterMethod = data.readUnsignedByte();
            _interlaceMethod = data.readUnsignedByte();
        }
        protected function readPalette(data:ByteArray):void
        {
            for (var i:int = 0; data.bytesAvailable >= 3; i++) {
                _paletteTable[i] = readRGB(data);
            }
        }
        protected function readTransparent(data:ByteArray):void
        {
            for (var i:int = 0; data.bytesAvailable > 0; i++) {
                _transparentTable[i] = data.readUnsignedByte();
            }
        }
        protected function readBackground(data:ByteArray):void
        {
            _background = data.readUnsignedByte();
            _hasBackground = true;
        }
        protected function checkHeader(header:ByteArray):Boolean
        {
            return header.readUnsignedInt() == 0x89504e47 && header.readUnsignedInt() == 0x0D0A1A0A;
        }
        protected function readRGB(bytes:ByteArray):uint
        {
            return (bytes.readUnsignedByte() << 16) + (bytes.readUnsignedByte() << 8) + bytes.readUnsignedByte();
        }
    }    
}