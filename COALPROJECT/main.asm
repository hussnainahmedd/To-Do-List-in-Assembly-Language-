INCLUDE Irvine32.inc

; Constants
MAX_TASKS = 100
MAX_DESC_LENGTH = 100
MAX_DATE_LENGTH = 12 ; MM/DD/YYYY format

.DATA
goodbyeMsg BYTE "Goodbye! Tasks saved.", 0Dh, 0Ah, 0
; File-related variables
filen BYTE "todo.txt", 0         ; File to store tasks
fileBuffer BYTE 501 DUP(?)
 
bytewritten dd ?                 ; Number of bytes written to file
 data byte 501 dup (?)
 datas equ 501
 handler handle ?
; Buffer for file operations
newline BYTE 0Ah, 0              ; Newline character
pendingStr BYTE "[pending]", 0   ; Pending status string
completedStr BYTE "[completed]", 0 ; Completed status string

; Menu strings
taskNumberDot BYTE ". ", 0
colonSpace BYTE ": ", 0
space BYTE " ", 0
menuPrompt   BYTE "==================", 0Dh, 0Ah
             BYTE "Todo List Menu:", 0Dh, 0Ah
             BYTE "==================", 0Dh, 0Ah
             BYTE "1. Add Task", 0Dh, 0Ah
             BYTE "2. View Tasks", 0Dh, 0Ah
             BYTE "3. Mark Task Completed", 0Dh, 0Ah
             BYTE "4. Edit Task", 0Dh, 0Ah
             BYTE "5. Remove Task", 0Dh, 0Ah
             BYTE "6. Exit", 0Dh, 0Ah
             BYTE "==================", 0Dh, 0Ah
             BYTE "Enter your choice: ", 0

; Prompt strings
descPrompt BYTE "Enter task description: ", 0
datePrompt BYTE "Enter task date (MM/DD/YYYY): ", 0
editPrompt BYTE "Enter task number to edit: ", 0
removePrompt BYTE "Enter task number to remove: ", 0
completePrompt BYTE "Enter task number to mark completed: ", 0

; Task management (parallel arrays)
taskDescriptions BYTE MAX_DESC_LENGTH * MAX_TASKS DUP(0)
taskDates BYTE MAX_DATE_LENGTH * MAX_TASKS DUP(0)
taskCompletionStatus BYTE MAX_TASKS DUP(0)
taskCount DWORD 0

; Additional error message strings
invalidChoiceMsg BYTE "Invalid choice. Try again.", 0Dh, 0Ah, 0
taskLimitMsg BYTE "Maximum task limit reached!", 0Dh, 0Ah, 0
noTasksMsg BYTE "No tasks in the list.", 0Dh, 0Ah, 0
invalidTaskMsg BYTE "Invalid task number.", 0Dh, 0Ah, 0
completedMsg BYTE "[completed]", 0
pendingMsg BYTE "[pending]", 0

.CODE

; Function Prototypes
AddTask PROTO 
ViewTasks PROTO 
MarkCompleted PROTO 
EditTask PROTO 
RemoveTask PROTO 

main PROC 
  call LoadTasks       ; Load tasks from file into memory
    jmp MainMenu
    ; Main menu loop
MainMenu:
    ; Display menu
    mov edx, OFFSET menuPrompt 
    call WriteString 

    ; Get user choice
    call ReadInt 

    ; Branch based on choice

    cmp eax, 1 
    je AddTaskLabel 
    cmp eax, 2 
    je ViewTasksLabel 
    cmp eax, 3 
    je MarkCompletedLabel 
    cmp eax, 4 
    je EditTaskLabel 
    cmp eax, 5 
    je RemoveTaskLabel 
    cmp eax, 6 
    je ExitLabel 

    ; Invalid choice handling
    call Crlf 
    mov edx, OFFSET invalidChoiceMsg 
    call WriteString 
    jmp MainMenu 

AddTaskLabel: 
    call AddTask 
    jmp MainMenu 

ViewTasksLabel: 
    call ViewTasks 
    jmp MainMenu 

MarkCompletedLabel: 
    call MarkCompleted 
    jmp MainMenu 

EditTaskLabel: 
    call EditTask 
    jmp MainMenu 

RemoveTaskLabel: 
    call RemoveTask 
    jmp MainMenu 

ExitLabel: 
  mov edx, OFFSET goodbyeMsg    ; add this
    call WriteString  
    call SaveTasks
    exit 

main ENDP 

; Function to add a new task
AddTask PROC 
    ; Check if max tasks reached
    mov eax, taskCount 
    cmp eax, MAX_TASKS 
    jae TaskLimitReached 

    ; Calculate memory offset for current task index (esi)
    mov esi, eax 

    ; Prompt for description and read it safely
    mov edx, OFFSET descPrompt 
    call WriteString 
    mov edx, OFFSET taskDescriptions 
    imul ebx, esi, MAX_DESC_LENGTH  
    add edx, ebx
    mov ecx, MAX_DESC_LENGTH - 1  
    call ReadString  
    mov byte ptr [edx + ecx], 0  ; Ensure null-termination for description

    ; Prompt for date and read it safely  
    mov edx, OFFSET datePrompt  
    call WriteString  
    mov edx, OFFSET taskDates  
    imul ebx, esi, MAX_DATE_LENGTH   
    add edx, ebx
    mov ecx, MAX_DATE_LENGTH - 1  
    call ReadString  
    mov byte ptr [edx + ecx], 0  ; Ensure null-termination for date

    ; Increment task count  
    inc taskCount  
    ret 

TaskLimitReached:  
    ; Display error message  
    mov edx, OFFSET taskLimitMsg  
    call WriteString  
    ret 

AddTask ENDP 


; Function to view all tasks
ViewTasks PROC 
    ; Check if there are no tasks
    .IF (taskCount == 0)
        mov edx, OFFSET noTasksMsg
        call WriteString
        ret
    .ENDIF

    ; Loop through each task and display
    mov ecx, 0           ; Task index
ViewLoop:
    ; Display task number
    mov eax, ecx
    inc eax
    call WriteDec
    mov al, '.'          ; Display a dot after the number
    call WriteChar
    mov al, ' '          ; Add a space
    call WriteChar

    ; Display task description
    mov edx, OFFSET taskDescriptions
    imul ebx, ecx, MAX_DESC_LENGTH
    add edx, ebx
    call WriteString
    
    ; Display colon and space
    mov al, ':'
    call WriteChar
    mov al, ' '
    call WriteChar

    ; Display task date
    mov edx, OFFSET taskDates
    imul ebx, ecx, MAX_DATE_LENGTH
    add edx, ebx
    call WriteString
    
    ; Display space
    mov al, ' '
    call WriteChar

    ; Display task status
    movzx eax, byte ptr [taskCompletionStatus + ecx]
    .IF (eax == 1)  ; Completed
        mov edx, OFFSET completedStr
    .ELSE           ; Pending
        mov edx, OFFSET pendingStr
    .ENDIF
    call WriteString

    ; New line
    call Crlf

    ; Move to next task
    inc ecx
    cmp ecx, taskCount
    jl ViewLoop

    ret
ViewTasks ENDP


; Function to mark a task as completed
MarkCompleted PROC  
   ; Prompt for task number  
   mov edx ,OFFSET completePrompt    
   call WriteString    
   call ReadInt    
   dec eax ; Convert to a zero-based index   

   ; Validate task number  
   .IF (eax < 0) || (eax >= taskCount)    
       mov edx ,OFFSET invalidTaskMsg    
       call WriteString    
       ret    
   .ENDIF   

   ; Mark task as completed   
   mov byte ptr [taskCompletionStatus + eax], 1    
   ret   

MarkCompleted ENDP 

; Function to edit a task
EditTask PROC USES eax ebx ecx edx
    ; Prompt for task number  
    mov edx, OFFSET editPrompt    
    call WriteString    
    call ReadInt    
    dec eax ; Convert to a zero-based index   

    ; Validate task number  
    .IF (eax < 0) || (eax >= taskCount)    
        mov edx, OFFSET invalidTaskMsg    
        call WriteString    
        ret    
    .ENDIF   

    ; Store the task index in a safe register
    mov ebx, eax

    ; Prompt for new description and read it safely  
    mov edx, OFFSET descPrompt    
    call WriteString    

    ; Calculate address for the task description
    mov edx, OFFSET taskDescriptions   
    imul eax, ebx, MAX_DESC_LENGTH   
    add edx, eax   

    ; Read new description
    mov ecx, MAX_DESC_LENGTH - 1   
    call ReadString    

    ; Null terminate new description manually  
    mov byte ptr [edx + ecx], 0    

    ; Prompt for new date and read it safely  
    mov edx, OFFSET datePrompt    
    call WriteString    

    ; Calculate address for the task date
    mov edx, OFFSET taskDates   
    imul eax, ebx, MAX_DATE_LENGTH   
    add edx, eax   

    ; Read new date
    mov ecx, MAX_DATE_LENGTH - 1   
    call ReadString    

    ; Null terminate new date manually  
    mov byte ptr [edx + ecx], 0    

    ; Set the task status to pending by default
    mov edx, OFFSET taskCompletionStatus
    mov byte ptr [edx + ebx], 0  ; 0 represents pending status

    ret  
EditTask ENDP 
; Function to remove a task
RemoveTask PROC USES eax ebx ecx edx esi edi
    ; Check if any tasks exist
    cmp taskCount, 0
    je NoTasks

    ; Prompt for task to remove
    mov edx, OFFSET removePrompt
    call WriteString
    call ReadInt
    dec eax               ; Convert to 0-based index

    ; Validate task number
    cmp eax, 0
    jl InvalidChoice
    cmp eax, taskCount
    jge InvalidChoice

    ; Store the index of task to remove
    mov ebx, eax

    ; Calculate number of tasks to shift
    mov ecx, taskCount
    dec ecx
    sub ecx, ebx          ; Number of tasks after the deleted task

    ; Shift descriptions
    .IF (ecx > 0)
        ; Source: tasks after the deleted task
        mov esi, ebx
        inc esi
        imul esi, MAX_DESC_LENGTH
        lea esi, taskDescriptions[esi]

        ; Destination: overwrite the task to be deleted
        mov edi, ebx
        imul edi, MAX_DESC_LENGTH
        lea edi, taskDescriptions[edi]
        
        ; Multiply shift count by description length
        push ecx
        imul ecx, MAX_DESC_LENGTH
        rep movsb
        pop ecx
    .ENDIF

    ; Shift dates (carefully preserving MM/DD/YYYY format)
    .IF (ecx > 0)
        ; Source: tasks after the deleted task
        mov esi, ebx
        inc esi
        imul esi, MAX_DATE_LENGTH
        lea esi, taskDates[esi]

        ; Destination: overwrite the task to be deleted
        mov edi, ebx
        imul edi, MAX_DATE_LENGTH
        lea edi, taskDates[edi]
        
        ; Multiply shift count by date length
        push ecx
        imul ecx, MAX_DATE_LENGTH
        rep movsb
        pop ecx
    .ENDIF

    ; Shift completion status
    .IF (ecx > 0)
        ; Source: tasks after the deleted task
        mov esi, ebx
        inc esi
        lea esi, taskCompletionStatus[esi]

        ; Destination: overwrite the task to be deleted
        mov edi, ebx
        lea edi, taskCompletionStatus[edi]
        
        ; Shift completion status
        rep movsb
    .ENDIF

    ; Zero out the last task's memory to prevent ghost data
    ; Clear description
    mov edi, OFFSET taskDescriptions
    imul eax, taskCount, MAX_DESC_LENGTH
    add edi, eax
    mov ecx, MAX_DESC_LENGTH
    mov al, 0
    rep stosb

    ; Clear date
    mov edi, OFFSET taskDates
    imul eax, taskCount, MAX_DATE_LENGTH
    add edi, eax
    mov ecx, MAX_DATE_LENGTH
    mov al, 0
    rep stosb

    ; Clear completion status
    mov edi, OFFSET taskCompletionStatus
    add edi, taskCount
    mov al, 0
    stosb

    ; Decrement task count
    dec taskCount

    ret

NoTasks:
    mov edx, OFFSET noTasksMsg
    call WriteString
    ret

InvalidChoice:
    mov edx, OFFSET invalidTaskMsg
    call WriteString
    ret
RemoveTask ENDP

LoadTasks PROC USES eax ebx ecx edx esi edi
    ; Reset task count
    mov taskCount, 0

    ; Open the file for reading
    mov edx, OFFSET filen
    call OpenInputFile
    .IF eax == INVALID_HANDLE_VALUE
        ; File doesn't exist or can't be opened, silently return
        ret
    .ENDIF

    mov handler, eax  ; Save file handle

    ; Read file contents into buffer
    mov edx, OFFSET fileBuffer
    mov ecx, 500  ; Buffer size
    call ReadFromFile
    .IF CARRY?  ; Check for read error
        call CloseFile
        ret
    .ENDIF

    ; Null-terminate the buffer
    mov byte ptr [fileBuffer + eax], 0

    ; Initialize parsing variables
    mov esi, OFFSET fileBuffer  ; Source index for parsing
    mov edi, 0  ; Task count index

ParseNextTask:
    ; Check buffer limits
    .IF (byte ptr [esi] == 0) || (edi >= MAX_TASKS)
        jmp LoadTasksDone
    .ENDIF

    ; Prepare task description buffer
    mov edx, OFFSET taskDescriptions
    imul ebx, edi, MAX_DESC_LENGTH
    add edx, ebx

    ; Skip leading whitespace
    .WHILE (byte ptr [esi] == ' ')
        inc esi
    .ENDW

    ; Copy description until ':'
    mov ecx, 0  ; Description length counter
    .WHILE (byte ptr [esi] != ':' && byte ptr [esi] != 0)
        mov al, [esi]
        mov [edx + ecx], al
        inc esi
        inc ecx
        .IF (ecx >= MAX_DESC_LENGTH - 1)
            .BREAK
        .ENDIF
    .ENDW
    mov byte ptr [edx + ecx], 0  ; Null terminate

    ; Skip ':'
    .IF (byte ptr [esi] == ':')
        inc esi
    .ENDIF

    ; Skip whitespace before date
    .WHILE (byte ptr [esi] == ' ')
        inc esi
    .ENDW

    ; Prepare date buffer
    mov edx, OFFSET taskDates
    imul ebx, edi, MAX_DATE_LENGTH
    add edx, ebx

    ; Copy date
    mov ecx, 0
    .WHILE (byte ptr [esi] != ' ' && byte ptr [esi] != 0)
        mov al, [esi]
        mov [edx + ecx], al
        inc esi
        inc ecx
        .IF (ecx >= MAX_DATE_LENGTH - 1)
            .BREAK
        .ENDIF
    .ENDW
    mov byte ptr [edx + ecx], 0  ; Null terminate

    ; Determine status
    .WHILE (byte ptr [esi] == ' ')
        inc esi
    .ENDW

    ; Check for status
    mov byte ptr [taskCompletionStatus + edi], 0  ; Default to pending

    .IF (byte ptr [esi] == '[')
        ; Compare status
        .IF (BYTE PTR [esi + 1] == 'c' || BYTE PTR [esi + 1] == 'C')
            ; Completed status
            mov byte ptr [taskCompletionStatus + edi], 1
        .ENDIF
    .ENDIF

    ; Find next line
    .WHILE (byte ptr [esi] != 0Ah && byte ptr [esi] != 0)
        inc esi
    .ENDW
    
    ; Move to next line if possible
    .IF (byte ptr [esi] == 0Ah)
        inc esi
    .ENDIF

    ; Increment task count
    inc edi
    jmp ParseNextTask

LoadTasksDone:
    ; Close the file
    mov eax, handler
    call CloseFile

    ; Update task count
    mov taskCount, edi
    ret
LoadTasks ENDP

; Enhanced SaveTasks Procedure
SaveTasks PROC USES eax ebx ecx edx esi edi
    ; Create/Open the file for writing
    mov edx, OFFSET filen
    call CreateOutputFile
    .IF eax == INVALID_HANDLE_VALUE
        ; Error creating file
        ret
    .ENDIF

    mov handler, eax  ; Save file handle

    ; Prepare to write tasks
    mov ecx, 0  ; Task index
    mov edi, OFFSET fileBuffer  ; Destination buffer

SaveLoop:
    .IF (ecx >= taskCount)
        jmp SaveTasksDone
    .ENDIF

    ; Prepare task description
    mov edx, OFFSET taskDescriptions
    imul ebx, ecx, MAX_DESC_LENGTH
    add edx, ebx

    ; Copy description to buffer
    mov esi, edx
    .WHILE (BYTE PTR [esi] != 0)
        mov al, [esi]
        mov [edi], al
        inc esi
        inc edi
    .ENDW

    ; Add colon and space
    mov BYTE PTR [edi], ':'
    inc edi
    mov BYTE PTR [edi], ' '
    inc edi

    ; Prepare and copy task date
    mov edx, OFFSET taskDates
    imul ebx, ecx, MAX_DATE_LENGTH
    add edx, ebx
    mov esi, edx

    .WHILE (BYTE PTR [esi] != 0)
        mov al, [esi]
        mov [edi], al
        inc esi
        inc edi
    .ENDW

    ; Add space before status
    mov BYTE PTR [edi], ' '
    inc edi

    ; Add status
    movzx eax, BYTE PTR [taskCompletionStatus + ecx]
    .IF (eax == 1)
        ; Completed status
        mov BYTE PTR [edi], '['
        inc edi
        mov BYTE PTR [edi], 'c'
        inc edi
        mov BYTE PTR [edi], 'o'
        inc edi
        mov BYTE PTR [edi], 'm'
        inc edi
        mov BYTE PTR [edi], 'p'
        inc edi
        mov BYTE PTR [edi], 'l'
        inc edi
        mov BYTE PTR [edi], 'e'
        inc edi
        mov BYTE PTR [edi], 't'
        inc edi
        mov BYTE PTR [edi], 'e'
        inc edi
        mov BYTE PTR [edi], 'd'
        inc edi
        mov BYTE PTR [edi], ']'
        inc edi
    .ELSE
        ; Pending status
        mov BYTE PTR [edi], '['
        inc edi
        mov BYTE PTR [edi], 'p'
        inc edi
        mov BYTE PTR [edi], 'e'
        inc edi
        mov BYTE PTR [edi], 'n'
        inc edi
        mov BYTE PTR [edi], 'd'
        inc edi
        mov BYTE PTR [edi], 'i'
        inc edi
        mov BYTE PTR [edi], 'n'
        inc edi
        mov BYTE PTR [edi], 'g'
        inc edi
        mov BYTE PTR [edi], ']'
        inc edi
    .ENDIF

    ; Add newline
    mov BYTE PTR [edi], 0Dh
    inc edi
    mov BYTE PTR [edi], 0Ah
    inc edi

    ; Move to next task
    inc ecx
    jmp SaveLoop

SaveTasksDone:
    ; Null-terminate the buffer
    mov BYTE PTR [edi], 0

    ; Calculate buffer length
    mov ecx, edi
    sub ecx, OFFSET fileBuffer

    ; Write buffer to file
    mov eax, handler
    mov edx, OFFSET fileBuffer
    call WriteToFile

    ; Close the file
    mov eax, handler
    call CloseFile
    ret
SaveTasks ENDP
END main