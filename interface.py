import tkinter as tk
from tkinter import messagebox, simpledialog
import subprocess

MARS_PATH = "Mars4_5.jar"
ASM_FILE = "caixaEletronico_servidor.asm"

# aqui ele chama o mars e o arquivo para entrar em processo
processo = subprocess.Popen(
    ["java", "-jar", MARS_PATH, ASM_FILE],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True
)

def enviar_comando(comando):
    """
    Envia um comando ao Assembly e lê todas as respostas
    até encontrar OK ou ERRO.
    Retorna a lista de linhas recebidas.
    """
    respostas = []

    processo.stdin.write(comando + "\n")
    processo.stdin.flush()

    while True:
        linha = processo.stdout.readline().strip()
        if linha:
            respostas.append(linha)
        if linha == "OK" or linha == "ERRO":
            break

    return respostas

def enviar_sem_resposta(comando):
    processo.stdin.write(comando + "\n")
    processo.stdin.flush()

def fazer_login():
    conta = entry_conta.get()
    senha = entry_senha.get()

    if not conta or not senha:
        messagebox.showwarning("Erro", "Preencha todos os campos!")
        return

    enviar_sem_resposta("LOGIN")
    enviar_sem_resposta(conta)
    respostas = enviar_comando(senha)

    if "OK" in respostas:
        messagebox.showinfo("Sucesso", "Login realizado com sucesso!")
        abrir_menu()
    else:
        messagebox.showerror("Erro", "Falha no login!")

def abrir_menu():
    janela_login.withdraw()

    global janela_menu
    janela_menu = tk.Toplevel()
    janela_menu.title("ATM - Menu")
    janela_menu.geometry("350x320")
    janela_menu.resizable(False, False)

    tk.Label(janela_menu, text="Menu Principal", font=("Arial", 14)).pack(pady=10)

    tk.Button(janela_menu, text="Consultar Saldo", width=25, command=consultar_saldo).pack(pady=5)
    tk.Button(janela_menu, text="Depositar", width=25, command=depositar).pack(pady=5)
    tk.Button(janela_menu, text="Sacar", width=25, command=sacar).pack(pady=5)
    tk.Button(janela_menu, text="Extrato", width=25, command=ver_extrato).pack(pady=5)
    tk.Button(janela_menu, text="Logout", width=25, command=logout).pack(pady=15)

def consultar_saldo():
    respostas = enviar_comando("S")

    saldo_encontrado = None
    for r in respostas:
        if r.startswith("SALDO"):
            saldo_encontrado = r

    if saldo_encontrado:
        messagebox.showinfo("Saldo", saldo_encontrado)
    else:
        messagebox.showerror("Erro", "Erro ao consultar saldo")

def depositar():
    valor = simpledialog.askinteger("Depósito", "Digite o valor do depósito:")
    if valor is None:
        return

    enviar_sem_resposta("D")
    respostas = enviar_comando(str(valor))

    if "OK" in respostas:
        messagebox.showinfo("Sucesso", "Depósito realizado com sucesso!")
    else:
        messagebox.showerror("Erro", "Erro no depósito")

def sacar():
    valor = simpledialog.askinteger("Saque", "Digite o valor do saque:")
    if valor is None:
        return

    enviar_sem_resposta("A")
    respostas = enviar_comando(str(valor))

    if "OK" in respostas:
        messagebox.showinfo("Sucesso", "Saque realizado com sucesso!")
    else:
        messagebox.showerror("Erro", "Saldo insuficiente ou erro")

def ver_extrato():
    respostas = enviar_comando("EXTRATO")

    linhas_formatadas = []

    for r in respostas:
        if r in ("OK", "ERRO"):
            continue

        try:
            valor = int(r)
            if valor > 0:
                linhas_formatadas.append(f"Depósito: {valor}")
            elif valor < 0:
                linhas_formatadas.append(f"Saque: {abs(valor)}")
        except:
            pass

    texto = "\n".join(linhas_formatadas) if linhas_formatadas else "(extrato vazio)"
    messagebox.showinfo("Extrato", texto)

def logout():
    enviar_sem_resposta("O")   
    janela_menu.destroy()
    janela_login.deiconify()

def sair():
    enviar_comando("EXIT")
    processo.terminate()
    janela_login.destroy()

# tela de login
janela_login = tk.Tk()
janela_login.title("Caixa Eletrônico - Login")
janela_login.geometry("300x220")
janela_login.resizable(False, False)

tk.Label(janela_login, text="Caixa Eletrônico", font=("Arial", 14)).pack(pady=10)

tk.Label(janela_login, text="Número da conta:").pack()
entry_conta = tk.Entry(janela_login)
entry_conta.pack()

tk.Label(janela_login, text="Senha:").pack()
entry_senha = tk.Entry(janela_login, show="*")
entry_senha.pack()

tk.Button(janela_login, text="Login", width=15, command=fazer_login).pack(pady=15)
tk.Button(janela_login, text="Sair", width=15, command=sair).pack()

janela_login.mainloop()
