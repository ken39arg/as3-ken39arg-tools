package ken39arg.util
{
	import com.adobe.crypto.SHA1;
	
	import mx.formatters.DateFormatter;
	import mx.utils.Base64Encoder;
	import mx.utils.StringUtil;
	
	/**
	 * よく使う処理をまとめたユーティリティ. 
	 * 
	 * 全てのメソッドはstatic function にして下さい
	 * 
	 * @access    public
	 * @package   ken39arg.util
	 * @author    K.Araga
	 * @varsion   $id : KAUtil.as, v 1.0 2008/02/15 K.Araga Exp $
	 */
	public class KAUtil
	{
		private static var _dateFormatter : DateFormatter;
		
		private static function get dateFormatter():DateFormatter
		{
			if (_dateFormatter == null) {
				_dateFormatter = new DateFormatter();
			}
			return _dateFormatter;
		}
		
		/**
		 * 日付をフォーマットする
		 * @param date フォーマットする日付　デフォルトは現在時間
		 * @param format フォーマットパターン　デフォルトは"YYYYMMDDHHNNSS"
		 * @return フォーマットされた日付
		 * 
		 */
		public static function getDateString(date:Date = null,format:String = "YYYYMMDDHHNNSS"):String
		{
			if (date == null) {
				date = new Date();
			}
			
			dateFormatter.formatString = format;
			return dateFormatter.format(date);
		}
		
		/**
		 * 秒数をいい感じに時間文字列にする 
		 * @param sec 秒
		 * @param separator 区切り文字
		 * @return いい感じになった時間文字列
		 * 
		 */
		public static function secondsToMinStr(sec:Number, hour:Boolean = false, separator:String = ":"):String
		{
			var mim : String;
			var flag : String = "";
			if (sec < 0) {
				flag = "-";
				sec = Math.abs(sec);
			}
			
			if (hour || sec >= 3600) {
				var minNum : Number = Math.floor(sec / 60);
				mim = zeroPadding(Math.floor(minNum / 60), 2) + separator + zeroPadding(Math.floor(minNum % 60), 2);
			} else {
				mim = zeroPadding(Math.floor(sec / 60), 2);
			}
			
			var local_sec : String = zeroPadding(Math.floor(sec % 60), 2);
			
			return mim + separator + local_sec;
		}
		
		/**
		 *　改行コードを任意の文字列に置換する 
		 * @param str  変換対象の文字列
		 * @param hoge 改行コードの代わりに代入する文字列
		 * @return 変換後の文字列
		 * 
		 */
		public static function nl2hoge(str:String, hoge:String = " "):String
		{
			if (str == null) {
				return "";
			}
			//const CR:String = String.fromCharCode(0x08);
			//const LF:String = String.fromCharCode(0x02);
			const CR:String = "\n";
			const LF:String = "\r";
			str = replaceAll(str, CR+LF, hoge);
			str = replaceAll(str, CR, hoge);
			str = replaceAll(str, LF, hoge);
			return str;
		}
		
		/**
		 * 検索パターンに一致する全ての文字を一括置換する 
		 * @param str     変換対象の文字列
		 * @param pattern 検索パターン
		 * @param repl    変換する文字列
		 * @return  変換後の文字列
		 * 
		 */
		public static function replaceAll(str:String, pattern:*, repl:*):String
		{
			//var ret : String = "";
			if (str == null) {
				return "";
			}
			
			while (str.search(pattern) >= 0) {
				//str = ret;
				str = str.replace(pattern, repl);
			}
			return str;
		}
		
		/**
		 * ゼロパディングする
		 * number の桁数が sizeより大きいと何もしません 
		 * @param number 対象数値
		 * @param size   変換後の桁数
		 * @return ゼロパディングした文字列
		 * 
		 */
		public static function zeroPadding(number:Number, size:uint):String
		{
			var str:String = number.toString(10);
			while (str.length < size) {
				str = "0" + str;
			}
			return str;
		}
		
		/**
		 * 空文字、NULL以外の値がセットされているかどうかを調べます
		 * StringUtil#isWhitespaceとは戻りが逆なので注意
		 * @param character 照合対象のString
		 * @return 空文字、NULL以外の値が入力されていれば、true
		 * 
		 */
		public static function isInput(character:String):Boolean
		{
			if (character == null ) {
				return false;
			}
			if (character.length > 0) {
				return !StringUtil.isWhitespace(character);
				
			}
			return false;
		}
		
		
		/**
		 * 最大文字数を超える文字列をカットして、カットした場合は末尾に指定の文字列を追加する 
		 * @param string 元の文字列
		 * @param length 最大文字数
		 * @param tail   最大文字数を超えた場合に末尾に追加する文字列  default="..."
		 * @return 変換後の文字列
		 * 
		 */
		public static function cutString(string:String, length:int, tail:String = "..."):String
		{
			if (string.length <= length) {
				// 文字数が超過していない場合は、そのまま返す
				return string;
			}
			var ret:String;
			ret = string.substr(0, length);
			return ret + tail;
		}
		
		/**
		 * oneのオブジェクトの値がtwoのオブジェクトが持っている値と同じかどうか調べる. 
		 * twoに無い値は比較対照になりません 
		 * @param one
		 * @param two
		 * @return 異なるパラメータ名を持つ配列
		 */
		public static function checkDifferObject(one:Object, two:Object):Array
		{
			var ret:Array = [];
			for (var prop:String in one) {
				if (two.hasOwnProperty(prop) && one[prop] != two[prop]) {
					ret.push(prop);
				}
			}
			return ret;
		}
		
		
		/**
		 * WSSE認証用のパスワードダイジェスト周りの諸々を作成する
		 * @param password
		 * @return Object
		 * passwordDigest:***
		 * nonce:***
		 * created:***
		 * 
		 */
		public static function createPasswordDigestForWSSE(password:String):Object
		{
			var created:String = generateTimestamp(null);
			var nonce:String = base64Encode(generateNonce());
			var password64:String = getBase64Digest(nonce,created,password);
			
			return {created:created, nonce:nonce, passwordDigest:password64};
			
		}
		
		//
		// 以下,corelibからinternalを拝借
		//
		
		private static function generateNonce():String
		{
			// Math.random returns a Number between 0 and 1.  We don't want our
			// nonce to contain invalid characters (e.g. the period) so we
			// strip them out before returning the result.
			var s:String =  Math.random().toString();
			return s.replace(".", "");
		}
		
		/**
		 *　base64エンコードをする 
		 * @param s 文字列
		 * @return  エンコード後の文字列
		 * 
		 */
		public static function base64Encode(s:String):String
		{
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encode(s);
			return encoder.flush();
		}
		
		private static function generateTimestamp(timestamp:Date):String
		{
			if (timestamp == null)
			{
				timestamp = new Date();
			}
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = "YYYY-MM-DDTJJ:NN:SS"
			return dateFormatter.format(timestamp) + "Z";
		}
		
		private static function getBase64Digest(nonce:String, created:String, password:String):String
		{
			return SHA1.hashToBase64(nonce + created + password);
		}
	}
}