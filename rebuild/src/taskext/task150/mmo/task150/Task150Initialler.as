package mmo.task150
{
   import mmo.common.dialog.NewDialog;
   import mmo.revival.RComic;
   import mmo.revival.task.TaskScript;

   /**
    * REBUILT taskext/task150 (version 130110): 新手任务, the end of the 2012
    * newbie quest. The task panel taskpanel/tp150: "去指挥中心向司令官麦哲伦报告
    * 这一事件", reward 3000 HELLO experience and 2000 晶币 (paid by the
    * server). The walkthrough of December 2011 ends here: "最后，回到指挥中心向
    * 司令官麦哲伦汇报，新手任务就完成了。真正的探险正等待着我". The era comic
    * task147res_reword0–2 (version 130117) is the ceremony that ends it: 麦哲伦
    * gives the 奥拉勇士勋章. The words are RECONSTRUCTED.
    *
    *   152  指挥中心: report to 麦哲伦; the ceremony; 任务完成
    */
   public class Task150Initialler extends TaskScript
   {
      private static const MAGELLAN:Array = [9, 1, 600, 330];

      public function Task150Initialler()
      {
         super(150);
      }

      override protected function refresh():void
      {
         if (step != 152) return;
         if (scene == "maintown2")
         {
            var x:XML = <config>
                  <context npcId="9" iconId="1" str="#username#，你回来了！看来你已经学到了不少本领。">
                     <choice str="报告司令官，我已经准备好了！" action="t152_ceremony"/>
                  </context>
               </config>;
            addNpc(MAGELLAN[0], MAGELLAN[1], MAGELLAN[2], MAGELLAN[3]);
            setTalk(9, x);
            delay(600, function():void { sayOnce("152", 9, x); });
         }
         else sayOnce("152go", 1, <config>
               <context npcId="1" str="司令官麦哲伦在指挥中心等你的报告呢！">
                  <choice str="回指挥中心" nextScene="maintown2"/>
               </context>
            </config>);
      }

      override protected function onAction(a:String):void
      {
         if (a == "t152_end")
         {
            // The rewards the server pays with the last step (tp150).
            NewDialog.showSucceedMessage("新手任务完成！你获得了2000晶币，HELLO获得了3000点经验。");
            finish(152);
            return;
         }
         if (a != "t152_ceremony") return;
         var c:int = color();
         RComic.play("taskres/task147res_reword" + c, "mmo.task147.RewordMc" + c, function():void
         {
            say(9, <config>
                  <context npcId="9" iconId="1" str="从今天起，你就是奥拉星的小勇士了！HELLO会帮你把奖励的经验分给亚比。真正的探险正等待着你！">
                     <choice str="是！司令官！" action="t152_end"/>
                  </context>
               </config>);
         });
      }
   }
}
