package mmo.fbteam.fbsiwude.sceneplayer.common
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import mmo.fbteam.configure.FBConfig;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   
   public class ArrowHelper
   {
      
      private static const arrowRes:String = "fbteam/fbsiwude_res";
      
      private static const lClassName:String = "mmo.scene.fbsiwude.ShowArrowhead_L";
      
      private static const rClassName:String = "mmo.scene.fbsiwude.ShowArrowhead_R";
      
      public function ArrowHelper()
      {
         super();
      }
      
      public static function getArrowhead(param1:Number, param2:Boolean = true) : Sprite
      {
         var rs:Sprite = null;
         var cls:Class = null;
         var rotation:Number = param1;
         var isR:Boolean = param2;
         rs = new Sprite();
         var clsName:String = isR ? rClassName : lClassName;
         rs.rotation = rotation;
         if(!FBConfig.instence.getSceneApplicationDomain().hasDefinition(clsName))
         {
            ResScheduler.getResource(arrowRes,function(param1:DisplayObject):void
            {
               if(rs.root != null)
               {
                  rs.addChild(param1);
               }
            },clsName,null,null,ResPriority.NORMAL,true,FBConfig.instence.getSceneApplicationDomain());
         }
         else
         {
            cls = FBConfig.instence.getClass(clsName) as Class;
            rs.addChild(new cls());
         }
         return rs;
      }
   }
}

