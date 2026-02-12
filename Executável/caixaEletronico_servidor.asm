.data
buffer: .space 64

mensagem_ok: .asciiz "OK\n"
mensagem_erro: .asciiz "ERRO\n"
mensagem_saldo: .asciiz "SALDO "
mensagem_quebraLinha: .asciiz "\n"

conta1:
    .word 1234              # numero da conta
    .word 1111              # senha
    .word 0                 # tentativas
    .word 0                 # bloqueada (0 é não e 1 sim)
    .word 1000              # saldo
    .word 0                 # índice do extrato
    .word 0,0,0,0,0         # extrato (últimas 5 transações)

conta2:                     # conta 2 segue a mesma lógica da conta 1
    .word 5678
    .word 2222
    .word 0
    .word 0
    .word 500
    .word 0
    .word 0,0,0,0,0

.text
.globl main 

main:
    move $s0, $zero         # nenhuma conta logada

loop:
    li $v0, 8
    la $a0, buffer
    li $a1, 64
    syscall

    lb $t0, buffer

    beq $t0, 'L', login
    beq $t0, 'S', verificar_saldo
    beq $t0, 'D', deposito
    beq $t0, 'A', saque
    beq $t0, 'E', extrato
    beq $t0, 'O', sair
    beq $t0, 'X', encerrar

    j loop

login:
    li $v0, 5               # ler numero da conta
    syscall
    move $t0, $v0

    li $v0, 5               # ler senha
    syscall
    move $t4, $v0

    la $t1, conta1
    lw $t2, 0($t1)
    beq $t0, $t2, conta_ok

    la $t1, conta2
    lw $t2, 0($t1)
    beq $t0, $t2, conta_ok

    j erro

conta_ok:
    lw $t3, 12($t1)         # verifica bloqueio
    beq $t3, 1, erro

    lw $t5, 4($t1)          # verifica senha
    bne $t4, $t5, erro

    sw $zero, 8($t1)        # zera tentativas
    move $s0, $t1           # salva conta logada

    li $v0, 4
    la $a0, mensagem_ok
    syscall
    j loop

verificar_saldo:
    beq $s0, $zero, erro

    lw $t1, 16($s0)         # saldo

    li $v0, 4
    la $a0, mensagem_saldo
    syscall

    lw $t1, 16($s0)

    li $v0, 1
    move $a0, $t1
    syscall

    li $v0, 4
    la $a0, mensagem_quebraLinha
    syscall

    li $v0, 4
    la $a0, mensagem_ok
    syscall

    j loop

deposito:
    beq $s0, $zero, erro

    li $v0, 5
    syscall
    move $t1, $v0

    blez $t1, erro

    lw $t2, 16($s0)
    add $t2, $t2, $t1
    sw $t2, 16($s0)

    jal registrar_extrato

    li $v0, 4
    la $a0, mensagem_ok
    syscall
    j loop

saque:
    beq $s0, $zero, erro

    li $v0, 5
    syscall
    move $t1, $v0

    blez $t1, erro

    lw $t2, 16($s0)
    blt $t2, $t1, erro

    sub $t2, $t2, $t1
    sw $t2, 16($s0)

    # cria valor negativo apenas para o extrato
    sub $t7, $zero, $t1
    move $t1, $t7
    jal registrar_extrato

    # restaura $t1 (boa prática)
    sub $t1, $zero, $t7

    li $v0, 4
    la $a0, mensagem_ok
    syscall
    j loop

extrato:
    beq $s0, $zero, erro

    addi $t0, $s0, 24
    li $t1, 0

ext_loop:
    beq $t1, 5, extrato_fim

    sll $t2, $t1, 2
    add $t3, $t0, $t2
    lw $t4, 0($t3)

    beq $t4, $zero, ext_next

    li $v0, 1
    move $a0, $t4
    syscall

    li $v0, 4
    la $a0, mensagem_quebraLinha
    syscall

ext_next:
    addi $t1, $t1, 1
    j ext_loop

extrato_fim:
    li $v0, 4
    la $a0, mensagem_ok
    syscall
    j loop

sair:
    move $s0, $zero         # logout
    li $v0, 4
    la $a0, mensagem_ok
    syscall
    j loop

encerrar:
    li $v0, 10
    syscall

erro:
    li $v0, 4
    la $a0, mensagem_erro
    syscall
    j loop

registrar_extrato:
    lw $t3, 20($s0)      # extrato_index
    addi $t4, $s0, 24    # base extrato
    sll $t5, $t3, 2
    add $t4, $t4, $t5
    sw $t1, 0($t4)

    addi $t3, $t3, 1
    li $t6, 5
    blt $t3, $t6, idx_ok
    li $t3, 0

idx_ok:
    sw $t3, 20($s0)
    jr $ra
