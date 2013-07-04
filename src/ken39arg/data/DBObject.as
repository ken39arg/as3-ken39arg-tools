package ken39arg.data
{
	import flash.data.SQLConnection;
	import flash.data.SQLIndexSchema;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLTableSchema;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	
	import ken39arg.core.ClassUtil;
	import ken39arg.core.Iterator;
	import ken39arg.logging.Logger;
	import ken39arg.util.KAUtil;

	/**
	 * DBObject
	 * 
	 * DB全体を管理するクラス
	 * 
	 * 初期化処理などのパフォーマンスは保障しないので
	 * 何らかの方法でインスタンスは唯一にする必要がある
	 * 
	 * 内部にDB構成要素を下記のように持ち、テーブルに対するイテレーターを保持する
	 * 
	 * +- DBObject
	 * 　@- tables:Array
	 *    +- TableObject
	 *     @- columns:Array
	 *      +- ColumnObject
	 * 
	 * またViewなどには対応していない 
	 * 
	 * 全体的にリレーション管理には対応出来ていないので
	 * リレーションを作成する場合は、拡張または別途SQLを作成する必要がある
	 * 
	 * @access    public
	 * @package   ken39argdata
	 * @author    K.Araga
	 * @varsion   $id : DBObject.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class DBObject extends EventDispatcher
							 implements Iterator
	{
		private var _index : int = 0;
		
		//
		// tables
		//
		
		private var _tables:Array;
		
		/**
		 * テーブルの集まり
		 */
		public function get tables():Array
		{
			return _tables;
		}
		
		/**
		 * DB識別子
		 */
		public var name:String;
		
		/**
		 * 表示ラベル
		 */
		public var label:String;
		
		/**
		 * DB名
		 */
		public var dbName:String;
		
		/**
		 * DBファイル
		 */
		public var dbFile:File;
		
		//
		// sqlConnection
		//
		private var _sqlConnection : SQLConnection;
		
		public function get sqlConnection() : SQLConnection
		{
			if (_sqlConnection == null) {
				_sqlConnection = new SQLConnection();
			}
			return _sqlConnection;
		}
		
		//
		// schema
		//
		private var _schemaResult : SQLSchemaResult;
		
		/**
		 * SQLSchemaResult
		 * このプロパティはupdatePrepareを実行した際にセットされ
		 * updateCompleteで削除されます
		 */
		protected function get schemaResult():SQLSchemaResult
		{
			return _schemaResult;
		}
		
		/**
		 * 現在のスキーマが保有するSQLTableSchemaインスタンスの配列
		 * このプロパティはupdatePrepareを実行した際にセットされ
		 * updateCompleteで削除されます
		 */
		public function get schemaTables():Array
		{
			if (_schemaResult == null) {
				return [];
			}
			return _schemaResult.tables;
		}
		
		/**
		 * 現在のスキーマが保有するSQLIndexSchemaインスタンスの配列
		 * このプロパティはupdatePrepareを実行した際にセットされ
		 * updateCompleteで削除されます
		 */
		public function get schemaIndices():Array
		{
			if (_schemaResult == null) {
				return [];
			}
			return _schemaResult.indices;
		}
		
		
		//
		// definitionXML
		//
		
		private var _definitionXML : XML;
		
		public function get definitionXML() : XML
		{
			return _definitionXML;
		}
		
		/**
		 * DB定義XML
		 * 
		 * DB単位で定義する
		 * +-database
		 *   @- name    : 識別子
		 *   @- label   : 表示用ラベル
		 *   @- dbName  : db名(dbFileを指定した場合は不要)
		 *   @- dbFile  : dbファイル(指定しない場合はapplicationStorageDirectory)
		 *    +- tables
		 *      +- table
		 *        @- name       : テーブル名
		 *        @- label      : 表示用ラベル
		 *        @- prymaryKey : プライマリーキー
		 *        @- itemClass  : itemClassが必要であれば(ItemClassはSQLStatement::itemClassを参照)
		 *        @- tableClass : TableObjectまたはTableObjectのサブクラス
		 *        +- columns      : カラム
		 *         +- column
		 *          @- name          : カラム名
		 *          @- label         : 表示名
		 *          @- formClass     : 入力フォームで使用するクラス名
		 *          @- type          : TEXT/INTEGER/BLOB (DATA::自動変換対応予定)Default=TEXT
		 *          @- notnull       : TRUE/FALSE Default=false
		 *          @- default       : デフォルト値
		 *          @- autoIncrement : AUTOINCREMENTかどうか Default=false
		 *          @- index         : インデックスを生成するかDefault=false
		 *          @- uniq          : ユニークかどうか
		 *          @- columnClass   : ColumnObjectまたはColumnObjectのサブクラス
		 *           +- options         : オプション情報
		 *             +-option           :オプション要素
		 *               @- value            : 値
		 *               @- label            : 表示ラベル
		 *        +- items  : デフォルトINSERT項目  -  将来の拡張のために予約していますが、現在サポートしていません
		 *         +- item
		 *          +- <colum_name>value</colum_name>
		 */ 
		public function set definitionXML(value:XML) : void
		{
			if (_definitionXML === value) {
				return;
			}
			
			//trace(value);
			
			_definitionXML = value;
			
			name    = value.@name;
			label   = value.@label;
			dbName  = value.@dbName;
			dbFile  = value.@dbFile as File;
			
			if (dbFile == null) {
				if ( !KAUtil.isInput(dbName) ) {
					throw new IllegalOperationError("dbNameまたはdbFileを設定してください");
				}
				dbFile = File.applicationStorageDirectory.resolvePath(dbName+".db");
			}
			
			_tables = [];
			
			for each (var t_xml:XML in value.tables.table) {
				// テーブルオブジェクトを追加
				var tableClass:String  = t_xml.@tableClass;
				var table:TableObject;
				if (KAUtil.isInput(tableClass)) {
					table = ClassUtil.newInstance(tableClass) as TableObject;
					table.definitionXML = t_xml;
				} else {
					table = new TableObject(t_xml);
				}
				table.dbObject = this;
				_tables.push(table);
			}
			
		}

		
		/**
		 * コンストラクタ 
		 * @param definitionXML
		 * 
		 */
		public function DBObject(definitionXML:XML = null)
		{
			this.definitionXML = definitionXML;
		}

		/**
		 * TableObjectを取得する 
		 * @param tableName
		 * @return 
		 */
		public function getTable(tableName:String):TableObject
		{
			var tbl:TableObject = null;
			for (var i:int = 0; i < _tables.length; i++) {
				if (TableObject(_tables[i]).tableName == tableName) {
					tbl = TableObject(_tables[i]);
					break;
				}
				tbl = null;
			}
			return tbl;
		} 

		/**
		 * TableObjectをセットする
		 * テーブルオブジェクトの生成を遅延させたいときなどに使用するかも
		 * @param tableObject
		 * 
		 */
		public function setTableObject(tableObject:TableObject):void
		{
			if (_tables == null) {
				_tables = [];
			}
			_tables.push(tableObject);
		}

		/**
		 * テーブル名からスキーマを返す 
		 * @param tableName
		 * @return 
		 * 
		 */
		public function getTableSchema(tableName:String):SQLTableSchema
		{
			if (schemaTables == null) {
				return null;
			}
			
			var t:SQLTableSchema = null;
			for (var i:int = 0; i < schemaTables.length; i++) {
				t = schemaTables[i] as SQLTableSchema
				if (t.name == tableName) {
					break;
				}
				t = null;
			}
			return t;
		}
		
		/**
		 * テーブルに属すschemaIndicesを返す
		 * @param tableName
		 * @return 
		 * 
		 */
		public function getIndicesAtTable(tableName:String):Array
		{
			var tableFilter:Function = function(element:*, index:int, arr:Array):Boolean
			{
				return SQLIndexSchema(element).table == tableName;
			}
			
			return schemaIndices.filter(tableFilter);
		}
		
		/**
		 * インデックス名からスキーマを返す
		 * @param indexName
		 * @return 
		 * 
		 */
		public function getIndexSchema(indexName:String):SQLIndexSchema
		{
			var t:SQLIndexSchema = null;
			for (var i:int = -1; i < schemaIndices.length; i++) {
				t = schemaIndices[i] as SQLIndexSchema
				if (t.name == indexName) {
					break;
				}
				t = null;
			}
			return t;
		}
		
//		//
//		// IUpdateMethods
//		//
//		/*
//		private var updateTable:TableObject;
//
//		/*
//		 * アップデートの準備を行う
//		 * @event Event.COMPLETE 準備完了
//		 */
//		public function updatePrepare():void
//		{
//			_index = 0;
//			try {
//				if (!sqlConnection.connected) {
//					sqlConnection.addEventListener(SQLEvent.OPEN,updatePrepare_openHandler);
//					sqlConnection.openAsync(dbFile);
//				} else {
//					sqlConnection.addEventListener(SQLEvent.SCHEMA, updatePrepare_schemaHandler);
//					sqlConnection.addEventListener(SQLErrorEvent.ERROR, updatePrepare_errorHandler);
//					sqlConnection.loadSchema();
//				}
//			} catch (e:Error) {
//				Logger.stactrace(e);
//			}
//		}
//
//		private function _updatePrepare():void
//		{
//			if (hasNext()) {
//				var t:TableObject = getNext() as TableObject;
//				t.addEventListener(Event.COMPLETE, updatePrepare_childCompleteHandler);
//				t.updatePrepare();
//			} else {
//				_index = 0;
//				dispatchEvent(new Event(Event.COMPLETE));
//			}
//		}
//
//		private function updatePrepare_openHandler(event:SQLEvent):void
//		{
//			sqlConnection.removeEventListener(SQLEvent.OPEN,updatePrepare_openHandler);
//			updatePrepare();
//		}
//
//		private function updatePrepare_schemaHandler(event:SQLEvent):void
//		{
//			sqlConnection.removeEventListener(SQLEvent.SCHEMA, updatePrepare_schemaHandler);
//			sqlConnection.removeEventListener(SQLErrorEvent.ERROR, updatePrepare_errorHandler);
//			_schemaResult = sqlConnection.getSchemaResult();
//			_updatePrepare();
//		}
//
//		private function updatePrepare_errorHandler(event:SQLErrorEvent):void
//		{
//			sqlConnection.removeEventListener(SQLEvent.SCHEMA, updatePrepare_schemaHandler);
//			sqlConnection.removeEventListener(SQLErrorEvent.ERROR, updatePrepare_errorHandler);
//			
//			// ERRORの場合は全て作成する
//			_schemaResult = null;
//			_updatePrepare();
//		}		
//
//		private function updatePrepare_childCompleteHandler(event:Event):void
//		{
//			IEventDispatcher(event.target).removeEventListener(Event.COMPLETE, updatePrepare_childCompleteHandler);
//			_updatePrepare();
//		}
//
//		/*
//		 * 内部アップデート処理が必要かどうか 
//		 * @return 
//		 * 
//		 */
//		/*
//		public function hasUpdate():Boolean
//		{
//			var ret:Boolean = false;
//			
//			while (hasNext()) {
//				ret = TableObject(getNext()).hasUpdate();
//				if (ret) break;
//			}
//			_index = 0;
//			return ret;
//		}
//		*/
//		
//		/*
//		 * 次のアップデート処理があるかどうか 
//		 * @return 
//		 */
//		/*
//		public function hasNextUpdate():Boolean
//		{
//			return hasNext();
//		}
//		*/
//		
//		/* 
//		 * 次のアップデート処理を行うオブジェクトを取得する
//		 * @return 
//		 */
//		 /* 廃止
//		public function getNextUpdate():IUpdate
//		{
//			var updater : IUpdate;
//			while (hasNextUpdate()) {
//				updater = getNext() as IUpdate;
//				if (updater.hasUpdate()) {
//					break;
//				}
//			} 
//			return updater;
//		}
//		*/
//		
//		/*
//		 * アップデート処理を実行する
//		 */
//		 /*
//		public function execUpdate():void
//		{
//			if (hasNextUpdate()) {
//				var updator:IUpdate = getNextUpdate();
//				if (updator == null) {
//					execUpdate();
//				}
//				updator.addEventListener(Event.COMPLETE, execUpdate_updatorCompleteHandler);
//				updator.execUpdate();
//			} else {
//				_index = 0;
//				dispatchEvent(new Event(Event.COMPLETE));
//			}
//		}
//		*/
//		/*
//		private function execUpdate_updatorCompleteHandler(event:Event):void
//		{
//			event.target.removeEventListener(Event.COMPLETE, execUpdate_updatorCompleteHandler);
//			execUpdate();
//		}
//		*/
		
		//
		// Iterator Methods
		//
		
		public function hasNext():Boolean
		{
			return (_index < _tables.length);
		}
		
		public function getNext():*
		{
			return _tables[_index++];
		}
		
		public function getItemAt(index:uint):*
		{
			if (index < _tables.length) {
				_index = index;
				return _tables[index];
			} else {
				throw new IllegalOperationError("指定のインデックスが範囲外です");
			}
		}
		
	}
}