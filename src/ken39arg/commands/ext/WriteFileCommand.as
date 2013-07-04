package ken39arg.commands.ext
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import ken39arg.commands.CommandBase;

	public class WriteFileCommand extends CommandBase
	{
		private var str:String;
		
		private var file:File;
		
		private var mode:String;
		
		private var stream:FileStream;
		
		public function WriteFileCommand(string:String, file:File, mode:String=FileMode.APPEND)
		{
			super();
			this.str=string;
			this.file=file;
			this.mode=mode;
		}
		
		override public function execute():void
		{
			stream = new FileStream();
			//stream.addEventListener(Event.COMPLETE, fileCompleteHandler);
			stream.open(file, mode);
			stream.writeUTFBytes(str+"\n");
		}
		
		private function fileCompleteHandler(event:Event):void
		{
			stream.removeEventListener(Event.COMPLETE, fileCompleteHandler);
			stream.writeUTFBytes(str+"\r\n");
		}
		
	}
}