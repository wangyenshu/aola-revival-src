package mmo.task140
{
   import mmo.interfaces.task.ext.TaskExtServiceBase;

   /** REBUILT taskext/task140: the task's service, as the later copy names it. */
   public class Task140Service extends TaskExtServiceBase
   {
      public function Task140Service()
      {
         super();
         resInitiallerDefines = [Task140Initialler];
      }
   }
}
