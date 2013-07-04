package ken39arg.data
{
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLIndexSchema;
	import flash.data.SQLTableSchema;
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.filesystem.File;
	
	import ken39arg.commands.ICommand;
	import ken39arg.commands.NullCommand;
	import ken39arg.commands.SerialCommand;
	import ken39arg.commands.ext.SQLExecuteCommand;
	import ken39arg.core.ClassLoader;
	import ken39arg.core.ClassUtil;
	import ken39arg.core.Iterator;
	import ken39arg.event.SQLResultEvent;
	import ken39arg.event.TableValidateErrorEvent;
	import ken39arg.logging.Logger;
	import ken39arg.util.KAUtil;
	
	import mx.collections.ArrayCollection;
	
	/**
	 * TableObject
	 * 
	 * テーブルの基本的なSQLやアイテムを管理するクラス
	 * 
	 * リレーションには対応していないので、必要がある場合は別途SQLを記述する必要があります。
	 * 
	 * 内部にレコードに対するイテレーターを保持する
	 * 
	 * 複数のSQLを処理したい場合は hogeCommandでICommandを取得してSerialCoammandなどで実行させると便利です。
	 * 
	 * 1テーブルにつき1インスタンス生成される
	 * 1レコードではないので注意
	 * 別途アイテムクラスを定義するのがよいと思う
	 * 
	 * SQLを実行するイベントでは全てSQL_COMPLETEとSQL_ERROR、SQL_GET_RECORDSのいずれかが発行されます
	 * 
	 * @access    public
	 * @author    K.Araga
	 * @varsion   $id : TableObject.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class TableObject extends EventDispatcher 
								implements Iterator
	{
		//
		// Event Type
		//
		
		/**
		 * SQLの実行が終了した際に送出するイベント
		 */
		public static const SQL_COMPLETE : String = "sqlComplete";
		
		/**
		 * SQLの実行が失敗した場合に送出するイベント
		 */
		public static const SQL_ERROR : String = "sqlError";
		
		/**
		 * SELECTの実行でレコードが取得された時に送出するイベント
		 */
		public static const SQL_GET_RECORDS : String = "sqlGetRecords";
		
		//
		//  properties
		//
		
		/**
		 * Itelatorの現在のインデックス
		 */
		private var _index : int = 0;
		
		/**
		 * コントロール中のインデックス
		 */
		private var controlIndex:int = 0;
		
		/**
		 * SELECT時にitemsをリフレッシュするかどうか
		 */
		private var _refresh:Boolean = false;
		
		/**
		 * getRecordsで使用するprefetch
		 */
		private var _prefetch : int = -1;

		/**
		 * 各excecuteで使用するクロージャー
		 */
		private var _closure : Function;
		
		/**
		 * キーカラム名
		 */
		protected var keyColumn : String;
		
		/**
		 * 使用するアイテムクラス
		 */
		protected var itemClass : Class;
		
		/**
		 * 保持するカラム
		 * definitionXMLを設定すれば自動生成される
		 */
		private var _columns : Array;
		
		public function get columns():Array
		{
			//Logger.debug("get columns");
			return _columns;
		}
		
		/**
		 * DBオブジェクト
		 */
		public var dbObject : DBObject;
		
		/**
		 * テーブル名
		 */
		public var tableName : String;

		/**
		 * テーブル表示名
		 */
		public var label : String;
		
		/**
		 * データベースファイル
		 */
		public function get database():File
		{
			return dbObject.dbFile;
		}
		
		//
		// items
		//
		[Bindable]
		private var _items : ArrayCollection;
		
		/**
		 * 取得しているアイテム配列
		 */
		public function get items():ArrayCollection
		{
			return _items;
		}
		
		public function set items(value:ArrayCollection):void
		{
			_items = value;
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
		 * テーブル定義XML. 
		 * 
		 * <p>
		 * テーブル単位で定義する. 
		 * <code>
		 * +- table
		 *   @- name       : テーブル名
		 *   @- label      : 表示用ラベル
		 *   @- prymaryKey : プライマリーキー
		 *   @- itemClass  : itemClassが必要であれば(ItemClassはSQLStatement::itemClassを参照)
		 *   +- columns      : カラム
		 *    +- column
		 *     @- name          : カラム名
		 *     @- label         : 表示名
		 *     @- formClass     : 入力フォームで使用するクラス名
		 *     @- type          : TEXT/INTEGER/BLOB (DATA::自動変換対応予定)Default=TEXT
		 *     @- notnull       : TRUE/FALSE Default=false
		 *     @- default       : デフォルト値
		 *     @- autoIncrement : AUTOINCREMENTかどうか Default=false
		 *     @- index         : インデックスを生成するかDefault=false
		 *     @- uniq          : ユニークかどうか
		 *     @- columnClass   : ColumnObjectまたはColumnObjectのサブクラス
		 *      +- options         : オプション情報
		 *        +-option           :オプション要素
		 *          @- value            : 値
		 *          @- label            : 表示ラベル
		 *   +- items  : デフォルトINSERT項目  -  将来の拡張のために予約していますが、現在サポートしていません
		 *    +- item
		 *     +- colmun
		 *      @- name
		 *      @- value
		 *  </code>
		 */ 
		public function set definitionXML(value:XML) : void
		{
			if (_definitionXML === value) {
				return;
			}
			
			_definitionXML = value;
			
			this.tableName = value.@name;
			this.keyColumn = value.@prymaryKey;
			this.itemClass = (KAUtil.isInput(value.@itemClass)) ? ClassLoader.getClass(value.@itemClass) : null;
			this.label     = value.@label;
			
			//Logger.debug("_columns.edit");
			_columns = [];
			
			for each (var t_xml:XML in value.columns.column) {	
				var isPrymaryKey:Boolean = (t_xml.@name == keyColumn);
				
				// カラムオブジェクトを追加
				var columnClass:String  = t_xml.@columnClass;
				var table:TableObject;
				var column:ColumnObject;
				if ( KAUtil.isInput( columnClass ) ) {
					column = ClassUtil.newInstance(columnClass) as ColumnObject;
					column.definitionXML = t_xml;
					column.primaryKey = isPrymaryKey;
				} else {
					column = new ColumnObject(isPrymaryKey,	t_xml);
				}
				//Logger.putVerdump(column, "set columObject table is" + this.tableName);
				_columns.push(column);
			}
			
			
		}
		
		//
		// connection
		//
		
		/**
		 * SQLConnectionオブジェクト
		 */
		public function get sqlConnection():SQLConnection
		{
			return dbObject.sqlConnection;
		}
		
		
		//
		// Methods
		//
		
		/**
		 * コンストラクタ
		 * @param definitionXML テーブル定義ファイル
		 * 
		 */
		public function TableObject(definitionXML:XML = null)
		{
			this.definitionXML = definitionXML;
			_items = new ArrayCollection();
			//Logger.debug("constract Tableobj "+ this.tableName);
		}
		
		//
		// column
		//
		/**
		 * ColumnObjectを取得する 
		 * @param colName
		 * @return 
		 */
		public function getColumn(colName:String):ColumnObject
		{
			var col:ColumnObject = null;
			for (var i:int = 0; i < _columns.length; i++) {
				if (ColumnObject(_columns[i]).name == colName) {
					col = ColumnObject(_columns[i]);
					break;
				}
				col = null;
			}
			return col;
		} 
		
		//
		// craeteTable
		//
		
		/**
		 * テーブルを作成する
		 */
		public function createTable():void
		{
			exec(buildCreateTable(),-1,false);
		}
		
		/**
		 * CREATE TABLE実行コマンドを返す
		 * @return ICommand
		 */
		public function getCreateTableCommand():ICommand
		{
			return buildCommand(buildCreateTable(), -1);
		}
		
		//
		// DROP TABLE
		//
		
		/**
		 * テーブルを削除する
		 */
		public function dropTable():void
		{
			exec(buildCreateTable(),-1);
		}
		
		/**
		 * DROP TABLE実行コマンドを返す
		 * @return ICommand
		 */
		public function getDropTableCommand():ICommand
		{
			return buildCommand(buildDropTable(), -1);
		}
		
		//
		// get records
		//
		
		/**
		 * テーブルからレコードを取得する
		 * 取得したレコードはitemsまたはgetItemAt,getNextで取得する
		 * (OR条件やリレーションを使用する場合は別途SQLを作成してください)
		 * 
		 * @param where WHERE句の条件を設定 {<column name>:<value>,,,}
		 * @param sort  ORDER条件 {column name>:TRUE-ASC/FALSE-DESC,,,}
		 * @param limit 取得件数
		 * @param offset オフセット
		 * @param refresh 結果セットをリフレッシュして取得しなおすかどうか default=true
		 * @param custom カスタムパラメータWEHERにStringを使用したときにパラメータを設定する
		 */
		public function getRecords(where:Object, sort:Object, 
									limit:Number = 0, offset:Number = 0, 
									prefecth:int = -1, refresh:Boolean = true, custom:Object = null):void
		{
			_refresh = refresh;
			exec(buildGetRecords(where,sort,limit,offset,custom),prefecth);
		}
		
		/**
		 * getRecordコマンドを取得する
		 * 取得したレコードはitemsまたはgetItemAt,getNextで取得する
		 * (OR条件やリレーションを使用する場合は別途SQLを作成してください)
		 * 
		 * @param where WHERE句の条件を設定 {<column name>:<value>,,,}
		 * @param sort  ORDER条件 {column name>:TRUE-ASC/FALSE-DESC,,,}
		 * @param limit 取得件数
		 * @param offset オフセット
		 * @param refresh 結果セットをリフレッシュして取得しなおすかどうか default=true
		 * @param custom カスタムパラメータWEHERにStringを使用したときにパラメータを設定する
		 * @return ICommand
		 */
		public function getRecordsCommand(where:Object, sort:Object, 
									limit:Number = 0, offset:Number = 0, 
									prefecth:int = -1, refresh:Boolean = true, custom:Object = null):ICommand
		{
			Logger.putVardump(custom, "getRecordsCommand::custom");
			_refresh = refresh;
			return buildCommand(buildGetRecords(where,sort,limit,offset,custom),prefecth);
		}
		
		
		//
		// GetRecordsById
		//
		
		/**
		 * キーからレコードを取得する 
		 * @param id
		 * @param refresh 結果セットをリフレッシュして取得しなおすかどうか default=true
		 */
		public function getRecordById(id:*, refresh:Boolean = true):void
		{
			if (_items.length > 0) {
				// 既にitemsがセットされている場合はインデックスを変更するのみ
				for (var i:int = 0; i < _items.length; i++) {
					if (_items[i][keyColumn] == id) {
						_index = i;
						dispatchEvent(new Event(SQL_COMPLETE));
						return;
					}
				}
			}
			_prefetch = -1;
			_refresh = refresh;
			
			exec(buildGetRecordById(id),-1);
		}

		/**
		 * getRecordByIdコマンドを取得する 
		 * @param id
		 * @param refresh 結果セットをリフレッシュして取得しなおすかどうか default=true
		 * @return ICommand
		 */
		public function getRecordByIdCommand(id:*, refresh:Boolean = true):ICommand
		{
			if (_items.length > 0) {
				// 既にitemsがセットされている場合はインデックスを変更するのみ
				for (var i:int = 0; i < _items.length; i++) {
					if (_items[i][keyColumn] == id) {
						_index = i;
						//dispatchEvent(new Event(SQL_COMPLETE));
						return null;
					}
				}
			}
			_prefetch = -1;
			_refresh = refresh;
			
			return buildCommand(buildGetRecordById(id),-1);
		}

		
		//
		// INSERT
		//
		
		/**
		 * 1件挿入する
		 * 
		 * item,indexともに未指定の場合は現在のitem
		 * 
		 * @param item 挿入するアイテムオブジェクト
		 * @param index 挿入するアイテムのインデックス
		 */
		public function insert(item:* = null, index:int = -1):void
		{
			if (item != null) {
				index = setItem(item);
				//index = _items.length - 1;
			} else {
			
				if (index < 0) {
					index = this._index;
				}
				
				item = getItemAt(index);
			}
			
			controlIndex = index;
			
			if (!validate(controlIndex)) {
				// バリデート失敗
				return;
			}
			
			exec(buildInsert(item),-1);
		}
		
		/**
		 * INSERTコマンドを取得する
		 * 
		 * item,indexともに未指定の場合は現在のitem
		 * 
		 * @param item 挿入するアイテムオブジェクト
		 * @param index 挿入するアイテムのインデックス
		 * @return ICommand
		 */
		public function insertCommand(item:* = null, index:int = -1):ICommand
		{
			if (item != null) {
				index = setItem(item);
				//index = _items.length - 1;
			} else {
			
				if (index < 0) {
					index = this._index;
				}
				
				item = getItemAt(index);
			}
			
			controlIndex = index;
			
			if (!validate(controlIndex)) {
				// バリデート失敗
				return null;
			}
			
			return buildCommand(buildInsert(item),-1);
			
		}
		
		//
		// UPDATE
		//
		
		/**
		 * 1件更新する
		 * 
		 * item,indexともに未指定の場合は現在のitem
		 * 
		 * @param item 挿入するアイテムオブジェクト
		 * @param index 挿入するアイテムのインデックス
		 */
		public function update(item:* = null, index:int = -1):void
		{
			//Logger.debug("updateNow");
			
			Logger.putVardump(item);
			
			if (item != null) {
				index = setItem(item);
				//index = _items.length - 1;
			} else {
			
				if (index < 0) {
					index = this._index;
				}
				
				item = getItemAt(index);
			}
			
			controlIndex = index;
			
			if (!validate(controlIndex, true)) {
				// バリデート失敗
				return;
			}

			if (!item.hasOwnProperty(keyColumn)) {
				throw new IllegalOperationError("キーの値がありません");
			}
			
			exec(buildUpdate(item),-1);
		}
		
		/**
		 * UPDATEコマンドを取得する
		 * 
		 * item,indexともに未指定の場合は現在のitem
		 * 
		 * @param item 挿入するアイテムオブジェクト
		 * @param index 挿入するアイテムのインデックス
		 * @return ICommand
		 */
		public function updateComamnd(item:* = null, index:int = -1):ICommand
		{
			if (item != null) {
				index = setItem(item);
				//index = _items.length - 1;
			} else {
			
				if (index < 0) {
					index = this._index;
				}
				
				item = getItemAt(index);
			}
			
			controlIndex = index;
			
			if (!validate(controlIndex, true)) {
				// バリデート失敗
				return null;
			}

			if (!item.hasOwnProperty(keyColumn)) {
				throw new IllegalOperationError("キーの値がありません");
			}
			
			return buildCommand(buildUpdate(item),-1);
		}

		//
		// DELETE
		//
		
		/**
		 * 1件削除する
		 * 
		 * item,indexともに未指定の場合は現在のitem
		 * 
		 * @param item 挿入するアイテムオブジェクト
		 * @param index 挿入するアイテムのインデックス
		 * 
		 */
		public function deleteRecord(item:* = null, index:int = -1):void
		{
			if (item != null) {
				index = setItem(item);
				//index = _items.length - 1;
			} else {
			
				if (index < 0) {
					index = this._index;
				}
				
				item = getItemAt(index);
			}
			
			controlIndex = index;
			
			if (!item.hasOwnProperty(keyColumn)) {
				throw new IllegalOperationError("キーの値がありません");
			}
			
			exec(buildRecordDelete(item),-1);
			
			
		}
		
		/**
		 * DELETE コマンドを取得する
		 * 
		 * item,indexともに未指定の場合は現在のitem
		 * 
		 * @param item 挿入するアイテムオブジェクト
		 * @param index 挿入するアイテムのインデックス
		 * @return ICommand
		 */
		public function deleteCommand(item:* = null, index:int = -1):ICommand
		{
			if (item != null) {
				index = setItem(item);
				//index = _items.length - 1;
			} else {
			
				if (index < 0) {
					index = this._index;
				}
				
				item = getItemAt(index);
			}
			
			controlIndex = index;
			
			if (!item.hasOwnProperty(keyColumn)) {
				throw new IllegalOperationError("キーの値がありません");
			}
			
			return buildCommand(buildRecordDelete(item),-1);
			
			
		}
		
		
		//
		// validator
		//
		
		/**
		 * indexのアイテムをバリデートする
		 * エラーの場合エラーイベントを送出
		 * index = -1なら現在のアイテム
		 * 
		 * @param index
		 * @param requireDelete  必須項目のNULLエラーは無視する
		 * @return true:OK/false:NG
		 * 
		 */
		public function validate(index:int = -1, requireDelete:Boolean = false):Boolean
		{
			if (index < 0) {
				index = this._index;
			}
			
			var item:* = _items[index];
			var	col:ColumnObject;
			var ret:Object;
			var errors:Array = [];
			
			for (var i:int = 0; i < columns.length; i++) {
				col = columns[i] as ColumnObject;
				if ((col.primaryKey || col.autoIncrement) && !item.hasOwnProperty(col.name) ) { 
					// キーカラムがNULLなら無視する
					continue;
				}
				if (requireDelete && item[col.name] == null) {
					continue;
				}
				ret = col.validate(item[col.name]);
				
				Logger.debug("col.name is " + ret);
				
				if (!ret.status) {
					if (!requireDelete || !col.notnull) {
						errors.push({colmun:col.name,error:ret.message});
					} else {
						if (col.notnull && item[col.name] == null ) {
							 delete item[col.name];
							
						} else {
							errors.push({colmun:col.name,error:ret.message});
						}
					}
				}
			}
			
			if (errors.length > 0) {
				Logger.putVardump(errors);
				dispatchEvent(new TableValidateErrorEvent(TableValidateErrorEvent.VALIDATE_ERROR,false,false,errors));
				return false;
			} else {
				return true;
			}
		}
		
		//
		// ItemAccesser
		//
		
		/**
		 * アイテムをセットする
		 * 
		 * 追加しただけでINSERTをするわけではない
		 * @param item
		 * @return 追加または更新されたインデックス
		 */
		public function setItem(item:*):int
		{
            if (item is XML) {
            	Logger.debug(item);
            	Logger.debug(item["item"]);
            	Logger.debug(item[keyColumn]);
            	item = xmlToItem(item);
            	
            }

			if (itemClass != null && !(item is itemClass)) {
				throw new IllegalOperationError("アイテムの型が違います");
			}
			
			var i:int = 0;
			var update:Boolean = false;
			
			if (item.hasOwnProperty(keyColumn) && item[keyColumn] != null) {
				for (i; i < _items.length; i++) {
					if (_items[i][keyColumn] == item[keyColumn]) {
						_items[i] = item;
						update = true;
						break;
					}
				}
			}
			
			if (!update) {
				_items.addItem(item);
			}
			
			if (update) {
				return i;
			} else {
				return (_items.length - 1);
			}
		}
		
		/**
		 * XMLオブジェクトをitemオブジェクトまたは、ハッシュオブジェクトに変換する.  
		 * 
		 * XMLオブジェクトの形式は、<item>[ノード名をレコード名とする]</item>
		 * 
		 * @param xml
		 * @return 
		 * 
		 */
		public function xmlToItem(xml:XML):Object
		{	
			var item : Object;
			if ( itemClass != null ) {
				item = new itemClass();				
			} else {
				item = {};
			}
			
            for (var i:int = 0; i < _columns.length; i++) {
                var colName:String = ColumnObject(_columns[i]).name;
                item[colName] = xml[colName][0];
            }
            
            return item;
			
		}
		
		//
		// Itelator Methods
		//
		
		/**
		 * 次の要素があるかどうか
		 */
		public function hasNext():Boolean
		{
			return (_index < _items.length);
		}
		
		/**
		 * 次の要素を取り出す
		 * @return 次の要素
		 */
		public function getNext():*
		{
			return _items[_index++];
		}
		
		/**
		 * インデックスを指定してアイテムを取り出す
		 * インデックスも同時に移動する
		 * @param index インデックス
		 * @return アイテム
		 */
		public function getItemAt(index:uint):*
		{
			if (index < _items.length) {
				_index = index;
				return _items[index];
			} else {
				throw new IllegalOperationError("指定のインデックスが範囲外です");
			}
		}
		
		/**
		 * インデックスを移動する
		 * moveIndex()とすると先頭に戻すことが出来る
		 */
		public function moveIndex(index:int = 0):void
		{
			if (index < _items.length) {
				// インデックスが範囲内の場合そのまま
				_index = index;
			} else {
				// 範囲外のインデックスの場合最後尾に移動する
				_index = _items.length - 1;
				
			}			
		}
		
		//
		// IUpdateMethods
		//
		private var updateFlag : Boolean = false;
		
		private var myTable:SQLTableSchema;

		/**
		 * カラムが作成されていないColumnObjectの配列
		 */
		private var notExistsColumns:Array;
		
		/**
		 * INDEXが作成されていないColumnObjectの配列
		 */
		private var notExistsIndices:Array;
		
		/**
		 * アップデートの準備を行う
		 * @event Event.COMPLETE 準備完了
		 */
		public function updatePrepare():void
		{
			myTable = dbObject.getTableSchema(tableName);
			var myIndices:Array = dbObject.getIndicesAtTable(tableName);
			
			var notExistsColumnFilter:Function = function(element:*, index:int, arr:Array):Boolean
			{				
				for (var i:int = 0; i < myTable.columns.length; i++) {
					if (ColumnObject(element).name == SQLColumnSchema(myTable.columns[i]).name) {
						return false;
					}
				}
				return true;
			}
			
			var notExistsIndexFilter:Function = function(element:*, index:int, arr:Array):Boolean
			{
				for (var i:int = 0; i < myIndices.length; i++) {
					if (ColumnObject(element).indexName == SQLIndexSchema(myIndices[i]).name) {
						return false;
					}
				}
				return true;
			}
			
			if (myTable == null) {
				updateFlag = true;
				notExistsColumns = [];
				notExistsIndices = _columns.concat();
				dispatchEvent(new Event(Event.COMPLETE));
				return;
			}
			
			// 未定義のカラムスタック
			notExistsColumns = _columns.filter(notExistsColumnFilter);
			
			// 未定義のインデックススタック
			notExistsIndices = _columns.filter(notExistsIndexFilter);
	
	
			if (notExistsColumns.length > 0
			    || notExistsIndices.length > 0) {
				updateFlag = true;
			}
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/**
		 * UPDATE処理があるかどうか 
		 * @return 
		 */
		public function hasUpdate():Boolean
		{
			return updateFlag;
		}

		/**
		 * Updateの実行
		 * @eventType Event.COMPLETE 同期、非同期に関わらずexecuteによって行われる処理の終了時にEvent.Completeイベントを発行してください。
		 */
		public function execUpdate():void
		{
			if (!updateFlag) {
				// 何かの間違いで実行された場合
				dispatchEvent(new Event(Event.COMPLETE));
				return;
			}
			
			// SerialCommandキューにコマンドを格納する
			// Createには順番があるのでPararelとかAsyncは禁止
			var seriArr:Array = [];
			if (myTable == null) {
				// まずCreateTable;
				seriArr.push(getCreateTableCommand());
			}
			
			var col:ColumnObject;
			
			while (notExistsColumns.length > 0) {
				// 次にAlter Table
				col = notExistsColumns.shift() as ColumnObject;
				seriArr.push( buildCommand(col.buildAddColum(tableName),-1) );
			}
			
			while (notExistsIndices.length > 0) {
				col = notExistsIndices.shift() as ColumnObject;
				var sqlParam:Object = col.buildCreateIndex(tableName);
				if (sqlParam != null) {
					seriArr.push( buildCommand(sqlParam, -1) );
				}
			}
			
			var command:SerialCommand = new SerialCommand(seriArr);
			
			command.addEventListener(Event.COMPLETE, execUpdate_completeHandler);
			
			command.execute();
		}
		
		private function execUpdate_completeHandler(event:Event):void
		{
			event.target.removeEventListener(Event.COMPLETE, execUpdate_completeHandler);
			updateFlag = false;
			myTable = null;
			notExistsColumns = null;
			notExistsIndices = null;
			dispatchEvent(new Event(Event.COMPLETE));
			
		}
		
		// 
		// protected methods
		//
		
		// build
		/**
		 * CREATE TABLE のSQL要素を作成し返す
		 * @return 
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * 
		 */
		protected function buildCreateTable():Object
		{
			// TABLEが無ければ作成
			var sql:String = "CREATE TABLE IF NOT EXISTS ";
			sql += this.tableName + "(";
			
			var col:ColumnObject;
		    var colsStr:String = "";
			for (var i:uint = 0; i < columns.length; i++) {
				col = columns[i] as ColumnObject;
				if (colsStr != "") {
					colsStr += ",";
				}
				colsStr += col.getColumnDef();
			}
			sql += colsStr + ")";
			
			return {sql:sql, paramaters:null};
		}
		
		/**
		 * DROP TABLE のSQL要素を作成し返す
		 * @return 
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * 
		 */
		protected function buildDropTable():Object
		{
			var sql:String = "DROP TABLE IF EXISTS " + tableName;
			return {sql:sql, paramaters:null};
		}
		
		/**
		 * テーブルからレコードを取得する自由なSELECT句を作成
		 * @param where WHERE句の条件を設定 {<column name>:<value>,,,}
		 * @param sort  ORDER条件 {column name>:TRUE-ASC/FALSE-DESC,,,}
		 * @param limit 取得件数
		 * @param offset オフセット
		 * @param custom カスタムパラメータWEHERにStringを使用したときにパラメータを設定する
		 * @return 
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * 
		 */
		protected function buildGetRecords(where:Object, sort:Object, 
									limit:Number = 0, offset:Number = 0, custom:Object=null):Object
		{
			var sql : String = "SELECT * FROM " + tableName; // SQL
			var paramaters:Object = {}; //プレースホルダーパラメータ
		
			Logger.putVardump(custom, "buildGetRecords::custom");
		
			// WHERE句作成
			var whereStr : String = "";
			if (where is String) {
				whereStr = " " + where;
				paramaters = custom;
			} else {
				for (var key:String in where) {
					if (whereStr == "") {
						whereStr += " WHERE ";
					} else {
						whereStr += " AND ";
					}
					whereStr += " " + key + " = :" + key;
					paramaters[":"+key] = where[key];
				}
			}
			
			// ORDER BY句作成
			var sortStr : String = "";
			if (sort != null) {
				for (var s_key:String in sort) {
					if (sortStr == "") {
						sortStr += " ORDER BY "
					} else {
						sortStr += " ,"
					}
					if (sort[s_key] === true || sort[s_key] == "ASC" || sort[s_key] == "asc" ) {
						sortStr += " " + s_key + " ASC";
					} else {
						sortStr += " " + s_key + " DESC";
					}
				}
			}
			var limitStr : String = "";
			
			if (limit > 0) {
				limitStr += " LIMIT " + limit + " OFFSET " + offset;
			}
			
			sql += whereStr + sortStr + limitStr;
			
			return {sql:sql, paramaters:paramaters};
		
		}
		
		
		/**
		 * キーからレコードを取得する SELECT句を作成
		 * @param id
		 * @return 
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * 
		 */
		protected function buildGetRecordById(id:*):Object
		{
			var sql : String = "SELECT * FROM " + tableName;
			var paramaters:Object = {};
			sql += " WHERE " + keyColumn + " = :"+ keyColumn;

			paramaters[":"+keyColumn] = id;
			
			return {sql:sql, paramaters:paramaters};
		}

		/**
		 * INSERT SQLオブジェクトを作成
		 * @param item 挿入するアイテムオブジェクト
		 * @return 
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * 
		 */
		protected function buildInsert(item:*):Object
		{
			var sql : String = "INSERT INTO " + tableName;
			var paramaters:Object = {};
			
			var col_str : String = "";
			var value_str : String = "";
			var	col:ColumnObject;
			
			for (var i:int = 0; i < columns.length; i++) {
				col = columns[i] as ColumnObject;
				if (item.hasOwnProperty(col.name)) {
					if (col.autoIncrement) {
						// AUTOINCREMENTはINSERTしない
						continue;
					}
					if (col_str != "") {
						col_str += ", ";
						value_str += ", ";
					}
					col_str += col.name;
					value_str += ":" + col.name;
					paramaters[":" + col.name] = item[col.name];
				}
			}
			sql += "("+col_str+") VALUES ("+value_str+")";
			
			return {sql:sql, paramaters:paramaters};
		}
		
		/**
		 * UPDATE SQLオブジェクトを作成
		 * @param item 更新するアイテムオブジェクト
		 * @return 
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * 
		 */
		protected function buildUpdate(item:*):Object
		{
			var sql : String = "UPDATE " + tableName;
			var paramaters:Object = {};
			
			var col_str : String = "";
			//var value_str : String = "";
			var	col:ColumnObject;
			
			for (var i:int = 0; i < columns.length; i++) {
				col = columns[i] as ColumnObject;
				//Logger.debug(col.name);
				if (item.hasOwnProperty(col.name)) {
					if (col.autoIncrement) {
						// AUTOINCREMENTはUPDATEしない
						continue;
					}
					if (col.notnull && item[col.name] == null) {
						continue;
					}
					if (col_str != "") {
						col_str += ", ";
					}
					col_str += col.name + " = :" + col.name;
					//value_str += ":" + col.name;
					paramaters[":" + col.name] = item[col.name];
				}
			}
			sql += " SET "+col_str+" WHERE "+keyColumn+" = :" + keyColumn;
			paramaters[":" + keyColumn] = item[keyColumn];			
			
			//Logger.putVerdump(paramaters);
			
			return {sql:sql, paramaters:paramaters};
		}
		
		/**
		 * DELETE SQLオブジェクトを作成
		 * @param item 削除するアイテムオブジェクト
		 * @return 
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * 
		 */
		protected function buildRecordDelete(item:*):Object
		{
			var sql : String = "DELETE FROM " + tableName;
			var paramaters:Object = {};
			sql += " WHERE "+keyColumn+" = :" + keyColumn;
			paramaters[":" + keyColumn] = item[keyColumn];			
			
			return {sql:sql, paramaters:paramaters};
		}
		
		// テーブル&インデックスの存在確認を行う
		/**
		 * テーブルがDBに存在するかどうか
		 * 同期処理
		 */
		protected function checkTableExists():Boolean
		{
			return false;
		}
		
		/**
		 * 全てのレコードが存在するかどうか
		 */
		protected function checkAllColumnExsists():Boolean
		{
			return false;
		}
		
		
		/**
		 * SQL実行コマンドを返す
		 * @param sqlObj
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * @param prefetch    prefetchを使用する場合はセットする
		 * @param async       非同期処理を行うか
		 * @param closure     処理終了時に実行するFunction
		 * @return SQLExecuteCommand
		 * 
		 */
		protected function buildCommand(sqlObj:Object, prefetch:int = -1, async:Boolean = true, closure:Function = null):ICommand
		{
			Logger.putVardump(sqlObj, "TableObj::buildCommand::sqlParam");
			
			if (sqlObj == null) {
				return new NullCommand();
			}
			
			// コマンドパラメータの設定
			var execParam:Object = {};
			
			execParam.sql        = sqlObj.sql;
			execParam.paramators = sqlObj.paramaters;
			execParam.connection = sqlConnection;
			execParam.async      = async;
			execParam.prefetch   = prefetch;
			execParam.database   = database;
			execParam.itemClass  = itemClass;
			
			if (closure != null) {
				_closure = closure;
			} else {
				_closure = sqlResultHandler;
 			}

			var execCmd:ICommand = new SQLExecuteCommand(execParam);

 			execCmd.addEventListener(SQLResultEvent.SQL_COMPLETE, _closure);
 			execCmd.addEventListener(SQLResultEvent.SQL_ON_THE_WAY, _closure);
			execCmd.addEventListener(SQLErrorEvent.ERROR, sqlErrorHandler);
			/*
			execCmd.addEventListener(ErrorEvent.ERROR, function(e:ErrorEvent):void
			{
				e.target.removeEventListener(e.type,arguments.callee);
			});
			*/
			
			//Logger.putVerdump(execParam);
			
			
			return execCmd;
			
		}
		
		// execute
		/**
		 * SQLを実行する 
		 * @param sqlObj
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * @param prefetch    prefetchを使用する場合はセットする
		 * @param async       非同期処理を行うか
		 * @param closure     処理終了時に実行するFunction
		 * 
		 */
		protected function exec(sqlObj:Object, prefetch:int = -1, async:Boolean = true, closure:Function = null):void
		{
			// コマンドの発行
			buildCommand(sqlObj,prefetch,async,closure).execute();
		}
		
		//
		// private methods
		//
		
		//
		//  コマンドハンドラ
		//
		
		/**
		 * デフォルトのSQL成功時ハンドラ 
		 * @param event
		 * 
		 */
		private function sqlResultHandler(event:SQLResultEvent):void
		{
			switch (event.sqlType) {
				case "SELECT":
					// アイテムを更新する
					if (event.result != null) {
						if (_refresh) {
							_items = new ArrayCollection();
							_index = 0;
						}
						_refresh = false;
						if (event.result.data == null) {
							break;
						}
						var numRows:int = event.result.data.length;
						for (var i:int = 0; i < numRows; i++) {
							setItem(event.result.data[i]);
						}
					}
					break;
				case "INSERT":
					// キーをセット
					_items[controlIndex][keyColumn] = event.result.lastInsertRowID;
					controlIndex = 0;
					break;
				case "UPDATE":
					// 特に何もしない
					break;
				case "DELETE":
					// itemsからデータを削除する
					if (event.result.rowsAffected == 1) {
						_items.removeItemAt(controlIndex);
					}
					break;
				default:
			}
			
			// 処理が終了していたらイベントリスナーを削除する
			if (event.type == SQLResultEvent.SQL_COMPLETE) {
				if (event.target is SQLExecuteCommand) {
					event.target.removeEventListener(SQLResultEvent.SQL_COMPLETE, _closure);
					event.target.removeEventListener(SQLResultEvent.SQL_ON_THE_WAY, _closure);
					event.target.removeEventListener(SQLErrorEvent.ERROR, sqlErrorHandler);
				}
				dispatchEvent(new Event(SQL_COMPLETE));
			} else {
				dispatchEvent(new Event(SQL_GET_RECORDS));
			}
			
		}
		
		/**
		 * SQLエラーハンドラー
		 */
		private function sqlErrorHandler(event:SQLErrorEvent):void
		{
			if (event.target is SQLExecuteCommand) {
				event.target.removeEventListener(SQLResultEvent.SQL_COMPLETE, _closure);
				event.target.removeEventListener(SQLResultEvent.SQL_ON_THE_WAY, _closure);
				event.target.removeEventListener(SQLErrorEvent.ERROR, sqlErrorHandler);
				
			}
			
			Logger.error("[SQL ERROR] DETAIL::" + event.error.details + 
							" OPERATION::" + event.error.operation);
			
			// Dispacheしません			
			//dispatchEvent(new Event(SQL_ERROR));
		}


	}
}