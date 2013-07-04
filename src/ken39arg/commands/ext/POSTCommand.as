package ken39arg.commands.ext
{
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import ken39arg.commands.CommandBase;
	import ken39arg.logging.Logger;

	public class POSTCommand extends CommandBase
	{
		protected var _paramObj:Object;
		
		public function POSTCommand(url:String, paramObj:Object = null)
		{
			//Logger.putVerdump(paramObj);
			
			this._paramObj = (paramObj == null) ? {} : paramObj;
			this._paramObj.url = url;
			super();
		}

		public function getUrlRequest():URLRequest
		{
			return buildURLRequest();
		}

		protected function buildURLRequest():URLRequest
		{
			var urlRequest:URLRequest = new URLRequest(_paramObj.url);
			
			// リクエストパラメータの設定
			var valiables:URLVariables = new URLVariables();
			
			if (_paramObj.param) {
				for (var key:String in _paramObj.param) {
					valiables[key] = _paramObj.param[key];
				}
			}
			
			urlRequest.data = valiables;
			
			// メソッドの設定	
			urlRequest.method = URLRequestMethod.POST;
			
			
			return urlRequest;
		}

		
	}
}