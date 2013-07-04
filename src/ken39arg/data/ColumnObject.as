package ken39arg.data
{
	import ken39arg.core.ClassLoader;
	import ken39arg.util.KAUtil;
	
	
	/**
	 * ColumnObject
	 * 
	 * テーブルのカラムを定義している
	 * 型ごとにクラスを分けたほうがExcerentだが時間が無いので1クラスにまとめた
	 * 
	 * @access    public
	 * @package   ken39arg.data
	 * @author    K.Araga
	 * @varsion   $id : ColumnObject.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class ColumnObject
	{	
		/** カラム名 */
		public var name : String;
		
		/** 表示名 */
		public var label : String;
		
		/** 入力フォーム */
		public var formClass : Class;
		
		//
		// type
		//
		
		/* SQLiteより広めのタイプ属性 */
		private var _type : String = "TEXT";
		
		/* SQLiteにインサートするタイプ属性 */
		private var colType : String  = "TEXT"

		/**
		 * データ型
		 * Integerの場合は値はNumber,int,uintのいずれかである必要があります。
		 * TEXTはString型以外はtoStringが使用されます。
		 * DATEの場合はこのクラスを使用する限り内部でDate型を使用しますが、DBにはTEXT型のYYYY/MM/DD HH:II:SSで登録されます
		 * BLOB型の場合特に自動変換は行わないので、自力で変換してください
		 */
		public function get type():String
		{
			return _type;
		}
		
		public function set type(value:String):void
		{
		    switch (value) {
		    	case "INTEGER":
		    	case "integer":
		    	case "Integer":
		    		_type = "INTEGER";
		    		colType = "INTEGER";
		    	break;
		    	
		    	case "BLOB":
		    	case "blob":
		    	case "Blob":
		    		_type = "BLOB";
		    		colType = "BLOB";
		    	break;
		    		
		    	case "Date":
		    	case "DATE":
		    	case "date":
		    		_type = "DATE";
		    		colType = "TEXT";
		    	break;

		    	default:
		    		_type = "TEXT";
		    		colType = "TEXT";
		    	break;
		    }
		}
		
		/**
		 * NOT NULLかどうか
		 */
		public var notnull : Boolean = false;
		
		/**
		 * DEFAULT値を設定するかどうか
		 */
		public var defaultData : * = null;

		/**
		 * 主キーかどうか
		 */
		public var primaryKey : Boolean = false;
		
		/**
		 * AUTOINCREMENTかどうか
		 */
		public var autoIncrement : Boolean = false;
		
		/**
		 * INDEXを生成するかどうか
		 */
		public var index : Boolean = false;
		
		/**
		 * ユニークかどうか
		 */
		public var uniq:Boolean = false;
		
		public var tableName:String;
		
		/**
		 * Option
		 * 入力オプションが存在する場合は配列に格納する
		 * 必須指定項目:data=<DBに格納する値> label=<名称>
		 */
		public var options:Array;
		
		//
		// definitionXML
		//
		
		private var _definitionXML : XML;
		
		public function get definitionXML() : XML
		{
			return _definitionXML;
		}
		
		/**
		 * カラム定義XML
		 * 
		 * カラム単位で定義する
		 *  +- column
		 *   @- name          : カラム名
		 *   @- label         : 表示名
		 *   @- formClass     : 入力フォームで使用するクラス名
		 *   @- type          : TEXT/INTEGER/BLOB (DATA::自動変換対応予定)Default=TEXT
		 *   @- notnull       : TRUE/FALSE Default=false
		 *   @- default       : デフォルト値
		 *   @- autoIncrement : AUTOINCREMENTかどうか Default=false
		 *   @- index         : インデックスを生成するかDefault=false
		 *   @- uniq          : ユニークかどうか
		 *     +- options         : オプション情報
		 *       +-option           :オプション要素
		 *         @- data            : 値
		 *         @- label            : 表示ラベル
		 */ 
		public function set definitionXML(value:XML) : void
		{
			if (_definitionXML === value) {
				return;
			}
			
			name          = value.@name;
			label         = value.@label;
			formClass     = ( !KAUtil.isInput( value.@formClass ) ) ? null : ClassLoader.getClass(value.@formClass);
			type          = value.@type;
			notnull       = ( !KAUtil.isInput( value.@notnull ) )? false : value.@notnull as Boolean;
			autoIncrement = ( !KAUtil.isInput( value.@autoIncrement) )? false : value.@autoIncrement as Boolean;
			index         = ( !KAUtil.isInput( value.@index ) )? false : value.@index as Boolean;
			uniq          = ( !KAUtil.isInput( value.@uniq ) )? false : value.@uniq as Boolean;
			
			// オプションのセット
			
			if (value.options == null || value.options.option.length() == 0) {
				options = null;
			} else {
				options = [];
				for each (var t_xml:XML in value.options.option) {
					options.push({data:String(t_xml.@data), label:String(t_xml.@label)});
				}
			}		
		}

		public function get indexName():String
		{
			if (primaryKey || !index) {
				return null;
			}
			return tableName + "_idx_" + name;
		}

		/**
		 * コンストラクタ
		 * 
		 * @param primaryKey    プライマリーキーかどうか
		 * @param definitionXML 定義XML
		 * @param index       インデックスを生成するか
		 * @param uniq        ユニークかどうか
		 * @param options     入力オプション
		 */
		public function ColumnObject(isPrymaryKey:Boolean = false, definitionXML:XML = null)
		{
			this.primaryKey = isPrymaryKey;
			this.definitionXML = definitionXML;
		}
		
		/**
		 * CLEATE TABLE 文のcolumn-defを作成する 
		 * @return SQL文のカラム定義部
		 * 
		 */
		public function getColumnDef():String
		{
			var ret:String = name + " " + colType;
			if (notnull) {
				ret += " NOT NULL";
			}
			if (primaryKey) {
				ret += " PRIMARY KEY";
			}
			if (autoIncrement) {
				ret += " AUTOINCREMENT";
			}
			
			if (defaultData != null) {
				ret += " DEFAULT ";
				if (colType != "INTEGER") {
					ret += "'" + defaultData + "'";
				} else {
					ret += defaultData;
				}
			}
			
			return ret;
		}
		
		/**
		 * CREATE INDEX文を生成する
		 * @param tableName
		 * @return 
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * 
		 */
		public function buildCreateIndex(tableName:String):Object
		{
			if (primaryKey || !index) {
				return null;
			}
			
			var ret:String = "CLEATE";
			if (uniq) {
				ret += " UNIQUE";
			}
			ret += " INDEX IF NOT EXISTS " + indexName;
			ret += " ON " + tableName + "(" + name + ")";
			return {sql:ret,paramaters:null};
		}
		
		/**
		 * カラム追加SQL文を生成する
		 * @param tableName
		 * @return 
		 *   - sql : SQL文
		 *   - paramaters : プレースホルダーパラメーター
		 * 
		 */
		public function buildAddColum(tableName:String):Object
		{
			var ret:String = "ALTER TABLE " + tableName + " ADD ";
			ret += getColumnDef();
			return {sql:ret,paramaters:null};
		}
		
		/**
		 * カラムの入力値のバリデートを行う
		 * カスタムバリデートを行いたい場合はサブクラスを作成するなり
		 * その部分を外に出すなりして工夫してください
		 * 
		 * ただし、処理速度には自信が無いのでValidatorを普通に実行することをオススメする
		 * 
		 * @param value 入力値
		 * @return {status:Boolean, message:String}
		 * 
		 */
		public function validate(value:*):Object
		{
			var ret : Boolean = true;
			var message : String = "";

			// 必須チェック
			if (notnull && defaultData == null) {
				// not nullかつデフォルト値が無い場合
				if (value == null || value == "") {
					ret = false;
					message = "値が入力されていません";
				}
			} else if (primaryKey && !autoIncrement) {
				// 主キーだがAUTOINCREMENTではない場合
				if (value == null || value == "") {
					ret = false;
					message = "値が入力されていません";
				}
			}
			
			// 型のチェック
			switch (_type) {
				case "INTEGER":
					if (value is Number
						|| value is int
						|| value is uint) {
						// 数値型の場合はOK
						ret = true;
						
					} else if (value is String) {
						// 文字列の場合数値のみかどうか
						try {
							// 型変換の可否で確認する
							value = Number(value);
						} catch (e:Error) {
							ret = false;
							message = "数値以外が入力されています";
						}
						/*
						var regExp : RegExp = new RegExp("/^[0-9]+$/","i");
						ret = regExp.test(String(value));
						if (!ret) {
							message = "数値以外が入力されています";
							
						}
						*/
						
					} else {
						ret = false;
						message = "数値以外が入力されています";
					}
				break;
				case "DATE":
					// Date型は何でも可にしておく
					/*
					if (value is Date) {
						ret = true;
					}
					*/
				break;
				case "TEXT":
				case "BLOB":
					// TEXTとBLOBはチェックしない
					ret = true;
				break;
				
			}
			
			if (!ret) {
				return {status:ret, message:message};
			}
			
			// Optionチェック
			if (options != null && options.length > 0) {
				ret = false;
				for (var i:int = 0; i < options.length; i++) {
					if (options[i]["data"] == value) {
						ret = true;
						break;
					}
				}
			}
			
			if (!ret) {
				message = "範囲外の値が入力されています";
				return {status:ret, message:message};
			}
			
			return {status:ret, message:message};
		}
		
		/**
		 * オプションを返します
		 * @param data
		 * @return 
		 * 
		 */
		public function getOptionItem(data:*):Object
		{
			for (var i:int = 0; i < options.length; i++) {
				if (options[i].data == data) {
					return options[i]
				}
			}
			return null;
		}
		
		/**
		 * データの型をDB入力に対応して変換する
		 * 現状はDate型以外は変更しません
		 * @param value 元の値
		 * @return 変換後の値
		 * 
		 */
		public function convertToDB(value:*):*
		{
			if (_type == "DATE") {
				var ret : String;
				var date : Date = value as Date;
				if (date != null) {
					// Date型を文字列に変換する
					ret = date.getFullYear() + "-" + 
						  KAUtil.zeroPadding(date.getMonth() + 1, 2) + "-" +
						  KAUtil.zeroPadding(date.getDate(), 2) + " " +
						  KAUtil.zeroPadding(date.getHours(), 2) + ":" +
						  KAUtil.zeroPadding(date.getMinutes(), 2) + ":" +
						  KAUtil.zeroPadding(date.getSeconds(), 2);
					return ret;
					
				} else {
					return value;
				}
			}
			return value;
		}
		
		/**
		 * データ型をDBの値からオブジェクトの型に変換する
		 * 現状はDate型以外は変更しません
		 * @param value 元の値
		 * @return 変換後の値
		 * 
		 */
		public function convertFromDB(value:*):*
		{
			if (_type == "DATE") {
				var val:String = value as String;
				var y:Number = Number(val.substr(0,  4));
				var m:Number = Number(val.substr(5,  2));
				var d:Number = Number(val.substr(8,  2));
				var h:Number = Number(val.substr(11, 2));
				var i:Number = Number(val.substr(14, 2));
				var s:Number = Number(val.substr(16, 2));
				return new Date(y,m,d,h,i,s);
			}
			return value;
		}
	}
}