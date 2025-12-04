ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS recurrence_type TEXT DEFAULT 'none' CHECK (recurrence_type IN ('none', 'daily', 'weekly', 'monthly')),
  ADD COLUMN IF NOT EXISTS parent_recurring_task_id UUID REFERENCES tasks(id) ON DELETE SET NULL;


-- Create index for better query performance on recurring tasks

CREATE INDEX IF NOT EXISTS idx_tasks_is_recurring ON tasks(is_recurring) WHERE is_recurring = TRUE;

CREATE INDEX IF NOT EXISTS idx_tasks_parent_recurring ON tasks(parent_recurring_task_id) WHERE parent_recurring_task_id IS NOT NULL;
 

-- Add comment to columns for documentation

COMMENT ON COLUMN tasks.is_recurring IS 'Whether this task is a recurring task template';

COMMENT ON COLUMN tasks.recurrence_type IS 'Type of recurrence: none, daily, weekly, or monthly';

COMMENT ON COLUMN tasks.parent_recurring_task_id IS 'Reference to the parent recurring task if this is an instance';