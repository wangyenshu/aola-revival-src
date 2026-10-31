package mmo.game.parkour.helper
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.bonus.ShowBonusHelper;
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.game.parkour.common.rank.ParkourRankInfo;
   import mmo.game.parkour.config.ParkourRoleConfig;
   import mmo.game.parkour.data.ParkourRewardInfo;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.ridepet.ParkourRidePetInfo;
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.data.role.ParkourRoleInfo;
   import mmo.game.parkour.data.role.ParkourRoleUserData;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.navigate.INavigateService;
   
   public class ParkourHelper
   {
      
      public function ParkourHelper()
      {
         super();
      }
      
      public static function setRoleView(param1:MovieClip, param2:int) : void
      {
         param1.gotoAndStop(param2);
      }
      
      public static function addRoleSkillTip(param1:DisplayObjectContainer, param2:ParkourRoleInfo) : void
      {
         var _loc3_:MovieClip = param1.getChildByName("mcSkillTip") as MovieClip;
         if(_loc3_ != null)
         {
            if(param2.skillTip != null)
            {
               TipsManager.getInstance().addComplexTips(_loc3_,"",param2.skillTip);
            }
            else
            {
               TipsManager.getInstance().removeTips(_loc3_);
            }
         }
      }
      
      public static function addRidePetSkillTip(param1:DisplayObjectContainer, param2:ParkourRidePetInfo) : void
      {
         var _loc3_:MovieClip = param1.getChildByName("mcSkillTip") as MovieClip;
         if(_loc3_ != null && param2.effectTip != null)
         {
            if(param2.effectTip != null)
            {
               TipsManager.getInstance().addComplexTips(_loc3_,"",param2.effectTip);
            }
            else
            {
               TipsManager.getInstance().removeTips(_loc3_);
            }
         }
      }
      
      public static function showBnAndGBn(param1:Array, param2:Array, param3:Function = null) : void
      {
         var bn:Array = param1;
         var gBn:Array = param2;
         var callback:Function = param3;
         var onShowBn:Function = function():void
         {
            ParkourHelper.showGBn(gBn);
         };
         ShowBonusHelper.showBonus(bn,onShowBn);
      }
      
      public static function showGBn(param1:Array, param2:Function = null) : void
      {
         var _loc7_:Object = null;
         var _loc8_:int = 0;
         if(param1 == null)
         {
            return;
         }
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         while(_loc5_ < param1.length)
         {
            _loc7_ = param1[_loc5_];
            _loc8_ = int(_loc7_.va);
            if(_loc7_.op == 1)
            {
               _loc3_ += _loc8_;
            }
            else if(_loc7_.op == 2)
            {
               _loc4_ += _loc8_;
            }
            _loc5_++;
         }
         ParkourUserData.instance.myMoney += _loc3_;
         ParkourUserData.instance.myLove += _loc4_;
         var _loc6_:String = "";
         if(_loc3_ != 0)
         {
            _loc6_ += "恭喜你获得了" + _loc3_ + "金币!";
         }
         if(_loc4_ != 0)
         {
            _loc6_ += "\n恭喜你获得了" + _loc3_ + "星星能量!";
         }
         showSucessMsg(_loc6_,param2);
      }
      
      public static function showSucessMsg(param1:String, param2:Function = null) : void
      {
         showMessage(param1,param2,NewDialog.getSucceedIcon());
      }
      
      public static function showFailMsg(param1:String, param2:Function = null) : void
      {
         showMessage(param1,param2,NewDialog.getFailIcon());
      }
      
      private static function showMessage(param1:String, param2:Function = null, param3:DisplayObject = null) : void
      {
         var msg:String = param1;
         var callback:Function = param2;
         var icon:DisplayObject = param3;
         NewDialog.getMessageDialog(msg,function(param1:ModalDialog):void
         {
            var content:ModalDialog = param1;
            content.addEventListener(ModalDialogEvent.CLOSE,function onClose(param1:ModalDialogEvent):void
            {
               content.removeEventListener(ModalDialogEvent.CLOSE,onClose);
               applyFunc(callback);
            },false);
            content.show();
         },null,icon);
      }
      
      public static function isMember() : Boolean
      {
         return Boolean(MemberManager.instance.isMember()) || Boolean(MemberManager.instance.isTrialMember());
      }
      
      public static function parseRewardInfos(param1:Array) : Array
      {
         var _loc4_:Object = null;
         var _loc5_:ParkourRewardInfo = null;
         var _loc2_:Array = [];
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1[_loc3_];
            _loc5_ = new ParkourRewardInfo();
            _loc5_.parseParams(_loc4_);
            _loc2_.push(_loc5_);
            _loc3_++;
         }
         return _loc2_;
      }
      
      public static function showOpenBluePage() : void
      {
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService(INavigateService,function(param1:INavigateService, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.goToBlueDiamond();
         });
      }
      
      public static function formatNumber(param1:Number) : Number
      {
         return int(param1 * 10) / 10;
      }
      
      public static function millSecToSec(param1:int) : Number
      {
         var _loc2_:Number = param1 / 1000;
         return formatNumber(_loc2_);
      }
      
      public static function parseRoleDataMap(param1:Array) : Object
      {
         var _loc4_:ParkourRoleInfo = null;
         var _loc5_:int = 0;
         var _loc6_:ParkourRoleUserData = null;
         var _loc7_:Object = null;
         var _loc8_:int = 0;
         var _loc9_:ParkourRoleUserData = null;
         var _loc2_:Object = {};
         var _loc3_:Array = ParkourRoleConfig.getRoleInfoClone();
         for each(_loc4_ in _loc3_)
         {
            _loc6_ = new ParkourRoleUserData(_loc4_);
            _loc2_[_loc6_.id] = _loc6_;
         }
         _loc5_ = 0;
         while(_loc5_ < param1.length)
         {
            _loc7_ = param1[_loc5_];
            _loc8_ = int(_loc7_.pId);
            _loc9_ = _loc2_[_loc8_] as ParkourRoleUserData;
            _loc9_.level = _loc7_.lv;
            _loc9_.totalExp = _loc7_.ce;
            _loc9_.isExit = true;
            _loc5_++;
         }
         return _loc2_;
      }
      
      public static function parseRidePetDataMap(param1:Array) : Object
      {
         var _loc4_:Object = null;
         var _loc5_:ParkourRidePetUserData = null;
         var _loc2_:Object = {};
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1[_loc3_];
            _loc5_ = ParkourRidePetUserData.createByParams(_loc4_);
            _loc2_[_loc5_.info.id] = _loc5_;
            _loc3_++;
         }
         return _loc2_;
      }
      
      public static function isNear(param1:Number, param2:Number, param3:int = 5) : Boolean
      {
         return Math.abs(param1 - param2) <= param3;
      }
      
      public static function inInRange(param1:Number, param2:Number, param3:Number) : Boolean
      {
         return param1 >= param2 && param1 <= param2 + param3;
      }
      
      public static function parseRankDatas(param1:Array, param2:int = 0, param3:int = -1) : Array
      {
         var _loc7_:Object = null;
         var _loc8_:ParkourRankInfo = null;
         var _loc4_:Array = [];
         var _loc5_:int = param3 == -1 || param3 >= param1.length ? int(param1.length) : param3;
         var _loc6_:int = param2;
         while(_loc6_ < _loc5_)
         {
            _loc7_ = param1[_loc6_] as Object;
            _loc8_ = _loc4_[_loc6_] as ParkourRankInfo;
            _loc8_ = new ParkourRankInfo();
            _loc8_.parseParam(_loc7_);
            _loc8_.rank = _loc6_ + 1;
            _loc4_.push(_loc8_);
            _loc6_++;
         }
         return _loc4_;
      }
      
      public static function applyFunc(param1:Function, param2:* = null, param3:* = null) : void
      {
         if(param1 != null)
         {
            param1.apply(param2,param3);
         }
      }
      
      public static function setMcButton(param1:MovieClip, param2:Boolean, param3:String = null) : void
      {
         if(param2)
         {
            grayMcButton(param1,param3);
         }
         else
         {
            clearFilterMcButton(param1);
         }
      }
      
      public static function grayMcButton(param1:MovieClip, param2:String = null) : void
      {
         param1.mouseChildren = false;
         DisplayUtil.applyGray(param1);
         if(param2 != null)
         {
            // aola-revival: the 2013 TipsManager has no replaceTips.
            TipsManager.getInstance().removeTips(param1);
            TipsManager.getInstance().addTips(param1,param2);
         }
      }
      
      public static function clearFilterMcButton(param1:MovieClip) : void
      {
         param1.mouseChildren = true;
         DisplayUtil.clearFilters(param1);
         TipsManager.getInstance().removeTips(param1);
      }
      
      public static function clearContainer(param1:DisplayObjectContainer) : void
      {
         while(param1.numChildren > 0)
         {
            param1.removeChildAt(0);
         }
      }
   }
}

