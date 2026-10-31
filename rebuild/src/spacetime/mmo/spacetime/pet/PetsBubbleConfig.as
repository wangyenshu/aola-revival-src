package mmo.spacetime.pet
{
   import com.adobe.utils.ArrayUtil;
   import com.adobe.utils.NumberUtilities;
   import mmo.loader.ErrorThrower;
   
   public class PetsBubbleConfig
   {
      
      public static const appearSecond:Number = 4;
      
      public static const disappearSecond:Number = 2;
      
      private static const levelBubbles0:Array = ["来和我一较高下吧！","别犹豫了，来挑战我吧！","好想找个对手比试一下啊！"];
      
      private static const levelBubbles1:Array = ["我在等一个能打败我的对手！","手又痒了，快来让我打个痛快！","谁来实现我只求一败的理想！","我觉得我是无敌的，你别不信！","为你的亚比加满血，再来挑战我吧！","来，让我战到生命尽头！"];
      
      private static const levelBubbles2:Array = ["我强大到让自己害怕！你怕不怕我？","敢打败我，我就叫你好看！","打赢我，你才是真正的强！","盼星星，盼月亮，盼一个能打败我的人！","时间不停，战斗不止！"];
      
      private static const levelBubbles3:Array = ["时空如同战斗，永远都是无尽头的！","不重视对手的人，往往输得很惨！","我是一个战斗狂，每天都陶醉在战斗中不能自拔！","战斗是一门艺术，懂它的人才能赢！"];
      
      public function PetsBubbleConfig()
      {
         super();
      }
      
      public static function getBubbleArray(param1:int) : Array
      {
         if(param1 > 0 && param1 <= 10)
         {
            return getArrayRandomByCount(ArrayUtil.copyArray(levelBubbles0),1);
         }
         if(param1 > 10 && param1 <= 30)
         {
            return getArrayRandomByCount(ArrayUtil.copyArray(levelBubbles1),2);
         }
         if(param1 > 30 && param1 <= 40)
         {
            return getArrayRandomByCount(ArrayUtil.copyArray(levelBubbles2),2);
         }
         if(param1 > 40 && param1 <= 45)
         {
            return getArrayRandomByCount(ArrayUtil.copyArray(levelBubbles3),2);
         }
         ErrorThrower.throwError(new Error("未配置的冒泡!"));
         return null;
      }
      
      private static function getArrayRandomByCount(param1:Array, param2:int) : Array
      {
         var _loc6_:int = 0;
         if(null == param1)
         {
            return null;
         }
         var _loc3_:int = param2 > param1.length ? int(param1.length) : param2;
         var _loc4_:Array = [];
         var _loc5_:int = 0;
         while(_loc5_ < _loc3_)
         {
            _loc6_ = int(NumberUtilities.random(0,param1.length - 1));
            _loc4_.push(param1.splice(_loc6_,1)[0]);
            _loc5_++;
         }
         return _loc4_;
      }
   }
}

