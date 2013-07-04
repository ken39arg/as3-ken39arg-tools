package ken39arg.component
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.core.IUITextField;
	import mx.core.UITextField;
	import mx.events.FlexEvent;
	
	
	/**
	 * Marquee
	 * 
	 * マーキーを作成します
	 * 
	 * @access    public
	 * @package   ken39arg.component
	 * @author    K.Araga
	 * @varsion   $id : Marquee.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class Marquee extends Canvas
	{
		public static const RIGHT : int = 1;
		public static const LEFT : int = -1;
		
		private var textField : IUITextField;

		private var textFieldComplete : Boolean = false;
		
		/** スクロール中かどうか */
		private var isScrolling : Boolean = true;
		
		/** 折り返しポイント */
		private var returnPoint : Number;
		
		/** スタートポイント */
		private var startPoint : Number;
		
		/** スクロールしない */
		private var noScroll : Boolean = false;
		
		private var _scrollVelocity : Number = -5;
		
		[Inspectable]
		[Bindable]	
		/**
		 * 速度(scrollDirection × scrollSpeed)
		 */
		public function set scrollVelocity(value:Number):void
		{
			_scrollVelocity = value;
			_scrollDirection = (_scrollVelocity < 0)? -1 : 1;
			_scrollSpeed = Math.abs(_scrollVelocity);
		}
		
		public function get scrollVelocity():Number
		{
			return _scrollVelocity;
		}
		
		// 進行方向
		private var _scrollDirection : int = LEFT;
		
		
		[Inspectable(enumeration="-1,1,0")]
		[Bindable]	
		/**
		 * スクロールの進行方向
		 * -1 -- LEFT
		 * +1 -- RIGHT
		 * 0  -- 停止
		 * デフォルト LEFT
		 */
		public function set scrollDirection(value:int):void
		{
			if (Math.abs(value) > 1 ) {
				throw new Error("範囲外です");
			}
			_scrollDirection = value;
			_scrollVelocity = _scrollDirection * _scrollSpeed;
			changeScrollSpeed();
		}
		
		public function get scrollDirection():int
		{
			return _scrollDirection;
		}
		
		// 速度
		private var _scrollSpeed : Number = 5;
		
		
		[Inspectable]
		[Bindable]	
		/**
		 * スクロールの速さ
		 * １フレームあたりの移動距離
		 */
		public function set scrollSpeed(value:Number):void
		{
			_scrollSpeed = value;
			_scrollVelocity = _scrollDirection * _scrollSpeed;
			changeScrollSpeed();
		}
		
		public function get scrollSpeed():Number
		{
			return _scrollSpeed;
		}
		
		// 停止時間
		private var _stopInterval : Number = 0;
		
		[Inspectable]
		[Bindable]	
		/**
		 * 全スクロール完了後の停止時間（millseconds）. 
		 * 
		 * <p>
		 * このプロパティを設定した場合、スクロールの開始位置が文字が見える位置にかわり、
		 * 文字が全て表示されている場合はスクロールしません
		 * </p>
		 * 
		 * @default 0
		 */
		public function set stopInterval(value:Number):void
		{
			if (_stopInterval == value) {
				return;
			}
			_stopInterval = value;
		}
		
		public function get stopInterval():Number
		{
			return _stopInterval;
		}
		

		private var _text : String = "";
		
		
		[Inspectable]
		[Bindable]	
		/**
		 *　マーキーに表示する文字列 
		 * @return 
		 * 
		 */
		public function get text():String
		{
			return _text;
		}
		
		public function set text(value:String):void
		{
			if (value == "") {
				value = " ";
			}
			if (_text == value) {
				return;
			}

			_text = value;
			_htmlText = '';
			changeTextField();
		}
		
		private var _htmlText : String = "";

		
		[Inspectable]
		[Bindable]	
		/**
		 * マーキーに表示するHTMLテキスト 
		 * @return 
		 * 
		 */
		public function get htmlText():String
		{
			return _htmlText;
		}
		
		public function set htmlText(value:String):void
		{
			if (value == "") {
				value = " ";
			}
			if (_htmlText == value) {
				return;
			}
			_htmlText = value;
			_text = '';
			changeTextField();
		}
		
		
		public function Marquee()
		{
			super();
			verticalScrollPolicy = "off";
			horizontalScrollPolicy = "off";
			addEventListener(FlexEvent.CREATION_COMPLETE, onCreationCpmplete);
		}
		
		/////////////////////////
		//   Methods
		/////////////////////////
		/**
		 * スクロールを開始する 
		 * 
		 */
		public function scrollStart():void
		{
			if (stopInterval > 0) {
				if (isScrolling)
					removeEventListener(Event.ENTER_FRAME,onEnterFrame);
				var timer:Timer = new Timer(stopInterval, 1);
				timer.addEventListener(
					TimerEvent.TIMER_COMPLETE, 
					function (event:TimerEvent):void
					{
						event.target.removeEventListener(event.type, arguments.callee);
						isScrolling = true;
						addEventListener(Event.ENTER_FRAME,onEnterFrame);
					}
					);
				timer.start();
			} else {		
			
				isScrolling = true;
				addEventListener(Event.ENTER_FRAME,onEnterFrame);
			}
		}
		
		/**
		 * スクロールを停止する
		 */
		public function scrollStop():void
		{
			isScrolling = false;
			removeEventListener(Event.ENTER_FRAME,onEnterFrame);
		}
		
		private function changeScrollSpeed():void
		{
			if (textFieldComplete ) {
				noScroll = false;
				
				// スタートポイント&折り返しポイント
				if (_scrollDirection < 0) {
					startPoint = width;
					returnPoint = 0 - textField.textWidth;
				} else {
					startPoint = 0 - textField.textWidth;
					returnPoint = width;
				}
				
				if (stopInterval > 0) {
					// stopInterval が設定されている場合、スタートポイントが変更かわる
					startPoint = 0;
					
					if ( textField.textWidth < width ) {
						noScroll = true;
					}
					
					if (_scrollDirection < 0) {
						returnPoint -= stopInterval / 100;
					} else {
						returnPoint += stopInterval / 100;
					}
				}
				
				if (_scrollVelocity == 0) {
					_scrollVelocity = _scrollDirection * _scrollSpeed;
				}
			}
		}
		
		private function changeTextField():void
		{
			//Logger.debug("Marquee::changeTextField");
			if (textField) {
				var change1:Boolean = false;
				var change2:Boolean = false;
				
				if (_text != '' && _text != textField.text) {
					textField.text = _text;
					change1 = true;
				}
				
				if (_htmlText != '' && _htmlText != textField.htmlText) {
					textField.htmlText = _htmlText;
					change2 = true;
				}
				
				if (change1 || change2) {
					// 一度removeしないと上手くもぐりこまない
					var old:IUITextField = removeChild(UITextField(textField)) as IUITextField;
					textField = new UITextField();
					textField.addEventListener(Event.ADDED, textFieldAddedHandler);
	
					textField.height = old.height;
					
					if (change1) {
						textField.text = old.text;
					} else {
						textField.htmlText = old.htmlText;
					}
					
					textField.width = textField.textWidth + 150; // やや余裕を持たせる

					addChild(UITextField(textField));
					
					changeScrollSpeed();
					dispatchEvent(new Event(Event.CHANGE));
				}
			}
		}
		
		private function onEnterFrame(event:Event):void
		{
			if (noScroll) {
				textField.x = startPoint;
				return;
			}
			
			if ( (_scrollDirection < 0 && textField.x < returnPoint)
				|| (_scrollDirection > 0 && textField.x > returnPoint) ) {
				
				if (stopInterval > 0) {
					scrollStart();
				}
				
				textField.x = startPoint;
			} else {
				
				textField.x += _scrollVelocity;
			}
			//trace("this.width="+this.width+" text.x="+textField.x);
		}
		
		private function onCreationCpmplete(event:FlexEvent):void
		{
			textField = new UITextField();
			textField.addEventListener(Event.ADDED, textFieldAddedHandler);

			if (this.height <= 0) {
				textField.height = 12;
			} else {
				textField.height = this.height;
			}
			
			addChild(UITextField(textField));
			removeEventListener(FlexEvent.CREATION_COMPLETE, onCreationCpmplete);
		}
		
		private function textFieldAddedHandler(event:Event):void
		{
			textField.removeEventListener(Event.ADDED, textFieldAddedHandler);

			textFieldComplete = true;

			changeScrollSpeed();
			
			if (isScrolling) {
				textField.x = startPoint;
				scrollStart();
				
			}
		}
	}
}