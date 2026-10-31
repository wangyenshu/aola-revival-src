package mmo.fbteam.common
{
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.MaterialTypes;
   
   public class BonusPraiseHelper
   {
      
      private static var fbTeamService:IFBTeamService = null;
      
      public function BonusPraiseHelper()
      {
         super();
      }
      
      private static function tryInit() : void
      {
         if(null == fbTeamService)
         {
            fbTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
         }
      }
      
      public static function onFinFb(param1:SocketClientEvent) : void
      {
         var _loc7_:Object = null;
         tryInit();
         var _loc2_:Boolean = param1.params.fin as Boolean;
         var _loc3_:Array = param1.params.bn as Array;
         var _loc4_:Array = [];
         if(_loc2_ && _loc3_ != null)
         {
            for each(_loc7_ in _loc3_)
            {
               _loc4_.push({
                  "type":_loc7_.type,
                  "id":_loc7_.id,
                  "num":_loc7_.num
               });
            }
         }
         var _loc5_:String = param1.params.gr as String;
         var _loc6_:int = param1.params.tm as int;
         fbTeamService.dispatchEvent(new FbEvent(FbEvent.ON_FIN_FB,{
            "succ":_loc2_,
            "bonus":_loc4_,
            "gr":_loc5_,
            "tm":_loc6_
         }));
      }
      
      public static function onGetCase(param1:SocketClientEvent) : void
      {
         var _loc5_:Object = null;
         tryInit();
         var _loc2_:Boolean = param1.params.succ as Boolean;
         var _loc3_:Array = param1.params.bn as Array;
         var _loc4_:Array = [];
         if(_loc2_ && _loc3_ != null && _loc3_.length > 0)
         {
            for each(_loc5_ in _loc3_)
            {
               _loc4_.push({
                  "type":_loc5_.type,
                  "id":_loc5_.id,
                  "num":_loc5_.num
               });
            }
         }
         fbTeamService.dispatchEvent(new FbEvent(FbEvent.ON_TRYGET_CASE,{
            "succ":_loc2_,
            "bonus":_loc4_
         }));
         showBonus(_loc2_,_loc3_);
      }
      
      public static function showBonus(param1:Boolean, param2:Array) : void
      {
         var _loc3_:IMaterialGetPanel = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Object = null;
         if(param1)
         {
            _loc3_ = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
            _loc4_ = 0;
            _loc5_ = 0;
            for each(_loc6_ in param2)
            {
               if(_loc6_.type == MaterialTypes.MONEY)
               {
                  _loc4_ = int(_loc6_.num);
               }
               else if(_loc6_.type == MaterialTypes.EXP)
               {
                  _loc5_ = int(_loc6_.num);
               }
               else
               {
                  _loc3_.showTips(_loc6_.type,_loc6_.id,_loc6_.num);
               }
            }
            if(_loc4_ > 0 || _loc5_ > 0)
            {
               _loc3_.showGetMoneyAndExpPanel(_loc4_,_loc5_);
            }
         }
         else
         {
            NewDialog.showFailMessage("很抱歉，你获得了空奖励！");
         }
      }
      
      public static function onGetbestPraise(param1:SocketClientEvent) : void
      {
         tryInit();
         var _loc2_:String = param1.params.gr as String;
         var _loc3_:Array = [];
         if(_loc2_ != null)
         {
            _loc3_ = _loc2_.split(";");
         }
         fbTeamService.dispatchEvent(new FbEvent(FbEvent.ON_GET_BEST_PRAISE,{"gr":_loc3_}));
      }
   }
}

