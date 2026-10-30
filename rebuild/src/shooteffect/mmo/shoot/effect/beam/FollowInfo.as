package mmo.shoot.effect.beam
{
   public class FollowInfo
   {
      
      public var x:Number;
      
      public var y:Number;
      
      public var rotation:Number;
      
      public var visible:Boolean;
      
      public function FollowInfo(param1:Number, param2:Number, param3:Number, param4:Boolean)
      {
         super();
         this.x = param1;
         this.y = param2;
         this.rotation = param3;
         this.visible = param4;
      }
   }
}

