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
    public class ColorData
    {
        public static const RGB:String = 'rgb';
        public static const HSV:String = 'hsv';
        public static const HLS:String = 'hls';
        public static const LAB:String = 'lab';
        
        public var color:uint;
        
        public var alpha:int;
        public var red:int;
        public var green:int;
        public var blue:int;
        
        public var l:Number;
        public var a:Number;
        public var b:Number;
        
        public var hue:int;
        public var lightness:Number;
        public var saturation:Number;
        public var value:Number;
        
        
        public function ColorData(color:uint) 
        {
            this.color = color;
            
            alpha = (color & 0xFF000000) >>> 24;
            red = (color & 0xFF0000) >>> 16;
            green = (color & 0xFF00) >>> 8;
            blue = (color & 0xFF);
        }
        
        public function getLabToRGB(l:Number, a:Number, b:Number):uint
        {
            var yr:Number = l > 903.3 * 0.008856 ? Math.pow((l + 16) / 116, 3) : l / 903.3;
            var fy:Number = yr > 0.008856 ? (l + 16) / 116 : (903.3 * yr + 16) / 116;
            var fx:Number = a / 500 + fy;
            var fz:Number = fy - b / 200;
            var fx3:Number = Math.pow(fx, 3);
            var fz3:Number = Math.pow(fz, 3);
            var xr:Number = fx3 > 0.008856 ? fx3 : (116 * fx - 16) / 903.3;
            var zr:Number = fz3 > 0.008856 ? fz3 : (116 * fz - 16) / 903.3;
            var x:Number = xr * 0.95045;
            var y:Number = yr;
            var z:Number = zr * 1.08892;
            
            var myRed:int = limitInt((3.240479 * x - 1.53715 * y - 0.498535 * z) * 255, 0, 255);
            var myGreen:int = limitInt((-0.969256 * x + 1.875991 * y + 0.041556 * z) * 255, 0, 255);
            var myBlue:int = limitInt((0.055648 * x - 0.204043 * y + 1.057311 * z)* 255, 0, 255); 
            
            return (myRed << 16) + (myGreen << 8) + myBlue;
        }
        
        public function calcLab():void
        {
            var x:Number = 0.412391 * red/255 + 0.357584 * green/255 + 0.180481 * blue/255;
            var y:Number = 0.212639 * red/255 + 0.715169 * green/255 + 0.072192 * blue/255;
            var z:Number = 0.019331 * red/255 + 0.119195 * green/255 + 0.950532 * blue/255;
            
            var fx:Number = f(x / 0.95045);
            var fy:Number = f(y);
            var fz:Number = f(z / 1.08892);
            
            l = 116 * fy - 16;
            a = 500 * (fx - fy);
            b = 200 * (fy - fz);
            
            function f(value:Number):Number
            {
                return value > 0.008856 ? Math.pow(value, 1 / 3) : (903.3 * value + 16) / 116;
            }
        }
        
        public function getHLSToRGB(h:int, l:Number, s:Number):uint
        {
            var myRed:int, myGreen:int, myBlue:int;
            var maxR:Number = l <= 0.5 ? l * (1 + s) : l * (1 - s) + s;
            var minR:Number = 2 * l - maxR;
            
            if (s == 0){
                myRed = myGreen = myBlue = lightness * 255;
            }
            else {
                var hk:Number = h / 360;
                var tr:Number = hk + 1 / 3;
                var tg:Number = hk;
                var tb:Number = hk - 1 / 3;
                
                if (tr < 0) tr += 1.0;
                if (tg < 0) tg += 1.0;
                if (tb < 0) tb += 1.0;
                
                if (tr > 1) tr -= 1.0;
                if (tg > 1) tg -= 1.0;
                if (tb > 1) tb -= 1.0;
                
                myRed = limitInt(funcT(minR, maxR, tr)*255, 0, 255);
                myGreen = limitInt(funcT(minR, maxR, tg)*255, 0, 255);
                myBlue = limitInt(funcT(minR, maxR, tb)*255, 0, 255);    
            }
            
            return (myRed << 16) + (myGreen << 8) + myBlue;
            
            function funcT(p:Number, q:Number, t:Number):Number
            {
                if (t < 1 / 6)
                    return p +((q - p) * 6 * t);
                else if (t < 1 / 2)
                    return q;
                else if (t < 2 / 3)
                    return p + ((q - p) * (4 - 6*t));
                else
                    return p;
            }
        }
        
        public function calcHLS():void
        {
            var max:int = red;
            var min:int = red;
            
            if (max < green)
                max = green;
            if (max < blue)
                max = blue;
                
            if (green < min)
                min = green;
            if (blue < min)
                min = blue;
            
            var maxR:Number = max / 255;
            var minR:Number = min / 255;
            
            lightness = (maxR + minR) / 2;
            
            if (max == min) {
                saturation = 0;
                hue = 0;
            }
            else {
                saturation = lightness <= 0.5 ? (maxR - minR) / (maxR + minR) : (maxR - minR) / (2 - maxR - minR);
                var cr:Number = (maxR - red / 255) / (maxR - minR);
                var cg:Number = (maxR - green / 255) / (maxR - minR);
                var cb:Number = (maxR - blue / 255) / (maxR - minR);
                
                if (red == max)
                    hue = (cb - cg) * 60;
                else if (green == max)
                    hue = (2 + cr - cb) * 60;
                else
                    hue = (4 + cg - cr) * 60;
                
                hue = (hue + 360) % 360;
            }
        }
        
        public function labLength(cd:ColorData):Number
        {
            return Math.pow(l - cd.l, 2) + Math.pow(a - cd.a, 2) + Math.pow(b - cd.b, 2);
        }
        
        private function limitInt(value:int, min:int, max:int):int
        {
            if (value < min)
                value = min;
            else if (value > max)
                value = max;
            return value;
        }
        private function limitNumber(value:Number, min:Number, max:Number):Number
        {
            if (value < min)
                value = min;
            else if (value > max)
                value = max;
            return value;
        }
    }
    
}