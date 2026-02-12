import tkinter as tk
import subprocess

MARS_PATH = "Mars4_5.jar"
ASM_FILE = "caixaEletronico_servidor.asm"

processo = subprocess.Popen(
    ["java", "-jar", MARS_PATH, ASM_FILE],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True
)

BG_COLOR = "#1E1E2F"
BTN_COLOR = "#3A7FF6"
BTN_HOVER = "#2F6DE1"
DANGER_COLOR = "#E74C3C"
TEXT_COLOR = "#FFFFFF"
FONT_TITLE = ("Segoe UI", 16, "bold")
FONT_TEXT = ("Segoe UI", 11)

def enviar_comando(comando):
    respostas = []
    processo.stdin.write(comando + "\n")
    processo.stdin.flush()

    while True:
        linha = processo.stdout.readline().strip()
        if linha:
            respostas.append(linha)
        if linha in ("OK", "ERRO"):
            break
    return respostas

def enviar_sem_resposta(comando):
    processo.stdin.write(comando + "\n")
    processo.stdin.flush()

def popup_info(titulo, mensagem):
    popup = tk.Toplevel()
    popup.title(titulo)
    popup.geometry("320x180")
    popup.configure(bg=BG_COLOR)
    popup.resizable(False, False)
    popup.grab_set()

    tk.Label(popup, text=titulo, font=FONT_TITLE,
             bg=BG_COLOR, fg=TEXT_COLOR).pack(pady=15)

    tk.Label(popup, text=mensagem, font=FONT_TEXT,
             bg=BG_COLOR, fg=TEXT_COLOR, wraplength=280,
             justify="center").pack(pady=10)

    criar_botao(popup, "OK", popup.destroy).pack(pady=10)

def popup_valor(titulo, texto):
    popup = tk.Toplevel()
    popup.title(titulo)
    popup.geometry("320x220")
    popup.configure(bg=BG_COLOR)
    popup.resizable(False, False)
    popup.grab_set()

    tk.Label(popup, text=titulo, font=FONT_TITLE,
             bg=BG_COLOR, fg=TEXT_COLOR).pack(pady=15)

    tk.Label(popup, text=texto, font=FONT_TEXT,
             bg=BG_COLOR, fg=TEXT_COLOR).pack()

    entry = tk.Entry(popup, font=FONT_TEXT, width=20)
    entry.pack(pady=10)

    resultado = {"valor": None}

    def confirmar():
        try:
            resultado["valor"] = int(entry.get())
            popup.destroy()
        except ValueError:
            popup_info("Erro", "Digite um número válido")

    criar_botao(popup, "Confirmar", confirmar).pack(pady=5)
    criar_botao(popup, "Cancelar", popup.destroy, DANGER_COLOR).pack()

    popup.wait_window()
    return resultado["valor"]

def popup_extrato(texto):
    popup = tk.Toplevel()
    popup.title("Extrato")
    popup.geometry("360x300")
    popup.configure(bg=BG_COLOR)
    popup.resizable(False, False)
    popup.grab_set()

    tk.Label(popup, text="Extrato", font=FONT_TITLE,
             bg=BG_COLOR, fg=TEXT_COLOR).pack(pady=10)

    frame = tk.Frame(popup, bg=BG_COLOR)
    frame.pack(fill="both", expand=True, padx=10)

    scrollbar = tk.Scrollbar(frame)
    scrollbar.pack(side="right", fill="y")

    text = tk.Text(frame, bg="#2B2B3C", fg=TEXT_COLOR,
                   font=FONT_TEXT, yscrollcommand=scrollbar.set,
                   bd=0, height=10)
    text.pack(fill="both", expand=True)
    scrollbar.config(command=text.yview)

    text.insert("1.0", texto)
    text.config(state="disabled")

    criar_botao(popup, "Fechar", popup.destroy).pack(pady=10)

def fazer_login():
    conta = entry_conta.get()
    senha = entry_senha.get()

    if not conta or not senha:
        popup_info("Erro", "Preencha todos os campos")
        return

    enviar_sem_resposta("L")
    enviar_sem_resposta(conta)
    respostas = enviar_comando(senha)

    if "OK" in respostas:
        popup_info("Bem-vindo", "Login realizado com sucesso")
        abrir_menu()
    else:
        popup_info("Erro", "Falha no login")

def consultar_saldo():
    respostas = enviar_comando("S")
    for r in respostas:
        if r.startswith("SALDO"):
            popup_info("Saldo", r)

def depositar():
    valor = popup_valor("Depósito", "Digite o valor do depósito")
    if valor is None:
        return

    enviar_sem_resposta("D")
    respostas = enviar_comando(str(valor))

    if "OK" in respostas:
        popup_info("Sucesso", "Depósito realizado com sucesso")
    else:
        popup_info("Erro", "Erro no depósito")

def sacar():
    valor = popup_valor("Saque", "Digite o valor do saque")
    if valor is None:
        return

    enviar_sem_resposta("A")
    respostas = enviar_comando(str(valor))

    if "OK" in respostas:
        popup_info("Sucesso", "Saque realizado com sucesso")
    else:
        popup_info("Erro", "Saldo insuficiente")

def ver_extrato():
    respostas = enviar_comando("E")
    linhas = []

    for r in respostas:
        if r in ("OK", "ERRO"):
            continue
        v = int(r)
        if v > 0:
            linhas.append(f"Depósito: {v}")
        else:
            linhas.append(f"Saque: {abs(v)}")

    texto = "\n".join(linhas) if linhas else "(extrato vazio)"
    popup_extrato(texto)

def logout():
    enviar_sem_resposta("O")
    janela_menu.destroy()
    janela_login.deiconify()

def sair():
    enviar_sem_resposta("X")
    janela_login.destroy()

def criar_botao(pai, texto, comando, cor=BTN_COLOR):
    return tk.Button(
        pai, text=texto, command=comando,
        bg=cor, fg=TEXT_COLOR,
        font=FONT_TEXT,
        width=22, height=2,
        bd=0, cursor="hand2",
        activebackground=BTN_HOVER
    )

def abrir_menu():
    janela_login.withdraw()
    global janela_menu

    janela_menu = tk.Toplevel()
    janela_menu.title("Menu")
    janela_menu.geometry("360x420")
    janela_menu.configure(bg=BG_COLOR)
    janela_menu.resizable(False, False)

    tk.Label(janela_menu, text="Menu Principal",
             font=FONT_TITLE, bg=BG_COLOR,
             fg=TEXT_COLOR).pack(pady=30)

    criar_botao(janela_menu, "💰 Consultar Saldo", consultar_saldo).pack(pady=5)
    criar_botao(janela_menu, "➕ Depositar", depositar).pack(pady=5)
    criar_botao(janela_menu, "➖ Sacar", sacar).pack(pady=5)
    criar_botao(janela_menu, "📄 Extrato", ver_extrato).pack(pady=5)
    criar_botao(janela_menu, "🚪 Logout", logout, DANGER_COLOR).pack(pady=25)

janela_login = tk.Tk()
janela_login.title("Caixa Eletrônico")
janela_login.geometry("360x420")
janela_login.configure(bg=BG_COLOR)
janela_login.resizable(False, False)

tk.Label(janela_login, text="💳 Caixa Eletrônico",
         font=FONT_TITLE, bg=BG_COLOR,
         fg=TEXT_COLOR).pack(pady=30)

frame = tk.Frame(janela_login, bg=BG_COLOR)
frame.pack()

tk.Label(frame, text="Número da conta", bg=BG_COLOR,
         fg=TEXT_COLOR).pack(anchor="w")
entry_conta = tk.Entry(frame, font=FONT_TEXT, width=25)
entry_conta.pack(pady=5)

tk.Label(frame, text="Senha", bg=BG_COLOR,
         fg=TEXT_COLOR).pack(anchor="w", pady=(10, 0))
entry_senha = tk.Entry(frame, font=FONT_TEXT,
                       width=25, show="*")
entry_senha.pack(pady=5)

criar_botao(janela_login, "Entrar", fazer_login).pack(pady=20)
criar_botao(janela_login, "Sair", sair, DANGER_COLOR).pack()

janela_login.mainloop()
