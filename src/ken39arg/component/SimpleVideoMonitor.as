package ken39arg.component
{
import flash.media.Camera;
import flash.media.Video;
import flash.net.NetStream;

import mx.containers.Canvas;
import mx.core.UIComponent;
import mx.events.FlexEvent;


/**
 * SimpleVideoMonitor
 * 
 * ビデオモニター:
 * VideoDisplayのしょぼい版
 * でもNetStreamが使用できる
 * 16:9,4:3に対応した自動サイズ補正
 * 
 * @access    public
 * @package   ken39arg.component
 * @author    K.Araga
 * @varsion   $id : SimpleVideoMonitor.as, v 1.0 2007/12/06 K.Araga Exp $
 */
public class SimpleVideoMonitor extends Canvas
{
	/** 16:9ハイビジョンかどうか */
	public var wideMode:Boolean = false;
	
	/** ストリーム名 */
	[Bindable]
	public var channel:String;
	
	/** 余白サイズ */
	public var space:int = 0;
	
	/** 内部に持っているビデオの幅(read-only) */
	private var _videoHolderWidth:int = 0;
	
	public function get videoHolderWidth():int
	{
		return this._videoHolderWidth;
	}
	
	/** 内部に持っているビデオの高さ(read-only) */
	private var _videoHolderHeight:int = 0;
	
	public function get videoHolderHeight():int
	{
		return this._videoHolderHeight;
	}

	[Bindable]
	private var v_holder:UIComponent = new UIComponent();

	[Bindable]
	private var _video:Video = null;

	public function set video(val:Video):void
	{
		this._video = val;
	}

	[Bindable]
	public function get video():Video
	{
		return this._video;
	}

	[Bindable]
	private var _ns:NetStream = null;
	
	public function set ns(val:NetStream):void
	{
		this._ns = val;
	}

	[Bindable]
	public function get ns():NetStream
	{
		return this._ns;
	}

	public function get deblocking():int
	{
		this.settingVideo();
		return this.video.deblocking;
	}
	
	public function set deblocking(value:int):void
	{
		this.settingVideo();
		this.video.deblocking = value;	
	}
	
    public function get smoothing():Boolean
	{
		this.settingVideo();
		return this.video.smoothing;
	}
	
    public function set smoothing(value:Boolean):void
	{
		this.settingVideo();
		this.video.smoothing = value;	
	}
	
	public function get videoHeight():int
	{
		this.settingVideo();
		return this.video.videoHeight;
	}
	
	public function get videoWidth():int
	{
		this.settingVideo();
		return this.video.videoWidth;
	}
	
	public function SimpleVideoMonitor():void
	{
		super();
		//this.init();
		this.addEventListener(FlexEvent.CREATION_COMPLETE, init);
		//this.addEventListener(ResizeEvent.RESIZE, resizeHandler);
	}
	
	private function init(event:FlexEvent):void
	{
		// デフォルトの色を黒くする
		if ( this.getStyle("backgroundColor") == null ) {
			this.setStyle("backgroundColor","0x000000");
		}
		
		// サイズ補正
		this.autoSize();
		
		this.v_holder.setStyle("top",space);
		this.v_holder.setStyle("bottom",space);
		this.v_holder.setStyle("left",space);
		this.v_holder.setStyle("right",space);
		this.horizontalScrollPolicy = "off";
		this.verticalScrollPolicy = "off";
		
		this.changeVideoSize();
		
		this.addChild(v_holder);
		this.removeEventListener(FlexEvent.CREATION_COMPLETE, init);
		
		change_flag = true;
	}
	
	private var change_flag:Boolean = false;
	
	override public function set width(value:Number):void
	{
		super.width = value;
		this.chnageSize();
	}
	
	override public function set height(value:Number):void
	{
		super.height = value;
		this.chnageSize();
	}
			
	
	private function chnageSize():void
	{
		if (this.change_flag) {
			this.autoSize();
			this.changeVideoSize();
		}
	}
	
	private function autoSize():void
	{
		//　変更後のサイズ
		var v_height:int = this.width * ratio;
		var v_width:int = this.height / ratio;
		
		if (v_width <= this.width) {
			v_height = this.height;
		} else {
			v_width = this.width;
		}
		
		super.width = v_width;
		super.height = v_height;
		
	}
	
	private function changeVideoSize():void
	{
		var v_height:int = this.height - this.space;
		var v_width:int = this.width - this.space;
		if (this.space != 0) {
			if (v_width * this.ratio > v_height) {
				v_width = v_height * this.ratio;
			} else {
				v_height = v_width * this.ratio;
			}
		}

		this._videoHolderHeight = v_height;
		this._videoHolderWidth  = v_width;
		
		if (this.video != null) {
			this.video.width = v_width;
			this.video.height = v_height;
			
		}
	}
	
	public function get ratio():Number
	{
		var ret:Number;
		if (this.wideMode) {
			// 16:9
			ret = 9 / 16;
		} else {
			// 4:3
			ret = 3 / 4;
		}
		return ret;
	}

	private function settingVideo():void
	{
		if (this.video == null) {
			this.video = new Video();
			this.changeVideoSize();
			this.v_holder.addChild(this.video);
			this.video.visible = true;
		}
	}

	public function setJustSize():void
	{
		this.change_flag = false;
		this.width = this.videoWidth + space;
		this.height = videoHeight + space;
		this.v_holder.width = this.videoWidth;
		this.v_holder.height = this.videoHeight;
		this.video.width = this.videoHeight;
		this.video.height = this.videoHeight;
		this.change_flag = true;
	}
	
	public function attachCamera(_camera:Camera):void
	{
		this.settingVideo();
		this.video.attachCamera( _camera );
	}

	public function attachNetStream(netStream:NetStream):void
	{
		this.settingVideo();
		this.ns = netStream;
		this.video.attachNetStream(ns);
	}
	
	public function clear():void
	{
		if (this.ns != null) {
			this.ns.close();
			this.ns = null;
		}
		this.settingVideo();
		this.video.clear();
		this.video = null;
		
	}
	
	public function play():void
	{
		if (this.ns == null) return;

		this.ns.play(channel);
	}
	
	public function changeVolume(value:Number):void
	{
		if (this.ns != null) {
			this.ns.soundTransform.volume = value;
		}
	}
	
	public function pause():void
	{
		this.ns.pause();
	}
	
	public function resume():void
	{
		this.ns.resume();
	}
		
}
}