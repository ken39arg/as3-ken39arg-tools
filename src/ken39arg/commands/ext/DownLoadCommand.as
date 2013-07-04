package  ken39arg.commands.ext
{
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	import ken39arg.event.DownLoadEvent;
	import ken39arg.commands.ext.LoaderCommand;
	import ken39arg.logging.Logger;

	/**
	 *  ダウンロードが完了したことを通知する
	 *
	 *  @eventType ken39arg.event.DownLoadEvent.SUCCESS
	 */
	[Event(name="success", type="ken39arg.event.DownLoadEvent")]

	/**
	 * DownLoadCommand
	 * 
	 * DownLoadを実行するもの
	 * 引数に渡すparamObjで多様な使い方を指定できる。
	 * 
	 * url:String
	 * request:URLRequest
	 * urlScope:Object, urlProp:String
	 * 
	 * outputFile:File
	 * 
	 * urlStream:Loader
	 * urlStreamScope:Object, urlStreamProp:String
 	 * @access    public
	 * @package    ken39arg.commands.ext
	 * @author    K.Araga
	 * @varsion   $id : DownLoadCommand.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class DownLoadCommand extends LoaderCommand
	{
		/**
		 * アウトプット先のファイルオブジェクト
		 */
		protected var outputFile:File;
		
		/**
		 * 取得元のURL
		 */
		protected var url:String;
		
		/**
		 * 取得するためのURLStream
		 */
		protected var urlStream:URLStream;
		
		/**
		 * ファイルデータを一時的に格納するByteArray
		 */
		protected var fileData:ByteArray;
		
		/**
		 * ローカルファイル(outputFile)の書き込みファイルストリーム
		 */
		protected var fileStream:FileStream;
		
		protected var overrideFile:Boolean;
		
		/**
		 * コンストラクタ 
		 * @param paramObj 下記のパラメータを組み合わせて柔軟に対応できます. 
		 *   <code>
		 *    url:String
		 *    request:URLRequest
		 *    urlScope:Object, urlProp:String
		 *    outputFile:File
		 *    urlStream:Loader
		 *    urlStreamScope:Object, urlStreamProp:String
		 *   </code>
 		 * @param outputFile アウトプットするファイルオブジェクト(paramObjで設定しても良い)
		 * @param overrideFile ファイルがローカルに存在する場合に上書きする
		 */
		public function DownLoadCommand(paramObj:Object, outputFile:File = null, overrideFile:Boolean = false)
		{
			super(paramObj);
			this.outputFile = outputFile;
			this.overrideFile = overrideFile;
			
			if (this.outputFile == null) {
				this.outputFile = paramObj.outputFile;
			}
			
			if (this.outputFile == null) {
				throw new IllegalOperationError("outputFileが指定されいません");
			}
			
		}
		
		/**
		 * 実行する 
		 * @eventType Event.COMPLETE Errorでも必ず発行される
		 * @eventType ErrorEvent.ERROR Error時に発行
		 * @eventType DownLoadEvent.SUCCESS 成功時に送出
		 */
		override public function execute():void
		{
			if (outputFile.exists && !overrideFile) {
				dispatchComplete();
				return;
			}
			
			Logger.debug("DownLoadCommand::execute");
			var req:URLRequest = this.buildURLRequest();
			
			url = req.url;
			
			urlStream = this.buildURLStream();
			urlStream.addEventListener(Event.COMPLETE, urlStreamCompleteHandler);
			urlStream.addEventListener(Event.OPEN, urlStreamOpenHandler);
			urlStream.addEventListener(HTTPStatusEvent.HTTP_STATUS, urlStreamHTTPStatusHandler);
			urlStream.addEventListener(IOErrorEvent.IO_ERROR, urlStreamIoErrorHandler);
			
			urlStream.load(req);
		}
		
		/**
		 * ファイルに書き込む 
		 * 
		 */
		protected function writeFile():void
		{
			Logger.debug("writeFile");
			fileStream = new FileStream();
			fileStream.addEventListener(Event.CLOSE, fileStreamCloseHandler);
			fileStream.addEventListener(IOErrorEvent.IO_ERROR, fileStreamIoErrorHandler);
			fileStream.openAsync(outputFile, FileMode.WRITE);
			fileStream.writeBytes(fileData, 0, fileData.length);
			fileStream.close();
		}
		
		//
		//eventHandler for URLStream
		//
		protected function urlStreamCompleteHandler(event:Event):void
		{
			Logger.debug("urlStreamCompleteHandler");
			urlStream.removeEventListener(Event.COMPLETE, urlStreamCompleteHandler);
			urlStream.removeEventListener(IOErrorEvent.IO_ERROR, urlStreamIoErrorHandler);
			urlStream.removeEventListener(Event.OPEN, urlStreamOpenHandler);
			urlStream.removeEventListener(HTTPStatusEvent.HTTP_STATUS, urlStreamHTTPStatusHandler);
			
			fileData = new ByteArray();
			urlStream.readBytes(fileData, 0, fileData.length);
			
			writeFile();
		}
		protected function urlStreamOpenHandler(event:Event):void
		{
			Logger.debug("urlStreamOpenHandler::" + event);
		}
		protected function urlStreamHTTPStatusHandler(event:HTTPStatusEvent):void
		{
			Logger.debug("urlStreamHTTPStatusHandler::" + event);
		}
		
		protected function urlStreamIoErrorHandler(event:IOErrorEvent):void
		{
			Logger.debug("urlStreamIoErrorHandler");
			urlStream.removeEventListener(Event.COMPLETE, urlStreamCompleteHandler);
			urlStream.removeEventListener(IOErrorEvent.IO_ERROR, urlStreamIoErrorHandler);
			urlStream.removeEventListener(Event.OPEN, urlStreamOpenHandler);
			urlStream.removeEventListener(HTTPStatusEvent.HTTP_STATUS, urlStreamHTTPStatusHandler);
			Logger.stactrace("[DownLoadCommand IOERROR]" + event.text);
			
			// IOエラーはエラーとしてディスパッチしない
			//dispatchError();

			paramObj = null;
			urlStream = null;
			this.dispatchComplete();	
			
		}
		
		//
		//eventHandler for FileStream
		//
		protected function fileStreamCloseHandler(event:Event):void
		{
			Logger.debug("fileStreamCloseHandler");
			fileStream.removeEventListener(Event.CLOSE, fileStreamCloseHandler);
			fileStream.removeEventListener(IOErrorEvent.IO_ERROR, fileStreamIoErrorHandler);
			
			dispatchEvent(new DownLoadEvent(DownLoadEvent.SUCCESS,false,false,url,outputFile));

			outputFile = null;
			fileData = null;
			paramObj = null;
			urlStream = null;
			fileStream = null;
			
			this.dispatchComplete();	
			
		}
		
		protected function fileStreamIoErrorHandler(event:IOErrorEvent):void
		{
			Logger.debug("fileStreamIoErrorHandler");
			fileStream.removeEventListener(Event.CLOSE, fileStreamCloseHandler);
			fileStream.removeEventListener(IOErrorEvent.IO_ERROR, fileStreamIoErrorHandler);
			outputFile = null;
			fileData = null;
			paramObj = null;
			urlStream = null;
			fileStream = null;
			Logger.stactrace("[DownLoadCommand IOERROR]" + event.text);
			
			this.dispatchError();
			
			this.dispatchComplete();	
			
		}
		
		
		// Build
		/**
		 * URLStreamを作成する 
		 * @return 
		 * 
		 */
		protected function buildURLStream():URLStream
		{
			var urlStream:URLStream
			if( paramObj.urlStream){
				urlStream = paramObj.urlStream;
			}else if( paramObj.urlStreamScope && paramObj.urlStreamProp ){
				urlStream = paramObj.urlStreamScope[paramObj.urlStreamProp]
			}else{
				urlStream = new URLStream();
			}
			
			return urlStream;
		}
		
		
	}
}