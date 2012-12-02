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

package info.heriet.images 
{
    import flash.display.BitmapData;
    
    public class PaletteUtil 
    {
        /**
         * 画像中の使用パレットを固定パレットへ置換するマップを生成する
         * 
         * @param    bitmapData 対象画像
         * @param    replacedPalette 空パレットを入力。固定パレット置換後の使用パレットが格納される
         * @param    replacementColorMap 空マップを入力。対象画像の色から固定パレット色への置換マップが格納される
         * @param    fixedPalette 固定パレット
         * @param    paletteLength 固定パレットの中から使用する色数。使用色より少ないとき、減色される
         */
        public static function createReplacementColorMap(
            bitmapData:BitmapData,
            replacedPalette:Vector.<ColorData>,
            replacementColorMap:Object,
            fixedPalette:Vector.<ColorData>,
            paletteLength:int
            ):void
        {
            
            // Step.1 画像中で使用されているパレットを抽出
            var usingColorMap:Object = extractUsingColorMap(bitmapData);
            var usingPalette:Vector.<ColorData> = new Vector.<ColorData>();
            for (var key:String in usingColorMap) {
                var color:uint = uint(key);
                var colorData:ColorData = new ColorData(color);
                colorData.calcLab();
                usingPalette.push(colorData);
            }
            
            // Step.2 使用パレットを元に固定パレットの中で最も近似色を選ぶ
            var nearlyPalette:Vector.<ColorData> = new Vector.<ColorData>();
            var n:int = usingPalette.length;
            for (var i:int = 0; i < n; i++ ) {
                colorData = usingPalette[i];
                var nearestColorData:ColorData = searchNearestColorData(colorData, fixedPalette);
                nearlyPalette.push(nearestColorData);
            }
            
            // Step.3 近似パレットの重複色を整理
            var uniqueNearlyPalette:Vector.<ColorData> = createUniquePalette(nearlyPalette);
            
            // Step.4 色数がpaletteLength以上なら最も近似な色を結合。最終的なパレットを置換パレットに採用
            while (uniqueNearlyPalette.length > paletteLength) {
                
                // Algorithm A (Nearest color declease)
                //    uniqueNearlyPalette = decleaseNearestColor(uniqueNearlyPalette);
                
                // Algorithm B (Low Frequency color eclease)
                uniqueNearlyPalette = decleaseLowFrequencyColor(bitmapData, usingPalette, uniqueNearlyPalette);
                
            }
            
            
            
            for each(colorData in uniqueNearlyPalette) {
                replacedPalette.push(colorData);
            }
            
            // Step.5 使用パレットから置換パレットに変換するマップを生成
            createReplacementColorMapByReplacedPalette(usingPalette, replacedPalette, replacementColorMap);
        }
        
        public static function createReplacementColorMapByReplacedPalette(usingPalette:Vector.<ColorData>, replacedPalette:Vector.<ColorData>, replacementColorMap:Object):void
        {
            var n:int = usingPalette.length;
            for (var i:int = 0; i < n; i++ ) {
                var colorData:ColorData = usingPalette[i];
                var nearestColorData:ColorData = searchNearestColorData(colorData, replacedPalette);
                
                replacementColorMap[(colorData.color & 0xFFFFFF)] = nearestColorData.color & 0xFFFFFF;
            }
        }
        
        /**
         * 色リストの中から最も近似な色を探す
         * 
         * @param    colorData 探索する色
         * @param    palette 色リスト
         * @return
         */
        public static function searchNearestColorData(colorData:ColorData, palette:Vector.<ColorData>):ColorData
        {
            var minColorData:ColorData = palette[0];
            var minLabLength:Number = colorData.labLength(minColorData);
            
            var n:int = palette.length;
            for (var i:int = 1; i < n; i++ ) {
                var oppColorData:ColorData = palette[i];
                if (oppColorData == null) {
                    continue;
                }
                
                var labLength:Number = colorData.labLength(oppColorData);
                
                if (labLength < minLabLength) {
                    minColorData = oppColorData;
                    minLabLength = labLength;
                }
            }
            
            return minColorData;
        }
        
        /**
         *  パレットの重複を除いたパレットを作成する
         * @param    palette 対象パレット
         * @return 重複除去済みパレット
         */
        public static function createUniquePalette(palette:Vector.<ColorData>):Vector.<ColorData>
        {
            var uniqurPalette:Vector.<ColorData> = new Vector.<ColorData>();
            for each(var colorData:ColorData in palette) {
                if (uniqurPalette.indexOf(colorData) < 0) {
                    uniqurPalette.push(colorData);
                }
            }
            return uniqurPalette;
        }
        
        /**
         * パレット中の色集合の中でで最も近い色を1色減色する
         * @param    palette 2色以上のパレット
         * @return 減色したパレット
         */
        public static function decleaseNearestColor(palette:Vector.<ColorData>):Vector.<ColorData>
        {
            var minColorDataList:Vector.<ColorData> = new Vector.<ColorData>();
            var minLabLengthList:Vector.<Number> = new Vector.<Number>();
            
            var n:int = palette.length;
            for (var i:int = 0; i < n-1; i++ ) {
                var colorData:ColorData = palette[i];
                
                var minLabLength:Number = Number.MAX_VALUE;
                var minColorData:ColorData = null;
                for (var j:int = i+1; j < n; j++ ) {
                    var oppColorData:ColorData = palette[j];
                    var labLength:Number = colorData.labLength(oppColorData);
                    if (labLength < minLabLength) {
                        minColorData = oppColorData;
                        minLabLength = labLength;
                    }
                }
                
                minColorDataList.push(minColorData);
                minLabLengthList.push(minLabLengthList);
            }
            
            var minIndex:int = 0;
            minLabLength = minLabLengthList[minIndex];
            for (i = 1; i < n - 1; i++ ) {
                labLength = minLabLengthList[i];
                if (labLength < minLabLength) {
                    minIndex = i;
                    minLabLength = labLength;
                }
            }
            
            var colorDataA:ColorData = palette[minIndex];
            var colorDataB:ColorData = minColorDataList[minIndex];
            
            var sumA:Number = calcLabLengthSum(colorDataA, palette);
            var sumB:Number = calcLabLengthSum(colorDataB, palette);
            
            var removeColor:ColorData;
            
            if (sumA < sumB) {
                removeColor = colorDataA;
            } else {
                removeColor = colorDataB;
            }
            
            var removeIndex:int = palette.indexOf(removeColor);
            palette.splice(removeIndex, 1);
            
            return palette;
        }
        
        /**
         * 画像を置換パレットに変換し、最も使われていない置換パレットを1色減らす
         * 
         * @param    bitmapData
         * @param    usingPalette
         * @param    replacedPalette 
         * @return 減色した置換パレット
         */
        public static function decleaseLowFrequencyColor(bitmapData:BitmapData, usingPalette:Vector.<ColorData>, replacedPalette:Vector.<ColorData>):Vector.<ColorData>
        {
            var colorMap:Object = { };
            createReplacementColorMapByReplacedPalette(usingPalette, replacedPalette, colorMap);
            var replacedBitmapData:BitmapData = createColorReplacedBitmapData(bitmapData, colorMap);
            var replacedUsingColorMap:Object = extractUsingColorMap(bitmapData);
                
            var minColorCount:int = int.MAX_VALUE;
            var minColorIndex:int = -1;
            for(var key:String in replacedPalette) {
                var index:int = int(key);
                var color:uint = replacedPalette[index].color;
                var count:int = replacedUsingColorMap[color]
                
                if (count < minColorCount) {
                    minColorIndex = index;
                    minColorCount = count;
                }
            }
                
            replacedPalette.splice(minColorIndex, 1);
            replacedBitmapData.dispose();
            
            return replacedPalette;
        }
        
        /**
         * パレットと色とのLab距離の総計を返す
         * @param    colorData 色
         * @param    palette パレット
         * @return Lab距離の総計
         */
        public static function calcLabLengthSum(colorData:ColorData, palette:Vector.<ColorData>):Number
        {
            var sum:Number = 0;
            var n:int = palette.length;
            for (var i:int = 0; i < n; i++ ) {
                sum += colorData.labLength(palette[i]);
            }
            return sum;
        }
        
        /**
         * 画像を色置換マップで変換した画像を生成する
         * 
         * @param    bitmapData 画像
         * @param    replacementColorMap 色置換マップ
         * @return 色置換画像
         */
        public static function createColorReplacedBitmapData(bitmapData:BitmapData, replacementColorMap:Object):BitmapData
        {
            var replacedBitmapData:BitmapData = new BitmapData(bitmapData.width, bitmapData.height);
            for (var y:int = 0; y < bitmapData.height; y++ ) {
                for (var x:int = 0; x < bitmapData.width; x++ ) {
                    var color:uint = bitmapData.getPixel(x, y);
                    var replacedColor:uint = replacementColorMap[color];
                    replacedBitmapData.setPixel32(x, y, 0xFF000000 | replacedColor);
                }
            }
            return replacedBitmapData;
        }
        
        
        /**
         * 画像中に使用されている色ヒストグラムデータを抽出する
         * 
         * @param    bitmapData 対象画像
         * @return 使用パレット数マップ
         */
        public static function extractUsingColorMap(bitmapData:BitmapData):Object
        {
            var usingColorMap:Object = {};
            
            for (var y:int = 0; y < bitmapData.height; y++ ) {
                for (var x:int = 0; x < bitmapData.width; x++ ) {
                    var color:uint = bitmapData.getPixel(x, y);
                    if (color in usingColorMap) {
                        usingColorMap[color]++;
                    } else {
                        usingColorMap[color] = 1;
                    }
                }
            }
            
            return usingColorMap;
        }
    }

}