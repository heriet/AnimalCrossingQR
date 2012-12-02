/*
 * Copyright (c) Heriet [http://heriet.info/].
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

package info.heriet.animal_crossing_qr 
{
    import com.google.zxing.BarcodeFormat;
    import com.google.zxing.BinaryBitmap;
    import com.google.zxing.BufferedImageLuminanceSource;
    import com.google.zxing.ChecksumException;
    import com.google.zxing.common.BitArray;
    import com.google.zxing.common.BitMatrix;
    import com.google.zxing.common.flexdatatypes.HashTable;
    import com.google.zxing.common.HybridBinarizer;
    import com.google.zxing.DecodeHintType;
    import com.google.zxing.EncodeHintType;
    import com.google.zxing.FormatException;
    import com.google.zxing.NotFoundException;
    import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
    import com.google.zxing.Reader;
    import com.google.zxing.Result;
    import com.google.zxing.Writer;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import flash.geom.Point
    import flash.geom.Rectangle;
    import flash.net.FileReference;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
    import info.heriet.images.ColorData;
    import info.heriet.images.LayerData;
    import info.heriet.images.PaletteUtil;
    import info.heriet.zxing.qrcode.encoder.QRCodeBinaryWriter;
    import info.heriet.zxing.qrcode.decoder.StructuredQRCodeReader;
    
    public class AnimalCrossingQRCodeImage 
    {
        public static const TYPE_SINGLE:int = 0x4;
        public static const TYPE_SEPARATE:int = 0x3;
        
        public static const DESIGNNAME_MAX_LENGTH:int = 12;
        public static const AUTHERNAME_MAX_LENGTH:int = 6;
        public static const VILLAGENAME_MAX_LENGTH:int = 6;
        
        public static const MODEL_ONEPIECE_LONGSLEEVED:int = 0x00;
        public static const MODEL_ONEPIECE_SHORTSLEEVED:int = 0x01;
        public static const MODEL_ONEPIECE_SLEEVELESS:int = 0x02;
        public static const MODEL_SHIRT_LONGSLEEVED:int = 0x03;
        public static const MODEL_SHIRT_SHORTSLEEVED:int = 0x04;
        public static const MODEL_SHIRT_SLEEVELESS:int = 0x05;
        public static const MODEL_CAP_HORN:int = 0x06;
        public static const MODEL_CAP_KNIT:int = 0x07;
        public static const MODEL_COMIC_FOREGROUND:int = 0x08;
        public static const MODEL_SIMPLE:int = 0x09;
        
        public static const INTERNAL_TEXTURE_SIZE_BASE:Rectangle = new Rectangle(0, 0, 32, 32);
        public static const INTERNAL_TEXTURE_SIZE_ONEPIECE_SKIRT:Rectangle = new Rectangle(0, 0, 32, 16);
        public static const INTERNAL_TEXTURE_SIZE_SLEEVED:Rectangle = new Rectangle(0, 0, 32, 16);
        
        public static const MODEL_TEXTURE_SIZE_BASE:Rectangle = new Rectangle(0, 0, 32, 32);
        public static const MODEL_TEXTURE_SIZE_ONEPIECE:Rectangle = new Rectangle(0, 0, 32, 48);
        public static const MODEL_TEXTURE_SIZE_SHORTSLEEVED:Rectangle = new Rectangle(0, 0, 16, 16);
        public static const MODEL_TEXTURE_SIZE_LONGSLEEVED:Rectangle = new Rectangle(0, 0, 16, 32);
        public static const MODEL_TEXTURE_SIZE_COMIC_FOREGROUND:Rectangle = new Rectangle(0, 0, 52, 64);
        
        
        private static const PAGE_FRONT:int = 0;
        private static const PAGE_BACK:int = 1;
        private static const PAGE_LEFT:int = 2;
        private static const PAGE_RIGHT:int = 3;
        
        private static const PALETTE_LENGTH:int = 15;
        private static const IMAGE_WIDTH:int = 32;
        private static const IMAGE_HEIGHT:int = 32;
        private static const TRANSPARENT_COLOR:uint = 0xFF00FF;
        
        public static const INTERNAL_TEXTURE_SIZE_MAP:Object = {
            0:[INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_SLEEVED, INTERNAL_TEXTURE_SIZE_SLEEVED, INTERNAL_TEXTURE_SIZE_ONEPIECE_SKIRT, INTERNAL_TEXTURE_SIZE_ONEPIECE_SKIRT],
            1:[INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_SLEEVED, INTERNAL_TEXTURE_SIZE_SLEEVED, INTERNAL_TEXTURE_SIZE_ONEPIECE_SKIRT, INTERNAL_TEXTURE_SIZE_ONEPIECE_SKIRT],
            2:[INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_SLEEVED, INTERNAL_TEXTURE_SIZE_SLEEVED, INTERNAL_TEXTURE_SIZE_ONEPIECE_SKIRT, INTERNAL_TEXTURE_SIZE_ONEPIECE_SKIRT],
            
            3:[INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_SLEEVED, INTERNAL_TEXTURE_SIZE_SLEEVED],
            4:[INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_SLEEVED, INTERNAL_TEXTURE_SIZE_SLEEVED],
            5:[INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_BASE],
            
            6:[INTERNAL_TEXTURE_SIZE_BASE],
            7:[INTERNAL_TEXTURE_SIZE_BASE],
            8:[INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_BASE, INTERNAL_TEXTURE_SIZE_BASE],
            9:[INTERNAL_TEXTURE_SIZE_BASE]
        };
        
        public static const MODEL_TEXTURE_SIZE_MAP:Object = {
            0:[MODEL_TEXTURE_SIZE_ONEPIECE, MODEL_TEXTURE_SIZE_ONEPIECE, MODEL_TEXTURE_SIZE_LONGSLEEVED, MODEL_TEXTURE_SIZE_LONGSLEEVED],
            1:[MODEL_TEXTURE_SIZE_ONEPIECE, MODEL_TEXTURE_SIZE_ONEPIECE, MODEL_TEXTURE_SIZE_SHORTSLEEVED, MODEL_TEXTURE_SIZE_SHORTSLEEVED],
            2:[MODEL_TEXTURE_SIZE_ONEPIECE, MODEL_TEXTURE_SIZE_ONEPIECE],
            
            3:[MODEL_TEXTURE_SIZE_BASE, MODEL_TEXTURE_SIZE_BASE, MODEL_TEXTURE_SIZE_LONGSLEEVED, MODEL_TEXTURE_SIZE_LONGSLEEVED],
            4:[MODEL_TEXTURE_SIZE_BASE, MODEL_TEXTURE_SIZE_BASE, MODEL_TEXTURE_SIZE_SHORTSLEEVED, MODEL_TEXTURE_SIZE_SHORTSLEEVED],
            5:[MODEL_TEXTURE_SIZE_BASE, MODEL_TEXTURE_SIZE_BASE],
            
            6:[MODEL_TEXTURE_SIZE_BASE],
            7:[MODEL_TEXTURE_SIZE_BASE],
            8:[MODEL_TEXTURE_SIZE_COMIC_FOREGROUND],
            9:[MODEL_TEXTURE_SIZE_BASE]
        };
        
        public static const PRO_MODEL_LIST:Vector.<int> = new Vector.<int>(
            [
                MODEL_ONEPIECE_LONGSLEEVED,
                MODEL_ONEPIECE_SHORTSLEEVED,
                MODEL_ONEPIECE_SLEEVELESS,
                MODEL_SHIRT_LONGSLEEVED,
                MODEL_SHIRT_SHORTSLEEVED,
                MODEL_SHIRT_SLEEVELESS,
                MODEL_CAP_HORN,
                MODEL_CAP_KNIT,
                MODEL_COMIC_FOREGROUND,
            ]
        )
        
        private static const CHARACTER_CODE_LATIN1:String = "iso-8859-1";
        private static const CHARACTER_CODE_UTF16:String = "utf-16";
        
        private static const QRCODE_MARGIN_PIXEL:int = 2;
        private static const QRCODE_WIDTH:int = 104;
        private static const QRCODE_HEIGHT:int = 104;
        
        private static const COLOR_PIXEL_BLACK:int = 0x000000;
        private static const COLOR_PIXEL_WHITE:int = 0xFFFFFF;
        
        public static const FIXED_PALETTE:Vector.<Vector.<ColorData>> = createColorDataPaletteTable([
        [
            0xFFEFFF, 0xFF9AAD, 0xEF559C, 0xFF65AD, 0xFF0063, 0xBD4573, 0xCE0052, 0x9C0031, 0x522031, -1, -1, -1, -1, -1, -1, 0xFFFFFF,
            0xFFBACE, 0xFF7573, 0xDE3010, 0xFF5542, 0xFF0000, 0xCE6563, 0xBD4542, 0xBD0000, 0x8C2021, -1, -1, -1, -1, -1, -1, 0xEFEFEF,
            0xDECFBD, 0xFFCF63, 0xDE6521, 0xFFAA21, 0xFF6500, 0xBD8A52, 0xDE4500, 0xBD4500, 0x633010, -1, -1, -1, -1, -1, -1, 0xDEDFDE,
            0xFFEFDE, 0xFFDFCE, 0xFFCFAD, 0xFFBA8C, 0xFFAA8C, 0xDE8A63, 0xBD6542, 0x9C5531, 0x8C4521, -1, -1, -1, -1, -1, -1, 0xCECFCE,
            0xFFCFFF, 0xEF8AFF, 0xCE65DE, 0xBD8ACE, 0xCE00FF, 0x9C659C, 0x8C00AD, 0x520073, 0x310042, -1, -1, -1, -1, -1, -1, 0xBDBABD,
            0xFFBAFF, 0xFF9AFF, 0xDE20BD, 0xFF55EF, 0xFF00CE, 0x8C5573, 0xBD009C, 0x8C0063, 0x520042, -1, -1, -1, -1, -1, -1, 0xADAAAD,
            0xDEBA9C, 0xCEAA73, 0x734531, 0xAD7542, 0x9C3000, 0x733021, 0x522000, 0x311000, 0x211000, -1, -1, -1, -1, -1, -1, 0x9C9A9C,
            0xFFFFCE, 0xFFFF73, 0xDEDF21, 0xFFFF00, 0xFFDF00, 0xCEAA00, 0x9C9A00, 0x8C7500, 0x525500, -1, -1, -1, -1, -1, -1, 0x8C8A8C,
            0xDEBAFF, 0xBD9AEF, 0x6330CE, 0x9C55FF, 0x6300FF, 0x52458C, 0x42009C, 0x210063, 0x211031, -1, -1, -1, -1, -1, -1, 0x737573,
            0xBDBAFF, 0x8C9AFF, 0x3130AD, 0x3155EF, 0x0000FF, 0x31308C, 0x0000AD, 0x101063, 0x000021, -1, -1, -1, -1, -1, -1, 0x636563,
            0x9CEFBD, 0x63CF73, 0x216510, 0x42AA31, 0x008A31, 0x527552, 0x215500, 0x103021, 0x002010, -1, -1, -1, -1, -1, -1, 0x525552,
            0xDEFFBD, 0xCEFF8C, 0x8CAA52, 0xADDF8C, 0x8CFF00, 0xADBA9C, 0x63BA00, 0x529A00, 0x316500, -1, -1, -1, -1, -1, -1, 0x424542,
            0xBDDFFF, 0x73CFFF, 0x31559C, 0x639AFF, 0x1075FF, 0x4275AD, 0x214573, 0x002073, 0x001042, -1, -1, -1, -1, -1, -1, 0x313031,
            0xADFFFF, 0x52FFFF, 0x008ABD, 0x52BACE, 0x00CFFF, 0x429AAD, 0x00658C, 0x004552, 0x002031, -1, -1, -1, -1, -1, -1, 0x212021,
            0xCEFFEF, 0xADEFDE, 0x31CFAD, 0x52EFBD, 0x00FFCE, 0x73AAAD, 0x00AA9C, 0x008A73, 0x004531, -1, -1, -1, -1, -1, -1, 0x000000,
            0xADFFAD, 0x73FF73, 0x63DF42, 0x00FF00, 0x21DF21, 0x52BA52, 0x00BA00, 0x008A00, 0x214521, -1, -1, -1, -1, -1, -1, -1
        ],
        [
            0xFFF8F8, 0xFFC0D0, 0xE080D0, 0xF890D0, 0xF85090, 0xB05090, 0xC04070, 0x904050, 0x402030,-1,-1,-1,-1,-1,-1, 0xFFFFFF,
            0xFFF0F0, 0xFFB0B0, 0xE06050, 0xF87050, 0xFF5030, 0xC08090, 0xB06060, 0xB03030, 0x903030,-1,-1,-1,-1,-1,-1, 0xF0F0F0,
            0xF8F8F0, 0xFFF0A0, 0xE08050, 0xF8C060, 0xFF8040, 0xC0A080, 0xE06040, 0xB05030, 0x503020,-1,-1,-1,-1,-1,-1, 0xE0E0E0,
            0xF8F0F0, 0xF8E8E8, 0xF8E0D0, 0xF8C8B8, 0xFFB8A0, 0xE0A090, 0xC08060, 0xA07050, 0x905030,-1,-1,-1,-1,-1,-1, 0xD0D0D0,
            0xF0E8F8, 0xE0C0FF, 0xD0A0FF, 0xD0C0F8, 0xD080F8, 0xA090D0, 0x9050E0, 0x403090, 0x202050,-1,-1,-1,-1,-1,-1, 0xC0C0C0,
            0xF8E0F8, 0xFFD0FF, 0xE060E0, 0xFFA0FF, 0xF860F8, 0x806080, 0xC050C0, 0x703070, 0x402040,-1,-1,-1,-1,-1,-1, 0xB0B0B0,
            0xE0D0C0, 0xC0B0A0, 0x705050, 0xB09070, 0x904030, 0x704040, 0x603030, 0x402020, 0x302020,-1,-1,-1,-1,-1,-1, 0xA0A0A0,
            0xFFFFF0, 0xF8F890, 0xE0E840, 0xFFFF50, 0xFFE850, 0xC8B030, 0x90A050, 0x908040, 0x505040,-1,-1,-1,-1,-1,-1, 0x909090,
            0xE0E0F8, 0xC0C0FF, 0x6060E0, 0xB090F8, 0x4060E0, 0x5060B0, 0x4050C0, 0x303070, 0x202040,-1,-1,-1,-1,-1,-1, 0x808080,
            0xD0E0FF, 0xA0C0FF, 0x3050D0, 0x4080F8, 0x2050FF, 0x4050B0, 0x2040D0, 0x203070, 0x202030,-1,-1,-1,-1,-1,-1, 0x707070,
            0xC0F0E0, 0x80E0B0, 0x207050, 0x50C060, 0x209030, 0x608060, 0x306040, 0x304030, 0x203020,-1,-1,-1,-1,-1,-1, 0x606060,
            0xE0F8E0, 0xD0F8B0, 0x90B070, 0xC0E0B0, 0xA0F840, 0xB0D0C0, 0x80C050, 0x60A030, 0x306030,-1,-1,-1,-1,-1,-1, 0x505050,
            0xD0F0FF, 0x90E8FF, 0x4070E0, 0x80C0FF, 0x3090FF, 0x6090E0, 0x3060C0, 0x3040A0, 0x303060,-1,-1,-1,-1,-1,-1, 0x404040,
            0xC0FFFF, 0x80FFFF, 0x4090E0, 0x80D0FF, 0x40E8F8, 0x40B0E0, 0x3070B0, 0x305080, 0x203040,-1,-1,-1,-1,-1,-1, 0x303030,
            0xE0FFF8, 0xB0F0F0, 0x70D0D0, 0x80E8E8, 0x70F8F8, 0x80B0B0, 0x60B0B0, 0x408080, 0x204040,-1,-1,-1,-1,-1,-1, 0x202020,
            0xD0F8E0, 0xB0F8B0, 0x80D080, 0x70F870, 0x30E030, 0x60C060, 0x50C050, 0x308030, 0x305030,-1,-1,-1,-1,-1, -1, -1
        ]
        ]
        );
        
        public static const FIXED_PALETTE_INDEX_MAP:Object = createPaletteIndexMap(FIXED_PALETTE);
        
        public static const STATE_INIT:int = 0;
        public static const STATE_COMPLETE:int = 1;
        
        public var type:int;
        public var tmpName:String;
        public var designName:String = "";
        public var autherName:String = "";
        public var villageName:String = "";
        
        public var filenameList:Vector.<String>;
        public var textureImageList:Vector.<BitmapData>;
        public var qrBitmapDataList:Vector.<BitmapData>;
        public var internalBitmapDataList:Vector.<BitmapData>;
        
        public var model:int;
        public var paletteType:int;
        
        public var unknownByteArray1:ByteArray;
        public var unknownByteArray2:ByteArray;
        public var unknownByteArray3:ByteArray;
        public var unknownByteArray4:ByteArray;
        
        public var structireAppendParityBit:int;
        public var readedQRCodeCount:int;
        public var readedTextureCount:int;
        public var readedTextureX:int;
        public var readedTextureY:int;
        public var paletteArray:Array
        
        public var replacedImage:BitmapData;
        public var replacedImageList:Vector.<BitmapData>;
        public var replacedPalette:Vector.<ColorData>;
        public var replacementColorMap:Object;
        public var paletteIndexMap:Object;
        public var joinedInternalImage:BitmapData;
        
        public var state:int;
        
        /**
         * コンストラクタ
         */
        public function AnimalCrossingQRCodeImage() 
        {
            filenameList = new Vector.<String>(4);
            textureImageList = new Vector.<BitmapData>(4);
            qrBitmapDataList = new Vector.<BitmapData>(4);
            internalBitmapDataList = new Vector.<BitmapData>(6);
            replacedImageList = new Vector.<BitmapData>(4);
            
            state = STATE_INIT;
        }
        
        /**
         * QR所有者が同じかどうか判定する
         */
        public function isEqualUser(profile:AnimalCrossingQRCodeImage):Boolean
        {
            return autherName == profile.autherName && villageName == profile.villageName;
        }
        
        /**
         * QRコードにエンコードする
         * 
         * @param   profile 所有者のデザイン情報
         * @return
         */
        public function encode(profile:AnimalCrossingQRCodeImage):Boolean
        {
            if (type == TYPE_SINGLE) {
                var bitmapData:BitmapData = encodeSingleQRCode(textureImageList[0], profile);
                if (bitmapData != null) {
                    qrBitmapDataList[0] = bitmapData;
                    return true;
                }
            } else if (type == TYPE_SEPARATE) {
                createJoinedReplacementColorMap(); //画像を全部結合して減色＆パレット作成
                convertTextureModelToInternal(); // 置換後の結合画像＆パレットをInternal画像に分割
                encodeSeparateQRCode(profile);   // Internal画像をエンコードする
                return true;
            }
            
            return false;
        }
        
        /**
         * 単体デザインをQRコードにエンコードする
         * 
         * @param   bitmapData デザイン画像
         * @param   profile 所有者のデザイン情報
         * @return  エンコードしたQRコード画像
         */
        private function encodeSingleQRCode(bitmapData:BitmapData, profile:AnimalCrossingQRCodeImage):BitmapData
        {
            var byteArray:ByteArray = new ByteArray();
            byteArray.endian = Endian.LITTLE_ENDIAN;
            
            writeMaxCharLength(byteArray, designName, DESIGNNAME_MAX_LENGTH);
            byteArray.writeBytes(profile.unknownByteArray1, 0, 20);
            
            writeMaxCharLength(byteArray, autherName, AUTHERNAME_MAX_LENGTH);
            byteArray.writeBytes(profile.unknownByteArray2, 0, 10);
            
            writeMaxCharLength(byteArray, villageName, VILLAGENAME_MAX_LENGTH);
            byteArray.writeBytes(profile.unknownByteArray3, 0, 10);
            
            var replacementColorMap:Object = {};
            var replacedPalette:Vector.<ColorData> = new Vector.<ColorData>();
            PaletteUtil.createReplacementColorMap(bitmapData, replacedPalette, replacementColorMap, FIXED_PALETTE[paletteType], PALETTE_LENGTH);
            
            var paletteIndexMap:Object = {};
            var paletteNum:int = replacedPalette.length;
            for (var i:int = 0; i < PALETTE_LENGTH; i++ ) {
                var color:uint = FIXED_PALETTE[paletteType][0x0F].color;
                if (i < paletteNum) {
                    color = replacedPalette[i].color & 0xFFFFFF;
                }
                
                var paletteIndex:uint = FIXED_PALETTE_INDEX_MAP[paletteType][color];
                paletteIndexMap[paletteIndex] = i;
                byteArray.writeByte(paletteIndex);
            }
            
            byteArray.writeBytes(profile.unknownByteArray4, 0, 2);
            byteArray.writeByte(model);
            byteArray.writeByte(0);
            byteArray.writeByte(0);
            
            for (var y:int = 0; y < IMAGE_HEIGHT; y++ ) {
                for (var x:int = 0; x < IMAGE_WIDTH; x += 2 ) {
                    var preColor:uint = bitmapData.getPixel(x+1, y) & 0xFFFFFF;
                    var postColor:uint = bitmapData.getPixel(x, y) & 0xFFFFFF;
                    
                    var replacedPreColor:uint = replacementColorMap[preColor];
                    var replacedPostColor:uint = replacementColorMap[postColor];
                    
                    var preIndex:uint = paletteIndexMap[FIXED_PALETTE_INDEX_MAP[paletteType][replacedPreColor]];
                    var postIndex:uint = paletteIndexMap[FIXED_PALETTE_INDEX_MAP[paletteType][replacedPostColor]];
                    
                    var indexByte:uint = (preIndex << 4) | postIndex;
                    
                    byteArray.writeByte(indexByte);
                }
            }
            
            replacedImage = PaletteUtil.createColorReplacedBitmapData(bitmapData, replacementColorMap);
            
            var qrBitmapData:BitmapData = encodeQRCode(byteArray);
            
            return qrBitmapData;
        }
        
        /**
         * 分割デザインをQRコードにエンコードする
         * 
         * @param	profile 所有者のデザイン情報
         */
        private function encodeSeparateQRCode(profile:AnimalCrossingQRCodeImage):void
        {
            var byteArrayList:Vector.<ByteArray> = new Vector.<ByteArray>(4);
            
            byteArrayList[0] = createSeparateFirstQRCodeByteArray(profile);
            byteArrayList[1] = createSeparateSubsequenceQRCodeByteArray(0, 27, 540);
            byteArrayList[2] = createSeparateSubsequenceQRCodeByteArray(24, 32 + 28, 540);
            byteArrayList[3] = createSeparateSubsequenceQRCodeByteArray(16, 32 + 32 + 30, 536);
            byteArrayList[3].writeUnsignedInt(0x0000);
            
            var parity:int = 0x00;
            
            for (var i:int = 0; i < 4; i++ ) {
                var byteArray:ByteArray = byteArrayList[i];
                byteArray.position = 0;
                var m:int = byteArray.length;
                for (var j:int = 0; j < m; j++ ) {
                    parity ^= byteArray.readUnsignedByte();
                }
            }
            
            for (i = 0; i < 4; i++ ) {
                byteArrayList[i].position = 0;
                var qrBitmapData:BitmapData = encodeQRCode(byteArrayList[i], 4, i, parity);
                qrBitmapDataList[i] = qrBitmapData;
            }
            
        }
        
        /**
         * 分割デザインの最初のQRコードバイナリを生成する
         * 
         * @param	profile 所有者のデザイン情報
         * @return 生成したQRコードバイナリ
         */
        private function createSeparateFirstQRCodeByteArray(profile:AnimalCrossingQRCodeImage):ByteArray
        {
            var byteArray:ByteArray = new ByteArray();
            byteArray.endian = Endian.LITTLE_ENDIAN;
            
            writeMaxCharLength(byteArray, designName, DESIGNNAME_MAX_LENGTH);
            byteArray.writeBytes(profile.unknownByteArray1, 0, 20);
            
            writeMaxCharLength(byteArray, autherName, AUTHERNAME_MAX_LENGTH);
            byteArray.writeBytes(profile.unknownByteArray2, 0, 10);
            
            writeMaxCharLength(byteArray, villageName, VILLAGENAME_MAX_LENGTH);
            byteArray.writeBytes(profile.unknownByteArray3, 0, 10);
            
            paletteIndexMap = {};
            var paletteNum:int = replacedPalette.length;
            for (var i:int = 0; i < PALETTE_LENGTH; i++ ) {
                var color:uint = FIXED_PALETTE[paletteType][0x0F].color;
                if (i < paletteNum) {
                    color = replacedPalette[i].color & 0xFFFFFF;
                }
                
                var paletteIndex:uint = FIXED_PALETTE_INDEX_MAP[paletteType][color];
                paletteIndexMap[paletteIndex] = i;
                byteArray.writeByte(paletteIndex);
            }
            
            byteArray.writeBytes(profile.unknownByteArray4, 0, 2);
            byteArray.writeByte(model);
            byteArray.writeByte(0);
            byteArray.writeByte(0);
            
            for (var y:int = 0; y < 27; y++ ) {
                for (var x:int = 0; x < 32; x += 2 ) {
                    var preColor:uint = joinedInternalImage.getPixel(x+1, y) & 0xFFFFFF;
                    var postColor:uint = joinedInternalImage.getPixel(x, y) & 0xFFFFFF;
                    
                    var preIndex:uint = paletteIndexMap[FIXED_PALETTE_INDEX_MAP[paletteType][preColor]];
                    var postIndex:uint = paletteIndexMap[FIXED_PALETTE_INDEX_MAP[paletteType][postColor]];
                    
                    var indexByte:uint = (preIndex << 4) | postIndex;
                    
                    byteArray.writeByte(indexByte);
                }
            }
            
            return byteArray;
        }
        
        /**
         * 分割デザインの2枚目以降のQRコードバイナリを生成する
         * 
         * @param	startX  デザイン画像初期X座標
         * @param	startY  デザイン画像初期Y座標
         * @param	length  バイナリサイズ
         * @return
         */
        private function createSeparateSubsequenceQRCodeByteArray(startX:int, startY:int, length:int):ByteArray
        {
            var byteArray:ByteArray = new ByteArray();
            byteArray.endian = Endian.LITTLE_ENDIAN;
            
            var count:int = 0;
            
            for (var y:int = startY; y < joinedInternalImage.height; y++ ) {
                var sx:int = count == 0 ? startX : 0;
                for (var x:int = sx; x < joinedInternalImage.width; x += 2 ) {
                    if (count >= length) {
                        return byteArray;
                    }
                    
                    var preColor:uint = joinedInternalImage.getPixel(x+1, y) & 0xFFFFFF;
                    var postColor:uint = joinedInternalImage.getPixel(x, y) & 0xFFFFFF;
                    
                    var preIndex:uint = paletteIndexMap[FIXED_PALETTE_INDEX_MAP[paletteType][preColor]];
                    var postIndex:uint = paletteIndexMap[FIXED_PALETTE_INDEX_MAP[paletteType][postColor]];
                    
                    var indexByte:uint = (preIndex << 4) | postIndex;
                    
                    byteArray.writeByte(indexByte);
                    count++;
                }
            }
            
            return byteArray;
        }
        
        /**
         * バイナリに対して文字列をmaxLengthまで書き込む。不足文字列は0で埋める
         * 
         * @param	byteArray 書き込み対象バイナリ
         * @param	value     文字列
         * @param	maxLength 書き込む文字数
         */
        private function writeMaxCharLength(byteArray:ByteArray, value:String, maxLength:int):void
        {
            byteArray.writeMultiByte(value, CHARACTER_CODE_UTF16);
            
            var n:int = maxLength - value.length;
            for (var i:int = 0; i < n; i++ ) {
                byteArray.writeShort(0);
            }
        }
        
        /**
         * バイナリをQRコードにエンコードする
         * 
         * @param	byteArray バイナリ
         * @param	structureNum QRコードの構造的連接数（連接しないときは0）
         * @param	structureIndex 構造的連接位置
         * @param	structureParity 構造的連接のパリティ
         * @return  エンコードしたQRコード画像
         */
        private function encodeQRCode(byteArray:ByteArray, structureNum:int = 0, structureIndex:int = 0, structureParity:int = 0):BitmapData
        {
            try {
                var hints:HashTable = new HashTable();
                hints.Add(EncodeHintType.CHARACTER_SET, CHARACTER_CODE_LATIN1);
                hints.Add(EncodeHintType.ERROR_CORRECTION,  ErrorCorrectionLevel.M);
                
                var writer:QRCodeBinaryWriter = new QRCodeBinaryWriter();
                var barcodeType:BarcodeFormat = BarcodeFormat.QR_CODE;
                var result:BitMatrix = writer.encodeByteArray(
                        byteArray,
                        barcodeType,
                        QRCODE_WIDTH,
                        QRCODE_HEIGHT,
                        hints,
                        structureNum,
                        structureIndex,
                        structureParity
                    ) as BitMatrix;
                
                var resultBits:Array = new Array(result.getWidth());
                for (var i:int=0; i < result.getWidth(); i++)
                {
                    resultBits[i] = result._get(i,0);
                }
                
                var bitmapData:BitmapData = new BitmapData(
                        QRCODE_WIDTH + QRCODE_MARGIN_PIXEL * 2,
                        QRCODE_HEIGHT + QRCODE_MARGIN_PIXEL * 2,
                        false,
                        0x009900
                    );
                
                var isWhitePixel:Boolean;

                for (var h:int = 0; h < bitmapData.height; h++)
                {
                    for (var w:int = 0; w < bitmapData.width; w++)
                    {
                        if ( (w < QRCODE_MARGIN_PIXEL) || (w >=  QRCODE_WIDTH - QRCODE_MARGIN_PIXEL)
                        ||   (h < QRCODE_MARGIN_PIXEL) || (h >=  QRCODE_HEIGHT - QRCODE_MARGIN_PIXEL)) 
                        {
                            bitmapData.setPixel(w,h, COLOR_PIXEL_WHITE);
                        }
                        else
                        {
                            isWhitePixel = (result._get(w - QRCODE_MARGIN_PIXEL, h - QRCODE_MARGIN_PIXEL) == 0);
                            bitmapData.setPixel(w, h, (isWhitePixel ? COLOR_PIXEL_WHITE : COLOR_PIXEL_BLACK));
                        }
                    }
                }
                
            } catch (e:Error) {
                return null;
            }
            
            return bitmapData;
        }
        
        
        /**
         * バイナリを文字列に変換する
         * 
         * @param	byteArray バイナリ
         * @return  変換した文字列
         */
        private function convertByteArrayToString(byteArray:ByteArray):String
        {
            byteArray.position = 0;
            var contents:String = byteArray.readMultiByte(byteArray.length, CHARACTER_CODE_LATIN1);
            return contents;
        }
        
        /**
         * QRコードバイナリをデコードする
         * 
         * @param	byteArray QRコードバイナリ
         * @return  デコードの成否
         */
        public function decode(byteArray:ByteArray):Boolean
        {
            if (state == STATE_COMPLETE) {
                return true;
            }
            
            byteArray.position = 0;
            
            var header:int = byteArray.readByte();
            var typeHeader:int = header >> 4;
            
            if(typeHeader　== TYPE_SINGLE) {
                return decodeSingleQRCode(byteArray);
            } else if (typeHeader == TYPE_SEPARATE) {
                return decodeSeparateQRCode(byteArray);
            }
            
            return false;
        }
        
        /**
         * 単体QRコードバイナリをデコードする
         * 
         * @param	byteArray QRコードバイナリ
         * @return 　デコード成否
         */
        private function decodeSingleQRCode(byteArray:ByteArray):Boolean
        {
            type = TYPE_SINGLE;
            byteArray.position = 0;
            
            var header1:uint = byteArray.readUnsignedByte();
            var header2:uint = byteArray.readUnsignedByte();
            var header3:uint = byteArray.readUnsignedByte();
            
            var size:uint = ((header1 & 0x0F) << 20) + (header2 << 4) + ((header3　 & 0xF0) >> 4);
            
            var trimedByteArray:ByteArray = new ByteArray();
            
            // shift 20 bit & read
            byteArray.position = 2;
            var preByte:int = byteArray.readUnsignedByte();
            
            var i:int = 0;
            while (true) {
                if (i >= size) {
                    break;
                }
                
                var postByte:int = byteArray.readUnsignedByte();
                var byte:uint = ((preByte & 0x0F) << 4) + ((postByte & 0xF0) >> 4);
                trimedByteArray.writeByte(byte);
                
                preByte = postByte;
                i++;
            }
            
            trimedByteArray.position = 0;
            trimedByteArray.endian = Endian.LITTLE_ENDIAN;
            
            designName = trimedByteArray.readMultiByte(DESIGNNAME_MAX_LENGTH * 2, CHARACTER_CODE_UTF16);
            
            //trimedByteArray.position += 20;
            unknownByteArray1 = new ByteArray();
            trimedByteArray.readBytes(unknownByteArray1, 0, 20);
            
            autherName = trimedByteArray.readMultiByte(AUTHERNAME_MAX_LENGTH * 2, CHARACTER_CODE_UTF16);
            
            //trimedByteArray.position += 10;
            unknownByteArray2 = new ByteArray();
            trimedByteArray.readBytes(unknownByteArray2, 0, 10);
            
            villageName = trimedByteArray.readMultiByte(VILLAGENAME_MAX_LENGTH * 2, CHARACTER_CODE_UTF16);
            
            //trimedByteArray.position += 10;
            unknownByteArray3 = new ByteArray();
            trimedByteArray.readBytes(unknownByteArray3, 0, 10);
            
            var transratePalette:Vector.<ColorData> = FIXED_PALETTE[paletteType];
            var paletteArray:Array = [TRANSPARENT_COLOR];
            for (i = 0; i < PALETTE_LENGTH; i++ ) {
                var paletteNumber:uint = trimedByteArray.readUnsignedByte();
                
                if (paletteNumber in transratePalette) {
                    paletteArray.push(transratePalette[paletteNumber]);
                } else {
                    paletteArray.push(transratePalette[paletteNumber % transratePalette.length]);
                    //trace("invalid color table");
                    return false;
                }
            }
            
            //trimedByteArray.position += 5;
            unknownByteArray4 = new ByteArray();
            trimedByteArray.readBytes(unknownByteArray4, 0, 2);
            model = trimedByteArray.readUnsignedByte();
            trimedByteArray.position += 2;
            
            var bitmapData:BitmapData = new BitmapData(IMAGE_WIDTH, IMAGE_HEIGHT, false);
            
            for (var y:int = 0; y < IMAGE_HEIGHT; y++ ) {
                for (var x:int = 0; x < IMAGE_WIDTH; x += 2 ) {
                    var indexByte:uint = trimedByteArray.readUnsignedByte();
                    var preIndex:int = ((indexByte & 0xF0) >> 4) + 1;
                    var postIndex:int = (indexByte & 0x0F) + 1;
                    
                    if (preIndex > PALETTE_LENGTH || postIndex > PALETTE_LENGTH) {
                        return false;
                    }
                    
                    if(preIndex in paletteArray && paletteArray[preIndex] != null) {
                        bitmapData.setPixel(x + 1, y, ColorData(paletteArray[preIndex]).color);
                    }
                    
                    if(postIndex in paletteArray && paletteArray[postIndex] != null) {
                        bitmapData.setPixel(x, y, ColorData(paletteArray[postIndex]).color);
                    }
                }
            }
            
            this.paletteArray = paletteArray;
            textureImageList[0] = bitmapData;
            
            return true;
        }
        
        /**
         * 分割QRコードバイナリをデコードする
         * 
         * @param	byteAray QRコードバイナリ
         * @return  デコード成否
         */
        private function decodeSeparateQRCode(byteAray:ByteArray):Boolean
        {
            type = TYPE_SEPARATE;
            byteAray.position = 0;
            
            var header:uint = byteAray.readUnsignedByte();
            var page:int = header & 0x0F;
            
            if (page == PAGE_FRONT) {
                readedTextureCount = 0;
                readedTextureX = 0;
                readedTextureY = 0;
                
                return decodeSeparateQRCodeFirst(byteAray);
            } else if (page == PAGE_BACK) {
                return decodeSeparateQRCodeSubsequent(byteAray);
            } else if (page == PAGE_LEFT) {
                return decodeSeparateQRCodeSubsequent(byteAray);
            } else if (page == PAGE_RIGHT) {
                return decodeSeparateQRCodeSubsequent(byteAray);
            }
            
            return false;
        }
        
        /**
         * 分割QRコードバイナリの最初のデザイン画像をデコードする
         * 
         * @param	byteArray QRコードバイナリ
         * @return  デコード成否
         */
        private function decodeSeparateQRCodeFirst(byteArray:ByteArray):Boolean
        {
            byteArray.endian = Endian.LITTLE_ENDIAN;
            
            byteArray.position = 1;
            
            var headerA:uint = byteArray.readUnsignedByte();
            var headerB:uint = byteArray.readUnsignedByte();
            structireAppendParityBit = ((headerA & 0x0F) << 4) + ((headerB & 0xF0) >> 4);
            
            var size:uint = (byteArray.readUnsignedByte() << 8) + byteArray.readUnsignedByte();
            
            designName = byteArray.readMultiByte(DESIGNNAME_MAX_LENGTH * 2, CHARACTER_CODE_UTF16);
            
            unknownByteArray1 = new ByteArray();
            byteArray.readBytes(unknownByteArray1, 0, 20);
            
            autherName = byteArray.readMultiByte(AUTHERNAME_MAX_LENGTH * 2, CHARACTER_CODE_UTF16);
            
            unknownByteArray2 = new ByteArray();
            byteArray.readBytes(unknownByteArray2, 0, 10);
            
            villageName = byteArray.readMultiByte(VILLAGENAME_MAX_LENGTH * 2, CHARACTER_CODE_UTF16);
            
            unknownByteArray3 = new ByteArray();
            byteArray.readBytes(unknownByteArray3, 0, 10);
            
            var transratePalette:Vector.<ColorData> = FIXED_PALETTE[paletteType];
            paletteArray = [TRANSPARENT_COLOR];
            for (var i:int = 0; i < PALETTE_LENGTH; i++ ) {
                var paletteNumber:uint = byteArray.readUnsignedByte();
                
                if (paletteNumber in transratePalette) {
                    paletteArray.push(transratePalette[paletteNumber]);
                } else {
                    paletteArray.push(transratePalette[paletteNumber % transratePalette.length]);
                    return false;
                }
            }
            
            unknownByteArray4 = new ByteArray();
            byteArray.readBytes(unknownByteArray4, 0, 2);
            model = byteArray.readUnsignedByte();
            byteArray.position += 2;
            
            var frontSize:Rectangle = INTERNAL_TEXTURE_SIZE_MAP[model][0];
            var bitmapData:BitmapData = new BitmapData(frontSize.width, frontSize.height, false);
            
            var readedLength:int = readByteArrayToBitmapData(0, 0, 432, byteArray, bitmapData, paletteArray);
            readedQRCodeCount = 1;
            readedTextureCount = 0;
            readedTextureY = (int) (readedLength / (bitmapData.width/2));
            readedTextureX = (readedLength % (bitmapData.width/2)) * 2;
            
            internalBitmapDataList[0] = bitmapData;
            
            return true;
        }
        
        /**
         * 分割QRコード画像の2枚目以降のデザインをデコードする
         * 
         * @param	byteArray QRコードバイナリ
         * @return  デコード成否
         */
        private function decodeSeparateQRCodeSubsequent(byteArray:ByteArray):Boolean
        {
            byteArray.endian = Endian.LITTLE_ENDIAN;
            byteArray.position = 1;
            
            var headerA:uint = byteArray.readUnsignedByte();
            var headerB:uint = byteArray.readUnsignedByte();
            var parity:uint = ((headerA & 0x0F) << 4) + ((headerB & 0xF0) >> 4);
            
            if (structireAppendParityBit != parity) {
                return false;
            }
            
            var size:uint = (byteArray.readUnsignedByte() << 8) + byteArray.readUnsignedByte();
            var readedTotalLength:int = 0;
            
            while(readedTotalLength < 540) {
                var textureSize:Rectangle = INTERNAL_TEXTURE_SIZE_MAP[model][readedTextureCount];
                if (textureSize == null) {
                    break;
                }
                
                var bitmapData:BitmapData = createInternalTextureBitmapData(readedTextureCount, textureSize);
            
                var startX:int = readedTextureX;
                var startY:int = readedTextureY;
                
                var readedLength:int = readByteArrayToBitmapData(startX, startY, 540　 -　readedTotalLength, byteArray, bitmapData, paletteArray);
                
                if (readedLength == 0) {
                    break;
                }
                readedTotalLength += readedLength;
                
                if (startX == 0) {
                    readedTextureY += (int) (readedLength / (bitmapData.width / 2));
                    readedTextureX += (readedLength % (bitmapData.width / 2)) * 2;
                } else {
                    var postReadedLength:int = readedLength - (bitmapData.width - startX) / 2;
                    readedTextureY += 1;
                    readedTextureX = 0;
                    readedTextureY += (int) (postReadedLength / (bitmapData.width / 2));
                    readedTextureX += (postReadedLength % (bitmapData.width / 2)) * 2;
                }
                
                
                if (readedTextureX == 0 && readedTextureY == bitmapData.height) {
                    readedTextureCount += 1;
                    readedTextureX = 0;
                    readedTextureY = 0;
                }
            }
            
            readedQRCodeCount += 1;
            
            if (readedTextureCount == INTERNAL_TEXTURE_SIZE_MAP[model].length) {
                convertTextureInternalToModel();
                state = STATE_COMPLETE;
            }
            
            return true;
        }
        
        /**
         * 内部テクスチャ画像をデザイン表示画像に変換する
         */
        private function convertTextureInternalToModel():void
        {
            var modelTextureList:Vector.<BitmapData> = new Vector.<BitmapData>(6);
            var modelTextureSizeArray:Array = MODEL_TEXTURE_SIZE_MAP[model];
            var n:int = modelTextureSizeArray.length;
            for (var i:int = 0; i < n; i++ ) {
                var bitmapData:BitmapData = new BitmapData(modelTextureSizeArray[i].width, modelTextureSizeArray[i].height, false);
                modelTextureList[i] = bitmapData;
            }
            
            var zeroPoint:Point = new Point(0, 0);
            
            if (model == MODEL_SHIRT_LONGSLEEVED
            || model == MODEL_SHIRT_SHORTSLEEVED
            || model == MODEL_SHIRT_SLEEVELESS
            || model == MODEL_ONEPIECE_LONGSLEEVED
            || model == MODEL_ONEPIECE_SHORTSLEEVED
            || model == MODEL_ONEPIECE_SLEEVELESS) {
                modelTextureList[0].copyPixels(internalBitmapDataList[0], internalBitmapDataList[0].rect, zeroPoint);
                modelTextureList[1].copyPixels(internalBitmapDataList[1], internalBitmapDataList[1].rect, zeroPoint);
            }
            
            if (model == MODEL_CAP_HORN
            || model == MODEL_CAP_KNIT) {
                modelTextureList[0].copyPixels(internalBitmapDataList[0], internalBitmapDataList[0].rect, zeroPoint);
            }
            
            var skirtPoint:Point = new Point(0, 32);
            
            if (model == MODEL_ONEPIECE_LONGSLEEVED
            || model == MODEL_ONEPIECE_SHORTSLEEVED
            || model == MODEL_ONEPIECE_SLEEVELESS) {
                modelTextureList[0].copyPixels(internalBitmapDataList[4], internalBitmapDataList[4].rect, skirtPoint);
                modelTextureList[1].copyPixels(internalBitmapDataList[5], internalBitmapDataList[5].rect, skirtPoint);
            }
            
            if (model == MODEL_ONEPIECE_LONGSLEEVED
            || model == MODEL_ONEPIECE_SHORTSLEEVED
            || model == MODEL_SHIRT_LONGSLEEVED
            || model == MODEL_SHIRT_SHORTSLEEVED) {
                drawRotateBitmapData(modelTextureList[2], internalBitmapDataList[2], 0, -16, Math.PI / 2);
                drawRotateBitmapData(modelTextureList[3], internalBitmapDataList[3], 0, -16, Math.PI / 2);
            }
            
            if (model == MODEL_COMIC_FOREGROUND) {
                modelTextureList[0].copyPixels(internalBitmapDataList[0], internalBitmapDataList[0].rect, zeroPoint);
                modelTextureList[0].copyPixels(internalBitmapDataList[1], internalBitmapDataList[1].rect, new Point(0, 32));
                modelTextureList[0].copyPixels(internalBitmapDataList[2], internalBitmapDataList[2].rect, new Point(32, 0));
                modelTextureList[0].copyPixels(internalBitmapDataList[3], internalBitmapDataList[3].rect, new Point(32, 32));
            }
            
            n = modelTextureSizeArray.length;
            for (i = 0; i < n; i++ ) {
                bitmapData = modelTextureList[i];
                textureImageList[i] = bitmapData;
            }
            
            clearInternalImageList();
            
        }
        
        /**
         * デザイン表示画像を内部テクスチャ画像に変換する
         */
        private function convertTextureModelToInternal():void
        {
            var backgroundColor:uint = 12 in replacedPalette ? replacedPalette[12].color : FIXED_PALETTE[paletteType][0x0F].color;
            var internalTextureSizeArray:Array = INTERNAL_TEXTURE_SIZE_MAP[model];
            
            var n:int = internalTextureSizeArray.length;
            for (var i:int = 0; i < n; i++ ) {
                var bitmapData:BitmapData = new BitmapData(internalTextureSizeArray[i].width, internalTextureSizeArray[i].height, false, 0xFF000000 | backgroundColor);
                internalBitmapDataList[i] = bitmapData;
            }
            
            var zeroPoint:Point = new Point(0, 0);
            
            if (model == MODEL_ONEPIECE_LONGSLEEVED
            || model == MODEL_ONEPIECE_SHORTSLEEVED
            || model == MODEL_ONEPIECE_SLEEVELESS) {
                internalBitmapDataList[0].copyPixels(replacedImage, new Rectangle(0, 0, 32, 32), zeroPoint);
                internalBitmapDataList[1].copyPixels(replacedImage, new Rectangle(0, 48, 32, 32), zeroPoint);
                
                internalBitmapDataList[4].copyPixels(replacedImage, new Rectangle(0, 32, 32, 16), zeroPoint);
                internalBitmapDataList[5].copyPixels(replacedImage, new Rectangle(0, 48+32, 32, 16), zeroPoint);
            }
            
            if (model == MODEL_SHIRT_LONGSLEEVED
            || model == MODEL_SHIRT_SHORTSLEEVED
            || model == MODEL_SHIRT_SLEEVELESS) {
                internalBitmapDataList[0].copyPixels(replacedImage, new Rectangle(0, 0, 32, 32), zeroPoint);
                internalBitmapDataList[1].copyPixels(replacedImage, new Rectangle(0, 32, 32, 32), zeroPoint);
            }
            
            if (model == MODEL_ONEPIECE_LONGSLEEVED) {
                internalBitmapDataList[2].copyPixels(replacedImage, new Rectangle(0, 48*2, 32, 16), zeroPoint);
                internalBitmapDataList[3].copyPixels(replacedImage, new Rectangle(0, 48*2+16, 32, 16), zeroPoint);
            }
            
            if (model == MODEL_SHIRT_LONGSLEEVED) {
                internalBitmapDataList[2].copyPixels(replacedImage, new Rectangle(0, 32*2, 32, 16), zeroPoint);
                internalBitmapDataList[3].copyPixels(replacedImage, new Rectangle(0, 32*2+16, 32, 16), zeroPoint);
            }
            
            if (model == MODEL_ONEPIECE_SHORTSLEEVED) {
                internalBitmapDataList[2].copyPixels(replacedImage, new Rectangle(0, 48*2, 16, 16), zeroPoint);
                internalBitmapDataList[3].copyPixels(replacedImage, new Rectangle(16, 48*2, 16, 16), zeroPoint);
            }
            
            if (model == MODEL_SHIRT_SHORTSLEEVED) {
                internalBitmapDataList[2].copyPixels(replacedImage, new Rectangle(0, 32*2, 16, 16), zeroPoint);
                internalBitmapDataList[3].copyPixels(replacedImage, new Rectangle(16, 32*2, 16, 16), zeroPoint);
            }
            
            if (model == MODEL_COMIC_FOREGROUND) {
                internalBitmapDataList[0].copyPixels(replacedImage, new Rectangle(0, 0, 32, 32), zeroPoint);
                internalBitmapDataList[1].copyPixels(replacedImage, new Rectangle(0, 32, 32, 32), zeroPoint);
                internalBitmapDataList[2].copyPixels(replacedImage, new Rectangle(32, 0, 20, 32), zeroPoint);
                internalBitmapDataList[3].copyPixels(replacedImage, new Rectangle(32, 32, 20, 32), zeroPoint);
            }
            
            joinedInternalImage = new BitmapData(32, 32 * 4, false, 0xFF000000 | backgroundColor);
            
            var point:Point = new Point(0, 0);
            for (i = 0; i < n; i++ ) {
                joinedInternalImage.copyPixels(internalBitmapDataList[i], internalBitmapDataList[i].rect, point);
                point.y += internalBitmapDataList[i].height;
            }
        }
        
        /**
         * 分割デザイン画像を結合し、パレット変換画像を生成する
         */
        private function createJoinedReplacementColorMap():void
        {
            var separateBitmapDataList:Vector.<BitmapData> = new Vector.<BitmapData>();
            var modelTextureSizeArray:Array = MODEL_TEXTURE_SIZE_MAP[model];
            
            var sumHeight:int;
            var sleevedCount:int;
            var n:int = modelTextureSizeArray.length;
            for (var i:int = 0; i < n; i++ ) {
                var bitmapData:BitmapData = textureImageList[i];
                
                var rotateBitmapData:BitmapData;
                if (modelTextureSizeArray[i] == MODEL_TEXTURE_SIZE_LONGSLEEVED) {
                    rotateBitmapData = new BitmapData(modelTextureSizeArray[i].height, modelTextureSizeArray[i].width, false);
                    drawRotateBitmapData(rotateBitmapData, bitmapData, -16, 0, -Math.PI / 2);
                    bitmapData.dispose();
                    bitmapData = rotateBitmapData;
                    sumHeight += bitmapData.height;
                } else if (modelTextureSizeArray[i] == MODEL_TEXTURE_SIZE_SHORTSLEEVED) {
                    rotateBitmapData = new BitmapData(modelTextureSizeArray[i].height, modelTextureSizeArray[i].width, false);
                    drawRotateBitmapData(rotateBitmapData, bitmapData, -16, 0, -Math.PI / 2);
                    bitmapData.dispose();
                    bitmapData = rotateBitmapData;
                    
                    if (sleevedCount == 0) {
                        sumHeight += bitmapData.height;
                    }
                    
                    sleevedCount++;
                } else {
                    sumHeight += bitmapData.height;
                }
                
                separateBitmapDataList.push(bitmapData);
            }
            
            
            if(model != MODEL_COMIC_FOREGROUND) {
                replacedImage = new BitmapData(32, sumHeight);
            } else {
                replacedImage = new BitmapData(52, 64);
            }
            
            var y:int = 0;
            sleevedCount = 0;
            for (i = 0; i < n; i++ ) {
                var point:Point = new Point(0, y);
                
                if (modelTextureSizeArray[i] == MODEL_TEXTURE_SIZE_SHORTSLEEVED && sleevedCount != 0) {
                    point.x = MODEL_TEXTURE_SIZE_SHORTSLEEVED.width;
                }
                
                replacedImage.copyPixels(separateBitmapDataList[i], separateBitmapDataList[i].rect, point)
                
                if (modelTextureSizeArray[i] == MODEL_TEXTURE_SIZE_SHORTSLEEVED) {
                    if (sleevedCount != 0) {
                        y += separateBitmapDataList[i].height;
                    }
                    sleevedCount++;
                    
                } else {
                    y += separateBitmapDataList[i].height;
                }
                
            }
            
            replacementColorMap = {};
            replacedPalette = new Vector.<ColorData>();
            PaletteUtil.createReplacementColorMap(replacedImage, replacedPalette, replacementColorMap, FIXED_PALETTE[paletteType], PALETTE_LENGTH);
            var tmpImage:BitmapData = PaletteUtil.createColorReplacedBitmapData(replacedImage, replacementColorMap);
            replacedImage.dispose();
            replacedImage = tmpImage;
            
            y = 0;
            sleevedCount = 0;
            for (i = 0; i < n; i++ ) {
                point = new Point(0, y);
                
                if (modelTextureSizeArray[i] == MODEL_TEXTURE_SIZE_SHORTSLEEVED && sleevedCount != 0) {
                    point.x = MODEL_TEXTURE_SIZE_SHORTSLEEVED.width;
                }
                
                replacedImageList[i] = new BitmapData(separateBitmapDataList[i].width, separateBitmapDataList[i].height, false);
                var rect:Rectangle = new Rectangle(point.x, point.y, separateBitmapDataList[i].width, separateBitmapDataList[i].height);
                replacedImageList[i].copyPixels(replacedImage, rect, new Point(0,0))
                
                if (modelTextureSizeArray[i] == MODEL_TEXTURE_SIZE_SHORTSLEEVED) {
                    if (sleevedCount != 0) {
                        y += separateBitmapDataList[i].height;
                    }
                    sleevedCount++;
                    
                } else {
                    y += separateBitmapDataList[i].height;
                }
                
                separateBitmapDataList[i].dispose();
                separateBitmapDataList[i] = null;
            }
            
        }
        
        /**
         * ビットマップ画像を回転して描画する
         * 
         * @param	target 描画する対象
         * @param	source　回転元画像
         * @param	tx
         * @param	ty
         * @param	rotation
         */
        public static function drawRotateBitmapData(target:BitmapData, source:BitmapData, tx:int, ty:int, rotation:Number):void
        {
            var matrix:Matrix = new Matrix();
            matrix.tx = tx;
            matrix.ty = ty;
            matrix.rotate(rotation);
            target.draw(source, matrix);
        }
        
        /**
         * 内部テクスチャ画像をクリアする
         */
        private function clearInternalImageList():void
        {
            var n:int = internalBitmapDataList.length;
            for (var i:int = 0; i < n; i++ ) {
                var bitmapData:BitmapData = internalBitmapDataList[i];
                if (bitmapData != null) {
                    bitmapData.dispose();
                    internalBitmapDataList[i] = null;
                }
            }
        }
        
        /**
         * 空の内部テクスチャ画像を生成する
         * 
         * @param	textureIndex テクスチャ番号
         * @param	textureSize テクスチャサイズ
         * @return  生成した画像
         */
        private function createInternalTextureBitmapData(textureIndex:int, textureSize:Rectangle):BitmapData
        {
            var bitmapData:BitmapData = internalBitmapDataList[textureIndex];
            if (bitmapData == null) {
                bitmapData = new BitmapData(textureSize.width, textureSize.height, false);
                internalBitmapDataList[textureIndex] = bitmapData;
                return bitmapData;
            } else {
                return bitmapData;
            }
        }
        
        /**
         * バイナリを逐次読み込み、画素情報を書き込む
         * 
         * @param	startX 画像初期X座標
         * @param	startY 画像初期Y座標
         * @param	readLength 読み込むバイナリの長さ
         * @param	byteArray  パレットインデックスバイナリデータ
         * @param	bitmapData 書き込む画像データ
         * @param	paletteArray パレット情報
         * @return
         */
        private function readByteArrayToBitmapData(startX:int, startY:int, readLength:int, byteArray:ByteArray, bitmapData:BitmapData, paletteArray:Array):int
        {
            var readedCount:int = 0;
            var readLineLength:int;
            
            if (startX != 0) {
                readLineLength = (bitmapData.width - startX) / 2;
                readedCount += readByteArrayToBitmapDataLine(startY, startX, bitmapData.width, readLineLength, byteArray, bitmapData, paletteArray);
                startY++;
                startX = 0;
            }
            
            for (var y:int = startY; y < bitmapData.height; y++ ) {
                if (readedCount >= readLength) {
                    return readedCount;
                }
                
                readLineLength = (bitmapData.width - 0) / 2;
                if (readedCount + readLineLength > readLength) {
                    readLineLength = readLength - readedCount;
                }
                
                readedCount += readByteArrayToBitmapDataLine(y, 0, bitmapData.width, readLineLength, byteArray, bitmapData, paletteArray);
            }
            
            return readedCount;
        }
        
        /**
         * バイナリを逐次読み込み、画像1行分の画素情報を書き込む
         * @param	y 画像のy座標
         * @param	startX 画像の初期X座標
         * @param	endX 画像の終了X座標
         * @param	readLength 読み込むバイナリの長さ
         * @param	byteArray パレットインデックスバイナリデータ
         * @param	bitmapData 書き込む画像データ
         * @param	paletteArray パレット情報
         * @return
         */
        private function readByteArrayToBitmapDataLine(y:int, startX:int, endX:int, readLength:int, byteArray:ByteArray, bitmapData:BitmapData, paletteArray:Array):int
        {
            var readedCount:int = 0;
            for (var x:int = startX; x < endX; x += 2 ) {
                if (readedCount >= readLength) {
                    return readedCount;
                }
                
                var indexByte:uint = byteArray.readUnsignedByte();
                readedCount += 1;
                
                var preIndex:int = ((indexByte & 0xF0) >> 4) + 1;
                var postIndex:int = (indexByte & 0x0F) + 1;
                
                if (!(preIndex in paletteArray) || !(postIndex in paletteArray)
                || paletteArray[preIndex] == null || (paletteArray[postIndex] == null)
                ) {
                    continue;
                }
                
                bitmapData.setPixel(x+1, y, ColorData(paletteArray[preIndex]).color);
                bitmapData.setPixel(x, y, ColorData(paletteArray[postIndex]).color);
            }
            return readedCount;
        }
        
        /**
         * パレット配列をColorDataのVectorに変換する
         * 
         * @param	paletteTableArray
         * @return  変換後のVector
         */
        private static function createColorDataPaletteTable(paletteTableArray:Array):Vector.<Vector.<ColorData>>
        {
            var colorDataPaletteTableList:Vector.<Vector.<ColorData>> = new Vector.<Vector.<ColorData>>();
            
            var n:int = paletteTableArray.length;
            for (var i:int = 0; i < n; i++ ) {
                var paletteTable:Array = paletteTableArray[i];
                var m:int = paletteTable.length;
                
                var colorDataPaletteTable:Vector.<ColorData> = new Vector.<ColorData>();
                
                for (var j:int = 0; j < m; j++ ){
                    if (paletteTable[j] < 0) {
                        colorDataPaletteTable.push(null);
                        continue;
                    }
                
                    var color:uint = paletteTable[j];
                    var colorData:ColorData = new ColorData(color);
                    colorData.calcLab();
                    colorDataPaletteTable.push(colorData);
                }
                
                colorDataPaletteTableList.push(colorDataPaletteTable);
            }
            return colorDataPaletteTableList;
        }
        
        /**
         * パレットの色からパレット番号へのマップを生成する
         * 
         * @param	paletteTableList パレットテーブルリスト
         * @return  パレット番号へのマップリスト
         */
        private static function createPaletteIndexMap(paletteTableList:Vector.<Vector.<ColorData>>):Vector.<Object>
        {
            var mapList:Vector.<Object> = new Vector.<Object>();
            
            var n:int = paletteTableList.length;
            for (var i:int = 0; i < n; i++ ) {
                var paletteTable:Vector.<ColorData> = paletteTableList[i];
                var object:Object = { };
                var m:int = paletteTable.length;
                
                for (var j:int = 0; j < m; j++) {
                    if (paletteTable[j] == null) {
                        continue;
                    }
                
                    var color:uint = paletteTable[j].color & 0xFFFFFF;
                    object[color] = j;
                }
                
                mapList.push(object);
            }
            return mapList;
        }
        
        /**
         * QRコード画像をデコードする
         * 
         * @param	bitmapData　QRコードを含む画像データ
         * @return  デコード結果
         */
        public static function decodeQRCodeBitmapData(bitmapData:BitmapData):Result
        {
            var bufferedImageLuminanceSource:BufferedImageLuminanceSource = new BufferedImageLuminanceSource(bitmapData);
            var binaryBitmap:BinaryBitmap = new BinaryBitmap(new HybridBinarizer(bufferedImageLuminanceSource));
            
            var hints:HashTable = new HashTable();
            hints.Add(DecodeHintType.POSSIBLE_FORMATS, BarcodeFormat.QR_CODE);
            hints.Add(DecodeHintType.CHARACTER_SET, CHARACTER_CODE_LATIN1);
            hints.Add(DecodeHintType.TRY_HARDER, true);
            
            var result:Result = null;
            var reader:Reader = new StructuredQRCodeReader();
            
            try {
                result = reader.decode(binaryBitmap, hints);
            } catch (error:NotFoundException) {
                return null;
            } catch (error:ChecksumException) {
                return null;
            } catch (error:FormatException) {
                return null;
            } catch (error:Error) {
                return null;
            }
            
            return result;
        }
        
        /**
         * QRコードデコード結果をByteArrayに変換する
         * 
         * @param	result　QRコードデコード結果
         * @return  変換後のバイナリ
         */
        public static function resultToByteArray(result:Result):ByteArray
        {
            var byteArray:ByteArray = new ByteArray();
            var rawBytes:Array = result.getRawBytes();
            
            var n:int = rawBytes.length;
            for (var i:int = 0; i < n; i++) {
                byteArray.writeByte(rawBytes[i]);
            }
            
            return byteArray;
        }
        
    }
}