package mmo.shoot
{
   import flash.display.DisplayObject;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.loader.scheduler.ResScheduler;
   
   public class ShootCardViewCreator
   {
      
      private static const viewPrefix:String = "mmo.shoot.cards.Card";
      
      private static const viewUrl:String = "shoot/cardview";
      
      private var id:int;
      
      private var callback:Function;
      
      private var thisObject:*;
      
      public function ShootCardViewCreator()
      {
         super();
      }
      
      public function getView(param1:int, param2:Function = null, param3:* = null) : DisplayObject
      {
         this.id = param1;
         this.callback = param2;
         this.thisObject = param3;
         var _loc4_:DisplayObject = this.createView(param1);
         if(_loc4_ != null)
         {
            this.onGetView(_loc4_);
            return _loc4_;
         }
         var _loc5_:String = viewUrl;
         ResScheduler.getResource(_loc5_,this.onGetViewRes);
         return null;
      }
      
      private function onGetViewRes(param1:*) : *
      {
         this.onGetView(this.createView(this.id));
      }
      
      private function getClassName(param1:int) : String
      {
         return viewPrefix + param1;
      }
      
      private function createView(param1:int) : DisplayObject
      {
         var _loc2_:String = this.getClassName(param1);
         if(!ApplicationDomain.currentDomain.hasDefinition(_loc2_))
         {
            return null;
         }
         var _loc3_:Class = getDefinitionByName(_loc2_) as Class;
         return DisplayObject(new _loc3_());
      }
      
      private function onGetView(param1:DisplayObject) : void
      {
         this.callback.apply(this.thisObject,[param1]);
      }
   }
}

