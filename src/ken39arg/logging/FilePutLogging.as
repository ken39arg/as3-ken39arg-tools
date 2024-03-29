package ken39arg.logging
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	
	// only Air Application
	public class FilePutLogging implements ILogging
	{
		public var file:File;
		
		public var localLevel:int=99;
		
		public var maxFileSize:int=1024*1024; // byte
		
		public function FilePutLogging(file:File)
		{
			this.file = file;
		}

		public function put(string:String, level:int=0):void
		{
			if (localLevel==99) {
				localLevel=Logger.errorLevel;
			}
			if (level < localLevel) {
				return;
			}
			try {
				var now : Date = new Date();
				var nowYmd:String=now.getFullYear().toString()+"-"
					+zeroPadding(now.getMonth(), 2) + "-"
					+zeroPadding(now.getDate(), 2) + " "
					+zeroPadding(now.getHours(), 2) + ":"
					+zeroPadding(now.getMinutes(), 2) + ":"
					+zeroPadding(now.getSeconds(), 2);
				
				var mode:String=FileMode.APPEND;
				if (file.exists && file.size>=maxFileSize) {
					file.copyTo(new File(file.url+"-1"),true);
					mode = FileMode.WRITE;
				}
				var stream :FileStream = new FileStream();
				stream.open(file, mode);
				stream.writeUTFBytes(nowYmd+" "+string+"\n");
			} catch (e:Error) {}
		}
		
		private function zeroPadding(number:Number, size:uint):String
		{
			var str:String = number.toString(10);
			while (str.length < size) {
				str = "0" + str;
			}
			return str;
		}
		
		
	}
}