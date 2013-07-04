package  ken39arg.commands.ext
{
	import flash.data.SQLConnection;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	
	import ken39arg.commands.CancelableSerialCommand;

	/**
	 * TransactionLockSQLCommand
	 * 
	 * CancelableSerialCommandの拡張コマンドで、
	 * SQLの処理を行う際に使用すると便利です
	 * 
	 * SQLExcecuteCommandsを含むコマンドを登録すると
	 * 全てのコマンドをトランザクションでグループ化し、Error時にロールバック
	 * コンプリート時にコミットします
	 * 
	 * @access    public
	 * @author    K.Araga
	 * @varsion   $id : TransactionLockSQLCommand.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class TransactionLockSQLCommand extends CancelableSerialCommand
	{
		private var _conn:SQLConnection;
		
		public function TransactionLockSQLCommand(commandArray:Array=null)
		{
			super(commandArray);
		}
		
		override public function execute():void
		{
			_conn = getConnection();
			_conn.begin();
			doNext();
		}
		
		private var error : String = "";
		
		override protected function dispatchComplete():void
		{
			if (_conn == null) {
				return dispatchComplete();
			}
			
			_conn.addEventListener(SQLEvent.COMMIT, connCommitHandler);
			_conn.addEventListener(SQLErrorEvent.ERROR, connErrorHandler);
			_conn.commit();
		}
		
		override protected function dispatchError(message:String=""):void
		{
			if (_conn == null) {
				return dispatchError(message);
			}
			
			_conn.addEventListener(SQLEvent.ROLLBACK, connRollbackHandler);
			_conn.addEventListener(SQLErrorEvent.ERROR, connErrorHandler);
			if (message == "") {
				message = "error"
			}
			error = message;
			_conn.rollback();
			
		}
		
		protected function connCommitHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.COMMIT, connCommitHandler);
			_conn.removeEventListener(SQLErrorEvent.ERROR, connErrorHandler);
			super.dispatchComplete();
		}
		
		protected function connRollbackHandler(event:SQLEvent):void
		{
			_conn.removeEventListener(SQLEvent.ROLLBACK, connRollbackHandler);
			_conn.removeEventListener(SQLErrorEvent.ERROR, connErrorHandler);
			super.dispatchError(error);
			_conn = null;
			_commands = null;
		}
		
		protected function connErrorHandler(event:SQLErrorEvent):void
		{
			if (error != "") {
				_conn.removeEventListener(SQLEvent.ROLLBACK, connRollbackHandler);
			} else {
				_conn.removeEventListener(SQLEvent.COMMIT, connCommitHandler);
				
			}
			_conn.removeEventListener(SQLErrorEvent.ERROR, connErrorHandler);
			super.dispatchError(event.error.details);
			_conn = null;
			_commands = null;
		}
		
		protected function getConnection():SQLConnection
		{
			var conn:SQLConnection = null;
			for (var i:int = 0; i < _commands.length; i++) {
				if (_commands[i] is SQLExecuteCommand) {
					conn = SQLExecuteCommand(_commands[i]).statement.sqlConnection;
					break;
				}
			}
			return conn;
		}
		
	}
}