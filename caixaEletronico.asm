.data
mensagem_conta: .asciiz "Digite o número da conta: "
mensagem_senha: .asciiz "Digite a senha: "
mensagem_sucesso: .asciiz "\nLogin realizado com sucesso!\n"
mensagem_erro: .asciiz "\nSenha incorreta.\n"
mensagem_bloqueado: .asciiz "\nConta Bloqueada!\n"
mensagem_invalido: .asciiz "\nConta inexistente!\n"

conta1:
    .word 1234              # numero da conta
    .word 1111              # senha
    .word 0                 # tentativas
    .word 0                 # bloqueada (0 é não e 1 sim)

conta2:                     # conta 2 segue a mesma lógica da conta 1
    .word 5678
    .word 2222
    .word 0
    .word 0

.text
.global main 

main:
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

    li $v0, 4               # aqui repete o que foi lá na "pedir número da conta"
    la $a0, mensagem_sucesso
    syscall
    
    # eu acho que é aqui que entra a etapa do menu e tals...

    li $v0, 10
    syscall

bloquear:
    li $t7, 1               # aqui eu carrego o 1 no temporário $t7
    sw $t7, 12($t1)         # gravo 1 na posição 12($t1), marcando o status como bloqueado
    j conta_bloqueada       # e ai avisa ao usuário do bloqueio...

