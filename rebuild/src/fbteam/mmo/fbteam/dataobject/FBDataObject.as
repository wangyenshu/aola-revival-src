package mmo.fbteam.dataobject
{
   public class FBDataObject
   {
      
      public var fbId:int = -1;
      
      public var fbName:String = "";
      
      public var fbLevel:int = -1;
      
      public var sceneNum:int = 1;
      
      public var param:Object = null;
      
      public function FBDataObject()
      {
         super();
      }
      
      public function reset() : void
      {
         this.fbId = -1;
         this.fbName = "";
         this.fbLevel = -1;
         this.sceneNum = 1;
      }
      
      public function toObject() : Object
      {
         return {
            "fbId":this.fbId,
            "fbName":this.fbName,
            "fbLevel":this.fbLevel,
            "sceneNum":this.sceneNum
         };
      }
      
      public function setPar(param1:Object) : void
      {
         this.fbId = param1.fbId;
         this.fbName = param1.fbName;
         this.fbLevel = param1.fbLevel;
         this.sceneNum = param1.sceneNum;
      }
      
      public function toString() : String
      {
         return "[FBDataObject]" + "(" + "fbId:" + this.fbId + " fbName:" + this.fbName + " fbLevel:" + this.fbLevel + " sceneNum:" + this.sceneNum + ")";
      }
   }
}

