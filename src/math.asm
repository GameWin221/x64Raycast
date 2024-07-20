; https://www.desmos.com/calculator/ee5rh7otur
; https://en.wikipedia.org/wiki/Taylor_series
; Approximating trigonometric functions with Taylor series works perfectly good for values near zero. 
; The camera rotates by at most 0.05 radians per frame so there is no difference between this and an accurate sin / cos implementation.

; x @ xmm0
; ret @ xmm0
; Approximate sin(x), almost flawless (max 0.3% error) when x is in range: [-pi/4, pi/4], doesn't work at all if x is not in range [-pi/2, pi/2]
ApproxSin:
    push rbp
    mov rbp, rsp
    sub rsp, 64
    movdqu [rsp+32], xmm1 ; save xmm1
    movdqu [rsp+48], xmm2 ; save xmm2
    movdqu [rsp+56], xmm3 ; save xmm3

    movss xmm1, xmm0
    mulss xmm1, xmm1

    mov eax, 0x3F800000 ; 1.0
    movd xmm3, eax

    mov eax, 0x3E2AAAAB ; 1/6
    movd xmm2, eax

    vfnmadd213ss xmm1, xmm2, xmm3 ; xmm1 = -(x*x)*(1/6) + 1

    mulss xmm1, xmm0
    movss xmm0, xmm1

    movdqu xmm3, [rsp+56] ; restore xmm3
    movdqu xmm2, [rsp+48] ; restore xmm2
    movdqu xmm1, [rsp+32] ; restore xmm1
    add rsp, 64
    pop rbp
    ret

; x @ xmm0
; ret @ xmm0
; Approximate cos(x), almost flawless (max 2% error) when x is in range: [-pi/4, pi/4], doesn't work at all if x is not in range [-pi/2, pi/2]
ApproxCos:
    push rbp
    mov rbp, rsp
    sub rsp, 56
    movdqu [rsp+32], xmm1 ; save xmm1
    movdqu [rsp+48], xmm2 ; save xmm2

    mov eax, 0x3F800000 ; 1.0
    movd xmm2, eax

    mov eax, 0x3F000000 ; 0.5
    movd xmm1, eax

    mulss xmm0, xmm0
    vfnmadd213ss xmm0, xmm1, xmm2 ; xmm0 = -(x*x)*(1/2) + 1

    movdqu xmm3, [rsp+56] ; restore xmm3
    movdqu xmm2, [rsp+48] ; restore xmm2
    add rsp, 56
    pop rbp
    ret