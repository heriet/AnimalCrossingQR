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
    import flash.net.FileFilter;
    
    public class FileUtils 
    {
        public static const FILE_FILTER_ALL:FileFilter = new FileFilter('All files', '*.*');
        public static const FILE_FILTER_PHOTO:FileFilter = new FileFilter('Photo', '*.jpg;*.gif;*.png');
        public static const FILE_FILTER_PIXELART:FileFilter = new FileFilter('Pixel Art', '*.png;*.gif;*.edg;*.gal');
        
        public static const FILE_FILTER_PNG:FileFilter = new FileFilter('PNG','*.png');
        public static const FILE_FILTER_GIF:FileFilter = new FileFilter('GIF', '*.gif');
        public static const FILE_FILTER_JPG:FileFilter = new FileFilter('JPG', '*.jpg');
        public static const FILE_FILTER_EDG:FileFilter = new FileFilter('EDG', '*.edg');
        public static const FILE_FILTER_GAL:FileFilter = new FileFilter('GAL', '*.gal');
    }

}