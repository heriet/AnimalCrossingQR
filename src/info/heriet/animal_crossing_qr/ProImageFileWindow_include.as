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

//package info.heriet.animal_crossing_qr 
//{

     import flash.display.Bitmap;
     import flash.display.BitmapData;
     import flash.display.DisplayObjectContainer;
     import flash.display.Graphics;
     import flash.display.Loader;
     import flash.display.Sprite;
     import flash.events.Event;
     import flash.events.IOErrorEvent;
     import flash.geom.Rectangle;
     import flash.net.FileFilter;
     import flash.net.FileReference;
     import info.heriet.animal_crossing_qr.AnimalCrossingImageConverter;
     import info.heriet.animal_crossing_qr.AnimalCrossingQRCodeImage;
     import info.heriet.animal_crossing_qr.FileUtils;
     import info.heriet.images.FrameData;
     import info.heriet.images.IFrameData;
     import info.heriet.images.PixelArt;
     import mx.containers.HBox;
     import mx.controls.Button;
     import mx.controls.ComboBox;
     import mx.controls.Label;
     import mx.core.IUIComponent;
     import mx.core.UIComponent;
     
    /**
     * ...
     * @author heriet
     */
    
//    public class ProImageFileWindow_include 
//    {
        
        private static const VIEW_INDEX_FRONT:int = 0;
        private static const VIEW_INDEX_BACK:int = 1;
        private static const VIEW_INDEX_LEFT:int = 2;
        private static const VIEW_INDEX_RIGHT:int = 3;
        private static const VIEW_MAX_NUM:int = 4;
        
        public var textureImageList:Vector.<BitmapData>;
        public var currentModel:int;
        
        private var _fileReferenceList:Vector.<FileReference>;
        private var _spriteList:Vector.<Sprite>;
        
        private var _currentLoadingIndex:int;
        private var _pixelArtLoader:Loader;
        
        /**
         * 初期化
         */
        public function init():void 
        {
            _currentLoadingIndex = -1;
            
            textureImageList = new Vector.<BitmapData>(VIEW_MAX_NUM);
            
            _fileReferenceList = new Vector.<FileReference>(VIEW_MAX_NUM);
            _spriteList = new Vector.<Sprite>(VIEW_MAX_NUM);
            
            updateModel(modelComboBox.selectedItem.data);
        }
        
        /**
         * デザイン表示領域の初期化
         * 
         * @param	view デザイン表示領域
         * @param   rect デザインサイズ
         * @return  デザイン表示領域のスプライト
         */
        private function initViewSprite(view:UIComponent, rect:Rectangle):Sprite
        {
            removeSpriteChildren(view);
            
            var sprite:Sprite = new Sprite();
            var graphics:Graphics = sprite.graphics;
            graphics.lineStyle(1, 0xCCCCCC);
            graphics.drawRect(0, 0, rect.width * 4, rect.height * 4);
            view.addChild(sprite);
            
            return sprite;
        }
        
        /**
         * モデルコンボボックス CHANGEハンドラ
         * 
         * @param	event
         */
        private function modelComboBox_changeHandler(event:Event):void
        {
            var model:int = ComboBox(event.target).selectedItem.data;
            updateModel(model);
        }
        
        /**
         * モデル選択を更新する
         * 
         * @param	model 選択したモデル
         */
        private function updateModel(model:int):void
        {
            if (model == currentModel) {
                return;
            }
            
            currentModel = model;
            
            clearAll();
            
            var modelSizeArray:Array = AnimalCrossingQRCodeImage.MODEL_TEXTURE_SIZE_MAP[currentModel];
            var modelViewList:Array = separateFileReferenceViewGroup.getChildren();
            
            var textureNum:int = modelSizeArray.length;
            
            
            
            for (var i:int = 0; i < VIEW_MAX_NUM; i++) {
                if (i < textureNum) {
                    modelViewList[i].visible = true;
                    modelViewList[i].x = this.width / textureNum * i + (this.width / textureNum - Rectangle(modelSizeArray[i]).width * 4) / 2
                    
                    var view:UIComponent = modelViewList[i].getChildAt(0) as UIComponent;
                    modelViewList[i].width = view.width + 4;
                    
                    
                    view.height = Rectangle(modelSizeArray[i]).height * 4;
                    _spriteList[i] = initViewSprite(view, modelSizeArray[i]);
                    
                    var button:Button = modelViewList[i].getChildAt(1) as Button;
                    button.x = (view.width - button.width) / 2
                    
                } else {
                    modelViewList[i].width = 0;
                    modelViewList[i].visible = false;
                }
            }
        }
        
        /**
         * ファイル読み込みを開始する
         * 
         * @param	loadIndex 読み込むデザインの番号
         */
        private function startFileReference(loadIndex:int):void
        {
            if (_currentLoadingIndex != -1) {
                return;
            }
            
            _currentLoadingIndex = loadIndex;
            
            var fileReference:FileReference = new FileReference();
            _fileReferenceList[_currentLoadingIndex] = fileReference;
            
            fileReference.addEventListener(Event.SELECT, fileReference_selectHandler);
            fileReference.addEventListener(Event.COMPLETE, fileReference_completeHandler);
            fileReference.addEventListener(IOErrorEvent.IO_ERROR, fileReference_cancelHandler);
            fileReference.addEventListener(Event.CANCEL, fileReference_cancelHandler);
            
            fileReference.browse([
                            FileUtils.FILE_FILTER_PIXELART,
                            FileUtils.FILE_FILTER_PNG,
                            FileUtils.FILE_FILTER_GIF,
                            FileUtils.FILE_FILTER_EDG,
                            FileUtils.FILE_FILTER_GAL,
                            FileUtils.FILE_FILTER_ALL
                            ]);
                            
            
        }
        
        /**
         * デザイン画像FileReference SELECTハンドラ
         * 
         * @param	event
         */
        private function fileReference_selectHandler(event:Event):void
        {
            var fileReference:FileReference = _fileReferenceList[_currentLoadingIndex];
            
            fileReference.removeEventListener(Event.SELECT, fileReference_selectHandler);
            fileReference.load();
        }
        
        /**
         * デザイン画像FileReference COMPLETEハンドラ
         * 
         * @param	event
         */
        private function fileReference_completeHandler(event:Event):void
        {
            var fileReference:FileReference = _fileReferenceList[_currentLoadingIndex];
            fileReference.removeEventListener(Event.COMPLETE, fileReference_completeHandler);
            
            var nameSplit:Array = fileReference.name.split('.');
            var fileType:String = nameSplit[nameSplit.length - 1];
            fileType = fileType.toLocaleLowerCase();
            
            if (fileType == "edg" || fileType == "gal") {
                var pixelArt:PixelArt = new PixelArt();
                var loadResult:Boolean = pixelArt.loadFile(fileReference.data, fileReference.name);
                if (!loadResult) {
                    setStatusMessage("画像読み込みに失敗しました");
                    return;
                }
                
                var bitmapData:BitmapData = new BitmapData(pixelArt.width, pixelArt.height, false);
                bitmapData.draw(IFrameData(pixelArt.frameArray[0]).display);
                
                loadPixelartComplete(bitmapData);
            } else {
                _pixelArtLoader = new Loader();
                _pixelArtLoader.loadBytes(fileReference.data);
                _pixelArtLoader.contentLoaderInfo.addEventListener(Event.INIT, pixelArtLoader_initHandler);
            }
            
        }
        
        /**
         * デザイン画像Loader INITハンドラ
         * 
         * @param	event
         */
        public function pixelArtLoader_initHandler(event:Event):void
        {
            event.target.removeEventListener(Event.INIT, pixelArtLoader_initHandler);
            
            var bitmapData:BitmapData = new BitmapData(_pixelArtLoader.width, _pixelArtLoader.height, false);
            bitmapData.draw(_pixelArtLoader);
            
            loadPixelartComplete(bitmapData);
        }
        
        /**
         * デザイン画像を読み込む
         * 
         * @param	bitmapData 読み込むデザイン画像
         */
        private function loadPixelartComplete(bitmapData:BitmapData):void
        {
            var modelSizeArray:Array = AnimalCrossingQRCodeImage.MODEL_TEXTURE_SIZE_MAP[currentModel];
            var sizeRect:Rectangle = modelSizeArray[_currentLoadingIndex];
            
            bitmapData = AnimalCrossingImageConverter.adjustPixelArt(bitmapData, sizeRect);
            
            var bitmap:Bitmap = new Bitmap(bitmapData);
            bitmap.scaleX = 4.0;
            bitmap.scaleY = 4.0;
            
            var sprite:Sprite = _spriteList[_currentLoadingIndex];
            removeSpriteChildren(sprite);
            sprite.addChild(bitmap);
            
            textureImageList[_currentLoadingIndex] = bitmapData;
            setStatusMessage("画像を読み込みました");
            
            _currentLoadingIndex = -1;
        }
        
        /**
         * デザイン画像 FileReference CANCELハンドラ
         * @param	event
         */
        private function fileReference_cancelHandler(event:Event):void
        {
            _currentLoadingIndex = -1;
        }
        
        /**
         * 前面デザイン画像読み込みボタン MOUSE_DOWNハンドラ
         * @param	event
         */
        private function frontFileReferenceButton_mouseDownHandler(event:Event):void
        {
            startFileReference(VIEW_INDEX_FRONT);
        }
        
        /**
         * 背面デザイン画像読み込みボタン MOUSE_DOWNハンドラ
         * @param	event
         */
        private function backFileReferenceButton_mouseDownHandler(event:Event):void
        {
            startFileReference(VIEW_INDEX_BACK);
        }
        
        /**
         * 左面デザイン画像読み込みボタン MOUSE_DOWNハンドラ
         * @param	event
         */
        private function leftFileReferenceButton_mouseDownHandler(event:Event):void
        {
            startFileReference(VIEW_INDEX_LEFT);
        }
        
        /**
         * 右面デザイン画像読み込みボタン MOUSE_DOWNハンドラ
         * @param	event
         */
        private function rightFileReferenceButton_mouseDownHandler(event:Event):void
        {
            startFileReference(VIEW_INDEX_RIGHT);
        }
        
        /**
         * OKボタン MOUSE_DOWNハンドラ
         * 
         * @param	event
         */
        private function okButton_mouseDownHandler(event:Event):void
        {
            if (!isAllLoaded()) {
                setStatusMessage("画像がすべて読み込まれていません");
                return;
            }
            
            this.dispatchEvent(new Event(Event.CLOSE));
        }
        
        /**
         * メッセージを表示する
         * 
         * @param	message
         */
        private function setStatusMessage(message:String):void
        {
            var label:Label = this.statusLabel;
            label.text = message;
        }
        
        /**
         * 子をすべてremoveする
         * @param	sprite
         */
        private function removeSpriteChildren(sprite:DisplayObjectContainer):void
        {
            while (sprite.numChildren > 0) {
                sprite.removeChildAt(0);
            }
        }
        
        /**
         * すべてのデザイン画像が読み込まれているか判定する
         * 
         * @return すべてのデザイン画像が読み込まれているときtrue
         */
        public function isAllLoaded():Boolean
        {
            var modelSizeArray:Array = AnimalCrossingQRCodeImage.MODEL_TEXTURE_SIZE_MAP[currentModel];
            
            var n:int = modelSizeArray.length;
            for (var i:int = 0; i < n; i++) {
                if (textureImageList[i] == null) {
                    return false;
                }
            }
            
            return true;
        }
        
        /**
         * 読み込み済みのデザイン画像をクリアする
         */
        private function clearAll():void
        {
            var n:int = textureImageList.length;
            for (var i:int = 0; i < n; i++ ) {
                if(textureImageList[i] != null) {
                    textureImageList[i].dispose();
                    textureImageList[i] = null;
                }
            }
        }
        
//    }

//}