# 📝 Todo List — x86 Assembly (Irvine32)

A fully functional command-line **Todo List Manager** written in x86 32-bit Assembly using the **Irvine32 library**. Tasks are persisted to a plain-text file (`todo.txt`) so your list survives between sessions.

---

## ✨ Features

| Feature | Description |
|---|---|
| ➕ Add Task | Enter a description and due date (MM/DD/YYYY) |
| 📋 View Tasks | List all tasks with their status |
| ✅ Mark Completed | Mark any pending task as completed |
| ✏️ Edit Task | Update description, date, or reset status |
| 🗑️ Remove Task | Delete a task and shift remaining tasks up |
| 💾 Save / Load | Auto-saves on exit; auto-loads on startup |

---

## 🗂️ Project Structure

```
todo-list-asm/
│
├── todo.asm          # Main source file (all logic)
├── todo.txt          # Auto-generated task storage file
└── README.md         # This file
```

---

## ⚙️ Requirements

- **Assembler:** Microsoft MASM (ML.EXE)
- **Library:** [Irvine32](http://asmirvine.com/) — must be installed and linked
- **OS:** Windows (32-bit or 64-bit with 32-bit compatibility)
- **Tools:** Visual Studio with MASM support, or a standalone MASM + Irvine32 setup

> 💡 The Irvine32 library provides helper procedures like `ReadString`, `ReadInt`, `WriteString`, `WriteDec`, `WriteChar`, `Crlf`, `OpenInputFile`, `CreateOutputFile`, `ReadFromFile`, `WriteToFile`, and `CloseFile`.

---

## 🚀 How to Build & Run

### Using Visual Studio (recommended)
1. Clone or download this repository.
2. Open the project in Visual Studio with the Irvine32 template configured.
3. Add `todo.asm` to your project.
4. Build → Run (Ctrl+F5).

### Using Command Line (MASM)
```bat
ml /c /coff todo.asm
link /subsystem:console todo.obj irvine32.lib kernel32.lib user32.lib
todo.exe
```

---

## 🖥️ How to Use

When you run the program you will see the main menu:

```
==================
Todo List Menu:
==================
1. Add Task
2. View Tasks
3. Mark Task Completed
4. Edit Task
5. Remove Task
6. Exit
==================
Enter your choice:
```

### Adding a Task
Select **1**, then enter:
- Task description (up to 99 characters)
- Task date in `MM/DD/YYYY` format

### Viewing Tasks
Select **2** to see all tasks formatted as:
```
1. Buy groceries: 06/15/2025 [pending]
2. Submit report: 06/13/2025 [completed]
```

### Marking a Task Completed
Select **3** and enter the task number. The status changes from `[pending]` to `[completed]`.

### Editing a Task
Select **4**, enter the task number, then provide a new description and date. The status is reset to `[pending]`.

### Removing a Task
Select **5** and enter the task number. All tasks below it shift up automatically.

### Exiting
Select **6** — all tasks are saved to `todo.txt` before the program closes.

---

## 💾 File Format (`todo.txt`)

Each task is stored as one line:

```
<description>: <MM/DD/YYYY> [pending|completed]
```

**Example:**
```
Buy groceries: 06/15/2025 [pending]
Submit report: 06/13/2025 [completed]
Fix bug in project: 06/20/2025 [pending]
```

Tasks are loaded automatically on the next run.

---

## 🔧 Implementation Details

### Data Storage
Tasks are stored in three **parallel arrays** in the `.DATA` segment:

| Array | Type | Purpose |
|---|---|---|
| `taskDescriptions` | `BYTE[100 × 100]` | Stores up to 100 task descriptions |
| `taskDates` | `BYTE[12 × 100]` | Stores dates in `MM/DD/YYYY` format |
| `taskCompletionStatus` | `BYTE[100]` | `0` = pending, `1` = completed |

### Key Procedures

| Procedure | Purpose |
|---|---|
| `main` | Entry point; loads tasks and drives the menu loop |
| `AddTask` | Validates limit, reads input, stores in parallel arrays |
| `ViewTasks` | Loops through all tasks and prints formatted output |
| `MarkCompleted` | Sets completion byte to `1` for selected task index |
| `EditTask` | Overwrites description/date, resets status to pending |
| `RemoveTask` | Shifts array elements left using `rep movsb`, zeroes last slot |
| `LoadTasks` | Parses `todo.txt` line-by-line into memory on startup |
| `SaveTasks` | Serialises all tasks into a buffer and writes to `todo.txt` |

### Constraints
- Maximum **100 tasks** (`MAX_TASKS = 100`)
- Description up to **99 characters** (`MAX_DESC_LENGTH = 100`)
- Date up to **11 characters** (`MAX_DATE_LENGTH = 12`, for `MM/DD/YYYY\0`)
- File buffer size: **500 bytes** (suitable for small lists)

---

## ⚠️ Known Limitations

- The file buffer (`fileBuffer`) is 501 bytes, which limits the total file size that can be loaded in one read. Large task lists (many tasks with long descriptions) may get truncated on load.
- No duplicate detection — the same task can be added multiple times.
- Date input is not validated for correctness (e.g., `99/99/9999` is accepted).

---

## 📚 Concepts Demonstrated

- x86 32-bit Assembly (MASM syntax)
- Parallel array management with index-based addressing
- String I/O using Irvine32 (`ReadString`, `WriteString`)
- File I/O using Irvine32 (`OpenInputFile`, `CreateOutputFile`, `ReadFromFile`, `WriteToFile`)
- Memory shifting with `rep movsb` for task removal
- Conditional logic using `.IF` / `.WHILE` MASM directives
- Modular code with `PROC` / `ENDP` and `PROTO` declarations

---

## 👤 Author

**Hussnain Ahmad & Mahnoor Sohail**
Assembly Language Project — Academic Submission

---

## 📄 License

This project is for educational purposes. Feel free to use or modify it for your own learning.
