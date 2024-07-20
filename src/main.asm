bits 64
default rel

extern MessageBoxA
extern ExitProcess
extern SelectObject 
extern DeleteObject 

extern RegisterClassA
extern DefWindowProcA 
extern CreateWindowExA  
extern PostQuitMessage  
extern ShowWindow  

extern GetMessageA  
extern TranslateMessage  
extern DispatchMessageA 
extern GetAsyncKeyState  

extern SetTimer 
extern KillTimer 

extern BeginPaint
extern EndPaint
extern CreateBitmap
extern CreateCompatibleDC
extern BitBlt 
extern DeleteDC 
extern InvalidateRect 
extern AdjustWindowRect 

section .text
global WinMain  

WinMain:     
    push rbp
    mov rbp, rsp
    sub rsp, 128 ; Reserve stack shadow space + Preallocate general stack space

    mov qword [wnd_hinstance], rcx

    ; struct WNDCLASSA wnd_class {
    ;   UINT      style;         @ dword [rsp+32]
    ;   WNDPROC   lpfnWndProc;   @ qword [rsp+40]
    ;   int       cbClsExtra;    @ dword [rsp+48]
    ;   int       cbWndExtra;    @ dword [rsp+52]
    ;   HINSTANCE hInstance;     @ qword [rsp+56]
    ;   HICON     hIcon;         @ qword [rsp+64]
    ;   HCURSOR   hCursor;       @ qword [rsp+72]
    ;   HBRUSH    hbrBackground; @ qword [rsp+80]
    ;   LPCSTR    lpszMenuName;  @ qword [rsp+88]
    ;   LPCSTR    lpszClassName; @ qword [rsp+96]
    ; }
    mov dword [rsp+32], 0
    lea rax, [WindowProc]
    mov qword [rsp+40], rax
    mov dword [rsp+48], 0
    mov dword [rsp+52], 0
    mov rax, qword [wnd_hinstance]
    mov qword [rsp+56], rax
    mov qword [rsp+64], 0
    mov qword [rsp+72], 0
    mov qword [rsp+80], 0
    mov qword [rsp+88], 0
    lea rax, [wnd_class_name]
    mov qword [rsp+96], rax
    lea rcx, [rsp+32]
    call RegisterClassA

    ; struct RECT @ [rsp+32] {
    ;     LONG left;   @ dword [rsp+32] 
    ;     LONG top;    @ dword [rsp+36]
    ;     LONG right;  @ dword [rsp+40]
    ;     LONG bottom; @ dword [rsp+44]
    ; }
    mov dword [rsp+32], 0
    mov dword [rsp+36], 0
    mov dword [rsp+40], wnd_width
    mov dword [rsp+44], wnd_height
    lea rcx, [rsp+32]
    mov edx, wnd_style
    mov r8d, 1
    call AdjustWindowRect

    ; adjusted_wnd_width @ r12d
    ; adjusted_wnd_height @ r13d
    mov r12d, dword [rsp+40]
    sub r12d, dword [rsp+32]
    sub r12d, 4 ; Compensate for error on Win11 (at least on my pc)
    mov r13d, dword [rsp+44]
    sub r13d, dword [rsp+36]
    sub r13d, 24 ; Compensate for error on Win11 (at least on my pc)

    mov ecx, 0
    lea rdx, [wnd_class_name]
    lea r8, [wnd_title]
    mov r9d, wnd_style
    mov dword [rsp + 32], 2147483648 ; CW_USEDEFAULT 
    mov dword [rsp + 40], 2147483648 ; CW_USEDEFAULT 
    mov dword [rsp + 48], r12d
    mov dword [rsp + 56], r13d
    mov qword [rsp + 64], 0 
    mov qword [rsp + 72], 0
    mov rax, qword [wnd_hinstance]
    mov qword [rsp + 80], rax
    mov qword [rsp + 88], 0
    call CreateWindowExA 

    test rax, rax
    jnz _win_main_window_correct

    mov rcx, 0
    lea rdx, [error_window_text]
    lea r8, [error_text]
    mov r9d, 0 ; MB_OK
    call MessageBoxA

    mov rcx, 1
    call ExitProcess ; Restores stack shadow space

_win_main_window_correct:
    mov qword [wnd_hwnd], rax

    mov rcx, qword [wnd_hwnd]
    mov edx, 1 ; SW_SHOWNORMAL
    call ShowWindow

    mov rcx, qword [wnd_hwnd]
    mov rdx, 1
    mov r8, timer_interval_ms
    mov r9, 0
    call SetTimer

    test rax, rax
    jnz _win_main_timer_correct

    mov rcx, 0
    lea rdx, [error_timer_text]
    lea r8, [error_text]
    mov r9d, 0 ; MB_OK
    call MessageBoxA

    mov rcx, 2
    call ExitProcess ; Restores stack shadow space

_win_main_timer_correct:

    ; x @ r12
    ; y @ r13
    xor r13, r13
_win_main_texgen_y_loop_start:
    xor r12, r12
_win_main_texgen_x_loop_start:
    ; Paint pixel at [(y*world_texture_height + x) * 4 + world_textures]
    mov rcx, r12
    imul rcx, world_texture_height
    add rcx, r13
    shl rcx, 2
    lea rdx, [world_textures]

; tex 0
    add rcx, rdx

    ; y
    xor edx, edx
    mov eax, r13d
    shr eax, 3
    and eax, 1
    add eax, 1
    shl eax, 7
    sub eax, 1
    shl eax, 16
    add edx, eax

    ; x
    mov eax, r12d
    shr eax, 4
    and eax, 1
    add eax, 1
    shl eax, 7
    sub eax, 1
    shl eax, 16
    add edx, eax

    and edx, 0x00FFFFFF
    mov dword [rcx], edx
; tex 1
    add rcx, world_texture_width*world_texture_height*4
    
    xor edx, edx
    add edx, r12d
    add edx, r13d
    and edx, 8
    shr edx, 3
    imul edx, 0xff
    shl edx, 8 ; set G
    mov eax, edx
    shl eax, 8 ; set R
    or edx, eax

    and edx, 0x00FFFFFF
    mov dword [rcx], edx
; tex 2
    add rcx, world_texture_width*world_texture_height*4

    xor edx, edx
    add edx, r12d
    add edx, r13d
    and edx, 16
    shr edx, 4
    add ebx, r13d
    sub ebx, r12d
    and ebx, 16
    shr ebx, 4
    or edx, ebx
    imul edx, 0xff
    shl edx, 0 ; set B
    mov eax, edx
    shl eax, 16 ; set R
    or edx, eax
    
    and edx, 0x00FFFFFF
    mov dword [rcx], edx
; tex 3
    add rcx, world_texture_width*world_texture_height*4

    xor edx, edx
    mov eax, r12d
    shl eax, 2
    xor edx, eax
    mov eax, r13d
    shl eax, 2
    xor edx, eax
    shl edx, 2
    
    and edx, 0x00FFFFFF
    mov dword [rcx], edx

    inc r12
    cmp r12, world_texture_width
    jl _win_main_texgen_x_loop_start

    inc r13
    cmp r13, world_texture_height
    jl _win_main_texgen_y_loop_start

    ; msg_struct @ [rsp+32]

_win_main_start_msg_loop:
    lea rcx, [rsp+32]
    mov rdx, 0
    mov r8, 0
    mov r9, 0
    call GetMessageA

    cmp rax, 1
    jl _win_main_end_msg_loop ; if GetMessage(...) < 1, end loop  

    lea rcx, [rsp+32]
    call TranslateMessage

    lea rcx, [rsp+32]
    call DispatchMessageA

    jmp _win_main_start_msg_loop
_win_main_end_msg_loop:

    mov rcx, qword [wnd_hwnd]
    mov rdx, 1
    call KillTimer

    mov rcx, 0
    call ExitProcess ; Restores stack shadow space

; LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
; rcx - HWND (8 bytes)
; edx - UINT (4 bytes)
; r8 - UINT_PTR (8 bytes)
; r9 - LONG_PTR (int64) (8 bytes)
WindowProc:
    ; If handled properly return 0
    push rbp
    mov rbp, rsp
    sub rsp, 192

    cmp edx, 0x0113 ; WM_TIMER
    je _window_proc_timer

    cmp edx, 0x000f ; WM_PAINT
    je _window_proc_paint

    cmp edx, 0x0002 ; WM_DESTROY
    je _window_proc_destroy

    ; If no action is needed return DefWindowProcA(hwnd, uMsg, wParam, lParam);
    call DefWindowProcA
    jmp _window_proc_ret

_window_proc_timer:
    ; Key Up Arrow
    mov ecx, 0x26
    call GetAsyncKeyState 

    bt ax, 15 ; MSB set if key down
    jnc _window_proc_timer_up_not_pressed
    movss xmm0, dword [camera_move_speed]
    call MoveCameraForward
_window_proc_timer_up_not_pressed:

    ; Key Down Arrow
    mov ecx, 0x28
    call GetAsyncKeyState 

    bt ax, 15 ; MSB set if key down
    jnc _window_proc_timer_down_not_pressed
    mov eax, dword [camera_move_speed]
    xor eax, 0x80000000 ; Negate the last bit, that negates the float
    movd xmm0, eax
    call MoveCameraForward
_window_proc_timer_down_not_pressed:

    ; Key Left Arrow
    mov ecx, 0x25
    call GetAsyncKeyState 

    bt ax, 15 ; MSB set if key down
    jnc _window_proc_timer_left_not_pressed
    movss xmm0, dword [camera_rotate_speed]
    call RotateCameraLeft
_window_proc_timer_left_not_pressed:
    ; Key Right Arrow
    mov ecx, 0x27
    call GetAsyncKeyState 

    bt ax, 15 ; MSB set if key down
    jnc _window_proc_timer_right_not_pressed
    mov eax, dword [camera_rotate_speed]
    xor eax, 0x80000000 ; Negate the last bit, that negates the float
    movd xmm0, eax
    call RotateCameraLeft
_window_proc_timer_right_not_pressed:

    mov rcx, qword [wnd_hwnd]
    mov rdx, 0
    mov r8d, 0
    call InvalidateRect ; Redraw the window

    mov rax, 0
    jmp _window_proc_ret
_window_proc_destroy:
    mov rcx, 0
    call PostQuitMessage

    mov rax, 0
    jmp _window_proc_ret
_window_proc_paint:
    ; paint_struct @ [rsp+104]

    mov rcx, qword [wnd_hwnd]
    lea rdx, [rsp+104]
    call BeginPaint

    ; paint_hdc @ qword [rsp+96]
    mov qword [rsp+96], rax

    mov ecx, 0
    mov edx, wnd_height/2
    mov r8d, world_ceiling_color
    call FillCanvasRows

    mov ecx, wnd_height/2
    mov edx, wnd_height
    mov r8d, world_floor_color
    call FillCanvasRows

    call RaycastWorld

    ; http://parallel.vub.ac.be/education/modula2/technology/Win32_tutorial/bitmaps.html
    mov ecx, wnd_width 
    mov edx, wnd_height
    mov r8d, 1
    mov r9d, 32
    lea rax, [bitmap_data]
    mov qword [rsp+32], rax
    call CreateBitmap

    ; bitmap @ qword [rsp+72]
    mov qword [rsp+72], rax

    mov rcx, qword [rsp+96]
    call CreateCompatibleDC

    ; bitmap_hdc @ qword [rsp+80]
    mov qword [rsp+80], rax

    mov rcx, qword [rsp+80]
    mov rdx, qword [rsp+72]
    call SelectObject

    ; hbitmap_old @ qword [rsp+88]
    mov qword [rsp+88], rax 

    mov rcx, qword [rsp+96]
    mov edx, 0
    mov r8d, 0
    mov r9d, wnd_width
    mov dword [rsp+32], wnd_height
    mov rax, qword [rsp+80]
    mov qword [rsp+40], rax
    mov dword [rsp+48], 0
    mov dword [rsp+56], 0
    mov dword [rsp+64], 0x00CC0020 ; SRCCOPY
    call BitBlt

    mov rcx, qword [rsp+80]
    mov rdx, qword [rsp+88]
    call SelectObject

    mov rcx, qword [rsp+80]
    call DeleteDC

    mov rcx, qword [rsp+72]
    call DeleteObject

    mov rcx, qword [wnd_hwnd]
    lea rdx, [rsp+104]
    call EndPaint

    mov rax, 0
    jmp _window_proc_ret
    
_window_proc_ret:
    add rsp, 192
    pop rbp
    ret

; y_begin_inclusive @ ecx
; y_end_exclusive @ edx
; fill_color @ r8d
FillCanvasRows:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov qword [rsp+32], r12 ; save r12

    ; x @ r12
    ; y @ ecx
_fill_canvas_rows_y_loop_start:
    xor r12, r12
_fill_canvas_rows_x_loop_start:
    ; Paint pixel at [(y*wnd_width + x) * 4 + bitmap_data]
    mov ebx, ecx
    imul rbx, wnd_width
    add rbx, r12
    shl rbx, 2 ; imul rbx, 4
    lea rax, [bitmap_data]
    add rbx, rax
    mov dword [rbx], r8d ; Fill screen with color

    inc r12
    cmp r12, wnd_width
    jl _fill_canvas_rows_x_loop_start

    inc ecx
    cmp ecx, edx
    jl _fill_canvas_rows_y_loop_start

    mov r12, qword [rsp+32] ; restore r12

    add rsp, 40
    pop rbp
    ret

RaycastWorld:
    push rbp
    mov rbp, rsp
    sub rsp, 144

    ; x @ r12
    xor r12, r12

    ; https://lodev.org/cgtutor/raycasting.html
_raycast_x_loop:
    mov eax, r12d
    shl eax, 1

    ; camera_x_view_space @ xmm0
    ; camera_x_view_space = 2 * x / float(wnd_width-1) - 1
    ; maybe wnd_width instead of wnd_width-1?
    cvtsi2ss xmm0, eax
    mov eax, wnd_width
    dec eax
    cvtsi2ss xmm1, eax
    divss xmm0, xmm1

    mov eax, 0x3F800000 ; 1.0f
    movd xmm1, eax
    subss xmm0, xmm1

    ; ray_dir_x @ xmm1
    movss xmm1, xmm0
    mulss xmm1, dword [camera_plane_x]
    addss xmm1, dword [camera_dir_x]

    ; ray_dir_y @ xmm2
    movss xmm2, xmm0
    mulss xmm2, dword [camera_plane_y]
    addss xmm2, dword [camera_dir_y]

    ; ray_pos_x_i @ dword [rsp+56]
    cvttss2si eax, dword [camera_pos_x] 
    mov dword [rsp+56], eax

    ; ray_pos_y_i @ dword [rsp+64]
    cvttss2si eax, dword [camera_pos_y] 
    mov dword [rsp+64], eax
    
    ; delta_dist_x @ xmm3
    movd eax, xmm1
    and eax, 0x7FFFFFFF ; all 1s except for the left-most bit ; gets rid of negative 0
    test eax, eax
    jnz _ray_dir_x_nonzero ; if ray_dir_x != 0
_ray_dir_x_zero:
    mov eax, 0x7F800000 ; +Inf
    movd xmm3, eax
    jmp _ray_dir_x_nonzero_post
_ray_dir_x_nonzero:
    mov eax, 0x3F800000 ; 1.0f
    movd xmm5, eax
    divss xmm5, xmm1 ; 1.0 / ray_dir_x
    movss xmm3, xmm5

    mov eax, 0x7FFFFFFF ; all 1s except for the left-most bit
    movd xmm5, eax
    andps xmm3, xmm5 ; abs(xmm3)
_ray_dir_x_nonzero_post:

    ; delta_dist_y @ xmm4
    movd eax, xmm2
    and eax, 0x7FFFFFFF ; all 1s except for the left-most bit ; gets rid of negative 0
    test eax, eax
    jnz _ray_dir_y_nonzero ; if ray_dir_y != 0
_ray_dir_y_zero:
    mov eax, 0x7F800000 ; +Inf
    movd xmm4, eax
    jmp _ray_dir_y_nonzero_post
_ray_dir_y_nonzero:
    mov eax, 0x3F800000 ; 1.0f
    movd xmm5, eax
    divss xmm5, xmm2 ; 1.0 / ray_dir_y
    movss xmm4, xmm5

    mov eax, 0x7FFFFFFF ; all 1s except for the left-most bit
    movd xmm5, eax
    andps xmm4, xmm5 ; abs(xmm4)
_ray_dir_y_nonzero_post:

    ; step_x @ dword [rsp+72]
    ; step_y @ dword [rsp+80]
    
    ; side_dist_x @ xmm7
    ; side_dist_y @ xmm8
    
    movd eax, xmm1
    bt eax, 31 ; check last bit of ray_dir_x (negative/positive)
    jc _ray_dir_x_negative ; if ray_dir_x < 0
_ray_dir_x_positive:
    mov dword [rsp+72], 1

    cvtsi2ss xmm7, dword [rsp+56]
    mov eax, 0x3F800000
    movd xmm9, eax
    addss xmm7, xmm9
    subss xmm7, dword [camera_pos_x]
    mulss xmm7, xmm3

    jmp _ray_dir_x_negative_post
_ray_dir_x_negative:
    mov dword [rsp+72], -1

    movss xmm7, dword [camera_pos_x]
    cvtsi2ss xmm9, dword [rsp+56]
    subss xmm7, xmm9
    mulss xmm7, xmm3
_ray_dir_x_negative_post:

    movd eax, xmm2
    bt eax, 31 ; check last bit of ray_dir_y (negative/positive)
    jc _ray_dir_y_negative ; if ray_dir_y < 0
_ray_dir_y_positive:
    mov dword [rsp+80], 1

    cvtsi2ss xmm8, dword [rsp+64]
    mov eax, 0x3F800000
    movd xmm9, eax
    addss xmm8, xmm9
    subss xmm8, dword [camera_pos_y]
    mulss xmm8, xmm4

    jmp _ray_dir_y_negative_post
_ray_dir_y_negative:
    mov dword [rsp+80], -1

    movss xmm8, dword [camera_pos_y]
    cvtsi2ss xmm9, dword [rsp+64]
    subss xmm8, xmm9
    mulss xmm8, xmm4
_ray_dir_y_negative_post:

    ; side @ dword [rsp+88]

_ray_dda_start: 
    movss xmm12, xmm7
    cmpss xmm12, xmm8, 0x1 ; if side_dist_x < side_dist_y
    movd eax, xmm12
    test eax, eax
    jnz _ray_side_dist_x_less

_ray_side_dist_x_greater:
    addss xmm8, xmm4
    mov eax, dword [rsp+80]
    add dword [rsp+64], eax ; ray_pos_y_i += step_y
    mov dword [rsp+88], 1
    jmp _ray_side_dist_post
_ray_side_dist_x_less:
    addss xmm7, xmm3
    mov eax, dword [rsp+72]
    add dword [rsp+56], eax ; ray_pos_x_i += step_x
    mov dword [rsp+88], 0
_ray_side_dist_post:

    mov eax, dword [rsp+64]
    mov ecx, world_width
    imul eax, ecx
    add eax, dword [rsp+56]
    lea rcx, [world_data]
    add rcx, rax
    mov al, byte [rcx]
    test al, al
    jz _ray_dda_start ; if (world_data[ray_pos_y_i * world_width + ray_pos_x_i] == 0) repeat

    ; wall_dist @ xmm9
    ; wall_coord_u @ xmm5
    mov eax, dword [rsp+88]
    test eax, eax
    jnz _ray_side_one
_ray_side_zero:
    movss xmm9, xmm7
    subss xmm9, xmm3
    movss xmm5, xmm2
    mulss xmm5, xmm9
    addss xmm5, dword [camera_pos_y]
    jmp _ray_side_post
_ray_side_one:
    movss xmm9, xmm8
    subss xmm9, xmm4
    movss xmm5, xmm1
    mulss xmm5, xmm9
    addss xmm5, dword [camera_pos_x]
_ray_side_post:
    cvttss2si eax, xmm5 ; if wall_coord_u is ever negative, it will be buggy, luckily it shouldn't be ever negative
    cvtsi2ss xmm10, eax
    subss xmm5, xmm10

    ; texture_x_i @ dword [rsp+120]
    mov eax, world_texture_width
    cvtsi2ss xmm10, eax
    mulss xmm10, xmm5
    cvttss2si eax, xmm10
    mov dword [rsp+120], eax

    mov eax, 0
    movd xmm11, eax
    movss xmm10, xmm1
    cmpss xmm10, xmm11, 14 ; xay_dir_x > 0
    movd eax, xmm10
    and eax, 1
    mov ecx, dword [rsp+88]
    xor ecx, 1
    and eax, ecx ; if side == 0 and ray_dir_x > 0
    test eax, eax
    jnz _ray_wrap_texture_x_i

    mov eax, 0
    movd xmm11, eax
    movss xmm10, xmm2
    cmpss xmm10, xmm11, 1 ; xay_dir_y < 0
    movd eax, xmm10
    and eax, 1
    mov ecx, dword [rsp+88]
    and eax, ecx ; if side == 1 and ray_dir_y < 0
    test eax, eax
    jz _ray_not_wrap_texture_x_i

_ray_wrap_texture_x_i:
    mov eax, world_texture_width
    sub eax, dword [rsp+120]
    sub eax, 1
    mov dword [rsp+120], eax
_ray_not_wrap_texture_x_i:

    ; line_height @ dword [rsp+96]
    mov eax, wnd_height
    cvtsi2ss xmm10, eax
    divss xmm10, xmm9
    cvttss2si eax, xmm10
    mov dword [rsp+96], eax

    ; if line_height is greater than or equal to the screen height, draw a line from top to bottom
    cmp dword [rsp+96], wnd_height
    jge _ray_line_height_ge

    ; draw_start @ dword [rsp+104]
    ; draw_end @ dword [rsp+112]
_ray_line_height_less:
    mov edx, eax
    shr edx, 1

    mov eax, wnd_height / 2
    mov ecx, wnd_height / 2

    sub eax, edx
    add ecx, edx

    jmp _ray_line_height_post
_ray_line_height_ge:
    mov eax, 0
    mov ecx, wnd_height
_ray_line_height_post:
    mov dword [rsp+104], eax
    mov dword [rsp+112], ecx

    ; texture_step @ xmm6
    mov eax, world_texture_height
    cvtsi2ss xmm6, eax
    cvtsi2ss xmm10, dword [rsp+96]
    divss xmm6, xmm10

    ; texture_y @ xmm10 = (drawStart - h / 2 + lineHeight / 2) * step
    mov ecx, wnd_height
    add ecx, dword [rsp+96]
    shr ecx, 1
    mov eax, dword [rsp+104]
    sub eax, ecx
    add eax, 1
    cvtsi2ss xmm10, eax
    mulss xmm10, xmm6

    ; texture_id @ dword [rsp+128]
    mov eax, dword [rsp+64]
    mov ecx, world_width
    imul eax, ecx
    add eax, dword [rsp+56]
    lea rcx, [world_data]
    add rcx, rax
    mov al, byte [rcx] ; texture_id = world_data[ray_pos_y_i * world_width + ray_pos_x_i] - 1
    sub al, 1
    mov dword [rsp+128], eax

    mov r13d, dword [rsp+104]
    cmp r13d, dword [rsp+112]
    jge _ray_draw_line_end

_ray_draw_line_start:
    ; texture_y_i @ edx
    cvttss2si edx, xmm10
    mov eax, world_texture_height
    sub eax, 1
    sub edx, 1 ; offset by 1 down
    and edx, eax

    addss xmm10, xmm6

    ; draw_color @ edx
    mov ecx, world_texture_width * world_texture_height
    imul ecx, dword [rsp+128]
    mov eax, world_texture_height
    imul eax, dword [rsp+120] ; texture_x_i
    add eax, edx ; texture_y_i
    add eax, ecx
    shl eax, 2 ; eax = (world_texture_width * world_texture_height * texture_id + texture_y_i * world_texture_height + texture_x) * 4
    lea rcx, [world_textures]
    add rcx, rax
    mov edx, dword [rcx]

    mov eax, dword [rsp+88]
    test eax, eax
    jnz _ray_side_nonzero_color

    shr edx, 1
    and edx, 0x7F7F7F7F
_ray_side_nonzero_color:

    ; Paint pixel at [(y*wnd_width + x) * 4 + bitmap_data]
    mov rcx, r13
    imul rcx, wnd_width
    add rcx, r12
    shl rcx, 2 ; imul rax, 4
    lea rax, [bitmap_data]
    add rcx, rax
    mov dword [rcx], edx ; Fill screen with color

    inc r13
    cmp r13d, dword [rsp+112]
    jl _ray_draw_line_start
_ray_draw_line_end:
    inc r12
    cmp r12, wnd_width
    jl _raycast_x_loop

    add rsp, 144
    pop rbp
    ret

; dist_delta @ xmm0
MoveCameraForward:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    movss xmm1, dword [camera_dir_x]
    vfmadd213ss xmm1, xmm0, dword [camera_pos_x] ; multiply xmm1 by xmm0, add camera_pos_x and store in xmm1, Haswell (2013) or newer generation CPUs needed

    ; prevent from walking into walls in X
    cvttss2si eax, dword [camera_pos_y]
    mov ecx, world_width
    imul eax, ecx
    cvttss2si ecx, xmm1
    add eax, ecx
    lea rcx, [world_data]
    add rcx, rax
    mov al, byte [rcx]
    test al, al
    jnz _move_camera_forward_x_invalid

    movss dword [camera_pos_x], xmm1
_move_camera_forward_x_invalid:

    movss xmm1, dword [camera_dir_y]
    vfmadd213ss xmm1, xmm0, dword [camera_pos_y] ; multiply xmm1 by xmm0, add camera_pos_y and store in xmm1, Haswell (2013) or newer generation CPUs needed

    ; prevent from walking into walls in Y
    cvttss2si eax, xmm1
    mov ecx, world_width
    imul eax, ecx
    cvttss2si ecx, dword [camera_pos_x]
    add eax, ecx
    lea rcx, [world_data]
    add rcx, rax
    mov al, byte [rcx]
    test al, al
    jnz _move_camera_forward_y_invalid

    movss dword [camera_pos_y], xmm1
_move_camera_forward_y_invalid:

    add rsp, 32
    pop rbp
    ret

; rad_delta @ xmm0
RotateCameraLeft:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    movss xmm2, xmm0

    fninit

    ; sin(rad_delta) @ xmm0
    movss dword [fld_temp], xmm2
    fld dword [fld_temp]
    fsin 
    fstp dword [fld_temp]
    movss xmm0, dword [fld_temp]
    
    ; cos(rad_delta) @ xmm1
    movss dword [fld_temp], xmm2
    fld dword [fld_temp]
    fcos 
    fstp dword [fld_temp]
    movss xmm1, dword [fld_temp]

    ; old_dir_x @ xmm2
    ; old_dir_y @ xmm3
    movss xmm2, dword [camera_dir_x]
    movss xmm3, dword [camera_dir_y]

    movss xmm4, xmm2
    mulss xmm4, xmm1
    movss xmm5, xmm3
    mulss xmm5, xmm0
    subss xmm4, xmm5
    movss dword [camera_dir_x], xmm4

    movss xmm4, xmm2
    mulss xmm4, xmm0
    movss xmm5, xmm3
    mulss xmm5, xmm1
    addss xmm4, xmm5
    movss dword [camera_dir_y], xmm4

    ; old_plane_x @ xmm2
    ; old_plane_y @ xmm3
    movss xmm2, dword [camera_plane_x]
    movss xmm3, dword [camera_plane_y]

    movss xmm4, xmm2
    mulss xmm4, xmm1
    movss xmm5, xmm3
    mulss xmm5, xmm0
    subss xmm4, xmm5
    movss dword [camera_plane_x], xmm4

    movss xmm4, xmm2
    mulss xmm4, xmm0
    movss xmm5, xmm3
    mulss xmm5, xmm1
    addss xmm4, xmm5
    movss dword [camera_plane_y], xmm4

    ; dir_x = old_dir_x * cos(rad_delta) - old_dir_y * sin(rad_delta)
    ; dir_y = old_dir_x * sin(rad_delta) + old_dir_y * cos(rad_delta)
    ; plane_x = old_plane_x * cos(rad_delta) - old_plane_y * sin(rad_delta)
    ; plane_y = old_plane_x * sin(rad_delta) + old_plane_y * cos(rad_delta)

    add rsp, 32
    pop rbp
    ret

section .bss
align 16
    bitmap_data: resd wnd_width*wnd_height
    world_textures: resd world_texture_width*world_texture_height*8

    fld_temp: resq 1

section .data
align 4
    camera_move_speed: dd 0.05 
    camera_rotate_speed: dd 0.05 

    camera_pos_x: dd 6.0
    camera_pos_y: dd 4.0 
    camera_dir_x: dd -1.0
    camera_dir_y: dd 0.0
    camera_plane_x: dd 0.0
    camera_plane_y: dd 0.66

align 8
    wnd_hwnd: dq 0
    wnd_hinstance: dq 0

section .rodata
align 16
    world_data: 
align 1
    world_data_row0: db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    world_data_row1: db 1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 1
    world_data_row2: db 1, 0, 2, 2, 2, 0, 0, 0, 0, 3, 3, 0, 0, 0, 0, 1
    world_data_row3: db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
    world_data_row4: db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1
    world_data_row5: db 1, 0, 2, 2, 2, 0, 0, 0, 4, 4, 4, 4, 4, 0, 0, 1
    world_data_row6: db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1
    world_data_row7: db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1
    world_data_row8: db 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 1
    world_data_row9: db 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1

align 4
    world_floor_color: equ 0x00525252
    world_ceiling_color: equ 0x0094BCF7
    world_texture_width: equ 64
    world_texture_height: equ 64

    timer_interval_ms: equ 10

    world_width: equ 16
    world_height: equ 10

    wnd_width: equ 1280
    wnd_height: equ 720

    wnd_style: equ 0x00CA0000 ; WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_BORDER | WS_MINIMIZEBOX

    wnd_title: db "x64 Assembly Raycaster", 0         
    wnd_class_name: db "Window Class", 0           

    error_text: db "Error", 0
    error_timer_text: db "Failed to create a timer!", 0
    error_window_text: db "Failed to create a window!", 0