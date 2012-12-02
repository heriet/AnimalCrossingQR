/*
 * Almost all copy of ccom.google.zxing.qrcode.encoder.Encoder
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
     * @see com.google.zxing.qrcode.encoder.Encoder
     */
    
    import com.google.zxing.EncodeHintType;
    import com.google.zxing.qrcode.encoder.BitVector;
    import com.google.zxing.qrcode.encoder.BlockPair;
    import com.google.zxing.qrcode.encoder.MaskUtil;
    import com.google.zxing.qrcode.encoder.MatrixUtil;
    import com.google.zxing.qrcode.encoder.QRCode;
    import com.google.zxing.WriterException;
    import com.google.zxing.common.ByteMatrix;
    import com.google.zxing.common.CharacterSetECI;
    import com.google.zxing.common.flexdatatypes.ArrayList;
    import com.google.zxing.common.flexdatatypes.HashTable;
    import com.google.zxing.common.reedsolomon.GenericGF;
    import com.google.zxing.common.reedsolomon.ReedSolomonEncoder;
    import com.google.zxing.common.zxingByteArray;
    import com.google.zxing.qrcode.decoder.ECBlocks;
    import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
    import com.google.zxing.qrcode.decoder.Mode;
    import com.google.zxing.qrcode.decoder.Version;
    import flash.utils.ByteArray;
    
    public class QRCodeBinaryEncoder
    {
        public static var DEFAULT_BYTE_MODE_ENCODING:String = "iso-8859-1";
        
        protected static function calculateMaskPenalty(matrix:ByteMatrix):int
        {
            var penalty:int = 0;
            penalty += MaskUtil.applyMaskPenaltyRule1(matrix);
            penalty += MaskUtil.applyMaskPenaltyRule2(matrix);
            penalty += MaskUtil.applyMaskPenaltyRule3(matrix);
            penalty += MaskUtil.applyMaskPenaltyRule4(matrix);
            return penalty;
        }
        
        public static function encodeByteArray(byteArray:ByteArray, ecLevel:ErrorCorrectionLevel, qrCode:QRCode, hints:HashTable = null, structureNum:int = 0, structureIndex:int = 0, structureParity:int = 0):void
        {
            var encoding:String = DEFAULT_BYTE_MODE_ENCODING;
            
            // Step 1: Choose the mode (encoding).
            var mode:Mode = Mode.BYTE;
            
            // Step 2: Append "bytes" into "dataBits" in appropriate encoding.
            var dataBits:BitVector = new BitVector();
            appendByteArray(byteArray, dataBits);
            
            // Step 3: Initialize QR code that can contain "dataBits".
            var numInputBytes:int = dataBits.sizeInBytes();
            initQRCode(numInputBytes, ecLevel, mode, qrCode);
            
            // Step 4: Build another bit vector that contains header and data.
            var headerAndDataBits:BitVector = new BitVector();
            
            // Step 4.5: Append ECI message if applicable
            //if (mode == Mode.BYTE && encoding != DEFAULT_BYTE_MODE_ENCODING) {
            //    var eci:CharacterSetECI = CharacterSetECI.getCharacterSetECIByName(encoding);
            //    if (eci != null) {
            //        appendECI(eci, headerAndDataBits);
            //    }
            //}
            
            // Structure Append
            if (structureNum > 0) {
                headerAndDataBits.appendBits(Mode.STRUCTURED_APPEND.getBits(), 4);
                headerAndDataBits.appendBits(structureIndex, 4);
                headerAndDataBits.appendBits(structureNum-1, 4);
                headerAndDataBits.appendBits(structureParity, 8);
            }
            
            
            appendModeInfo(mode, headerAndDataBits);
            
            var numLetters:int = (mode == Mode.BYTE) ? dataBits.sizeInBytes() : byteArray.length;
            appendLengthInfo(numLetters, qrCode.getVersion(), mode, headerAndDataBits);
            headerAndDataBits.appendBitVector(dataBits);
            
            headerAndDataBits.makeByteArray(); // make byte array 
            
            // Step 5: Terminate the bits properly.
            terminateBits(qrCode.getNumDataBytes(), headerAndDataBits);
            
            // Step 6: Interleave data bits with error correction code.
            var finalBits:BitVector = new BitVector();
            interleaveWithECBytes(headerAndDataBits, qrCode.getNumTotalBytes(), qrCode.getNumDataBytes(), qrCode.getNumRSBlocks(), finalBits);
            
            finalBits.makeByteArray();
            
            // Step 7: Choose the mask pattern and set to "qrCode".
            var matrix:ByteMatrix = new ByteMatrix(qrCode.getMatrixWidth(), qrCode.getMatrixWidth());
            
            var ec:ErrorCorrectionLevel = qrCode.getECLevel()
            var v:int = qrCode.getVersion();
            
            var maskpattern:int = chooseMaskPattern(finalBits, qrCode.getECLevel(), qrCode.getVersion(), matrix)
            qrCode.setMaskPattern(maskpattern);
            
            // Step 8.  Build the matrix and set it to "qrCode".
            MatrixUtil.buildMatrix(finalBits, qrCode.getECLevel(), qrCode.getVersion(), qrCode.getMaskPattern(), matrix);
            
            qrCode.setMatrix(matrix);
            //var A:String = matrix.toString2();
            
            // Step 9.  Make sure we have a valid QR Code.
            if (!qrCode.isValid())
            {
                throw new WriterException("Invalid QR code: " + qrCode.toString());
            }
        }
        
        protected static function chooseMaskPattern(bits:BitVector, ecLevel:ErrorCorrectionLevel, version:int, matrix:ByteMatrix):int
        {
            var minPenalty:int = int.MAX_VALUE; // Lower penalty is better.
            var bestMaskPattern:int = -1;
            // We try all mask patterns to choose the best one.
            for (var maskPattern:int = 0; maskPattern < QRCode.NUM_MASK_PATTERNS; maskPattern++)
            {
                MatrixUtil.buildMatrix(bits, ecLevel, version, maskPattern, matrix);
                var penalty:int = calculateMaskPenalty(matrix);
                
                if (penalty < minPenalty)
                {
                    minPenalty = penalty;
                    bestMaskPattern = maskPattern;
                }
            }
            
            return bestMaskPattern;
        }
        
        protected static function initQRCode(numInputBytes:int, ecLevel:ErrorCorrectionLevel, mode:Mode, qrCode:QRCode):void
        {
            qrCode.setECLevel(ecLevel);
            qrCode.setMode(mode);
            
            // In the following comments, we use numbers of Version 7-H.
            for (var versionNum:int = 1; versionNum <= 40; versionNum++)
            {
                var version:Version = Version.getVersionForNumber(versionNum);
                var numBytes:int = version.getTotalCodewords();
                var ecBlocks:ECBlocks = version.getECBlocksForLevel(ecLevel);
                var numEcBytes:int = ecBlocks.getTotalECCodewords();
                var numRSBlocks:int = ecBlocks.getNumBlocks();
                var numDataBytes:int = numBytes - numEcBytes;
                
                // We want to choose the smallest version which can contain data of "numInputBytes" + some
                // extra bits for the header (mode info and length info). The header can be three bytes
                // (precisely 4 + 16 bits) at most. Hence we do +3 here.
                if (numDataBytes >= numInputBytes + 3)
                {
                    qrCode.setVersion(versionNum);
                    qrCode.setNumTotalBytes(numBytes);
                    qrCode.setNumDataBytes(numDataBytes);
                    qrCode.setNumRSBlocks(numRSBlocks);
                    qrCode.setNumECBytes(numEcBytes);
                    qrCode.setMatrixWidth(version.getDimensionForVersion());
                    return;
                }
            }
            
            throw new WriterException("Cannot find proper rs block info (input data too big?)");
        }
        
        /**
         * Terminate bits as described in 8.4.8 and 8.4.9 of JISX0510:2004 (p.24).
         */
        public static function terminateBits(numDataBytes:int, bits:BitVector):void
        {
            var capacity:int = numDataBytes << 3;
            if (bits.size() > capacity) {
                throw new WriterException("data bits cannot fit in the QR Code" + bits.size() + " > " + capacity);
            }
            
            // Append termination bits. See 8.4.8 of JISX0510:2004 (p.24) for details.
            // TODO: srowen says we can remove this for loop, since the 4 terminator bits are optional if
            // the last byte has less than 4 bits left. So it amounts to padding the last byte with zeroes
            // either way.
            for (var i3:int = 0; i3 < 4 && bits.size() < capacity; ++i3) {
                bits.appendBit(0);
            }
            
            var numBitsInLastByte:int = bits.size() % 8;
            // If the last byte isn't 8-bit aligned, we'll add padding bits.
            if (numBitsInLastByte > 0) {
                var numPaddingBits:int = 8 - numBitsInLastByte;
                for (var i2:int = 0; i2 < numPaddingBits; ++i2) {
                    bits.appendBit(0);
                }
            }
            // Should be 8-bit aligned here.
            if (bits.size() % 8 != 0) {
                throw new WriterException("Number of bits is not a multiple of 8");
            }
            
            // If we have more space, we'll fill the space with padding patterns defined in 8.4.9 (p.24).
            var numPaddingBytes:int = numDataBytes - bits.sizeInBytes();
            for (var i:int = 0; i < numPaddingBytes; ++i) {
                if (i % 2 == 0) {
                    bits.appendBits(0xec, 8);
                } else {
                    bits.appendBits(0x11, 8);
                }
            }
            
            if (bits.size() != capacity) {
                throw new WriterException("Bits size does not equal capacity");
            }
        }
        
        /**
         * Get number of data bytes and number of error correction bytes for block id "blockID". Store
         * the result in "numDataBytesInBlock", and "numECBytesInBlock". See table 12 in 8.5.1 of
         * JISX0510:2004 (p.30)
         */
        public static function getNumDataBytesAndNumECBytesForBlockID(numTotalBytes:int, numDataBytes:int, numRSBlocks:int, blockID:int, numDataBytesInBlock:Array, numECBytesInBlock:Array):void
        {
            if (blockID >= numRSBlocks) {
                throw new WriterException("Block ID too large");
            }
            
            var numRsBlocksInGroup2:int = numTotalBytes % numRSBlocks;
            var numRsBlocksInGroup1:int = numRSBlocks - numRsBlocksInGroup2;
            var numTotalBytesInGroup1:int = numTotalBytes / numRSBlocks;
            var numTotalBytesInGroup2:int = numTotalBytesInGroup1 + 1;
            var numDataBytesInGroup1:int = numDataBytes / numRSBlocks;
            var numDataBytesInGroup2:int = numDataBytesInGroup1 + 1;
            var numEcBytesInGroup1:int = numTotalBytesInGroup1 - numDataBytesInGroup1;
            var numEcBytesInGroup2:int = numTotalBytesInGroup2 - numDataBytesInGroup2;
            
            // Sanity checks.
            if (numEcBytesInGroup1 != numEcBytesInGroup2) {
                throw new WriterException("EC bytes mismatch");
            }
            
            if (numRSBlocks != numRsBlocksInGroup1 + numRsBlocksInGroup2) {
                throw new WriterException("RS blocks mismatch");
            }
            
            if (numTotalBytes != ((numDataBytesInGroup1 + numEcBytesInGroup1) * numRsBlocksInGroup1) + ((numDataBytesInGroup2 + numEcBytesInGroup2) * numRsBlocksInGroup2)) {
                throw new WriterException("Total bytes mismatch");
            }
            
            if (blockID < numRsBlocksInGroup1) {
                numDataBytesInBlock[0] = numDataBytesInGroup1;
                numECBytesInBlock[0] = numEcBytesInGroup1;
            } else {
                numDataBytesInBlock[0] = numDataBytesInGroup2;
                numECBytesInBlock[0] = numEcBytesInGroup2;
            }
        }
        
        /**
         * Interleave "bits" with corresponding error correction bytes. On success, store the result in
         * "result". The interleave rule is complicated. See 8.6 of JISX0510:2004 (p.37) for details.
         */
        public static function interleaveWithECBytes(bits:BitVector, numTotalBytes:int, numDataBytes:int, numRSBlocks:int, result:BitVector):void
        {
            // "bits" must have "getNumDataBytes" bytes of data.
            if (bits.sizeInBytes() != numDataBytes) {
                throw new WriterException("Number of bits and data bytes does not match");
            }
            
            // Step 1.  Divide data bytes into blocks and generate error correction bytes for them. We'll
            // store the divided data bytes blocks and error correction bytes blocks into "blocks".
            var dataBytesOffset:int = 0;
            var maxNumDataBytes:int = 0;
            var maxNumEcBytes:int = 0;
            
            // Since, we know the number of reedsolmon blocks, we can initialize the vector with the number.
            //var blocks:ArrayList = new ArrayList(numRSBlocks);
            var blocks:ArrayList = new ArrayList();
            
            for (var i4:int = 0; i4 < numRSBlocks; ++i4) {
                var numDataBytesInBlock:Array = new Array(1);
                var numEcBytesInBlock:Array = new Array(1);
                getNumDataBytesAndNumECBytesForBlockID(numTotalBytes, numDataBytes, numRSBlocks, i4, numDataBytesInBlock, numEcBytesInBlock);
                
                var dataBytes2:zxingByteArray = new zxingByteArray();
                dataBytes2._set(bits.getArray(), dataBytesOffset, numDataBytesInBlock[0]);
                var ecBytes2:zxingByteArray = generateECBytes(dataBytes2, numEcBytesInBlock[0]);
                blocks.addElement(new BlockPair(dataBytes2, ecBytes2));
                
                maxNumDataBytes = Math.max(maxNumDataBytes, dataBytes2.size());
                maxNumEcBytes = Math.max(maxNumEcBytes, ecBytes2.size());
                dataBytesOffset += numDataBytesInBlock[0];
            }
            
            if (numDataBytes != dataBytesOffset) {
                throw new WriterException("Data bytes does not match offset");
            }
            
            // First, place data blocks.
            for (var i2:int = 0; i2 < maxNumDataBytes; ++i2) {
                for (var j2:int = 0; j2 < blocks.size(); ++j2) {
                    var dataBytes:zxingByteArray = (blocks.elementAt(j2) as BlockPair).getDataBytes();
                    if (i2 < dataBytes.size()) {
                        result.appendBits(dataBytes.at(i2), 8);
                    }
                }
            }
            
            // Then, place error correction blocks.
            for (var i:int = 0; i < maxNumEcBytes; ++i) {
                for (var j:int = 0; j < blocks.size(); ++j) {
                    var ecBytes:zxingByteArray = (blocks.elementAt(j) as BlockPair).getErrorCorrectionBytes();
                    if (i < ecBytes.size()) {
                        result.appendBits(ecBytes.at(i), 8);
                    }
                }
            }
            
            if (numTotalBytes != result.sizeInBytes()) {
                throw new WriterException("Interleaving error: " + numTotalBytes + " and " + result.sizeInBytes() + " differ.");
            }
        }
        
        public static function generateECBytes(dataBytes:zxingByteArray, numEcBytesInBlock:int):zxingByteArray
        {
            var numDataBytes:int = dataBytes.size();
            var toEncode:Array = new Array(numDataBytes + numEcBytesInBlock);
            for (var i:int = 0; i < numDataBytes; i++) {
                toEncode[i] = dataBytes.at(i);
            }
            new ReedSolomonEncoder(GenericGF.QR_CODE_FIELD_256).encode(toEncode, numEcBytesInBlock);
            
            var ecBytes:zxingByteArray = new zxingByteArray(numEcBytesInBlock);
            for (var i4:int = 0; i4 < numEcBytesInBlock; i4++) {
                ecBytes.setByte(i4, toEncode[numDataBytes + i4]);
            }
            return ecBytes;
        }
        
        /**
         * Append mode info. On success, store the result in "bits".
         */
        public static function appendModeInfo(mode:Mode, bits:BitVector):void
        {
            bits.appendBits(mode.getBits(), 4);
        }
        
        /**
         * Append length info. On success, store the result in "bits".
         */
        public static function appendLengthInfo(numLetters:int, version:int, mode:Mode, bits:BitVector):void
        {
            var numBits:int = mode.getCharacterCountBits(Version.getVersionForNumber(version));
            if (numLetters > ((1 << numBits) - 1)) {
                throw new WriterException(numLetters + "is bigger than" + ((1 << numBits) - 1));
            }
            bits.appendBits(numLetters, numBits);
        }
        
        public static function appendByteArray(byteArray:ByteArray, bits:BitVector):void
        {
            var n:int = byteArray.length;
            for (var i:int = 0; i < n; i++) {
                bits.appendBits(byteArray[i], 8);
            }
        }
    }
}