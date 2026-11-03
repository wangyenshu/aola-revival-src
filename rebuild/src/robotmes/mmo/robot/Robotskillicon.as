package mmo.robot
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import mmo.common.member.MemberManager;
   import mmo.common.utils.tips.TipsManager;

   /**
    * LATER mmo.robot.Robotskillicon (robot/robotmes of November 2015, decompiled)
    * on the 2013 libraries, on that copy's art (symbol 76): the HELLO's skills as
    * icons, bright the ones it has (its own, and those woken at the HELLO学院 by
    * the skill string f), grey the others; the 蓝宝石 skills below, bright for a
    * member.
    */
   public class Robotskillicon extends MovieClip
   {
      public var sk0:MovieClip;
      public var sk1:MovieClip;
      public var sk2:MovieClip;
      public var sk3:MovieClip;
      public var sk4:MovieClip;
      public var sk5:MovieClip;
      public var sk6:MovieClip;
      public var sk7:MovieClip;
      public var sk8:MovieClip;
      public var ssk0:MovieClip;
      public var ssk1:MovieClip;
      public var ssk2:MovieClip;
      public var ssk3:MovieClip;
      public var ssk4:MovieClip;
      public var ssk5:MovieClip;
      public var ssk6:MovieClip;
      public var ssk7:MovieClip;
      public var ssk8:MovieClip;

      private var innateskills:Array = ["经验加成", "HELLO跟随", "亚比治疗", "亚比孵化", "经验分配", "语言功能", "道具", "亚比强化"];
      private var commonskill:Object = {"亚比技能排序": 0, "亚比孵化": 1, "稀有亚比搜索": 2, "技能替换": 4};
      private var comskPRI:Array = ["经验加成", "HELLO跟随", "亚比治疗", "语言功能", "亚比孵化", "经验分配", "道具", "亚比强化"];
      private var supskPRI:Array = ["蓝宝石经验加成", "亚比免费治疗", "远程亚比仓库", "快速孵化"];

      public var iconname:Object = {
         "经验加成": "sk0", "HELLO跟随": "sk1", "亚比治疗": "sk2", "语言功能": "sk3",
         "亚比孵化": "sk5", "经验分配": "sk6", "道具": "sk7", "亚比强化": "sk8"
      };
      public var iconNameSuper:Object = {"蓝宝石经验加成": "ssk0", "亚比免费治疗": "ssk2", "远程亚比仓库": "ssk3", "快速孵化": "ssk5"};

      public var iconarray:Array = [];
      public var iconArraySuper:Array = [];

      public function Robotskillicon(skills:String)
      {
         super();
         addtip();
         geticon(skills || "");
      }

      private function addtip():void
      {
         for (var n:String in iconname)
         {
            var c:MovieClip = getChildByName(iconname[n]) as MovieClip;
            if (c != null) TipsManager.getInstance().addTips(c as InteractiveObject, n, 100);
         }
         for (var s:String in iconNameSuper)
         {
            var d:MovieClip = getChildByName(iconNameSuper[s]) as MovieClip;
            if (d != null) TipsManager.getInstance().addTips(d as InteractiveObject, s, 100);
         }
      }

      public function geticonclip(skill:String):MovieClip
      {
         return getChildByName(iconname[skill]) as MovieClip;
      }

      private function geticon(f:String):void
      {
         var member:Boolean = MemberManager.instance.isMember();
         var greyed:Array = [];
         for (var i:int = 0; i < comskPRI.length; i++)
         {
            var name:String = comskPRI[i];
            var c:MovieClip = getChildByName(iconname[name]) as MovieClip;
            if (c == null) continue;
            var at:* = commonskill[name];
            if ((at != null && f.charAt(int(at)) == "1") || innateskills.indexOf(name) >= 0)
            {
               c.gotoAndStop(1);
               iconarray.push(c);
            }
            else
            {
               c.gotoAndStop(2);
               greyed.push(c);
            }
         }
         iconarray = iconarray.concat(greyed);
         for each (var sname:String in supskPRI)
         {
            var s:MovieClip = getChildByName(iconNameSuper[sname]) as MovieClip;
            if (s == null) continue;
            s.gotoAndStop(member ? 1 : 2);
            iconArraySuper.push(s);
         }
      }
   }
}
