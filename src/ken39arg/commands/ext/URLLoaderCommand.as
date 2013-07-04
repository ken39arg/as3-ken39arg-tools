package ken39arg.commands.ext
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	
	import ken39arg.commands.CommandBase;
	import ken39arg.logging.Logger;
	
	/*
	 * URLLoaderをCommandでラップしたもの。
	 * 
	 * paramObjectには以下のパラメーターを渡すことで柔軟に行動を指定できます。
	 * 
	 * url:String ロード先のURLを直接指定する場合
	 * request:URLRequest urlRequestを渡す場合
	 * urlScope:*, urlProp:String 特定のオブジェクトのプロパティを遅延評価で渡す場合
	 * 
	 * loader:URLLoader 任意のURLLoaderを使う場合。指定しない場合はCommand内で自前でURLLoaderが作られる。
	 * dataFormat 自動作成されるURLLoaderで用いられるデータフォーマット。ディフォルトはURLLoaderDataFormat.TEXT
	 *
	 * parser : Function	独自のパース関数を使いたい場合、関数にURLLoader.dataが渡されるので加工後にreturnしてください。ない場合はprotectedのformatData関数が呼ばれます。
	 * 
	 * dataScope:*, dataProp:String URLLoaderで取得したデータを、特定のオブジェクトのプロパティに代入する場合
	 */
	public class URLLoaderCommand extends CommandBase{
		
		protected var paramObj:Object
		protected var loader:URLLoader
		
		public function URLLoaderCommand( paramObj:Object ){
			super();
			this.paramObj = paramObj;
		}
		
		
		override public function execute():void{
			var req:URLRequest = buildRequest();
			
//			Logger.debug("SS--------------------SS");
//			Logger.putVerdump(paramObj);
//			Logger.debug(req.url);
//			Logger.debug("EE--------------------EE");
			
			loader = buildURLLoader();
			loader.addEventListener(Event.COMPLETE, _completeHandler, false, 0, true);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, loaderStatusHandler);
			loader.load(req);
		}
		
		
		//event handler for URLLoader
		protected function _completeHandler(e:Event):void{
			loader.removeEventListener(Event.COMPLETE, _completeHandler);
			loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, loaderStatusHandler);


			//Logger.putVerdump(loader.data);

			
			if(paramObj.dataScope && paramObj.dataProp){
				if(paramObj.parser){
					paramObj.dataScope[paramObj.dataProp] = paramObj.parser(loader.data);
				}else{
					paramObj.dataScope[paramObj.dataProp] = formatData(loader.data);
				}
			}
				
			
			paramObj = null;
			loader = null;
			
			dispatchComplete();
		}
		
		protected function loaderStatusHandler(e:HTTPStatusEvent):void
		{
			//Logger.debug(e.toString());
		}
		
		
		//creates UrlRequest from paramObj
		protected function buildRequest():URLRequest
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
		
		
		//creates URLLoader from paramObj
		protected function buildURLLoader():URLLoader
		{
			var loader:URLLoader
			if( paramObj.loader ){
				loader = paramObj.loader;
			}else{
				loader = new URLLoader();
				if(paramObj.dataFormat){
					loader.dataFormat = paramObj.dataFormat;
				}else{
					loader.dataFormat = URLLoaderDataFormat.TEXT;
				}
			}
			return loader;
		}
		
		
		//formats data used before property injection
		protected function formatData(data:*):*{
			return data;
		}
	}
}