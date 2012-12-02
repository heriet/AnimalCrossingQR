/*
 * Copyright (c) 2009 Heriet [http://heriet.info/].
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
  import flash.utils.ByteArray;
  import flash.utils.Dictionary;
  import flash.display.Bitmap;
  import flash.display.Sprite;
  
  public class PixelArt implements IPixelArt
  {
    
    private var _decoder:*;
    private var _type:String;
    private var _frameArray:Array;
    
    public function loadFile(data:ByteArray, fileName:String):Boolean
    {
        var nameSplit:Array = fileName.split('.');
        var type:String = nameSplit[nameSplit.length - 1];
        type = type.toLocaleLowerCase();
        return load(data, type);
    }
    public function load(data:ByteArray, type:String):Boolean
    {
      _type = type;
      
      switch(type) {
        case 'gif':
            return false;
          //return loadGIF(data);
          break;
        case 'png':
          return loadPNG(data);
          break;
        case 'edg':
          return loadEDG(data);
          break;
        case 'gal':
          return loadGAL(data);
          break;
        default:
          return false;
          break;
      }
      return false;
    }
    
    /*
    public function loadGIF(data:ByteArray):Boolean
    {
      var gifDecoder:GIFDecoder = new GIFDecoder();
      this._decoder = gifDecoder;
      
      try {
                gifDecoder.read(data);
            }
            catch (e:Error) {
                return false;
            }
            _frameArray = [];
            var n:int = gifDecoder.getFrameCount();
            for (var i:int = 0; i < n; i++) {
                var frame:FrameData = new FrameData();
                var gifFrame:GIFFrame = gifDecoder.getFrame(i);
                frame.display = new Sprite();
                frame.display.addChild(new Bitmap(gifFrame.bitmapData));
                frame.wait = gifFrame.delay;
                frame.nextBackgroundType = 0; //gifFrame.dispose;
                frame.width = gifFrame.bitmapData.width;
                frame.height = gifFrame.bitmapData.height;
                
                frame.layers = [];
                var layer:LayerData = new LayerData();
                layer.image = gifFrame.bitmapData;
                frame.layers.push(layer);
                
                _frameArray.push(frame);
            }
      return true;
    }
    */
    
    public function loadPNG(data:ByteArray):Boolean
    {
      var pngDecoder:PNGDecoder = new PNGDecoder();
      this._decoder = pngDecoder;
      
      try {
                pngDecoder.decode(data);
            }
            catch (e:Error) {
                return false;
            }
      
            _frameArray = [];
            var frame:FrameData = new FrameData();
            frame.display = new Sprite();
            frame.display.addChild(new Bitmap(pngDecoder.image));
            frame.width = pngDecoder.image.width;
            frame.height = pngDecoder.image.height;
            
            frame.layers = [];
            var layer:LayerData = new LayerData();
            layer.image = pngDecoder.image;
            layer.transparent = pngDecoder.transparent;
            frame.layers.push(layer);
            
            _frameArray.push(frame);

      return true;
    }
    public function loadEDG(data:ByteArray):Boolean
    {
      var edgDecoder:EDGDecoder = new EDGDecoder();
      this._decoder = edgDecoder;
      
      try {
                edgDecoder.decode(data);
            }
            catch (e:Error) {
                return false;
            }
      
      return true;
    }
    public function loadGAL(data:ByteArray):Boolean
    {
      var galDecoder:GALDecoder = new GALDecoder();
      this._decoder = galDecoder;
      
      try {
                galDecoder.decode(data);
            }
            catch (e:Error) {
                return false;
            }
      
      return true;
    }
    
    public function setBitmapData(bitmapData:BitmapData, paletteTable:Array, transparentIndex:int):void
    {
        _type = 'bmp';
        
        _frameArray = [];
        var frame:FrameData = new FrameData();
        frame.display = new Sprite();
        frame.display.addChild(new Bitmap(bitmapData));
        frame.width = bitmapData.width;
        frame.height = bitmapData.height;
        frame.transparent = transparentIndex;
        frame.paletteTable = paletteTable;
            
        frame.layers = [];
        var layer:LayerData = new LayerData();
        layer.image = bitmapData;
        layer.transparent = transparentIndex;
        frame.layers.push(layer);
            
        _frameArray.push(frame);
    }
    
    public function get decoder():*
    {
      return decoder;
    }
    public function get type():String
    {
      return _type;
    }
    public function get width():int
    {
      switch(type) {
        case 'gif':
            return 0;
          //var gifDecoder:GIFDecoder = _decoder as GIFDecoder;
          //return gifDecoder.getFrame(0).bitmapData.width;
          break;
        case 'png':
          var pngDecoder:PNGDecoder = _decoder as PNGDecoder;
          return pngDecoder.image.width;  
          break;
        case 'edg':
          var edgDecoder:EDGDecoder = _decoder as EDGDecoder;
          return edgDecoder.width;
          break;
        case 'gal':
          var galDecoder:GALDecoder = _decoder as GALDecoder;
          return galDecoder.width;
          break;
        case 'bmp':
          return FrameData(_frameArray[0]).width;
          break;
        default:
          return 0;
          break;
      }
    }
    
    public function get height():int
    {
      switch(type) {
        case 'gif':
            return 0;
          //var gifDecoder:GIFDecoder = _decoder as GIFDecoder;
          //return gifDecoder.getFrame(0).bitmapData.height;
          break;
        case 'png':
          var pngDecoder:PNGDecoder = _decoder as PNGDecoder;
          return pngDecoder.image.height;  
          break;
        case 'edg':
          var edgDecoder:EDGDecoder = _decoder as EDGDecoder;
          return edgDecoder.height;
          break;
        case 'gal':
          var galDecoder:GALDecoder = _decoder as GALDecoder;
          return galDecoder.height;
          break;
        case 'bmp':
          return FrameData(_frameArray[0]).height;
          break;
        default:
          return 0;
          break;
      }
    }
    
    public function get frameArray():Array
    {
      switch(type) {
        case 'gif':
            return null;
          //return _frameArray;
          break;
        case 'png':
          return _frameArray;  
          break;
        case 'edg':
          var edgDecoder:EDGDecoder = _decoder as EDGDecoder;
          return edgDecoder.pages;
          break;
        case 'gal':
          var galDecoder:GALDecoder = _decoder as GALDecoder;
          return galDecoder.frames;
          break;
        case 'bmp':
          return _frameArray;  
          break;
        default:
          return null;
          break;
      }
    }
    
    public function get paletteArray():Array
    {
      switch(type) {
        case 'gif':
            return null;
            /*
          var gifDecoder:GIFDecoder = _decoder as GIFDecoder;
          if(gifDecoder.globalColorTableFlag)
            return gifDecoder.globalColorTable;
          else if(gifDecoder.localColorTableFlag)
            return gifDecoder.localColorTable;
          else
            return null
            */
          break;
        case 'png':
          var pngDecoder:PNGDecoder = _decoder as PNGDecoder;
          return pngDecoder.paletteTable;  
          break;
        case 'edg':
          var edgDecoder:EDGDecoder = _decoder as EDGDecoder;
          return edgDecoder.paletteTable;
          break;
        case 'gal':
          var galDecoder:GALDecoder = _decoder as GALDecoder;
          return galDecoder.paletteTable;
          break;
        case 'bmp':
          return FrameData(_frameArray[0]).paletteTable;
          break;
        default:
          return null;
          break;
      }
    }
    public function get transparentIndex():int
    {
      switch(type) {
        case 'gif':
            /*
          var gifDecoder:GIFDecoder = _decoder as GIFDecoder;
          return gifDecoder.transparentIndex;
          */
          return int.MIN_VALUE;
          break;
        case 'png':
          var pngDecoder:PNGDecoder = _decoder as PNGDecoder;
          return pngDecoder.transparent;  
          break;
        case 'edg':
          var edgDecoder:EDGDecoder = _decoder as EDGDecoder;
          return edgDecoder.transparent;
          break;
        case 'gal':
          var galDecoder:GALDecoder = _decoder as GALDecoder;
          return galDecoder.transparent;
          break;
        case 'bmp':
          return FrameData(_frameArray[0]).transparent;
          break;
        default:
          return int.MIN_VALUE;
          break;
      }
    }
    
    
    public static function createImageFromIndexBitmapData(indexBitmapData:BitmapData, pixelArt:PixelArt, frameData:IFrameData):BitmapData
    {
        var bitmapData:BitmapData = new BitmapData(indexBitmapData.width, indexBitmapData.height, true, 0);
        var paletteTable:Array = pixelArt.paletteArray;
        
        for (var x:int = 0; x < bitmapData.width; x++ ) {
            for (var y:int = 0; y < bitmapData.height; y++ ) {
                var index:int = indexBitmapData.getPixel(x, y);
                if(index in paletteTable) {
                    bitmapData.setPixel32(x, y, 0xFF000000 | paletteTable[index]);
                }
            }
        }
        
        return bitmapData;
    }
    
    public static function createFrameIndexBitmapDataFromLayers(pixelArt:PixelArt, frameData:IFrameData):BitmapData
    {
        var bitmapData:BitmapData = new BitmapData(frameData.width, frameData.height, false, 0);
        var n:int = frameData.layers.length;
        for (var i:int = n-1; i >= 0; i-- ) {
            var layerData:LayerData = frameData.layers[i];
            var layerIndexBitmapData:BitmapData = layerData.indexImage;
            
            if (!layerData.visible) {
                continue;
            }
            
            for (var x:int = 0; x < layerIndexBitmapData.width; x++ ) {
                for (var y:int = 0; y < layerIndexBitmapData.height; y++ ) {
                    var index:int = layerIndexBitmapData.getPixel(x, y) & 0xFF;
                    
                    if(index != pixelArt.transparentIndex && i != n-1) {
                        bitmapData.setPixel(x, y, index);
                    }
                }
            }
        }
        return bitmapData;
    }
    
    public static function createFrameIndexBitmapDataFromDisplay(pixelArt:PixelArt, frameData:IFrameData):BitmapData
    {
        var bitmapData:BitmapData = new BitmapData(frameData.width, frameData.height);
        bitmapData.draw(frameData.display);
        
        var colorMap:Object = createColorToIndexMap(pixelArt.paletteArray);
        
        for (var x:int = 0; x < bitmapData.width; x++ ) {
            for (var y:int = 0; y < bitmapData.height; y++ ) {
                var color:uint = bitmapData.getPixel32(x, y);
                var isTransparent:Boolean = (color & 0xFF000000) > 0;
                color = color & 0xFFFFFF;
                
                if (color in colorMap && !isTransparent) {
                    bitmapData.setPixel32(x, y, 0xFF000000 | colorMap[color]);
                } else {
                    bitmapData.setPixel32(x, y, 0xFF000000 | pixelArt.transparentIndex);
                }
            }
        }
        
        return bitmapData;
    }
    
    public static function createColorToIndexMap(paletteTable:Array): Object
    {
        var map:Object = new Object();
        
        var n:int = paletteTable.length;
        for (var i:int = 0; i <  n; i++ ) {
            map[paletteTable[i]] = i;
        }
        
        return map;
    }
  }
}