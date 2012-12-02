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

     import com.google.zxing.Result;
     import flash.display.Bitmap;
     import flash.display.BitmapData;
     import flash.display.DisplayObject;
     import flash.display.Graphics;
     import flash.display.Loader;
     import flash.display.Sprite;
     import flash.events.Event;
     import flash.media.Camera;
     import flash.net.FileFilter;
     import flash.net.FileReference;
     import flash.utils.ByteArray;
     import info.heriet.animal_crossing_qr.AnimalCrossingImageConverter;
     import info.heriet.animal_crossing_qr.AnimalCrossingQRCodeImage;
     import info.heriet.animal_crossing_qr.FileUtils;
     import info.heriet.images.FrameData;
     import info.heriet.images.PixelArt;
     import mx.containers.TitleWindow;
     import mx.controls.Label;
     import mx.controls.VideoDisplay;
     import mx.core.UIComponent;
     import mx.managers.PopUpManager;
    
//    public class InitializeProfileWindow_include 
//    {
        
        private static const TRIM_QRCODE_AREA:Rectangle = new Rectangle(190, 40, 190, 188);
        private static const TRIM_QRCODE_POINT:Point = new Point(0, 0);
        
        private static const CAMERA_WIDTH:int = 480;
        private static const CAMERA_HEIGHT:int = 480;
        
        public var profile:AnimalCrossingQRCodeImage;
        
        private var _qrCodeFileReference:FileReference;
        private var _loadedQRCode:AnimalCrossingQRCodeImage;
        
        private var _qrCodeSprite:Sprite;
        
        private var _camera:Camera;
        private var _cameraScanWindow:TitleWindow;
        private var _cameraVideoDisplay:VideoDisplay;
        private var _cameraFrame:int;
        private var _cameraSuccess:Boolean;
        private var _cameraBitmapData:BitmapData;
        
        /**
         * 初期化
         */
        public function init():void 
        {
            _qrCodeSprite = initViewSprite(this.qrCodeReferenceView);
            setStatusMessage("あなたが作成したQRコードと、あなたの名前・村名を入力してください");
            
            _cameraScanWindow = new TitleWindow();
            _cameraScanWindow.title = "カメラモード";
            _cameraScanWindow.showCloseButton = true;
            
            _cameraVideoDisplay = new VideoDisplay();
            _cameraVideoDisplay.width = CAMERA_WIDTH;
            _cameraVideoDisplay.height = CAMERA_HEIGHT;
            _cameraScanWindow.addChild(_cameraVideoDisplay);
        }
        
        /**
         * QRコード表示領域の初期化
         * 
         * @param	view QRコード表示領域
         * @return  QRコード表示領域のスプライト
         */
        private function initViewSprite(view:UIComponent):Sprite
        {
            var sprite:Sprite = new Sprite();
            var graphics:Graphics = sprite.graphics;
            graphics.lineStyle(1, 0xCCCCCC);
            graphics.drawRect(0, 0, 400, 240);
            view.addChild(sprite);
            
            return sprite;
        }
        
        /**
         * QRコード読み込みボタン MOUSE_DOWNハンドラ
         * 
         * @param	event
         */
        private function qrCodeReferenceButton_mouseDownHandler(event:Event):void
        {
            _qrCodeFileReference = new FileReference();
            
            _qrCodeFileReference.addEventListener(Event.SELECT, qrCodeFileReference_selectHandler);
            _qrCodeFileReference.addEventListener(Event.COMPLETE, qrCodeFileReference_completeHandler);
            
            _qrCodeFileReference.browse([
                            FileUtils.FILE_FILTER_PHOTO,
                            FileUtils.FILE_FILTER_JPG,
                            FileUtils.FILE_FILTER_PNG,
                            FileUtils.FILE_FILTER_GIF,
                            FileUtils.FILE_FILTER_ALL
                            ]);    
        }
        
        /**
         * QRコード読み込みFileReference SELECTハンドラ
         * 
         * @param	event
         */
        private function qrCodeFileReference_selectHandler(event:Event):void
        {
            _qrCodeFileReference.removeEventListener(Event.SELECT, qrCodeFileReference_selectHandler);
            _qrCodeFileReference.load();
        }
        
        /**
         * QRコード読み込みFileReference COMPLETEハンドラ
         * 
         * @param	event
         */
        private function qrCodeFileReference_completeHandler(event:Event):void
        {
            _qrCodeFileReference.removeEventListener(Event.COMPLETE, qrCodeFileReference_completeHandler);
            
            var loader:Loader = new Loader();
            loader.loadBytes(_qrCodeFileReference.data);
            loader.contentLoaderInfo.addEventListener(Event.INIT, qrCodeLoader_initHandler);
        }
        
        /**
         * QRコードLoader INITハンドラ
         * 
         * @param	event
         */
        private function qrCodeLoader_initHandler(event:Event):void
        {
            event.target.removeEventListener(Event.INIT, qrCodeLoader_initHandler);
        
            var bitmap:Bitmap = Bitmap(event.target.content);
            var bitmapData:BitmapData = bitmap.bitmapData;
            
            if (bitmapData == null) {
                setStatusMessage("QRコード読み取りに失敗しました");
                return;
            }
            
            var result:Result = null;
            result = AnimalCrossingQRCodeImage.decodeQRCodeBitmapData(bitmapData);
            
            if (result == null) {
                setStatusMessage("QRコード読み取りに失敗しました");
                return;
            }
            
            var byteArray:ByteArray = AnimalCrossingQRCodeImage.resultToByteArray(result);
            
            var qrCodeImage:AnimalCrossingQRCodeImage = new AnimalCrossingQRCodeImage();
            var success:Boolean = qrCodeImage.decode(byteArray);
            
            if (success) {
                _loadedQRCode = qrCodeImage;
                
                while (_qrCodeSprite.numChildren > 0) {
                    _qrCodeSprite.removeChildAt(0);
                }
                
                _qrCodeSprite.addChild(bitmap);
                bitmap.x = (this.qrCodeReferenceView.width - bitmap.width) / 2;
                bitmap.y = (this.qrCodeReferenceView.height - bitmap.height) / 2
                
                setStatusMessage("QRコード読み取りに成功しました");
            }
        }
        
        /**
         * QRコードスキャンボタン MOUSE_DOWNハンドラ
         * 
         * @param	event
         */
        private function qrCodeScanButton_mouseDownHandler(event:Event):void
        {
            PopUpManager.addPopUp(_cameraScanWindow, parentApplication　as DisplayObject, true);
            PopUpManager.centerPopUp(_cameraScanWindow);
            
            _cameraScanWindow.addEventListener(Event.CLOSE, cameraScanWindow_closeHandler);
            
            _camera = Camera.getCamera();
            
            if (_camera != null) {
                _cameraSuccess = false;
                _cameraFrame = 60;
                _camera.setMode(CAMERA_WIDTH, CAMERA_HEIGHT, 10, true);
                _camera.setQuality(0, 100);
                _cameraVideoDisplay.attachCamera(_camera);
                
                _camera.addEventListener(StatusEvent.STATUS, camera_statusHandler);
            } else {
                setStatusMessage("カメラが検出されませんでした");
                _cameraScanWindow.removeEventListener(Event.CLOSE, cameraScanWindow_closeHandler);
                PopUpManager.removePopUp(_cameraScanWindow);
            }
        }
        
        /**
         * カメラ STATUSハンドラ
         * 
         * @param	event
         */
        private function camera_statusHandler(event:Event):void
        {
            if (!_camera.muted) {
                setStatusMessage("カメラ読み取りを開始します");
                _cameraBitmapData = new BitmapData(CAMERA_WIDTH, CAMERA_HEIGHT, false, 0);
                _cameraVideoDisplay.addEventListener(Event.ENTER_FRAME, cameraVideoDisplay_enterFrameHandler);
                
            } else {
                setStatusMessage("カメラ読み取りが拒否されました");
                _cameraScanWindow.removeEventListener(Event.CLOSE, cameraScanWindow_closeHandler);
                PopUpManager.removePopUp(_cameraScanWindow);
            }
        }
        
        /**
         * カメラ表示 ENTER_FRAMEハンドラ
         * 
         * @param	event
         */
        private function cameraVideoDisplay_enterFrameHandler(event:Event):void
        {
            if (_cameraFrame % 30 == 0) {
                _cameraBitmapData.draw(_cameraVideoDisplay);
                var byteArray:ByteArray = convertQRCodeToByteArray(_cameraBitmapData, true);
                var success:Boolean = convertQRCodeByteArrayToPixelArt(byteArray, _cameraBitmapData);
                
                if (success) {
                    _cameraSuccess = true;
                    cameraScanWindow_closeHandler();
                }
            }
            _cameraFrame++;
        }
        
        /**
         * カメラスキャンウィンドウ CLOSEハンドラ
         * 
         * @param	event
         */
        private function cameraScanWindow_closeHandler(event:Event = null):void
        {
            if(!_cameraSuccess && _cameraBitmapData != null) {
                _cameraBitmapData.dispose();
            }
            
            _cameraVideoDisplay.removeEventListener(Event.ENTER_FRAME, cameraVideoDisplay_enterFrameHandler);
            _cameraVideoDisplay.attachCamera(null);
            
            _cameraScanWindow.removeEventListener(Event.CLOSE, cameraScanWindow_closeHandler);
            PopUpManager.removePopUp(_cameraScanWindow);
        }
        
        /**
         * QRコード画像をバイナリに変換する
         * 
         * @param	bitmapData QRコードが含まれた画像
         * @param	isScanMode カメラスキャン中かどうか
         * @return 変換されたバイナリ
         */
        private function convertQRCodeToByteArray(bitmapData:BitmapData, isScanMode:Boolean = false):ByteArray
        {
            setStatusMessage("QRコード画像 解析開始");
            
            var result:Result = null;
            
            result = AnimalCrossingQRCodeImage.decodeQRCodeBitmapData(bitmapData);
            
            if (result == null && !isScanMode) {
                var trimedBitmapData:BitmapData = new BitmapData(TRIM_QRCODE_AREA.width, TRIM_QRCODE_AREA.height, false, 0);
                trimedBitmapData.copyPixels(bitmapData, TRIM_QRCODE_AREA, TRIM_QRCODE_POINT);
                result = AnimalCrossingQRCodeImage.decodeQRCodeBitmapData(trimedBitmapData);
                trimedBitmapData.dispose();
            }
            
            if (result == null) {
                var message:String = "QRコードが読み取れませんでした";
                if (isScanMode) {
                    var nowDate:Date = new Date();
                    message += ": " + nowDate.toString();
                }
                setStatusMessage(message);
                return null;
            }
            
            var byteArray:ByteArray = AnimalCrossingQRCodeImage.resultToByteArray(result);
            
            return byteArray;
        }
        
        /**
         * QRコードバイナリを画像に変換する
         * 
         * @param	byteArray QRコード解析後のバイナリデータ
         * @param	bitmapData QRコードが含まれた画像
         * @return 変換の成否
         */
        private function convertQRCodeByteArrayToPixelArt(byteArray:ByteArray, bitmapData:BitmapData):Boolean
        {
            if (byteArray == null) {
                return false;
            }
            
            byteArray.position = 0;
            var firstByte:uint = byteArray.readUnsignedByte();
            
            if (firstByte == 0x40 || firstByte == 0x30) {
                var qrCodeImage:AnimalCrossingQRCodeImage = new AnimalCrossingQRCodeImage();
            
                byteArray.position = 0;
                var success:Boolean = qrCodeImage.decode(byteArray);
            
                if (!success) {
                    setStatusMessage("画像読み取りに失敗しました");
                    return false;
                }
                
                _loadedQRCode = qrCodeImage;
                
                while (_qrCodeSprite.numChildren > 0) {
                    _qrCodeSprite.removeChildAt(0);
                }
                
                var bitmap:Bitmap = new Bitmap(bitmapData);
                bitmap.scaleX = 0.5;
                bitmap.scaleY = 0.5;
                
                _qrCodeSprite.addChild(bitmap);
                bitmap.x = (this.qrCodeReferenceView.width - bitmap.width) / 2;
                bitmap.y = (this.qrCodeReferenceView.height - bitmap.height) / 2
                
                setStatusMessage("QRコード読み取りに成功しました");
                
                return true;
            }
            
            return false;
        }
        
        /**
         * OKボタン MOUSE_DOWNハンドラ
         * 
         * @param	event
         */
        private function okButton_mouseDownHandler(event:Event):void
        {
            var inputAutherString:String = this.autherNameTextInput.text;
            var inputVillageString:String = this.villageNameTextInput.text;
            
            if (_loadedQRCode == null) {
                setStatusMessage("QRコードを読み込んでください");
                return;
            }
            
            
            if (!AnimalCrossingImageConverter.isValidInputString(inputAutherString, AnimalCrossingQRCodeImage.AUTHERNAME_MAX_LENGTH)) {
                setStatusMessage("名前が不正です");
                return;
            }
            
            if (!AnimalCrossingImageConverter.isValidInputString(inputVillageString, AnimalCrossingQRCodeImage.AUTHERNAME_MAX_LENGTH)) {
                setStatusMessage("村名が不正です");
                return;
            }
            
            if (_loadedQRCode.autherName != inputAutherString
            || _loadedQRCode.villageName != inputVillageString) {
                setStatusMessage("QRコード作成者の名前と村名を正しく入力してください");
                return;
            }
            
            profile = _loadedQRCode;
            
            this.dispatchEvent(new Event(Event.CLOSE));
        }
        
        /**
         * メッセージを表示する
         * 
         * @param	message
         */
        public function setStatusMessage(message:String):void
        {
            var label:Label = this.statusLabel;
            label.text = message;
        }
        
//    }

//}