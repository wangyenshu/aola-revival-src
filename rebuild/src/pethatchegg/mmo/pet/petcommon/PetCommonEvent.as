package mmo.pet.petcommon
{
   import flash.events.Event;
   
   public class PetCommonEvent extends Event
   {
      
      public static const PETHATCHMESSAGE:String = "PetHatchMessage";
      
      public static const PETXINPIANMESSAGE:String = "PetXinPianMessage";
      
      public var params:Object;
      
      public function PetCommonEvent(param1:String, param2:Object)
      {
         super(param1);
         this.params = param2;
      }
   }
}

