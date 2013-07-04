package ken39arg.commands.ext
{
	import ken39arg.logging.Logger;
	
	/**
	 * XMLを返す、URLLoaderCommandの拡張。
	 * 
	 * XMLにデータを変換する為には、URLLoaderのdataFormatがテキストであるように注意すること。
	 */
	public class XMLLoaderCommand extends URLLoaderCommand
	{
		public function XMLLoaderCommand(paramObj:Object)
		{
			super(paramObj);
		}
		
		// dataConversion
		override protected function formatData(data:*):*
		{	
			try {
				return new XML(data);
			} catch (e:Error) {
				Logger.error(e.message);
				Logger.debug(data);
				dispatchError(e.message);
			}
		}
	}
}