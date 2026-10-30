package mmo.shoot.client
{
   import mmo.framework.comm.SocketClient;
   
   public class ShootClient
   {
      
      public static const instance:ShootClient = new ShootClient();
      
      private static const extensionName:* = "ShootExtension";
      
      public static const onFire:* = "64_1";
      
      public static const onBump:* = "64_2";
      
      public static const onTargetValidate:* = "64_3";
      
      public static const onGetMyCards:* = "64_5";
      
      public static const setReplaceEffect:String = "64_6";
      
      public static const cancelReplaceEffect:String = "64_7";
      
      public function ShootClient()
      {
         super();
      }
      
      public function getMyCards() : void
      {
         this.sendXtMessage(onGetMyCards,{});
      }
      
      public function fire(param1:int, param2:String, param3:int, param4:int, param5:int, param6:Object = null, param7:Object = null) : void
      {
         this.sendXtMessage(onFire,{
            "cardId":param1,
            "target":param2,
            "targetType":param3,
            "x":param4,
            "y":param5,
            "mine":param6
         });
      }
      
      public function sendHitValidateResult(param1:Boolean, param2:int, param3:String, param4:Object = null) : void
      {
         this.sendXtMessage(onTargetValidate,{
            "targetType":param2,
            "hit":param1,
            "key":param3
         });
      }
      
      public function setReplaceEffectById(param1:int, param2:Object = null) : void
      {
         this.sendXtMessage(setReplaceEffect,{"id":param1});
      }
      
      public function cancelReplaceEffectById(param1:int, param2:Object = null) : void
      {
         this.sendXtMessage(cancelReplaceEffect,{"id":param1},param2);
      }
      
      private function sendXtMessage(param1:String, param2:Object, param3:Object = null) : *
      {
         SocketClient.instance.sendXtMessage(extensionName,param1,param2);
      }
   }
}

