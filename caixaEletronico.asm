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

