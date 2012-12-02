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
     import com.google.zxing.common.flexdatatypes.HashTable;
     import com.google.zxing.common.HybridBinarizer;
     import com.google.zxing.DecodeHintType;
     import com.google.zxing.FormatException;
     import com.google.zxing.NotFoundException;
     import com.google.zxing.Reader;
     import com.google.zxing.Result;
     import flash.display.Bitmap;
     import flash.display.BitmapData;
     import flash.display.DisplayObject;
     import flash.display.DisplayObjectContainer;
     import flash.display.Loader;
     import flash.display.Sprite;
     import flash.events.ContextMenuEvent;
     import flash.events.Event;
     import flash.events.MouseEvent;
     import flash.events.StatusEvent;
     import flash.filters.DropShadowFilter;
     import flash.geom.Matrix;
     import flash.geom.Point;
     import flash.geom.Rectangle;
     import flash.media.Camera;
     import flash.net.FileFilter;
     import flash.net.FileReference;
     import flash.ui.ContextMenu;
     import flash.ui.ContextMenuItem;
     import flash.utils.ByteArray;
     import flash.utils.Endian;
     import info.heriet.images.ColorData;
     import info.heriet.images.FrameData;
     import info.heriet.images.IFrameData;
     import info.heriet.images.PaletteUtil;
     import info.heriet.images.PixelArt;
     import info.heriet.images.PNGDecoder;
     import mx.collections.XMLListCollection;
     import mx.containers.Canvas;
     import mx.containers.TitleWindow;
     import mx.controls.Alert;
     import mx.controls.ComboBox;
     import mx.controls.Label;
     import mx.controls.List;
     import mx.controls.VideoDisplay;
     import mx.core.IFlexDisplayObject;
     import mx.core.UIComponent;
     import mx.events.FlexEvent;
     import mx.events.ListEvent;
     import mx.graphics.codec.PNGEncoder;
     import mx.managers.PopUpManager;
     
    public class AnimalCrossingImageConverter extends Canvas
    {
        private static const TRIM_QRCODE_AREA:Rectangle = new Rectangle(190, 40, 190, 188);
        private static const TRIM_QRCODE_POINT:Point = new Point(0, 0);
        
        private static const CAMERA_WIDTH:int = 480;
        private static const CAMERA_HEIGHT:int = 480;
        private static const CMERA_SCALE:Number = 1.0;
        
        private static const DRAGING_DROPSHADOW_FILTER:DropShadowFilter = new DropShadowFilter();
        
        public var currentProfile:AnimalCrossingQRCodeImage;
        
        private var _pixelArtFileReference:FileReference;
        private var _qrCodeImageFileReference:FileReference;
        
        private var _pixelArtLoader:Loader;
        private var _qrCodeImageLoader:Loader;
        
        private var _qrCodeImageList:Vector.<AnimalCrossingQRCodeImage>;
        
        private var _pixelArtUIComponent:UIComponent;
        private var _qrCodeImageUIComponent:UIComponent;
        private var _qrCodeImageBitmap:Bitmap;
        private var _pixelArtSprite:Sprite;
        private var _qrCodeImageSprite:Sprite;
        
        private var _imageListXML:XMLListCollection;
        
        private var _currentQRCodeImage:AnimalCrossingQRCodeImage;
        
        private var _camera:Camera;
        private var _cameraScanWindow:TitleWindow;
        private var _cameraVideoDisplay:VideoDisplay;
        private var _cameraFrame:int;
        private var _cameraSuccess:Boolean;
        private var _cameraBitmapData:BitmapData;
        
        private var _proImageFileWindow:ProImageFileWindow;
        private var _singleDesignNameCounter:int;
        private var _proDesignNameCounter:int;
        
        private var _initializeProfileWindow:InitializeProfileWindow;
        
        /**
         * コンストラクタ
         */
        public function AnimalCrossingImageConverter() 
        {
            _qrCodeImageList = new Vector.<AnimalCrossingQRCodeImage>();
            _pixelArtUIComponent = new UIComponent();
            _qrCodeImageUIComponent = new UIComponent();
            _qrCodeImageSprite = new Sprite();
            _imageListXML = new XMLListCollection();
            
            addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
            
        }
        
        /**
         * Creation Completeハンドラ
         * @param event
         */
        private function creationCompleteHandler(event:FlexEvent):void
        {
            removeEventListener(Event.ADDED, creationCompleteHandler);
            init();
        }
        
        /**
         * 初期化処理
         */
        private function init():void
        {
            addChild(_pixelArtUIComponent);
            parentApplication.qrCodeCanvas.addChild(_qrCodeImageUIComponent);
            
            parentApplication.loadSinglePixelArtButton.addEventListener(MouseEvent.CLICK, loadSinglePixelArtButton_mouseDownHandler);
            parentApplication.loadProPixelArtButton.addEventListener(MouseEvent.CLICK, loadProPixelArtButton_mouseDownHandler);
            
            parentApplication.initializeProfileButton.addEventListener(MouseEvent.CLICK, initializeProfileButton_mouseDownHandler);
            parentApplication.savePixelArtButton.addEventListener(MouseEvent.CLICK, savePixelArtButton_mouseDownHandler);
            parentApplication.encodePixelArtButton.addEventListener(MouseEvent.CLICK, encodePixelArtButton_mouseDownHandler);
            
            parentApplication.loadQRCodeImageButton.addEventListener(MouseEvent.CLICK, loadQRCodeImageButton_mouseDownHandler);
            parentApplication.saveQRCodeImageButton.addEventListener(MouseEvent.CLICK, saveQRCodeImageButton_mouseDownHandler);
            
            parentApplication.scanCameraButton.addEventListener(MouseEvent.CLICK, scanCameraButton_mouseDownHandler);
            
            parentApplication.designNameTextInput.addEventListener(Event.CHANGE, designNameTextInput_changeHandler);
            parentApplication.autherNameTextInput.addEventListener(Event.CHANGE, autherNameTextInput_changeHandler);
            parentApplication.villageNameTextInput.addEventListener(Event.CHANGE, villageNameTextInput_changeHandler);
            
            parentApplication.paletteComboBox.addEventListener(Event.CHANGE, paletteComboBox_changeHandler);
            
            parentApplication.designList.addEventListener(ListEvent.ITEM_CLICK, designList_itemClickHandler);
            
            parentApplication.encodePixelArtButton.enabled = false;
            parentApplication.savePixelArtButton.enabled = false;
            parentApplication.saveQRCodeImageButton.enabled = false;
            
            _cameraScanWindow = new TitleWindow();
            _cameraScanWindow.title = "カメラモード";
            _cameraScanWindow.showCloseButton = true;
            
            _cameraVideoDisplay = new VideoDisplay();
            _cameraVideoDisplay.width = CAMERA_WIDTH * CMERA_SCALE;
            _cameraVideoDisplay.height = CAMERA_HEIGHT * CMERA_SCALE;
            _cameraScanWindow.addChild(_cameraVideoDisplay);
            
            var contextMenu:ContextMenu = new ContextMenu();
            contextMenu.hideBuiltInItems();
            var item:ContextMenuItem = new ContextMenuItem("あさみしん");
            item.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,contextMenu_selectHandler);
            contextMenu.customItems.push(item);
            parentApplication.contextMenu = contextMenu;
            
            setStatusMessage("Version 1.0.0");
        }
        
        /**
         * コンテキストメニュー 著作表示
         * @param event
         */
        private function contextMenu_selectHandler(event:ContextMenuEvent):void
        {
            Alert.show(
            "Auther: heriet\nhttp://heriet.info/\nhttps://twitter.com/heriet\n\nあさみしんはZxingライブラリ（http://code.google.com/p/zxing/）を使用しています"
            , "あさみしん", Alert.OK, parentApplication as Sprite);
        }
        
        /**
         * 単体デザイン画像読み込みボタン MOUSE_DOWNハンドラ
         * @param event
         */
        private function loadSinglePixelArtButton_mouseDownHandler(event:MouseEvent):void
        {
            _pixelArtFileReference = new FileReference();
            
            _pixelArtFileReference.addEventListener(Event.SELECT, singlePixelArtFileReference_selectHandler);
            _pixelArtFileReference.addEventListener(Event.COMPLETE, singlePixelArtFileReference_completeHandler);
            
            _pixelArtFileReference.browse([
                            FileUtils.FILE_FILTER_PIXELART,
                            FileUtils.FILE_FILTER_PNG,
                            FileUtils.FILE_FILTER_GIF,
                            FileUtils.FILE_FILTER_EDG,
                            FileUtils.FILE_FILTER_GAL,
                            FileUtils.FILE_FILTER_JPG,
                            FileUtils.FILE_FILTER_ALL
                            ]);    
        }
        
        /**
         * 単体画像FileReference SELECTハンドラ
         * @param event
         */
        public function singlePixelArtFileReference_selectHandler(event:Event):void
        {
            _pixelArtFileReference.removeEventListener(Event.SELECT, singlePixelArtFileReference_selectHandler);
            _pixelArtFileReference.load();
        }
        
        /**
         * 単体画像FileReference COMPLETEハンドラ
         * @param event
         */
        public function singlePixelArtFileReference_completeHandler(event:Event):void
        {
            _pixelArtFileReference.removeEventListener(Event.COMPLETE, singlePixelArtFileReference_completeHandler);
            
            var nameSplit:Array = _pixelArtFileReference.name.split('.');
            var fileType:String = nameSplit[nameSplit.length - 1];
            fileType = fileType.toLocaleLowerCase();
            
            if (fileType == "edg" || fileType == "gal") {
                var pixelArt:PixelArt = new PixelArt();
                var loadResult:Boolean = pixelArt.loadFile(_pixelArtFileReference.data, _pixelArtFileReference.name);
                if (!loadResult) {
                    setStatusMessage("画像読み込みに失敗しました");
                    return;
                }
                
                var bitmapData:BitmapData = new BitmapData(pixelArt.width, pixelArt.height, false);
                bitmapData.draw(IFrameData(pixelArt.frameArray[0]).display);
                
                loadSinglePixelArt(bitmapData);
            } else {
                _pixelArtLoader = new Loader();
                _pixelArtLoader.loadBytes(_pixelArtFileReference.data);
                _pixelArtLoader.contentLoaderInfo.addEventListener(Event.INIT, singlePixelArtLoader_initHandler);
            }
        }
        
        /**
         * 単体画像Loader INITハンドラ
         * @param event
         */
        public function singlePixelArtLoader_initHandler(event:Event):void
        {
            event.target.removeEventListener(Event.INIT, singlePixelArtLoader_initHandler);
            
            var bitmapData:BitmapData = new BitmapData(_pixelArtLoader.width, _pixelArtLoader.height, false);
            bitmapData.draw(_pixelArtLoader);
            
            loadSinglePixelArt(bitmapData);
        }
        
        /**
         * 単体画像の読み込み
         * 
         * @param bitmapData
         */
        public function loadSinglePixelArt(bitmapData:BitmapData):void
        {
            var rect:Rectangle = AnimalCrossingQRCodeImage.MODEL_TEXTURE_SIZE_BASE;
            bitmapData = adjustPixelArt(bitmapData, rect);
            
            var qrCodeImage:AnimalCrossingQRCodeImage
            qrCodeImage = searchEqualSingleQRCodeImage(_pixelArtFileReference.name);
            
            if(qrCodeImage == null) {
                qrCodeImage = new AnimalCrossingQRCodeImage();
                qrCodeImage.filenameList[0] = _pixelArtFileReference.name;
                
                _singleDesignNameCounter++;
                qrCodeImage.tmpName = "Design " + _singleDesignNameCounter;
                
                if (currentProfile != null) {
                    qrCodeImage.autherName = currentProfile.autherName;
                    qrCodeImage.villageName = currentProfile.villageName;
                    parentApplication.autherNameTextInput.text = qrCodeImage.autherName;
                    parentApplication.villageNameTextInput.text = qrCodeImage.villageName;
                }
                
                pushNewQRCodeDesignList(qrCodeImage);
            } else {
                qrCodeImage.textureImageList[0].dispose();
            }
            
            qrCodeImage.type = AnimalCrossingQRCodeImage.TYPE_SINGLE;
            qrCodeImage.model = AnimalCrossingQRCodeImage.MODEL_SIMPLE;
            qrCodeImage.textureImageList[0] = bitmapData;
            
            encodeQRCodeImage(qrCodeImage);
            
            repaintQRCodeImageView(qrCodeImage);
        }
        
        /**
         * QRコードのエンコード
         * 
         * @param qrCodeImage
         */
        private function encodeQRCodeImage(qrCodeImage:AnimalCrossingQRCodeImage):void
        {
            var isValidInput:Boolean = isValidInputField(qrCodeImage);
            
            if(isValidInput) {
                var encodeResult:Boolean = qrCodeImage.encode(currentProfile);
                if (encodeResult) {
                    setStatusMessage("エンコードに成功しました");
                    repaintQRCodeImageView(qrCodeImage);
                } else {
                    setStatusMessage("エンコードに失敗しました");
                }
            }
        }
        
        /**
         * PROデザインロードボタン MOUSE_DOWNハンドラ
         * 
         * @param event
         */
        private function loadProPixelArtButton_mouseDownHandler(event:MouseEvent):void
        {
            _proImageFileWindow = new ProImageFileWindow();
            PopUpManager.addPopUp(_proImageFileWindow, parentApplication　as DisplayObject, true);
            PopUpManager.centerPopUp(_proImageFileWindow);
            
            _proImageFileWindow.addEventListener(Event.CLOSE, proImageFileWindow_closeHandler);
        }
        
        /**
         * PROデザインウィンドウ CLOSEハンドラ
         * 
         * @param event
         */
        private function proImageFileWindow_closeHandler(event:Event):void
        {
            _proImageFileWindow.removeEventListener(Event.CLOSE, proImageFileWindow_closeHandler);
            PopUpManager.removePopUp(_proImageFileWindow);
            
            if (_proImageFileWindow.isAllLoaded()) {
                var qrCodeImage:AnimalCrossingQRCodeImage = new AnimalCrossingQRCodeImage();
                
                qrCodeImage.model = _proImageFileWindow.currentModel;
                
                if (qrCodeImage.model == AnimalCrossingQRCodeImage.MODEL_CAP_HORN
                || qrCodeImage.model == AnimalCrossingQRCodeImage.MODEL_CAP_KNIT) {
                    qrCodeImage.type = AnimalCrossingQRCodeImage.TYPE_SINGLE;
                } else {
                    qrCodeImage.type = AnimalCrossingQRCodeImage.TYPE_SEPARATE;
                }
                
                var modelSizeArray:Array = AnimalCrossingQRCodeImage.MODEL_TEXTURE_SIZE_MAP[qrCodeImage.model];
                
                var n:int = modelSizeArray.length;
                for (var i:int = 0; i < n; i++) {
                    qrCodeImage.textureImageList[i] = _proImageFileWindow.textureImageList[i];
                }
                
                _proDesignNameCounter++;
                qrCodeImage.tmpName = "PRO design " + _proDesignNameCounter;
                
                if (currentProfile != null) {
                    qrCodeImage.autherName = currentProfile.autherName;
                    qrCodeImage.villageName = currentProfile.villageName;
                }
                
                pushNewQRCodeDesignList(qrCodeImage);
                repaintQRCodeImageView(qrCodeImage);
                
                setStatusMessage("PROデザインを読み込みました");
            }
        }
        
        /**
         * プロフィール設定ボタン MOUSE_DOWNハンドラ
         * 
         * @param event
         */
        private function initializeProfileButton_mouseDownHandler(event:MouseEvent):void
        {
            _initializeProfileWindow = new InitializeProfileWindow();
            PopUpManager.addPopUp(_initializeProfileWindow, parentApplication　as DisplayObject, true);
            PopUpManager.centerPopUp(_initializeProfileWindow);
            
            _initializeProfileWindow.addEventListener(Event.CLOSE, initializeProfileWindow_closeHandler);
        }
        
        /**
         * プロフィール設定ウィンドウ CLOSEハンドラ
         * 
         * @param	event
         */
        private function initializeProfileWindow_closeHandler(event:Event):void
        {
            _initializeProfileWindow.removeEventListener(Event.CLOSE, initializeProfileWindow_closeHandler);
            PopUpManager.removePopUp(_initializeProfileWindow);
            
            if(_initializeProfileWindow.profile != null) {
                currentProfile = _initializeProfileWindow.profile;
                parentApplication.profileAutherNameTextInput.text = currentProfile.autherName;
                parentApplication.profileVillageNameTextInput.text = currentProfile.villageName;
                
                var n:int = _qrCodeImageList.length;
                for (var i:int = 0; i < n; i++ ) {
                    var qrCodeImage:AnimalCrossingQRCodeImage = _qrCodeImageList[i];
                    
                    if (qrCodeImage.autherName == "") {
                        qrCodeImage.autherName = currentProfile.autherName;
                    }
                    if (qrCodeImage.villageName == "") {
                        qrCodeImage.villageName = currentProfile.villageName;
                    }
                }
                
                if(_currentQRCodeImage != null) {
                    repaintQRCodeImageView(_currentQRCodeImage);
                }
            }            
        }
        
        /**
         * 画面の再表示
         * 
         * @param	qrCodeImage
         */
        private function repaintQRCodeImageView(qrCodeImage:AnimalCrossingQRCodeImage):void
        {
            _currentQRCodeImage = qrCodeImage;
            
            checkEnableEncode();
            
            if(qrCodeImage.type == AnimalCrossingQRCodeImage.TYPE_SINGLE) {
                refreshQRCodeImageSinglePixelArtView(qrCodeImage);
                repaintQRCodeImageSingleQRCodeView(qrCodeImage);
            } else if (qrCodeImage.type == AnimalCrossingQRCodeImage.TYPE_SEPARATE) {
                repaintQRCodeImageSeparatePixelArtView(qrCodeImage);
                repaintQRCodeImageSeparateQRCodeView(qrCodeImage);
            }
            
            if (isValidInputString(_currentQRCodeImage.designName, AnimalCrossingQRCodeImage.DESIGNNAME_MAX_LENGTH)) {
                if(parentApplication.designNameTextInput.text != _currentQRCodeImage.designName) {
                    parentApplication.designNameTextInput.text = _currentQRCodeImage.designName;
                }
            } else if(parentApplication.designNameTextInput.text.length != ""){
                parentApplication.designNameTextInput.text = "";
            }
            
            parentApplication.autherNameTextInput.text = _currentQRCodeImage.autherName;
            parentApplication.villageNameTextInput.text = _currentQRCodeImage.villageName;
            
            var paletteComboBox:ComboBox = parentApplication.paletteComboBox;
            paletteComboBox.selectedIndex = _currentQRCodeImage.paletteType;
            
        }
        
        /**
         * 単体デザイン画像を再表示
         * 
         * @param	qrCodeImage
         */
        private function refreshQRCodeImageSinglePixelArtView(qrCodeImage:AnimalCrossingQRCodeImage):void
        {
            clearDisplayContainerChildren(_pixelArtUIComponent);
            
            if (qrCodeImage.textureImageList[0] == null) {
                parentApplication.savePixelArtButton.enabled = false;
                return;
            }
            parentApplication.savePixelArtButton.enabled = true;
            
            _pixelArtSprite = new Sprite();
            
            if (qrCodeImage.replacedImage != null) {
                var replacedBitmap:Bitmap = new Bitmap(qrCodeImage.replacedImage);
                _pixelArtSprite.addChild(replacedBitmap);
            } else {
            
                var bitmapData:BitmapData = qrCodeImage.textureImageList[0];
                var bitmap:Bitmap = new Bitmap(bitmapData);
            
                _pixelArtSprite = new Sprite();
                _pixelArtSprite.addChild(bitmap);
            
                bitmap.scaleX = 1.0;
                bitmap.scaleY = 1.0;
            }
            
            _pixelArtSprite.scaleX = 3.0;
            _pixelArtSprite.scaleY = 3.0;
            _pixelArtSprite.x = (this.width - _pixelArtSprite.width) / 2;
            _pixelArtSprite.y = (this.height - _pixelArtSprite.height) / 2;
            
            _pixelArtUIComponent.addChild(_pixelArtSprite);
            _pixelArtSprite.addEventListener(MouseEvent.MOUSE_DOWN, dragSprite_mouseDownHandler);
        }
        
        /**
         * 単体デザインQRコードを再表示する
         * 
         * @param	qrCodeImage
         */
        private function repaintQRCodeImageSingleQRCodeView(qrCodeImage:AnimalCrossingQRCodeImage):void
        {
            clearDisplayContainerChildren(_qrCodeImageUIComponent);
            clearDisplayContainerChildren(_qrCodeImageSprite);
            
            parentApplication.saveQRCodeImageButton.enabled = false;
            
            if (qrCodeImage.qrBitmapDataList[0] == null) {
                return;
            }
            
            if(currentProfile != null && currentProfile.isEqualUser(qrCodeImage)) {
                parentApplication.saveQRCodeImageButton.enabled = true;
            }
            
            _qrCodeImageBitmap = new Bitmap(qrCodeImage.qrBitmapDataList[0]);
            _qrCodeImageSprite.addChild(_qrCodeImageBitmap);
            
            var scale:Number = 1.0;
            var sx:int = (parentApplication.qrCodeCanvas.width - 20) / _qrCodeImageBitmap.width;
            var sy:int = (parentApplication.qrCodeCanvas.height - 20) / _qrCodeImageBitmap.height;
            
            if (sx > 1 && sy > 1) {
                scale = sx < sy ? sx : sy;
            } else if (_qrCodeImageBitmap.width > 400 && _qrCodeImageBitmap.height > 240) {
                var snx:Number = 400 / _qrCodeImageBitmap.width;
                var sny:Number = 240 / _qrCodeImageBitmap.height;
                scale = snx < sny ? snx : sny;
            } 
            
            _qrCodeImageSprite.scaleX = scale;
            _qrCodeImageSprite.scaleY = scale;
            
            _qrCodeImageSprite.x = (parentApplication.qrCodeCanvas.width - _qrCodeImageSprite.width) / 2;
            _qrCodeImageSprite.y = (parentApplication.qrCodeCanvas.height - _qrCodeImageSprite.height) / 2;
            
            _qrCodeImageSprite.addEventListener(MouseEvent.MOUSE_DOWN, dragSprite_mouseDownHandler);
            
            _qrCodeImageUIComponent.addChild(_qrCodeImageSprite);
        }
        
        /**
         * 分割デザイン画像を再表示する
         * 
         * @param	qrCodeImage
         */
        private function repaintQRCodeImageSeparatePixelArtView(qrCodeImage:AnimalCrossingQRCodeImage):void
        {
            clearDisplayContainerChildren(_pixelArtUIComponent);
            
            _pixelArtSprite = new Sprite();
            parentApplication.savePixelArtButton.enabled = false;
            
            var isAllImageExist:Boolean = true;
            var textureNum:int = AnimalCrossingQRCodeImage.MODEL_TEXTURE_SIZE_MAP[qrCodeImage.model].length;
            
            if (qrCodeImage.replacedImageList[0] != null) {
                for (i = 0; i < 4; i++ ) {
                    if (qrCodeImage.replacedImageList[i] == null) {
                        continue;
                    }
                    
                    var bitmapData:BitmapData = qrCodeImage.replacedImageList[i];
                    var sprite:Sprite = new Sprite();
                    var bitmap:Bitmap = new Bitmap(bitmapData);
                    sprite.addChild(bitmap);
                    
                    sprite.scaleX = 3.0;
                    sprite.scaleY = 3.0;
                    
                    sprite.x = ((this.width - 4*textureNum) / (textureNum + 1) +4)* (i+1) - 16 * (5-textureNum);
                    sprite.y = (this.height - sprite.height) / 2;
                    
                    sprite.addEventListener(MouseEvent.MOUSE_DOWN, dragSprite_mouseDownHandler);
                    _pixelArtSprite.addChild(sprite);
                    
                }
                
                if(currentProfile != null && currentProfile.isEqualUser(qrCodeImage)) {
                    parentApplication.savePixelArtButton.enabled = true;
                }
                
            } else if (qrCodeImage.textureImageList[0] != null) {
                
                for (var i:int = 0; i < textureNum; i++ ) {
                    if (qrCodeImage.textureImageList[i] == null) {
                        isAllImageExist = false;
                        continue;
                    }
                    
                    bitmapData = qrCodeImage.textureImageList[i];
                    sprite = new Sprite();
                    bitmap = new Bitmap(bitmapData);
                    sprite.addChild(bitmap);
                    
                    sprite.scaleX = 3.0;
                    sprite.scaleY = 3.0;
                    
                    sprite.x = ((this.width - 4*textureNum) / (textureNum + 1) +4)* (i+1) - 16 * (5-textureNum); //tekito
                    sprite.y = (this.height - sprite.height) / 2;
                    
                    sprite.addEventListener(MouseEvent.MOUSE_DOWN, dragSprite_mouseDownHandler);
                    _pixelArtSprite.addChild(sprite);
                }
                
                if (isAllImageExist && currentProfile != null && currentProfile.isEqualUser(qrCodeImage)) {
                    parentApplication.savePixelArtButton.enabled = true;
                }
                
            } else if (qrCodeImage.internalBitmapDataList[0] != null) {
                for (i = 0; i < 6; i++ ) {
                    if (qrCodeImage.internalBitmapDataList[i] == null) {
                        continue;
                    }
                    
                    bitmapData = qrCodeImage.internalBitmapDataList[i];
                    sprite = new Sprite();
                    bitmap = new Bitmap(bitmapData);
                    sprite.addChild(bitmap);
                    
                    sprite.scaleX = 3.0;
                    sprite.scaleY = 3.0;
                    
                    sprite.x = (this.width - 24) / 6 * i + 16;
                    sprite.y = (this.height - sprite.height) / 2;
                    
                    sprite.addEventListener(MouseEvent.MOUSE_DOWN, dragSprite_mouseDownHandler);
                    _pixelArtSprite.addChild(sprite);
                }
            }
            
            _pixelArtUIComponent.addChild(_pixelArtSprite);
        }
        
        /**
         * 分割QRコードを再表示する
         * 
         * @param	qrCodeImage
         */
        private function repaintQRCodeImageSeparateQRCodeView(qrCodeImage:AnimalCrossingQRCodeImage):void
        {
            clearDisplayContainerChildren(_qrCodeImageUIComponent);
            clearDisplayContainerChildren(_qrCodeImageSprite);
            
            parentApplication.saveQRCodeImageButton.enabled = false;
            
            if (qrCodeImage.qrBitmapDataList[0] == null) {
                return;
            }
            
            for (var i:int = 0; i < 4; i++ ) {
                if (!(i in qrCodeImage.qrBitmapDataList) || qrCodeImage.qrBitmapDataList[i] == null) {
                    continue;
                }
                
                var bitmap:Bitmap = new Bitmap(qrCodeImage.qrBitmapDataList[i]);
                var sprite:Sprite = new Sprite();
                sprite.addChild(bitmap);
                _qrCodeImageSprite.x = 0;
                _qrCodeImageSprite.y = 0;
                _qrCodeImageSprite.scaleX = 1.0;
                _qrCodeImageSprite.scaleY = 1.0;
                _qrCodeImageSprite.addChild(sprite);
                
                if (bitmap.width > 400 && bitmap.height > 240) {
                    var sx:Number = 400 / bitmap.width;
                    var sy:Number = 240 / bitmap.height;
                    var scale:Number = sx < sy ? sx : sy;
                    sprite.scaleX = scale;
                    sprite.scaleY = scale;
                } else {
                    sprite.scaleX = 1.0;
                    sprite.scaleY = 1.0;
                }
                
                sprite.x = (parentApplication.qrCodeCanvas.width - sprite.width) / 4 * i + 16;
                sprite.y = (parentApplication.qrCodeCanvas.height - sprite.height) / 2;
                
                if (bitmap.height > 200) {
                    sprite.y += 16 * (i - 2);
                }
                
                sprite.addEventListener(MouseEvent.MOUSE_DOWN, dragSprite_mouseDownHandler);
            }
            
            parentApplication.saveQRCodeImageButton.enabled = true
            _qrCodeImageUIComponent.addChild(_qrCodeImageSprite);
            
        }
        
        /**
         * 画像保存ボタン MOUSE_DOWNハンドラ
         * 
         * @param	event
         */
        private function savePixelArtButton_mouseDownHandler(event:MouseEvent):void
        {
            if (_currentQRCodeImage　== null) {
                setStatusMessage("画像がありません");
                return;
            }
            
            var bitmapData:BitmapData;
            
            if (_currentQRCodeImage.type == AnimalCrossingQRCodeImage.TYPE_SINGLE) {
                if (_currentQRCodeImage.textureImageList[0] == null) {
                    setStatusMessage("画像がありません");
                    return;
                }
                
                if(_currentQRCodeImage.replacedImage == null) {
                    bitmapData = _currentQRCodeImage.textureImageList[0];
                } else {
                    bitmapData = _currentQRCodeImage.replacedImage;
                }
                
            } else if (_currentQRCodeImage.type == AnimalCrossingQRCodeImage.TYPE_SEPARATE) {
                if (_currentQRCodeImage.replacedImageList[0] != null) {
                    bitmapData = createJoinedImage(_currentQRCodeImage.replacedImageList);
                } else if (_currentQRCodeImage.textureImageList[0] != null) {
                    
                    var imageList:Vector.<BitmapData> = new Vector.<BitmapData>();
                    var n:int = _currentQRCodeImage.textureImageList.length;
                    for (var i:int = 0; i < n; i++ ) {
                        imageList[i] = _currentQRCodeImage.textureImageList[i];
                    }
                    
                    bitmapData = createJoinedImage(imageList);
                } else {
                    setStatusMessage("画像がありません");
                    return;
                }
                
            }
            else {
                return;
            }
            
            var pngEncoder:PNGEncoder = new PNGEncoder();
            var byteArray:ByteArray = pngEncoder.encode(bitmapData);
            
            var nameSplit:Array = _currentQRCodeImage.designName.split('.');
            var filename:String = nameSplit[0];
            
            var fileReference:FileReference = new FileReference();
            fileReference.addEventListener(Event.COMPLETE, savePixelArtFileReference_completeHandler);
            fileReference.save(byteArray, filename + "_fullcolor.png");
        }
        
        /**
         * 画像保存FileRefelence COMPLETEハンドラ
         * @param	event
         */
        private function savePixelArtFileReference_completeHandler(event:Event):void
        {
            setStatusMessage("保存しました");
        }
        
        /**
         * エンコードボタン MOUSE_DOWNハンドラ
         * @param	event
         */
        private function encodePixelArtButton_mouseDownHandler(event:MouseEvent):void
        {
            if(_currentQRCodeImage != null) {
                encodeQRCodeImage(_currentQRCodeImage);
            }
        }
        
        /**
         * QRコード読み込みボタン MOUSE_DOWNハンドラ
         * 
         * @param	event
         */
        private function loadQRCodeImageButton_mouseDownHandler(event:MouseEvent):void
        {
            _qrCodeImageFileReference = new FileReference();
            
            _qrCodeImageFileReference.addEventListener(Event.SELECT, qrCodeImageFileReference_selectHandler);
            _qrCodeImageFileReference.addEventListener(Event.COMPLETE, qrCodeImageFileReference_completeHandler);
            
            _qrCodeImageFileReference.browse([
                            FileUtils.FILE_FILTER_PHOTO,
                            FileUtils.FILE_FILTER_JPG,
                            FileUtils.FILE_FILTER_PNG,
                            FileUtils.FILE_FILTER_GIF,
                            FileUtils.FILE_FILTER_ALL
                            ]);    
        }
        
        /**
         * QRコードFileReference SELECTハンドラ
         * @param	event
         */
        private function qrCodeImageFileReference_selectHandler(event:Event):void
        {
            _qrCodeImageFileReference.removeEventListener(Event.SELECT, qrCodeImageFileReference_selectHandler);
            _qrCodeImageFileReference.load();
        }
        
        /**
         * QRコードFileReference COMPLETEハンドラ
         * @param	event
         */
        private function qrCodeImageFileReference_completeHandler(event:Event):void
        {
            _qrCodeImageFileReference.removeEventListener(Event.COMPLETE, qrCodeImageFileReference_completeHandler);
            
            _qrCodeImageLoader = new Loader();
            _qrCodeImageLoader.loadBytes(_qrCodeImageFileReference.data);
            _qrCodeImageLoader.contentLoaderInfo.addEventListener(Event.INIT, qrCodeImageLoader_initHandler);
            
            setStatusMessage("QRコード画像 読み取り完了");
        }
        
        /**
         * QRコードLoader INITハンドラ
         * @param	event
         */
        private function qrCodeImageLoader_initHandler(event:Event):void
        {
            _qrCodeImageLoader.contentLoaderInfo.removeEventListener(Event.INIT, qrCodeImageLoader_initHandler);
            
            var bitmapData:BitmapData = Bitmap(event.target.content).bitmapData;
            
            var byteArray:ByteArray = convertQRCodeToByteArray(bitmapData);
            if(byteArray != null) {
                convertQRCodeByteArrayToPixelArt(byteArray, bitmapData);
            }
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
            
            // 読み取りに失敗したとき、スキャン中でなければ画像をトリミングして再度解析を試みる
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
            
                parentApplication.designNameTextInput.text = qrCodeImage.designName;
                parentApplication.autherNameTextInput.text = qrCodeImage.autherName;
                parentApplication.villageNameTextInput.text = qrCodeImage.villageName;
                
                qrCodeImage.qrBitmapDataList[0] = bitmapData;
            
                pushNewQRCodeDesignList(qrCodeImage);
                repaintQRCodeImageView(qrCodeImage);
                
                setStatusMessage("QRコードから画像を読み取りました");
                return true;
            } else if (firstByte == 0x31 || firstByte == 0x32 || firstByte == 0x33) {
                
                if (_currentQRCodeImage == null) {
                    setStatusMessage("ProデザインQRコードは1番目から読み込んでください");
                    return false;
                }
                
                if (_currentQRCodeImage.type != AnimalCrossingQRCodeImage.TYPE_SEPARATE) {
                    setStatusMessage("ProデザインQRコード（1番目）読み込み後のレコードを選択してください");
                    return false;
                }
                
                
                var index:int;
                if (firstByte == 0x31) {
                    index = 1;
                } else if (firstByte == 0x32) {
                    index = 2;
                } else {
                    index = 3;
                }
                
                if (_currentQRCodeImage.readedQRCodeCount != index) {
                    setStatusMessage("QRコードは1～4を順番に読み込んでください");
                    return false;
                }
                
                byteArray.position = 0;
                success = _currentQRCodeImage.decode(byteArray);
                
                if (!success) {
                    setStatusMessage("画像読み取りに失敗しました");
                    return false;
                }
                
                _currentQRCodeImage.qrBitmapDataList[index] = bitmapData;
                repaintQRCodeImageView(_currentQRCodeImage);
                
                setStatusMessage("QRコードから画像を読み取りました");
                
                return true;
            }
            
            setStatusMessage("画像読み取りに失敗しました");
            return false;
        }
        
        /**
         * QRコード画像保存ボタン MOUSE_DOWNハンドラ
         * 
         * @param	event
         */
        private function saveQRCodeImageButton_mouseDownHandler(event:MouseEvent):void
        {
            if (_currentQRCodeImage　== null) {
                setStatusMessage("QRコードがありません");
                return;
            }
            
            var bitmapData:BitmapData;
            
            if (_currentQRCodeImage.type == AnimalCrossingQRCodeImage.TYPE_SINGLE) {
                
                if( _currentQRCodeImage.qrBitmapDataList[0] == null) {
                    setStatusMessage("QRコードがありません");
                    return;
                }
                
                bitmapData = _currentQRCodeImage.qrBitmapDataList[0];
                
            } else if (_currentQRCodeImage.type == AnimalCrossingQRCodeImage.TYPE_SEPARATE) {
                
                bitmapData = createJoinedImage(_currentQRCodeImage.qrBitmapDataList);
                
            } else {
                return;
            }
            
            
            var pngEncoder:PNGEncoder = new PNGEncoder();
            var byteArray:ByteArray = pngEncoder.encode(bitmapData);
            
            var nameSplit:Array = _currentQRCodeImage.designName.split('.');
            var filename:String = nameSplit[0];
            
            var fileReference:FileReference = new FileReference();
            fileReference.addEventListener(Event.COMPLETE, saveQRCodeFileReference_completeHandler);
            fileReference.save(byteArray, filename + "_QRCode.png");
        }
        
        /**
         * QRコード保存FileReference COMPLETEハンドラ
         * 
         * @param	event
         */
        private function saveQRCodeFileReference_completeHandler(event:Event):void
        {
            setStatusMessage("保存しました");
        }
        
        /**
         * 画像リストを横に連結した画像を生成する
         * 
         * @param	imageList 画像リスト
         * @return 連結画像
         */
        private function createJoinedImage(imageList:Vector.<BitmapData>):BitmapData
        {
            var width:int = 0;
            var height:int = 0;
            
                
            var n:int = imageList.length;
            for (var i:int = 0; i < n; i++ ) {
                if (imageList[i] == null) {
                    continue;
                }
                    
                var partBitmapData:BitmapData = imageList[i];
                if (height < partBitmapData.height) {
                    height = partBitmapData.height;
                }
            
                width += partBitmapData.width;
            }
            
            var bitmapData:BitmapData = new BitmapData(width, height, true);
                
            var x:int = 0;
            for (i = 0; i < n; i++ ) {
                if (imageList[i] == null) {
                    continue;
                }
                    
                partBitmapData = imageList[i];
                bitmapData.copyPixels(imageList[i], imageList[i].rect, new Point(x, 0));
                
                x += partBitmapData.width;
            }
            return bitmapData;
        }
        
        /**
         * カメラスキャンボタン MOUSE_DOWNハンドラ
         * 
         * @param	event
         */
        private function scanCameraButton_mouseDownHandler(event:Event):void
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
         * カメラスキャン中 ENTER_FRAMEハンドラ
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
            if(!_cameraSuccess　&& _cameraBitmapData != null) {
                _cameraBitmapData.dispose();
            }
            
            _cameraVideoDisplay.removeEventListener(Event.ENTER_FRAME, cameraVideoDisplay_enterFrameHandler);
            _cameraVideoDisplay.attachCamera(null);
            
            _cameraScanWindow.removeEventListener(Event.CLOSE, cameraScanWindow_closeHandler);
            PopUpManager.removePopUp(_cameraScanWindow);
        }
        
        /**
         * デザインリスト ITEM_CLICKハンドラ
         * 
         * @param	event
         */
        private function designList_itemClickHandler(event:ListEvent):void
        {
            var list:List = parentApplication.designList;
            var index:int = parseInt(list.selectedItem.@value);
            var qrCodeImage:AnimalCrossingQRCodeImage = _qrCodeImageList[index];
            
            repaintQRCodeImageView(qrCodeImage);
        }
        
        /**
         * 子をすべてremoveする
         * 
         * @param	displayContainer
         */
        private function clearDisplayContainerChildren(displayContainer:DisplayObjectContainer):void
        {
            while(displayContainer.numChildren > 0) {
                displayContainer.removeChildAt(0);
            }
        }
        
        /**
         * 同一ファイル名の単体デザインを探す。存在しない場合はnullを返す
         * 
         * @param	filename 探索ファイル名
         * @return 同一ファイル名のデザイン
         */
        private function searchEqualSingleQRCodeImage(filename:String): AnimalCrossingQRCodeImage
        {
            for (var key:String in _qrCodeImageList) {
                var qrCodeImage:AnimalCrossingQRCodeImage = _qrCodeImageList[key];
                
                if (qrCodeImage.type != AnimalCrossingQRCodeImage.TYPE_SINGLE
                || qrCodeImage.filenameList.length < 1) {
                    continue;
                }
                
                if (filename == qrCodeImage.filenameList[0]) {
                    return qrCodeImage;
                }
            }
            return null;
        }
        
        /**
         * デザインリストを更新する
         */
        private function refreshDesignListXML():void
        {
            _imageListXML.removeAll();
            
            var n:int = _qrCodeImageList.length;
            
            for (var i:int = 0; i < n; i++)
            {
                var designName:String = _qrCodeImageList[i].designName;
                if (!isValidInputString(designName, AnimalCrossingQRCodeImage.DESIGNNAME_MAX_LENGTH, true)) {
                    designName = _qrCodeImageList[i].tmpName;
                }
                
                _imageListXML.addItem(new XML('<node label="' + designName +'" value="' + i +'" />'));
                
            }
            _imageListXML.refresh();
            
            var list:List = parentApplication.designList;
            list.dataProvider = _imageListXML;
        }
        
        /**
         * メッセージを表示する
         * 
         * @param	message
         */
        public function setStatusMessage(message:String):void
        {
            var label:Label = parentApplication.statusLabel;
            label.text = message;
        }
        
        /**
         * 正しい文字列かどうか判定する
         * 
         * @param	value 文字列
         * @param	maxLength 最大文字数
         * @param	checkInputableChar 文字コードチェックをするかどうか 
         * @return 正しい文字列かどうか
         */
        public static function isValidInputString(value:String, maxLength:int, checkInputableChar:Boolean = false):Boolean
        {
            if (value == null || value.length == 0 || value.length > maxLength) {
                return false;
            }
            
            if (checkInputableChar && !isInputableString(value)) {
                return false;
            }
            
            return true;
        }
        
        /**
         * 文字列が入力可能文字コードのみかどうか判定する
         * 
         * @param	value 文字列
         * @return 入力可能かどうか
         */
        public static function isInputableString(value:String):Boolean
        {
            var byteArray:ByteArray = new ByteArray
            byteArray.writeMultiByte(value, "utf-16");
            byteArray.endian = Endian.LITTLE_ENDIAN;
            
            byteArray.position = 0;
            
            // ゆるゆるチェック
            var n:int = byteArray.length;
            while(byteArray.position != n) {
                var char:uint = byteArray.readShort();
                if (char > 0x4000 && (char & 0xFF00) != 0xFF00) {
                    return false;
                }
            }
            
            return true;
        }
        
        /**
         * デザイン名入力フィールド CHANGEハンドラ
         * 
         * @param	event
         */
        private function designNameTextInput_changeHandler(event:Event):void
        {
            var value:String = parentApplication.designNameTextInput.text;
            if (isValidInputString(value, AnimalCrossingQRCodeImage.DESIGNNAME_MAX_LENGTH, true)) {
                if (_currentQRCodeImage != null) {
                    _currentQRCodeImage.designName = value;
                    setStatusMessage("デザイン名を変更しました");
                }
            } else {
                setStatusMessage("入力文字列が不正です");
                return;
            }
            
            checkEnableEncode();
            refreshDesignListXML();
        }
        
        /**
         * 作者名入力フィールド CHANGEハンドラ
         * 
         * @param	event
         */
        private function autherNameTextInput_changeHandler(event:Event):void
        {
            checkEnableEncode();
        }
        
        /**
         * 村名入力フィールドCHANGEハンドラ
         * 
         * @param	event
         */
        private function villageNameTextInput_changeHandler(event:Event):void
        {
            checkEnableEncode();
        }
        
        /**
         * エンコード可能か判定し、エンコードボタンの活性/非活性を設定する
         */
        private function checkEnableEncode():void
        {
            parentApplication.encodePixelArtButton.enabled = false;
            
            if (_currentQRCodeImage == null) {
                return;
            }
            
            if (currentProfile == null) {
                return;
            }
            
            if (!isValidInputField(_currentQRCodeImage)) {
                return;
            }
            
            if (currentProfile.autherName != _currentQRCodeImage.autherName
            || currentProfile.villageName != _currentQRCodeImage.villageName) {
                return;
            }
            
            parentApplication.encodePixelArtButton.enabled = true;
        }
        
        /**
         * テキスト入力フィールドすべてが有効な文字列か判定する
         * 
         * @param	qrCodeImage
         * @return
         */
        private function isValidInputField(qrCodeImage:AnimalCrossingQRCodeImage):Boolean
        {
            
            if (!isValidInputString(qrCodeImage.designName, AnimalCrossingQRCodeImage.DESIGNNAME_MAX_LENGTH, true)) {
                return false;
            }
            
            if (!isValidInputString(qrCodeImage.autherName, AnimalCrossingQRCodeImage.AUTHERNAME_MAX_LENGTH)) {
                return false;
            }
            
            if (!isValidInputString(qrCodeImage.villageName, AnimalCrossingQRCodeImage.VILLAGENAME_MAX_LENGTH)) {
                return false;
            }
            
            return true;
        }
        
        /**
         * デザインリストに新規デザインを追加する
         * 
         * @param	qrCodeImage 追加するデザイン
         */
        private function pushNewQRCodeDesignList(qrCodeImage:AnimalCrossingQRCodeImage):void
        {
            var newIndex:int = _qrCodeImageList.length;
            _qrCodeImageList.push(qrCodeImage);
            refreshDesignListXML();
            var list:List = parentApplication.designList;
            list.selectedIndex = newIndex;
        }
        
        /**
         * ドラッグ可能スプライト MOUSE_DOWNハンドラ
         * 
         * @param	event
         */
        private function dragSprite_mouseDownHandler(event:MouseEvent):void
        {
            var sprite:Sprite = Sprite(event.target);
            
            sprite.startDrag();
            sprite.filters = [DRAGING_DROPSHADOW_FILTER];
            
            sprite.removeEventListener(MouseEvent.MOUSE_DOWN, dragSprite_mouseDownHandler);
            
            sprite.addEventListener(MouseEvent.MOUSE_UP, dragSprite_mouseUpHandler);
        }
        
        /**
         * ドラッグ可能スプライト MOUSE_UPハンドラ
         * 
         * @param	event
         */
        private function dragSprite_mouseUpHandler(event:MouseEvent):void
        {
            var sprite:Sprite = Sprite(event.target);
            sprite.stopDrag();
            sprite.filters = [];
            
            sprite.addEventListener(MouseEvent.MOUSE_DOWN, dragSprite_mouseDownHandler);
            
            sprite.removeEventListener(MouseEvent.MOUSE_UP, dragSprite_mouseUpHandler);
        }
        
        /**
         * パレット選択コンボボックス CHANGEハンドラ
         * @param	event
         */
        private function paletteComboBox_changeHandler(event:Event):void
        {
            if (_currentQRCodeImage != null) {
                var paletteComboBox:ComboBox = parentApplication.paletteComboBox;
                _currentQRCodeImage.paletteType = int(paletteComboBox.selectedItem.data);
            }
        }
        
        /**
         * 使用可能なデザイン画像かどうか判定する
         * 
         * @param	bitmapData デザイン画像
         * @param	sizeRect デザインサイズ
         * @return 使用可否
         */
        public static function isValidPixelArt(bitmapData:BitmapData, sizeRect:Rectangle):Boolean
        {
            if (bitmapData.width != sizeRect.width || bitmapData.height != sizeRect.height) {
               return false;
            }
            
            return true;
        }
        
        /**
         * デザイン画像サイズを調整する
         * 
         * @param	bitmapData デザイン画像
         * @param	sizeRect デザインサイズ
         * @return 調整後のデザイン画像
         */
        public static function adjustPixelArt(bitmapData:BitmapData, sizeRect:Rectangle):BitmapData
        {
            if (isValidPixelArt(bitmapData, sizeRect)) {
                return bitmapData;
            } else {
                var matrix:Matrix = new Matrix();
                matrix.scale(sizeRect.width / bitmapData.width, sizeRect.height / bitmapData.height);
                
                var adjustedBitmapData:BitmapData = new BitmapData(sizeRect.width, sizeRect.height, false);
                adjustedBitmapData.draw(bitmapData, matrix);
                
                bitmapData.dispose();
                return adjustedBitmapData;
            }
        }
        
    }

}