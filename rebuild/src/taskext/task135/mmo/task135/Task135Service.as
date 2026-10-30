package mmo.task135
{
   import mmo.interfaces.task.ext.TaskExtServiceBase;

   /** REBUILT taskext/task135: the task's service, as the later copy names it. */
   public class Task135Service extends TaskExtServiceBase
   {
      public function Task135Service()
      {
         super();
         resInitiallerDefines = [Task135Initialler];
      }
   }
}
