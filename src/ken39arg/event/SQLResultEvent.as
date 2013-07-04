package ken39arg.event
{
	import flash.data.SQLResult;
	import flash.events.Event;

	/**
	 * SQL実行結果イベント.  
	 * 
	 * 取得中、実行完了のSQLのResultを取得できます
	 * 
	 * @access    public
	 * @author    K.Araga
	 * @varsion   $id : SQLResultEvent.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class SQLResultEvent extends Event
	{
		/**
		 * 処理が終了した際のイベント
		 */
		public static const SQL_COMPLETE : String = "sqlComplete";
		
		
		/**
		 * 処理途中で結果が更新された際のイベント
		 */
		public static const SQL_ON_THE_WAY : String = "sqlOnTheWay";
		
		/**
		 * SQLの結果セット
		 */
		public var result:SQLResult;
		
		/**
		 * SQL文のタイプ
		 */
		public var sqlType:String;
		
		/**
		 * 実行したSQL
		 */
		public var sql:String;
		
		public function SQLResultEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, sqlResult:SQLResult = null, sqlQuery:String = null,sqlType:String = null)
		{
			result = sqlResult;
			
			sql = sqlQuery;
			
			this.sqlType = sqlType;
			
			//TODO: implement function
			super(type, bubbles, cancelable);
		}
		
	}
}