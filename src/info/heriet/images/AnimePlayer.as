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
    import flash.display.Sprite;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    
    public class AnimePlayer extends Sprite
    {
        public var currentFrame:uint;
        public var frames:Array;
        
        private var _isAbailable:Boolean;
        private var _timer:Timer;
        
        public function AnimePlayer(frames:Array) 
        {
            this.frames = frames;
            currentFrame = 0;
            _isAbailable = true;
            
            var n:int = frames.length;
            
            var firstFrame:IFrameData = frames[currentFrame];
            while (firstFrame != null && (!firstFrame.isAbailable || currentFrame >= n)) {
                currentFrame++;
                firstFrame = frames[currentFrame];
            }
            
            if(firstFrame != null){
                addChild(firstFrame.display);
            
                _timer = new Timer(firstFrame.wait, 0);
            }
            else {
                addChild(frames[0].display);
                _isAbailable = false;
            }
        }
        private function update(event:TimerEvent):void
        {
            var prevFrame:IFrameData = frames[currentFrame];
            
            if(contains(prevFrame.display))
                removeChild(prevFrame.display);
            
            currentFrame++;    
            
            if (currentFrame >= frames.length) {
                currentFrame = 0;
            }
            
            var nextFrame:IFrameData = frames[currentFrame];
            
            while (!nextFrame.isAbailable) {
                currentFrame++;
                if (currentFrame >= frames.length) {
                    currentFrame = 0;
                }
                
                nextFrame = frames[currentFrame];
            }
            
            _timer.delay = nextFrame.wait;
            addChild(nextFrame.display);
        }
        public function play():void
        {
            if (_isAbailable && frames.length > 1 && !_timer.running) {
                _timer.addEventListener (TimerEvent.TIMER, update)
                _timer.start();
            }
        }
        public function stop():void
        {
            if (_timer.running) {
                _timer.removeEventListener (TimerEvent.TIMER, update)
                _timer.stop();
            }
        }
        
    }
    
}