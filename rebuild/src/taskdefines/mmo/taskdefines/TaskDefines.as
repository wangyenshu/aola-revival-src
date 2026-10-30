package mmo.taskdefines
{
   import mmo.interfaces.task.data.TaskDefine;
   import mmo.interfaces.task.data.TaskStarter;

   /**
    * REBUILT task/taskdefines (version 130124): which tasks exist, their
    * steps, and how they start. The January 2013 module is lost (the copy
    * under its URL is years later and lists another newbie quest). Only the
    * 2012 newbie quest is defined so far, RECONSTRUCTED from the task
    * panels taskpanel/tp135, tp140 and tp150, the era task resources and
    * scenes, and the official walkthrough of December 2011
    * (aola.100bt.com/renwugonglue/3073):
    *
    *   135 新手任务            136 to the 指挥中心; 137 the first 亚比;
    *                           138 the 达斯特 in the 机械废墟; 139 the 奥拉之辉
    *   140 贝鲁特博士的指导    142 贝鲁特; 143 5 亚比球 from 米娜; 144 贝鲁特
    *                           teaches catching; 145 a 朵朵兔; 146 普伦博士 and
    *                           the HELLO; 147 what the HELLO can do
    *   150 新手任务            152 report to 麦哲伦 (3000 HELLO experience,
    *                           2000 晶币)
    *
    * TaskDefine(id, type, extData): type 0 a task whose extData lists its
    * steps; type 11 a client step. TaskStarter(id, type, extData, preTask,
    * isOnline, name, line, area): type 11 started by the client, 12 started
    * by the server when the pre-task is finished. The server keeps the same
    * list (server/src/game/sfs2013/tasks.ts).
    */
   public class TaskDefines
   {
      public static var defines:Object = {
         "135": new TaskDefine(135, 0, "136,137,138,139"),
         "136": new TaskDefine(136, 11, ""),
         "137": new TaskDefine(137, 11, ""),
         "138": new TaskDefine(138, 11, ""),
         "139": new TaskDefine(139, 11, ""),
         "140": new TaskDefine(140, 0, "142,143,144,145,146,147"),
         "142": new TaskDefine(142, 11, ""),
         "143": new TaskDefine(143, 11, ""),
         "144": new TaskDefine(144, 11, ""),
         "145": new TaskDefine(145, 11, ""),
         "146": new TaskDefine(146, 11, ""),
         "147": new TaskDefine(147, 11, ""),
         "150": new TaskDefine(150, 0, "152"),
         "152": new TaskDefine(152, 11, "")
      };

      public static var starters:Object = {
         "135": new TaskStarter(135, 11, "", "", 1, "新手任务", 1, 0),
         "140": new TaskStarter(140, 12, "", "135", 1, "贝鲁特博士的指导", 1, 0),
         "150": new TaskStarter(150, 12, "", "140", 1, "新手任务", 1, 0)
      };

      /** The scene each step is done in (TaskService.getTaskSceneByTaskId). */
      public static var scenes:Object = {
         "136": "maintown2", "137": "maintown2", "138": "junglecopy", "139": "maintown2",
         "142": "yabistudy", "143": "toolshopcopy", "144": "yabistudy", "145": "aixiscene2",
         "146": "helloschoolcopy", "147": "helloschoolcopy", "152": "maintown2"
      };

      /** Task panel art: taskpanel/tp<task>, classes mmo.taskpanel.Task<id> (one per task and step). */
      public static var panels:Object = { "135": "taskpanel/tp135", "140": "taskpanel/tp140", "150": "taskpanel/tp150" };

      /** Task scripts (task/taskextmanager): taskext/task<id>, class mmo.task<id>.Task<id>Service. */
      public static var exts:Array = [
         {file: "taskext/task135", cls: "mmo.task135.Task135Service", task: 135},
         {file: "taskext/task140", cls: "mmo.task140.Task140Service", task: 140},
         {file: "taskext/task150", cls: "mmo.task150.Task150Service", task: 150}
      ];

      public function TaskDefines()
      {
         super();
      }
   }
}
