package mmo.spacetime.number
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.geom.Matrix;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   
   public class SpacetimeNumberManager extends Sprite
   {
      
      private static var _instence:SpacetimeNumberManager = null;
      
      private static const NUM_WIDTH:Number = 31.4;
      
      private static const NUM_HEIGHT:Number = 40.5;
      
      private static const NUM_PREFIX:String = "mmo.spacetime.spacetimeNum";
      
      private static const FILE_NAME:String = "spacetime/spacetimenumber";
      
      private static const a:Number = 1;
      
      private static const b:Number = 0;
      
      private static const absC:Number = Math.tan(36 * Math.PI / 180);
      
      private static const d:Number = 1;
      
      private static const absTx:Number = 12.25;
      
      private static const ty:Number = 0;
      
      private static const SCALE_X:Number = 2;
      
      private static const SCALE_Y:Number = 2;
      
      private static const ALPHA_VAL:Number = 0.4;
      
      private static const ROTATE_NUM:Number = 3 * Math.PI / 180;
      
      private var numLength:int = -1;
      
      public function SpacetimeNumberManager()
      {
         super();
      }
      
      public static function get Instence() : SpacetimeNumberManager
      {
         if(null == _instence)
         {
            _instence = new SpacetimeNumberManager();
         }
         return _instence;
      }
      
      public function tryGetNumber(param1:int) : void
      {
         var _loc4_:Sprite = null;
         var _loc5_:Sprite = null;
         var _loc6_:Array = null;
         var _loc2_:ApplicationDomain = ApplicationDomain.currentDomain;
         var _loc3_:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         if(_loc3_ != null && (_loc3_.sceneName == "spacetimefb" || _loc3_.sceneName == "spacetimeboss"))
         {
            _loc4_ = _loc3_.scene.backGround.getChildByName("leftnumcontainer") as Sprite;
            _loc5_ = _loc3_.scene.backGround.getChildByName("rightnumcontainer") as Sprite;
            _loc6_ = this.getNumber(param1);
            _loc4_.addChild(_loc6_[0]);
            _loc5_.addChild(_loc6_[1]);
         }
      }
      
      public function getNumber(param1:int) : Array
      {
         var _loc2_:Sprite = new Sprite();
         var _loc3_:Sprite = new Sprite();
         var _loc4_:Array = [_loc2_,_loc3_];
         var _loc5_:Array = this.getFloorNumber(param1);
         _loc2_.addChild(_loc5_[0]);
         _loc3_.addChild(_loc5_[1]);
         this.setManner(_loc2_,-1);
         this.setManner(_loc3_,1);
         return _loc4_;
      }
      
      private function getFloorNumber(param1:int) : Array
      {
         var nums:Array = null;
         var rs1:Sprite = null;
         var rs2:Sprite = null;
         var num:int = param1;
         var number:String = String(num);
         nums = number.split("");
         rs1 = new Sprite();
         rs2 = new Sprite();
         if(ApplicationDomain.currentDomain.hasDefinition(NUM_PREFIX + nums[0]))
         {
            this.setTrueNumber(rs1,nums);
            this.setTrueNumber(rs2,nums);
         }
         else
         {
            ResScheduler.getResource(FILE_NAME,function(param1:*):void
            {
               setTrueNumber(rs1,nums);
               setTrueNumber(rs2,nums);
            });
         }
         return [rs1,rs2];
      }
      
      private function setTrueNumber(param1:Sprite, param2:Array) : void
      {
         var _loc3_:int = 0;
         if(param2.length == 1)
         {
            this.numLength = 2;
            param1.addChild(this.getSingleNumber(0,0));
            param1.addChild(this.getSingleNumber(param2[0],1));
         }
         else
         {
            this.numLength = param2.length;
            _loc3_ = 0;
            while(_loc3_ < param2.length)
            {
               param1.addChild(this.getSingleNumber(param2[_loc3_],_loc3_));
               param1.addChild(this.getSingleNumber(param2[_loc3_],_loc3_));
               _loc3_++;
            }
         }
         param1.x = -this.numLength * NUM_WIDTH / 2;
         param1.y = -NUM_HEIGHT / 2;
      }
      
      private function getSingleNumber(param1:int, param2:int) : Sprite
      {
         var _loc3_:Class = getDefinitionByName(NUM_PREFIX + param1) as Class;
         var _loc4_:Sprite = new _loc3_() as Sprite;
         _loc4_.x = NUM_WIDTH * param2;
         return _loc4_;
      }
      
      private function setManner(param1:DisplayObject, param2:int) : void
      {
         var _loc3_:Matrix = new Matrix(a,b,param2 * absC,d,param2 * absTx,ty);
         _loc3_.rotate(param2 * ROTATE_NUM);
         param1.transform.matrix = _loc3_;
         param1.scaleX = SCALE_X;
         param1.scaleY = SCALE_Y;
         param1.alpha = ALPHA_VAL;
      }
   }
}

