/*
 * Almost all copy of com.google.zxing.qrcode.QRCodeWriter
 * STRUCTURE_APPEND suported
 */

/*
 * Copyright 2007 ZXing authors
 * edit by Heriet [http://heriet.info/]
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package info.heriet.zxing.qrcode.encoder 
{
    /**
     * @see com.google.zxing.qrcode.QRCodeWriter
     * 
     * QRCodeBinaryWriter implements encode from Binary and encode by structured append mode
     */
    
    import com.google.zxing.common.ByteMatrix;
    import com.google.zxing.common.flexdatatypes.HashTable;
    import com.google.zxing.common.flexdatatypes.IllegalArgumentException;
    import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
       import com.google.zxing.BarcodeFormat;
    import com.google.zxing.EncodeHintType;
    import com.google.zxing.qrcode.encoder.QRCode;
    import com.google.zxing.Writer;
    import com.google.zxing.WriterException;
    import com.google.zxing.common.BitMatrix;
    import flash.utils.ByteArray;
     
    public class QRCodeBinaryWriter
    {
        private static  var QUIET_ZONE_SIZE:int = 4;
        
        /**
        * @see com.google.zxing.qrcode.QRCodeWriter#encode
        * 
        * copy of QRCodeWriter#encode
        */
        public function encodeByteArray(byteArray:ByteArray, format:BarcodeFormat = null, width:int = 0, height:int = 0, hints:HashTable = null, structureNum:int = 0, structureIndex:int = 0, structureParity:int = 0):Object
        {    
            if (byteArray == null || byteArray.length == 0) {
                throw new IllegalArgumentException("Found empty contents");
            }
            
            if (format != BarcodeFormat.QR_CODE) {
              throw new IllegalArgumentException("Can only encode QR_CODE, but got " + format);
            }
            
            if (width < 0 || height < 0) {
              throw new IllegalArgumentException("Requested dimensions are too small: " + width + 'x' + height);
            }
            
            var errorCorrectionLevel:ErrorCorrectionLevel = ErrorCorrectionLevel.L;
            if (hints != null) {
                var requestedECLevel:ErrorCorrectionLevel = hints.getValueByKey(EncodeHintType.ERROR_CORRECTION) as ErrorCorrectionLevel;
                if (requestedECLevel != null) {
                    errorCorrectionLevel = requestedECLevel;
                }
            }
            
            var code:QRCode = new QRCode();
            QRCodeBinaryEncoder.encodeByteArray(byteArray, errorCorrectionLevel, code, hints, structureNum, structureIndex, structureParity);
            return renderResult(code, width, height);
        }
        
        /**
        * @see com.google.zxing.qrcode.QRCodeWriter#renderResult
        * 
        * copy of QRCodeWriter#renderResult
        */
        protected static function renderResult(code:QRCode, width:int, height:int):BitMatrix
        {
            var input:ByteMatrix  = code.getMatrix();
            var inputWidth:int = input.width();
            var inputHeight:int = input.height();
            var qrWidth:int = inputWidth + (QUIET_ZONE_SIZE << 1);
            var qrHeight:int = inputHeight + (QUIET_ZONE_SIZE << 1);
            var outputWidth:int = Math.max(width, qrWidth);
            var outputHeight:int = Math.max(height, qrHeight);
            
            var multiple:int = Math.min(outputWidth / qrWidth, outputHeight / qrHeight);
            var leftPadding:int = (outputWidth - (inputWidth * multiple)) / 2;
            var topPadding:int = (outputHeight - (inputHeight * multiple)) / 2;
            
            var output:BitMatrix = new BitMatrix(outputHeight, outputWidth);
            
            for (var inputY:int = 0, outputY:int = topPadding; inputY < inputHeight; inputY++, outputY += multiple) {
                for (var inputX:int = 0, outputX:int = leftPadding; inputX < inputWidth; inputX++, outputX += multiple) {
                    if (input._get(inputX, inputY) == 1) {
                        output.setRegion(outputX, outputY, multiple, multiple);
                    }
                }
            }
            
            return output;
        }
    }
}