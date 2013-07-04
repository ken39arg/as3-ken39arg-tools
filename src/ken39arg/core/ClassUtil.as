package ken39arg.core
{
    /**
     * クラスのインスタンスを取得する 
     * @author araga
     */
    public class ClassUtil {
        
        private static const CLASS_NAME_SEPARATOR:String = "::";
        
        private static const DOT:String = ".";
        
        /**
         * クラスのインスタンスを取得する
         * @param className
         * @return インスタンス
         * 
         */
        public static function newInstance( className:String ):Object{
            var clazzName:String = className.replace( CLASS_NAME_SEPARATOR, DOT);
            var clazz:Class = ClassLoader.getClass(clazzName);
            return new clazz();
        }
    }
}