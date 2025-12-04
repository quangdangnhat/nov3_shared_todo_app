# Recurring Tasks Feature - Implementation Guide

## 📋 Overview
This document describes the implementation of the **Recurring Tasks** feature that allows users to create tasks that repeat daily, weekly, or monthly.

## ✅ User Story Completed
**As a user, I want to create a task that repeats daily/weekly/monthly so that I can automatically organize my tasks.**

### Requirements Implemented:
1. ✅ Add "Make recurring" checkbox to task creation
2. ✅ Implement daily/weekly/monthly recurrence options
3. ✅ Show "Recurring" badge on task

---

## 🗄️ Database Migration

**IMPORTANT:** Before testing, you must run the SQL migration on your Supabase database.

### Steps to Apply Migration:

1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Open the migration file: `database_migrations/add_recurring_tasks_fields.sql`
4. Copy and paste the SQL into the editor
5. Click **Run** to execute

### Migration Details:
The migration adds three new columns to the `tasks` table:
- `is_recurring` (boolean, default: false)
- `recurrence_type` (text, values: 'none', 'daily', 'weekly', 'monthly')
- `parent_recurring_task_id` (uuid, nullable, self-reference)

---

## 🏗️ Implementation Details

### 1. Data Model (`lib/data/models/task.dart`)
Added three new fields to the `Task` model:
```dart
final bool isRecurring;
final String recurrenceType;
final String? parentRecurringTaskId;
```

### 2. Enum (`lib/core/enums/recurrence_type.dart`)
Created `RecurrenceType` enum with:
- `none`
- `daily`
- `weekly`
- `monthly`

### 3. Repository (`lib/data/repositories/task_repository.dart`)
Updated `createTask()` method to accept recurring parameters:
```dart
bool isRecurring = false,
String recurrenceType = 'none',
String? parentRecurringTaskId,
```

### 4. Controller (`lib/features/todo_lists/presentation/controllers/task/task_create_controller.dart`)
Added recurring state management:
- `_isRecurring` (bool)
- `_recurrenceType` (RecurrenceType)
- `setRecurring()` method
- `setRecurrenceType()` method

### 5. UI Widget (`lib/features/todo_lists/presentation/widgets/create/task/recurrence_selector.dart`)
Created `RecurrenceSelector` widget with:
- Checkbox for "Make recurring"
- Three choice chips: Daily, Weekly, Monthly
- Icons and colors for each recurrence type
- Conditional display (only shows options when recurring is enabled)

### 6. Badge Widget (`lib/features/todo_lists/presentation/widgets/badges/recurring_badge.dart`)
Created `RecurringBadge` widget to display recurring status on task cards with:
- Color-coded badges (Blue=Daily, Purple=Weekly, Orange=Monthly)
- Icons for each recurrence type
- Responsive sizing

### 7. Updated Screens:
- **Task Creation** (`lib/features/todo_lists/presentation/screens/createPage/task_create.dart`)
  - Added `RecurrenceSelector` after PrioritySelector

- **Task Cards** (`lib/features/todo_lists/presentation/widgets/daily_tasks.dart/task_card.dart`)
  - Added `RecurringBadge` to info chips

- **Task List Tile** (`lib/features/todo_lists/presentation/widgets/task_list_tile.dart`)
  - Added `RecurringBadge` after location info

---

## 🧪 Testing Instructions

### 1. Run Database Migration
Follow the steps in the **Database Migration** section above.

### 2. Build and Run the App
```bash
cd shared_todo_app
flutter pub get
flutter run
```

### 3. Test Task Creation
1. Navigate to **Create Task** screen
2. Fill in task details (title, description, folder, dates)
3. Check the **"Make recurring"** checkbox
4. Select a recurrence pattern (Daily/Weekly/Monthly)
5. Click **Create Task**

### 4. Verify Badge Display
1. Navigate to **Today Tasks** or **List Detail** screen
2. Find your created recurring task
3. Verify that the recurring badge is displayed with correct:
   - Color (Blue/Purple/Orange)
   - Icon (refresh/event_repeat/calendar_today)
   - Text (Daily/Weekly/Monthly)

### 5. Test Edge Cases
- Create task without recurring (should not show badge)
- Toggle recurring checkbox on/off (UI should update)
- Switch between recurrence types (badge should update)

---

## 🎨 Visual Design

### Recurrence Selector (Task Creation)
```
☐ Make recurring

When checked:
┌─────────────────────────────────────┐
│ Recurrence Pattern                  │
│ ┌───────┐ ┌────────┐ ┌──────────┐ │
│ │ 🔄 Daily│ │ 📅 Weekly│ │ 📆 Monthly│ │
│ └───────┘ └────────┘ └──────────┘ │
└─────────────────────────────────────┘
```

### Recurring Badge (Task Cards)
```
Task Card:
┌─────────────────────────────────────┐
│ 📋 Task Title                    [⋮]│
│                                      │
│ ▶ Start: 04 Dec    🚩 Due: 10 Dec   │
│ 📊 To Do           🔄 Daily          │
└─────────────────────────────────────┘
```

---

## 📝 Notes for Future Enhancement

### Phase 2 (Not Implemented Yet):
The current implementation marks tasks as recurring but does NOT automatically create recurring instances. Future enhancements could include:

1. **Background Job**: Create a scheduled job to generate recurring task instances
2. **Recurrence Rules**:
   - End date for recurrence
   - Skip weekends option
   - Custom intervals (every 2 days, every 3 weeks, etc.)
3. **Bulk Operations**: Edit/delete all instances of a recurring task
4. **Recurrence UI**: Visual calendar showing all future instances

### Database Design for Phase 2:
The `parent_recurring_task_id` field is already in place to support parent-child relationships:
- Parent task: `isRecurring = true`, `parent_recurring_task_id = null`
- Child instances: `isRecurring = false`, `parent_recurring_task_id = <parent_id>`

---

## 📦 Files Changed

### New Files:
1. `database_migrations/add_recurring_tasks_fields.sql`
2. `shared_todo_app/lib/core/enums/recurrence_type.dart`
3. `shared_todo_app/lib/features/todo_lists/presentation/widgets/create/task/recurrence_selector.dart`
4. `shared_todo_app/lib/features/todo_lists/presentation/widgets/badges/recurring_badge.dart`
5. `RECURRING_TASKS_FEATURE.md`

### Modified Files:
1. `shared_todo_app/lib/data/models/task.dart`
2. `shared_todo_app/lib/data/repositories/task_repository.dart`
3. `shared_todo_app/lib/features/todo_lists/presentation/controllers/task/task_create_controller.dart`
4. `shared_todo_app/lib/features/todo_lists/presentation/screens/createPage/task_create.dart`
5. `shared_todo_app/lib/features/todo_lists/presentation/widgets/daily_tasks.dart/task_card.dart`
6. `shared_todo_app/lib/features/todo_lists/presentation/widgets/task_list_tile.dart`

---

## 🚀 Deployment Checklist

- [ ] Run database migration on production Supabase
- [ ] Test task creation with recurring enabled
- [ ] Verify badge display on all task views
- [ ] Test on mobile, tablet, and desktop layouts
- [ ] Verify backward compatibility (old tasks without recurring fields)
- [ ] Update API documentation if applicable
- [ ] Notify team about new feature

---

## 💡 Tips

- The recurring badge only appears when `isRecurring = true` and `recurrenceType != 'none'`
- The checkbox state is reset when the form is cleared
- The feature is fully backward compatible - existing tasks will have `isRecurring = false` by default
- The UI is responsive and adapts to mobile/tablet/desktop layouts

---

## 🐛 Troubleshooting

### Badge not showing?
1. Check that migration was applied successfully
2. Verify task has `isRecurring = true` in database
3. Ensure `recurrenceType` is not 'none'

### UI not updating?
1. Check that controller methods are calling `notifyListeners()`
2. Verify `ListenableBuilder` is wrapping the UI components

### Import errors?
1. Run `flutter pub get`
2. Check all import paths are correct
3. Restart IDE/editor

---

**Feature implemented by:** Claude AI Assistant
**Date:** December 4, 2025
**Version:** 1.0
