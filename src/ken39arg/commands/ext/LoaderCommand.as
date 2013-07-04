package ken39arg.commands.ext
{
	import ken39arg.commands.CommandBase;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.events.IOErrorEvent;

	/**
	 * LoaderクラスをCommand化したもの. 
	 * 引数に渡すparamObjで多様な使い方を指定できる。
	 *
	 * url:String.
	 * request:URLRequest
	 * urlScope:Object, urlProp:String
	 * 
	 * alternativeURL:String 代替イメージのURL
	 * 
	 * loader:Loader
	 * loaderScope:Object, loaderProp:String
	 */
	public class LoaderCommand extends CommandBase
	{
		protected var paramObj:Object
		protected var loader:Loader
		
		public function LoaderCommand(paramObj:Object)
		{
			this.paramObj = paramObj;
		}
		
		override public function execute():void
		{
			var req:URLRequest = this.buildURLRequest();
			loader = this.buildLoader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _completeHandler, false, 0, true);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, _ioErrorHandler, false, 0, true);
			
			loader.load(req);
		}
		
		
		//eventHandler for Loader
		protected function _completeHandler(e:Event):void
		{
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, _completeHandler);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, _ioErrorHandler);
			
			paramObj = null;
			loader = null;
			this.dispatchComplete();	
		}
		
		protected function _ioErrorHandler(e:Event):void
		{
			if(paramObj.alternativeURL){
				loader.load(new URLRequest(paramObj.alternativeURL));
			}else{
				_completeHandler(e);
			}
		}
		
		
		protected function buildURLRequest():URLRequest
		{
			var req:URLRequest
			if( paramObj.url ){
				req = new URLRequest(paramObj.url);
			}else if( paramObj.request ){
				req = paramObj.request;
			}else if( paramObj.urlScope && paramObj.urlProp ){
				req = new URLRequest( paramObj.urlScope[paramObj.urlProp] );
			}
			return req;
		}
		
		
		protected function buildLoader():Loader
		{
			var loader:Loader
			if( paramObj.loader){
				loader = paramObj.loader;
			}else if( paramObj.loaderScope && paramObj.loaderProp ){
				loader = paramObj.loaderScope[paramObj.loaderProp]
			}else{
				loader = new Loader();
			}
			
			return loader;
		}
	}
}