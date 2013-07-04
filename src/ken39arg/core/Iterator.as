package ken39arg.core
{
	public interface Iterator
	{
		/**
		 * 次の要素があるかどうか
		 */
		function hasNext():Boolean;
		
		/**
		 * 次の要素を取り出す
		 * @return 次の要素
		 */
		function getNext():*;
		
		/**
		 * インデックスを指定してアイテムを取り出す
		 * @param index インデックス
		 * @return アイテム
		 */
		function getItemAt(index:uint):*;
	}
}