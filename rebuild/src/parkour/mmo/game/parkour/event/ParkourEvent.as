package mmo.game.parkour.event
{
   import flash.events.Event;
   
   public class ParkourEvent extends Event
   {
      
      public static const AVATAR_LOAD_COMPLETED:String = "avatar_load_completed";
      
      public var param:Object;
      
      public function ParkourEvent(param1:String, param2:Object = null, param3:Boolean = false, param4:Boolean = false)
      {
         super(param1,param3,param4);
         this.param = param2;
      }
   }
}

