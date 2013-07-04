package ken39arg.event
{
	import flash.events.Event;
	import flash.filesystem.File;

	/**
	 * ダウンロード処理成功時のイベント.  
	 * 
	 * 成功時に出力先と取得もとのURLを参照できます
	 * 
	 * @access    public
	 * @author    K.Araga
	 * @varsion   $id : DownLoadEvent.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class DownLoadEvent extends Event
	{
		public static const SUCCESS : String = "success";
		
		/**
		 * ダウンロード元のURL
		 */
		public var url:String;
		
		/**
		 * ダウンロード先のパスを示すFileオブジェクト
		 */
		public var outputFile:File;
		
		public function DownLoadEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, _url:String = null, _file:File = null)
		{
			url = _url;
			outputFile = _file;
			
			super(type, bubbles, cancelable);
		}
		
	}
}