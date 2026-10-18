[org 0x0100]

jmp start

; 6 bits rate, 5 bits attempts, 5 bits entropy
obs:        dw 0x6552, 0x2C91, 0x7FA3
numObs:     db 3

; w1, w2, w3, bias per class
weights:    db  2, -3, -1, 10
            db  1,  4,  2,  0
            db -2,  5,  4, -5

; one slot per observation so nothing gets overwritten
normScore:  dw 0, 0, 0
susScore:   dw 0, 0, 0
atkScore:   dw 0, 0, 0
predFlag:   db 0, 0, 0

x1:         dw 0
x2:         dw 0
x3:         dw 0
prod:       dw 0      ; current multiply scratch
obsIndex:   db 0      ; cl/bx get reused below, need this in memory
bestFlag:   db 0

start:
    xor si, si          ; word offset into obs / score arrays
    mov byte [obsIndex], 0

process_loop:
    mov al, [obsIndex]
    cmp al, [numObs]
    jl continueObs
    jmp done
continueObs:

    mov bx, [obs + si]

; rate
    mov ax, bx
    shr ax, 10
    and ax, 003Fh
    sub ax, 20
    mov [x1], ax

; attempts
    mov ax, bx
    shr ax, 5
    and ax, 001Fh
    sub ax, 8
    mov [x2], ax

; entropy
    mov ax, bx
    and ax, 001Fh
    sub ax, 16
    mov [x3], ax

; NORMAL score
    xor dx, dx

    mov al, [weights]
    mov cl, al
    mov bx, [x1]
    mov word [prod], 0
mulN1:
    cmp cl, 0
    je mulN1done
    jl mulN1neg          ; negative weight, subtract instead
    mov ax, [prod]
    add ax, bx
    mov [prod], ax
    dec cl
    jmp mulN1
mulN1neg:
    mov ax, [prod]
    sub ax, bx
    mov [prod], ax
    inc cl
    jmp mulN1
mulN1done:
    mov ax, [prod]
    add dx, ax

    mov al, [weights + 1]
    mov cl, al
    mov bx, [x2]
    mov word [prod], 0
mulN2:
    cmp cl, 0
    je mulN2done
    jl mulN2neg
    mov ax, [prod]
    add ax, bx
    mov [prod], ax
    dec cl
    jmp mulN2
mulN2neg:
    mov ax, [prod]
    sub ax, bx
    mov [prod], ax
    inc cl
    jmp mulN2
mulN2done:
    mov ax, [prod]
    add dx, ax

    mov al, [weights + 2]
    mov cl, al
    mov bx, [x3]
    mov word [prod], 0
mulN3:
    cmp cl, 0
    je mulN3done
    jl mulN3neg
    mov ax, [prod]
    add ax, bx
    mov [prod], ax
    dec cl
    jmp mulN3
mulN3neg:
    mov ax, [prod]
    sub ax, bx
    mov [prod], ax
    inc cl
    jmp mulN3
mulN3done:
    mov ax, [prod]
    add dx, ax

; bias, just sign extend by hand and add
    mov al, [weights + 3]
    cmp al, 0
    jl biasNneg
    mov ah, 0
    jmp biasNdone
biasNneg:
    mov ah, 0FFh
biasNdone:
    add dx, ax

    mov [normScore + si], dx

; SUSPICIOUS score
    xor dx, dx

    mov al, [weights + 4]
    mov cl, al
    mov bx, [x1]
    mov word [prod], 0
mulS1:
    cmp cl, 0
    je mulS1done
    jl mulS1neg
    mov ax, [prod]
    add ax, bx
    mov [prod], ax
    dec cl
    jmp mulS1
mulS1neg:
    mov ax, [prod]
    sub ax, bx
    mov [prod], ax
    inc cl
    jmp mulS1
mulS1done:
    mov ax, [prod]
    add dx, ax

    mov al, [weights + 5]
    mov cl, al
    mov bx, [x2]
    mov word [prod], 0
mulS2:
    cmp cl, 0
    je mulS2done
    jl mulS2neg
    mov ax, [prod]
    add ax, bx
    mov [prod], ax
    dec cl
    jmp mulS2
mulS2neg:
    mov ax, [prod]
    sub ax, bx
    mov [prod], ax
    inc cl
    jmp mulS2
mulS2done:
    mov ax, [prod]
    add dx, ax

    mov al, [weights + 6]
    mov cl, al
    mov bx, [x3]
    mov word [prod], 0
mulS3:
    cmp cl, 0
    je mulS3done
    jl mulS3neg
    mov ax, [prod]
    add ax, bx
    mov [prod], ax
    dec cl
    jmp mulS3
mulS3neg:
    mov ax, [prod]
    sub ax, bx
    mov [prod], ax
    inc cl
    jmp mulS3
mulS3done:
    mov ax, [prod]
    add dx, ax

    mov al, [weights + 7]
    cmp al, 0
    jl biasSneg
    mov ah, 0
    jmp biasSdone
biasSneg:
    mov ah, 0FFh
biasSdone:
    add dx, ax

    mov [susScore + si], dx

; ATTACK score
    xor dx, dx

    mov al, [weights + 8]
    mov cl, al
    mov bx, [x1]
    mov word [prod], 0
mulA1:
    cmp cl, 0
    je mulA1done
    jl mulA1neg
    mov ax, [prod]
    add ax, bx
    mov [prod], ax
    dec cl
    jmp mulA1
mulA1neg:
    mov ax, [prod]
    sub ax, bx
    mov [prod], ax
    inc cl
    jmp mulA1
mulA1done:
    mov ax, [prod]
    add dx, ax

    mov al, [weights + 9]
    mov cl, al
    mov bx, [x2]
    mov word [prod], 0
mulA2:
    cmp cl, 0
    je mulA2done
    jl mulA2neg
    mov ax, [prod]
    add ax, bx
    mov [prod], ax
    dec cl
    jmp mulA2
mulA2neg:
    mov ax, [prod]
    sub ax, bx
    mov [prod], ax
    inc cl
    jmp mulA2
mulA2done:
    mov ax, [prod]
    add dx, ax

    mov al, [weights + 10]
    mov cl, al
    mov bx, [x3]
    mov word [prod], 0
mulA3:
    cmp cl, 0
    je mulA3done
    jl mulA3neg
    mov ax, [prod]
    add ax, bx
    mov [prod], ax
    dec cl
    jmp mulA3
mulA3neg:
    mov ax, [prod]
    sub ax, bx
    mov [prod], ax
    inc cl
    jmp mulA3
mulA3done:
    mov ax, [prod]
    add dx, ax

    mov al, [weights + 11]
    cmp al, 0
    jl biasAneg
    mov ah, 0
    jmp biasAdone
biasAneg:
    mov ah, 0FFh
biasAdone:
    add dx, ax

    mov [atkScore + si], dx

; pick winner, ties favor the lower class number
    mov ax, [normScore + si]
    mov byte [bestFlag], 1

    mov dx, [susScore + si]
    cmp dx, ax
    jle checkAtk
    mov ax, dx
    mov byte [bestFlag], 2

checkAtk:
    mov dx, [atkScore + si]
    cmp dx, ax
    jle storeFlag
    mov byte [bestFlag], 3

storeFlag:
    mov bl, [obsIndex]
    xor bh, bh
    mov al, [bestFlag]
    mov [predFlag + bx], al

nextObs:
    add si, 2
    inc byte [obsIndex]
    jmp process_loop

done:
    mov ax, 4C00h
    int 21h