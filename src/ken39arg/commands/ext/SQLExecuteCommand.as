package  ken39arg.commands.ext
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.IllegalOperationError;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	
	import ken39arg.event.SQLResultEvent;
	import ken39arg.commands.CommandBase;
	import ken39arg.logging.Logger;
	
	/**
	 *  SQLの実行が完了したことを通知する
	 *
	 *  @eventType ken39arg.event.SQLResultEvent.SQL_COMPLETE
	 */
	[Event(name="sqlComplete", type="ken39arg.event.SQLResultEvent")]
	
	/**
	 *  SELECTの一部が取得されResultが更新された際に通知
	 *
	 *  @eventType ken39arg.event.SQLResultEvent.SQL_ON_THE_WAY
	 */
	[Event(name="sqlOnTheWay", type="ken39arg.event.SQLResultEvent")]
	
	/**
	 *  SQLの実行が失敗したときに通知
	 *
	 *  @eventType flash.events.SQLErrorEvent.ERROR
	 */
	[Event(name="error", type="flash.events.SQLErrorEvent")]
	
	/**
	 * SQLの実行をラッピングしたコマンド. 
	 * 
	 * <p>
	 * コンストラクタでparamObjを自由に組み合わせていい感じにSQLを実行します. 
	 * 値を取得する方法は,SQLResultEventを取得するか、
	 * returnArrayを設定して下さい
	 * </p>
	 * 
	 * @access    public
	 * @author    K.Araga
	 * @varsion   $id : SQLExecuteCommand.as, v 1.0 2008/03/11 K.Araga Exp $
	 */
	public class SQLExecuteCommand extends CommandBase
	{
		/**
		 * SQLステートメント
		 */
		public var statement:SQLStatement;
		
		/**
		 * 取得したレコードの配列. 
		 * ただし、このパラメータがnullの場合はセットしません
		 */
		public var returnArray:Array;
		
		protected var sqlType:String;
		
		protected var paramObj:Object;
		
		protected var prefetch:int = -1;
		
		protected var resultScorp:Object;
		
		/**
		 * コンストラクタ. 
		 *  
		 * @param paramObj パラメータオブジェクト. 
		 *  <p>
		 *   下記の中から柔軟に設定することが出来る
		 *   <code>
		 *   - statement    : SQLStatement  SQLステートメント
		 *   - sql          : String        SQL文
		 *   - paramators   : Object        プレースホルダーパラメーター
		 *   - connection   : SQLConnection SQLコネクション
		 *   - async        : Boolean       非同期モードを使用するか
		 *   - prefetch     : int           prefetch
		 *   - database     : File          データベースファイル
		 *   - itemClass    : Class         アイテムクラス
		 * </code>
		 * </p>
		 * @param returnArray 取得したレコードの配列をセットする
		 */
		public function SQLExecuteCommand( paramObj:Object, returnArray:Array = null )
		{
			this.paramObj = paramObj;
			this.returnArray = ( returnArray == null ) ? [] : returnArray;
			
			/*
			if (paramObj.hasOwnProperty("resultScope") && paramObj.hasOwnProperty("resultProp")) {
				this.hasResultScorp = true;
			}
			*/
		}
		
		public function setResultScorp(scorp:Object, prop:String):void
		{
			this.resultScorp = {};
			this.resultScorp["scorp"] = scorp;
			this.resultScorp["prop"]  = prop;
			//this.hasResultScorp = true;
		}
		
		/**
		 * SQLを実行する
		 * 
		 * @eventType Event.COMPLETE Errorでも必ず発行される
		 * @eventType SQLErrorEvent.ERROR Error時に発行
		 * @eventType SQLResultEvent.SQL_ON_THE_WAY 
		 * @eventType SQLResultEvent.SQL_COMPLETE   
		 */
		override public function execute():void
		{
			prefetch = (paramObj.prefetch != null && paramObj.prefetch is int) ? paramObj.prefetch : -1;
			
			statement = buildSQLStatement();
			
			Logger.putVardump(paramObj, "paramObj");
			Logger.putVardump(statement.parameters, "statement parameter");
			
			if (statement.executing) {
				// 他のSQLが実行中なら終了を待つ
				statement.addEventListener(SQLEvent.RESULT, waitingResultHandler);
				return;
			}

			var conn:SQLConnection = statement.sqlConnection;

			if (conn == null) {
				throw new IllegalOperationError("statementにconnectionがセットされていません");
			}
			
			if (statement.text == null) {
				throw new IllegalOperationError("statementにSQLがセットされていません");
			}
			
			if (conn.connected) {
				// 接続されていたらSQLを実行して終了
				return execSQL();
			}
			
			if (paramObj.database == null || !(paramObj.database is File) ) {
				throw new IllegalOperationError("データベースが指定されていません");
			}
			
			conn.addEventListener(SQLEvent.OPEN, connOpenHandler);
			conn.addEventListener(SQLErrorEvent.ERROR, connErrorHandler);
			
			
			if (paramObj.async) {
				conn.openAsync(paramObj.database);
			} else {
				conn.open(paramObj.database);
			}
		}
		
		private function execSQL():void
		{
			// SQL のタイプを調べる
			var t_i :int = statement.text.search(" ");
			if (t_i == -1) return;
			
			sqlType = statement.text.substring(0, t_i);
			sqlType = sqlType.toUpperCase();
			
			Logger.debug("execSQL:"+statement.text);
			
			// イベントリスナー
			statement.addEventListener(SQLEvent.RESULT, statementResultHandler);
			statement.addEventListener(SQLErrorEvent.ERROR, statementErrorHandler);
			statement.execute(prefetch);
		}
		
		// build
		protected function buildSQLStatement():SQLStatement
		{
			var stmt:SQLStatement;
			var conn:SQLConnection;
			
			if (paramObj.statement != null && paramObj.statement is SQLStatement) {
				stmt = paramObj.statement as SQLStatement;
			} else {
				stmt = new SQLStatement();
			}
			
			if (paramObj.connection != null && paramObj.connection is SQLConnection) {
				conn = paramObj.connection as SQLConnection;
			} else if (stmt.sqlConnection == null) {
				conn = new SQLConnection();
			}
			
			stmt.sqlConnection = conn;
			
			//  SQL文
			if (paramObj.sql != null) {
				stmt.text = paramObj.sql;
			} 
			
			// プレースホルダー
			if (paramObj.paramators != null) {
				stmt.clearParameters();
				for (var p:String in paramObj.paramators) {
					stmt.parameters[p] = paramObj.paramators[p];
				}
			}
			
			// アイテムクラス
			if (paramObj.itemClass != null && paramObj.itemClass is Class) {
				stmt.itemClass = paramObj.itemClass as Class;
			}
			
			return stmt;
		}		
		
		//
		// Handlers
		//
		
		private function connOpenHandler(event:SQLEvent):void
		{
			statement.sqlConnection.removeEventListener(SQLEvent.OPEN, connOpenHandler);
			statement.sqlConnection.removeEventListener(SQLErrorEvent.ERROR, connErrorHandler);
			
			execSQL();
		}

		private function connErrorHandler(event:SQLErrorEvent):void
		{
			statement.sqlConnection.removeEventListener(SQLEvent.OPEN, connOpenHandler);
			statement.sqlConnection.removeEventListener(SQLErrorEvent.ERROR, connErrorHandler);
			
			statement = null;
			paramObj = null;
			resultScorp = null;
			
			dispatchEvent(event.clone());
			//dispatchError();
			dispatchComplete();
		}

		private function waitingResultHandler(event:SQLEvent):void
		{
			var ret:SQLResult = statement.getResult();
			if (ret == null || ret.complete) {
				statement.removeEventListener(SQLEvent.RESULT, waitingResultHandler);
				execute();
			}
		}


		private function statementResultHandler(event:SQLEvent):void
		{
			var result:SQLResult = statement.getResult();
			
			if (result != null && (prefetch > 0 && !result.complete)) {
				dispatchEvent(new SQLResultEvent(SQLResultEvent.SQL_ON_THE_WAY,false,false,result,statement.text,sqlType));
				if (returnArray != null) {
					returnArray = returnArray.concat(result.data);
				}
				if (resultScorp != null) {
					resultScorp["scorp"][resultScorp["prop"]] = returnArray;
				}
				statement.next(prefetch);
			} else {
				dispatchEvent(new SQLResultEvent(SQLResultEvent.SQL_COMPLETE,false,false,result,statement.text,sqlType));
				
				statement.removeEventListener(SQLEvent.RESULT, statementResultHandler);
				statement.removeEventListener(SQLErrorEvent.ERROR, statementErrorHandler);

				if (returnArray != null) {
					returnArray = returnArray.concat(result.data);
				}
				if (resultScorp != null) {
					resultScorp["scorp"][resultScorp["prop"]] = returnArray;
				}
				statement = null;
				paramObj = null;
				resultScorp = null;

				dispatchComplete();
			}		
			
		}

		private function statementErrorHandler(event:SQLErrorEvent):void
		{
			statement.removeEventListener(SQLEvent.RESULT, statementResultHandler);
			statement.removeEventListener(SQLErrorEvent.ERROR, statementErrorHandler);
			
			statement = null;
			paramObj = null;
			resultScorp = null;

			dispatchEvent(event.clone());
			//dispatchError();
			dispatchComplete();			
		}
	}
}