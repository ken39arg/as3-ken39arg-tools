package ken39arg.component
{
	import flash.events.MouseEvent;
	
	import ken39arg.logging.Logger;
	import ken39arg.util.KAUtil;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.VideoDisplay;
	import mx.controls.sliderClasses.Slider;
	import mx.events.FlexEvent;
	import mx.events.SliderEvent;
	import mx.events.SliderEventClickTarget;
	import mx.events.VideoEvent;
	
	/**
	 * MoviePlayerBase
	 * 
	 * MoviePlayerのデザインに自由度を持たせるために変更
	 * 
	 * @access    public
	 * @author    K.Araga
	 * @varsion   $id : MoviePlayerBase.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class MoviePlayerBase extends Canvas
	{
		protected var cmmandBtnStyle : String = "";
			
		//
		// totalTime
		//
		
		private var _totalTime : String = "00:00";
		
		/**
		 * ビデオの全体の再生時間 
		 * @return 
		 * 
		 */
		protected function get totalTime() : String
		{
			return _totalTime;
		}
		
		protected function set totalTime(value:String) : void
		{
			_totalTime = value;
			if (totalPointText != null) {
				totalPointText.text = _totalTime;
			}
		}
		
		//
		// seekTime
		//
		
		private var _seekTime : String = "00:00";
		
		
		/**
		 * ビデオの現在の再生時間 
		 * @return 
		 * 
		 */
		protected function get seekTime() : String
		{
			return _seekTime;
		}
		
		protected function set seekTime(value:String) : void
		{
			_seekTime = value;
			if (seekPointText != null) {
				seekPointText.text = _seekTime;
			}
		}
		
		public var autoPlay : Boolean = false;
		
		/**
		 * スタートボタンのスタイル名
		 */
		public var playBtnStyle : String = "playBtn";
		
		/**
		 * ストップボタンのスタイル名
		 */
		public var pauseBtnStyle : String = "pauseBtn";
		
		//
		// コンポーネント
		//
		
		[Bindable]
		/**
		 * 保持するビデオディスプレイ
		 */
		private var _video : VideoDisplay;
		
		public function get video():VideoDisplay
		{
			return _video;
		}
		
		public function set video(value:VideoDisplay):void
		{
			if (_video == value) {
				return;
			}
			
			_video = value;
		}
		
		
		
		[Bindable]
		/**
		 * スタートストップボタン 
		 */
		public var commandBtn : Button;
		
		[Bindable]
		/**
		 * シークするスライダー
		 */
		public var seekSlider : Slider;
		
		[Bindable]
		/**
		 * 現在の表示時間をあらわすLabel
		 */
		public var seekPointText : Label;
		
		[Bindable]
		/**
		 * 全体時間をあらわすLabel
		 */
		public var totalPointText : Label;
		
		//
		// source
		//
		
		protected var _source : String;
		
		/**
		 * VideoのソースURL
		 */
		public function get source():String
		{
			return this._source;
		}
		
		public function set source(value:String):void
		{
			if (this._source != value) {
				this._source = value;
				adjustSize = false;
				make();
			}
		}
		
		//
		// status
		//
		
		protected var _status : String = "";
		
		private var _btnStatus : String = "";
		
		/**
		 * 現在の再生状態
		 * "play","pause","stop"
		 */
		public function get status():String
		{
			return _status;
		}
		
		public function set status(value:String):void
		{
			var _styleChanged : Boolean = false;
			
			if ( _status == value && cmmandBtnStyle != "" ) {
				return;
			}
			_status = value;
			
			switch (_status) {
				case "play":
					if (cmmandBtnStyle != pauseBtnStyle) {
						cmmandBtnStyle = pauseBtnStyle;
						_styleChanged = true;
					}
					_btnStatus = "pause";
					break;
				case "pause":
				case "stop":
					if (cmmandBtnStyle != playBtnStyle) {
						cmmandBtnStyle = playBtnStyle;
						_styleChanged = true;
					}
					_btnStatus = "play";
					break;
			}
			if (commandBtn != null && _styleChanged) {
				commandBtn.styleName = cmmandBtnStyle;
			}
		}
		
		//
		// size 調整用パラメータ
		// 
		
		private var nomalVideoWidth : Number;
		
		private var nomalVideoHeight : Number;
		
		private var adjustSize : Boolean = false;

		private var _maxVideoWidth : Number;
		
		public function get maxVideoWidth() : Number
		{
			return _maxVideoWidth;
		}
		
		public function set maxVideoWidth(value:Number):void
		{
			if (_maxVideoWidth == value) {
				return;
			}
			
			_maxVideoWidth = value;
			
			adjustSize = false;
			
			//settingVideoSize();
		}
		
		private var _maxVideoHeight : Number;
		
		public function get maxVideoHeight() : Number
		{
			return _maxVideoHeight;
		}
		
		public function set maxVideoHeight(value:Number):void
		{
			if (_maxVideoHeight == value) {
				return;
			}
			
			_maxVideoHeight = value;
			
			adjustSize = false;
			
			//settingVideoSize();
		}
		
		private var _fitDefaultVideoSize : Boolean = true;
		
		public function get fitDefaultVideoSize():Boolean
		{
			return _fitDefaultVideoSize;
		}
		
		public function set fitDefaultVideoSize(value:Boolean):void
		{
			if (_fitDefaultVideoSize == value) {
				return;
			}
			
			_fitDefaultVideoSize = value;
			
			adjustSize = false;
			
			//settingVideoSize();
		}
		
		/**
		 * コンストラクタ 
		 * 
		 */
		public function MoviePlayerBase()
		{
			addEventListener(FlexEvent.CREATION_COMPLETE, onCreationCompleteHandler, false, int.MAX_VALUE);
			super();
		}
		
		/** 
		 * @param event
		 * 
		 */
		protected function onCreationCompleteHandler(event:FlexEvent):void
		{
			removeEventListener(FlexEvent.CREATION_COMPLETE, onCreationCompleteHandler);
			
			status = "stop";
			seekTime = "00:00";
			totalTime = "00:00";
			
			if (video) {
				videoCreationCompleteHandler(event);
			}
			commandBtnCreationCompleteHandler(event);
			seekSliderCreationCompleteHandler(event);
			
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		protected function videoCreationCompleteHandler(event:FlexEvent):void
		{
			if (video.hasEventListener(FlexEvent.CREATION_COMPLETE)) {
				video.removeEventListener(FlexEvent.CREATION_COMPLETE, videoCreationCompleteHandler);
			}
			video.bufferTime = 2;
			video.autoPlay = false;
			
			// 元のビデオサイズをセット
			nomalVideoWidth = video.width;
			nomalVideoHeight = video.height;
			
			// ビデオに使用できる最大サイズが設定されていなければ設定する
			if (isNaN(maxVideoWidth) || maxVideoWidth <= 0)
				maxVideoWidth = nomalVideoWidth;

			if (isNaN(maxVideoHeight) || maxVideoHeight <= 0)
				maxVideoHeight = nomalVideoHeight;
				
			//autoPlay = video.autoPlay;
				
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		protected function commandBtnCreationCompleteHandler(event:FlexEvent):void
		{
			//trace("commandBtnCreationCompleteHandler");
			if (commandBtn.hasEventListener(FlexEvent.CREATION_COMPLETE)) {
				commandBtn.removeEventListener(FlexEvent.CREATION_COMPLETE, commandBtnCreationCompleteHandler);
			}
			commandBtn.addEventListener(MouseEvent.CLICK, commandBtnClickHandler);
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		protected function seekSliderCreationCompleteHandler(event:FlexEvent):void
		{
			if (seekSlider.hasEventListener(FlexEvent.CREATION_COMPLETE)) {
				seekSlider.removeEventListener(FlexEvent.CREATION_COMPLETE, seekSliderCreationCompleteHandler);
			}
			seekSlider.minimum = 0;
			seekSlider.liveDragging = true;
			seekSlider.addEventListener(SliderEvent.CHANGE, seekSliderChangeHandler);
			seekSlider.addEventListener(SliderEvent.THUMB_PRESS, seekSliderThumbPressHandler);
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		protected function commandBtnClickHandler(event:MouseEvent):void
		{
			commandExec();
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		protected function seekSliderChangeHandler(event:SliderEvent):void
		{
			seekVideo();
			if (event.clickTarget == SliderEventClickTarget.THUMB) {
				pause();
			} else {
				play();
			}
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		protected function seekSliderThumbPressHandler(event:SliderEvent):void
		{
			seekSlider.removeEventListener(SliderEvent.THUMB_PRESS, seekSliderThumbPressHandler);
			seekSlider.addEventListener(SliderEvent.THUMB_RELEASE, seekSliderThumbReleaseHandler);
			pause();
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		protected function seekSliderThumbReleaseHandler(event:SliderEvent):void
		{
			seekSlider.removeEventListener(SliderEvent.THUMB_RELEASE, seekSliderThumbReleaseHandler);
			seekSlider.addEventListener(SliderEvent.THUMB_PRESS, seekSliderThumbPressHandler);
			play();
		}
		
		/**
		 * ビデオをロードする
		 */
		protected function make():void
		{
			try {
				if (video.playing) {
					video.stop();
				}
				video.close();
				seekSlider.value = 0;
				status = "stop";
				video.addEventListener(VideoEvent.READY, videoReadyHandler);
				video.source = this._source;
				if (!video.autoPlay) {
					if (autoPlay) {
						play();
					} else {
						video.load();
					}
				}
				//video.load();
			} catch (e:Error) {
				Logger.stactrace(e);
			}
		}
		
		private var prevVideoWidth:Number;
		
		private var prevVideoHeight:Number;
		
		protected function settingVideoSize():void
		{
			if (!video)
				return;
			
			if (adjustSize 
				&& 	video.videoWidth == prevVideoWidth
				&& video.videoHeight == prevVideoHeight) {
				return;
			}
			if (video.videoWidth == 0 || video.videoHeight == 0) {
				return;
			}

			
			do {
				var ratio:Number = video.width / video.height;
				var maxRatio:Number = maxVideoWidth / maxVideoHeight;
				
				if (video.videoWidth <= maxVideoWidth
					&& video.videoHeight <= maxVideoHeight
					) {
					//　高さ幅ともに枠内
					if (fitDefaultVideoSize) {
						video.width = video.videoWidth;
						video.height = video.videoHeight;
						break;
						
					} 
					else if (ratio == maxRatio) {	
						// 縦横比が標準					
						video.width = maxVideoWidth;
						video.height = maxVideoHeight;
						break;
					} 
					else if (ratio > maxRatio) {
						// 横長
						video.width = maxVideoWidth;
						video.height = maxVideoWidth / ratio;
					} 
					else {
						// 縦長
						video.width = maxVideoHeight * ratio;
						video.height = maxVideoHeight;
						
					}
				}
				
				if (video.videoWidth > maxVideoWidth) {
					// 幅がオーバー
					video.width = maxVideoWidth;
					video.height = maxVideoWidth / ratio;
					break;
				}

				if (video.videoHeight > maxVideoHeight) {
					// 高さオーバー
					video.width = maxVideoHeight * ratio;
					video.height = maxVideoHeight;
					break;
				}

				
			} while (false);
			
			prevVideoWidth = video.videoWidth;
			prevVideoHeight = video.videoHeight;
			adjustSize = true;
		}
		
		/**
		 * シークする
		 */
		protected function seekVideo():void
		{
			if (this._source == null) {
				seekSlider.value = 0;
				return;
			}
			
			if (video.playing) {
				pause();
			}
			
			if (video.stateResponsive) {
				video.playheadTime = seekSlider.value;
			}
			
		}
		
		/**
		 * ボタンを押したときの動作
		 */
		public function commandExec():void
		{
			if (video.state == VideoEvent.CONNECTION_ERROR
				|| video.state == VideoEvent.DISCONNECTED) {
				return;
			}
			
			switch (_btnStatus) {
				case "play":
					play();
					break;
				case "pause":
					pause();
					break;
				case "stop":
					stop();
					break;
					
			}
		}
		
		/**
		 * 動画を再生する
		 */
		public function play():void
		{
			video.play();
			status = "play";
			video.addEventListener(VideoEvent.PLAYHEAD_UPDATE, videoPlayheadUpdateHandler);
			video.addEventListener(VideoEvent.COMPLETE, videoCompleteHandler);
		}
		
		/**
		 * 動画を一時停止する
		 */
		public function pause():void
		{
			video.pause();
			status = "pause";
			//commandBtn.iconStatus = VideoControllBtn.PLAY;
			video.removeEventListener(VideoEvent.PLAYHEAD_UPDATE, videoPlayheadUpdateHandler);
		}
		
		/**
		 * 動画を停止する
		 */
		public function stop():void
		{
			if (!video.playing)
				return;
			
			video.stop();
			status = "stop";
			video.removeEventListener(VideoEvent.PLAYHEAD_UPDATE, videoPlayheadUpdateHandler);
		}

		/**
		 * 動画サイズをオリジナルサイズに変更する
		 */
		public function changeOriginalSize():void
		{
			if (video) {
				
				video.width = video.videoWidth;
				video.height = video.videoHeight;
			}
		}


		//
		// Handlers
		//
		
		/**
		 * ビデオソースが変更されて再生の準備が整ったとき 
		 * @param event
		 * 
		 */
		protected function videoReadyHandler(event:VideoEvent):void
		{
			video.removeEventListener(VideoEvent.READY, videoReadyHandler);
			
			if (video.totalTime > 0) 
				totalTime = KAUtil.secondsToMinStr(video.totalTime);
			else 
				totalTime = "00:00"; 
			
			if (seekSlider != null) {
				seekSlider.maximum = video.totalTime;
			}
			seekTime = "00:00";
			
			//settingVideoSize();
		}
		
		/**
		 * ビデオの再生ヘッドが更新されたとき
		 * @param event
		 * 
		 */
		protected function videoPlayheadUpdateHandler(event:VideoEvent):void
		{
			seekTime = KAUtil.secondsToMinStr(video.playheadTime);
			
			if (video.totalTime > 0) 
				totalTime = KAUtil.secondsToMinStr(video.totalTime);
			else 
				totalTime = "00:00"; 
			//totalTime = UoozoUtil.secondsToMinStr(video.totalTime);
			if (seekSlider != null) {
				seekSlider.maximum = video.totalTime;
				seekSlider.value = video.playheadTime;
			}
			status = "play";
			
			//settingVideoSize();
		}
		
		/**
		 * ビデオの再生が完了したとき
		 * @param event
		 * 
		 */
		protected function videoCompleteHandler(event:VideoEvent):void
		{
			seekTime = KAUtil.secondsToMinStr(video.playheadTime);
			if (seekSlider != null) {
				seekSlider.value = video.playheadTime;
			}
			video.removeEventListener(VideoEvent.PLAYHEAD_UPDATE, videoPlayheadUpdateHandler);
			video.removeEventListener(VideoEvent.COMPLETE, videoCompleteHandler);
			status = "stop";
		}
		
	}
}