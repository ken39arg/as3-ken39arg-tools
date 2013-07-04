package ken39arg.commands.ext
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	
	import ken39arg.logging.Logger;

	public class FileUploadCommand extends POSTCommand
	{
		private var _file : FileReference;
		private var _dataFieldName : String;
		
		public function FileUploadCommand(url:String, file:FileReference, paramObj:Object = null, dataFieldName:String = "data")
		{
			_file = file;
			_dataFieldName = dataFieldName;
			super(url, paramObj);
		}
		
		override public function execute():void
		{
			var urlRequest:URLRequest = buildURLRequest();
			
			// サーバーからレスポンスがない場合に、終了しないからやめた方がいいか？ -> responseを返しません
			//_file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, fileUoloadCompleteDataEvent);
			_file.addEventListener(Event.COMPLETE, fileCompleteHandler);
			_file.addEventListener(IOErrorEvent.IO_ERROR, fileIOErrorHandler);
			_file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, fileSecurityErrorErrorHandler);
			_file.addEventListener(HTTPStatusEvent.HTTP_STATUS, fileHTTPStatusHandler);
			
			_file.upload(urlRequest, _dataFieldName);
			
		}
		
		override protected function dispatchError(message:String= ""):void
		{
			super.dispatchError(message);
			removeListeners();
			dispatchComplete();
		}
		
		private function removeListeners():void
		{
			_file.removeEventListener(Event.COMPLETE, fileCompleteHandler);
			_file.removeEventListener(IOErrorEvent.IO_ERROR, fileIOErrorHandler);
			_file.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, fileSecurityErrorErrorHandler);
			_file.removeEventListener(HTTPStatusEvent.HTTP_STATUS, fileHTTPStatusHandler);
			
			// 参照を解除
			_file = null;
			
		}
		
		private function fileCompleteHandler(event:Event):void
		{
			removeListeners();
			dispatchComplete();
		}

		private function fileIOErrorHandler(event:IOErrorEvent):void
		{
			Logger.error(event.toString());
			dispatchError(event.toString());
		}

		private function fileSecurityErrorErrorHandler(event:SecurityErrorEvent):void
		{
			Logger.error(event.toString());
			dispatchError(event.toString());
		}

		private function fileHTTPStatusHandler(event:HTTPStatusEvent):void
		{
			Logger.error(event.toString());
			//dispatchError(event.toString());
			if (event.status >= 400) {
				dispatchError(event.toString());
			}
			
		}
		
	}
}