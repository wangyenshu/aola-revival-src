package mmo.task135
{
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.revival.RComic;
   import mmo.revival.task.TaskScript;

   /**
    * REBUILT taskext/task135 (version 130110): 新手任务, the start of the 2012
    * newbie quest. The 2013 script is lost (the copy under its URL tells a
    * later story). This follows the official walkthrough of 19 December
    * 2011 (renwugonglue/3073) and the task panel taskpanel/tp135 ("奥拉星出现
    * 紧急情况，司令官麦哲伦命你急速前往指挥中心"); 麦哲伦's line about the 奥拉之辉
    * and its two answers are those of the walkthrough's screenshot, the rest
    * of the words are RECONSTRUCTED. Era films: task150res_newbiefightstart
    * (the VS before the fight), task138res_groupfight (the 达斯特 driven
    * off), task136res_openbook0–2 (the story of the 奥拉之辉),
    * task146res_heroinfo (the three heroes), task138res_haludainfo (哈鲁达).
    *
    *   136  anywhere: HELLO sends the new player to the 指挥中心 (maintown2);
    *        there 麦哲伦 tells of the attack
    *   137  麦哲伦: choose the first 亚比 (StarterPanel)
    *   138  the 机械废墟 (junglecopy): fight the 达斯特's 达达 (Lv2)
    *   139  麦哲伦: the 奥拉之辉; then off to 贝鲁特 (task 140)
    */
   public class Task135Initialler extends TaskScript
   {
      /** 麦哲伦's place in the 指挥中心 (he has none in the later NPC data). */
      private static const MAGELLAN:Array = [9, 1, 600, 330];
      private static const DADA:int = 322;
      private var fighting:Boolean;

      public function Task135Initialler()
      {
         super(135);
      }

      override public function init():void
      {
         onFightEnd(fightEnded);
         super.init();
      }

      override protected function refresh():void
      {
         var s:String = scene;
         switch (step)
         {
            case 136:
               if (s == "maintown2") magellan("136", <config>
                     <context npcId="9" iconId="1" str="#username#，你终于来了！达斯特军团突然袭击了我们的奥拉飞船，情况十分紧急！">
                        <choice str="司令官，我能帮上什么忙？" taskId="136"/>
                     </context>
                  </config>);
               else sayOnce("136go", 1, <config>
                     <context npcId="1" str="#username#，欢迎来到奥拉星！不好了，达斯特军团正在攻打我们的奥拉飞船！司令官麦哲伦命你急速前往指挥中心！">
                        <choice str="马上出发！" nextScene="maintown2"/>
                     </context>
                  </config>);
               break;
            case 137:
               if (s == "maintown2") magellan("137", <config>
                     <context npcId="9" iconId="1" str="战斗离不开亚比伙伴。现在情况紧急，你先选一只初始亚比出战吧！吉拉、滴滴和兔小子没有谁强谁弱之分，选你最喜欢的就好。">
                        <choice str="我来选一只亚比！" action="t137_choose"/>
                     </context>
                  </config>);
               else backTo("137go");
               break;
            case 138:
               if (s == "junglecopy")
               {
                  sayOnce("138fight", 1, <config>
                     <context npcId="1" str="达斯特的士兵就在这里！战斗中点击技能就可以出招，威力越大，伤害越大。对方的体力消失，你就胜利了！">
                        <choice str="上吧！" action="t138_fight"/>
                     </context>
                  </config>);
               }
               else if (s == "maintown2") magellan("138", <config>
                     <context npcId="9" iconId="1" str="好样的！达斯特军团的先头部队就在机械废墟，带上你的亚比，把他们赶走！">
                        <choice str="交给我吧！" nextScene="junglecopy"/>
                     </context>
                  </config>);
               else backTo("138go");
               break;
            case 139:
               if (s == "maintown2") magellan("139", talk139());
               else sayOnce("139go", 1, <config>
                     <context npcId="1" str="达斯特被打退了！快回指挥中心向司令官麦哲伦报告吧！">
                        <choice str="回指挥中心" nextScene="maintown2"/>
                     </context>
                  </config>);
               break;
         }
      }

      private static function talk139():XML
      {
         return <config>
               <context npcId="9" iconId="1" str="干得漂亮，#username#！可惜，奥拉之辉已经破碎成了辉之碎片，散落到了异空间中，三英雄也下落不明。">
                  <choice str="这究竟是怎么回事呢？" action="t139_history"/>
                  <choice str="我已经了解奥拉之辉的历史了。">
                     <context npcId="9" iconId="1" str="要找回散落在异空间各处的辉之碎片可不是容易的事情，你首先要学好各方面的知识。"/>
                     <context npcId="9" iconId="1" str="贝鲁特是研究亚比的高手，去科学院的亚比研究中心，向贝鲁特请教一下关于亚比的知识吧！">
                        <choice str="是！司令官！" taskId="139" nextScene="sciencecopy"/>
                     </context>
                  </choice>
               </context>
            </config>;
      }

      /** 麦哲伦 stands in the 指挥中心 with this conversation, and says it once on arrival. */
      private function magellan(key:String, xml:XML):void
      {
         addNpc(MAGELLAN[0], MAGELLAN[1], MAGELLAN[2], MAGELLAN[3]);
         setTalk(9, xml);
         delay(600, function():void { sayOnce(key, 9, xml); });
      }

      private function backTo(key:String):void
      {
         sayOnce(key, 1, <config>
               <context npcId="1" str="司令官麦哲伦还在指挥中心等你呢！">
                  <choice str="回指挥中心" nextScene="maintown2"/>
               </context>
            </config>);
      }

      override protected function onAction(a:String):void
      {
         switch (a)
         {
            case "t137_choose":
               new StarterPanel(function(race:int):void
               {
                  PetClient.instance.addPM(race, 5);
                  delay(800, function():void { finish(137); });
               }).show();
               break;
            case "t138_fight":
               startFight();
               break;
            case "t139_history":
               var c:int = color();
               RComic.play("taskres/task136res_openbook" + c, "mmo.task136.OpenBook" + c, function():void
               {
                  RComic.play("taskres/task146res_heroinfo", "mmmo.task146.HeroInfo", function():void
                  {
                     RComic.play("taskres/task138res_haludainfo", "mmo.task137.HaludaInfo", function():void { say(9, talk139()); });
                  });
               });
               break;
         }
      }

      private function startFight():void
      {
         if (fighting) return;
         fighting = true;
         RComic.play("taskres/task150res_newbiefightstart", "mmo.task150.NewBieFSMc", function():void
         {
            PetClient2.instance.startPKWithRobot(DADA, 2, true, -1);
         }, false);
      }

      private function fightEnded(r:Object):void
      {
         if (step != 138 || scene != "junglecopy") return;
         fighting = false;
         if (r.isWin)
         {
            RComic.play("taskres/task138res_groupfight", "mmo.task138.GroupFightMc", function():void { finish(138); });
            return;
         }
         // The 亚比 get their strength back for another go.
         SocketClient.instance.sendXtMessage("PocketMonsterExtension", "revival_heal", {});
         say(1, <config>
               <context npcId="1" str="别灰心！你的亚比已经恢复了体力，再试一次吧！">
                  <choice str="再来一次！" action="t138_fight"/>
               </context>
            </config>);
      }
   }
}
