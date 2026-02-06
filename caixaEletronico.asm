.data
mensagem_conta: .asciiz "Digite o número da conta: "
mensagem_senha: .asciiz "Digite a senha: "
mensagem_sucesso: .asciiz "\nLogin realizado com sucesso!\n"
mensagem_erro: .asciiz "\nSenha incorreta.\n"
mensagem_bloqueado: .asciiz "\nConta Bloqueada!\n"
mensagem_invalido: .asciiz "\nConta inexistente!\n"

mensagem_menu: .asciiz "\n=== MENU CAIXA ELETRÔNICO ===\n1 - Consultar saldo\n2 - Deposito\n3 - Saque\n4 - Extrato\n0 - Sair\nOpção: "
mensagem_saldo: .asciiz "Saldo atual: "
mensagem_deposito: .asciiz "\nValor do depósito: "
mensagem_saque: .asciiz "\nValor do saque: "
mensagem_ok: .asciiz "\nOperação realizada com sucesso.\n"
mensagem_valorInvalido: .asciiz "\nValor inválido.\n"
mensagem_saldoInsuficiente: .asciiz "\nSaldo insuficiente.\n"
mensagem_extrato: .asciiz "\n=== EXTRATO ===\n"
mensagem_deposito2: .asciiz "Deposito: "
mensagem_saque2: .asciiz "Saque: "
mensagem_vazio: .asciiz "(vazio)"
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
.global main 

main:
    j login

login:
    # pedir número da conta 
    li $v0, 4               # aqui ele manda salvar o 4, que é um código de serviço para imprimir string, dentro do registrador $v0
    la $a0, mensagem_conta  # aqui salva a mensagem de "mensagem_conta" dentro do registrador $a0 
    syscall                 # só imprime

    li $v0, 5               # aqui ele ler um número. O 5 serve justamente para ler esse número digitado. Depois, coloca dentro do registrador $v0 
    syscall                 # espera o usuário digitar 
    move $t0, $v0           # move o valor retornado em $v0 para o registrador temporario $t0

    # encontrar a conta correta
    la $t1, conta1          # $t1 recebe o endereço de memória de conta1
    lw $t2, 0($t1)          # aqui ele vai até o endereço em $t1 e carrega o número da conta em $t2
    beq $t0, $t2, conta_ok  # compara se o valor de $t0 é igual o valor de $t2, se for, então vai para o trecho de "conta_ok"

    la $t1, conta2
    lw $t2, 0($t1)
    beq $t0, $t2, conta_ok

    # conta inexistente
    li $v0, 4               # o trecho de erro já vel logo após o "beq", que é como se fosse um "if-else". Funciona igual como fizemos lá em "pedir número da conta"
    la $a0, mensagem_invalido
    syscall
    j login

conta_ok:
    # verificar bloqueio
    lw $t3, 12($t1)         # aqui ele vai atpe o endereço de $t1, "pula" 12 byts, que é para chegar na parte de "bloqueada", e guarda o valor encontrado no registrador $t3
    beq $t3, 1, conta_bloqueada # aqui ele verifica... se for igual a 1, então ele vai para o trecho de "conta_bloqueada" , senão, segue normal o fluxo

    # pedir senha
    li $v0, 4               # funciona exatamente como lá no "pedir número da conta"
    la $a0, mensagem_senha
    syscall

    li $v0, 5              
    syscall
    move $t4, $v0            # aqui também funciona parecido com o "pedir número da conta"...  

    lw $t5, 4($t1)           # nessa parte ele vai até a memória (no endereço vase $t1 + 4 bytes, que é para chegar na parte de "senha"), depois, ele carrega essa senha correta no registradror $t5
    beq $t4, $t5, login_sucesso # só compara... Se $t4 for igual a $t5, pula pra "login_sucesso"

    # senha incorreta
    li $v0, 4               # novamente, funciona igual lá o "pedir número conta"
    la $a0, mensagem_erro
    syscall

    # incrementar tentativas
    lw $t6, 8($t1)          # carrega o número atual de tentativas, indo até o endereço $t1, pula 8 byts, para chegar na "tentativas" e guarda o valor no registrador $t6
    addi $t6, $t6, 1        # aqui ele soma +1 ao valor que já estava lá em $t6
    sw $t6, 8($t1)          # ele salva de volta na memória, onde pega o novo valor de $t6 e sobrescreve o valor antigo na posição 8($t1)

    beq $t6, 3, bloquear    # aqui é a verificação. Se atingir 3, ele vai pra o método "bloqueio"
    j login                 # se não falhou, ele volta para o inicio do processo de login

conta_bloqueada:            # funciona igual o "pedir número da conta"
    li $v0, 4
    la $a0, mensagem_bloqueado
    syscall
    j login

login_sucesso:              
    # aqui é onde zera o número de tentativas
    sw $zero, 8($t1)        # salva o valor 0 na posição 8($t1)

    move $s0, $t1           # salva o "ponteiro" da conta logada em $s0

    li $v0, 4               # aqui repete o que foi lá na "pedir número da conta"
    la $a0, mensagem_sucesso
    syscall
    
    j menu 

menu:
    li $v0, 4               # funciona exatamente como visto anteriormente
    la $a0, mensagem_menu
    syscall

    li $v0, 5               # também funciona ocmo foi visto anteriormente
    syscall
    move $t0, $v0

    beq $t0, 1, verificar_saldo     # apenas verifica a escolha do usuário e coloca no registrador temporário $t0
    beq $t0, 2, deposito 
    beq $t0, 3, saque
    beq $t0, 4, extrato
    beq $t0, 0, sair
    j menu

sair:
    move $s0, $zero         # limpa o "ponteiro" da conta, e agora o $s0 tem o valor de 0
    j login                 # aqui ele vai para o inicio do programa novamente

verificar_saldo:
    lw $t1, 16($s0)         # aqui ele vai até os 16 bytes, que é onde tá a informação do saldo

    li $v0, 4               # Como vimos anteriormente: Prepara para imprimir uma string
    la $a0, mensagem_saldo
    syscall

    li $v0, 1               # aqui ele imprimi um inteiro (qie é o saldo). 
    move $a0, $t1           # move o valor do saldo para $a0 que é para ser imprimido 
    syscall

    li $v0, 4               # novamente só prepara para imprimir a string
    la $a0, mensagem_quebraLinha
    syscall

    j menu                  # retorno para o menu principal

deposito:
    li $v0, 4               # prepara para imprimir uma string
    la $a0, mensagem_deposito
    syscall

    li $v0, 5               # lê o valor que o usuário quer depositar
    syscall
    move $t1, $v0           # $t1 recebe o valor do depósito

    blez $t1, valor_invalido    # verificação se o valor é menor ou igual 0

    lw $t2, 16($s0)         # Carrega o saldo atual da memória para $t2
    add $t2, $t2, $t1       # Soma: saldo_novo = saldo_antigo + deposito
    sw $t2, 16($s0)         # Salva o novo saldo de volta na memória da conta

    jal registrar_extrato   # chama a sub-rotina para salvar no histórico

    li $v0, 4               # prepara para imprimir uma string
    la $a0, mensagem_ok
    syscall
    j menu

saque:
    li $v0, 4
    la $a0, mensagem_saque
    syscall

    li $v0, 5
    syscall
    move $t1, $v0

    blez $t1, valor_invalido

    lw $t2, 16($s0)

    blt $t2, $t1, saldo_insuficiente
    sub $t2, $t2, $t1
    sw $t2, 16($s0)

    sub $t1, $zero, $t1

    jal registrar_extrato

    li $v0, 4

    la $a0, mensagem_ok

    syscall
    
    j menu

valor_invalido:
    li $v0, 4
    la $a0, mensagem_valorInvalido
    syscall

    j menu

saldo_insuficiente:
    li $v0, 4
    la $a0, mensagem_saldoInsuficiente
    syscall

    j menu

extrato:
    

bloquear:
    li $t7, 1               # aqui eu carrego o 1 no temporário $t7
    sw $t7, 12($t1)         # gravo 1 na posição 12($t1), marcando o status como bloqueado
    j conta_bloqueada       # e ai avisa ao usuário do bloqueio...
