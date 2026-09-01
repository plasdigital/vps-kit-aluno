# Comece aqui — do nada até o Chatwoot no ar

A ordem importa. Alguns passos **não são reversíveis de graça** — eles estão marcados 🔴.

Você vai conversar com o agente. Os comandos abaixo estão escritos para você entender **o que
está acontecendo**, não para decorar.

---

## Antes de comprar qualquer coisa

- [ ] **Um domínio que você controla.** Precisa poder criar registros nele. 🔴 Sem domínio não há
      cadeado: o certificado gratuito **não é emitido para endereço de número**.
- [ ] **Claude Code instalado**, com plano Pro ou Max. O plano grátis não inclui.
- [ ] Decidir os dois endereços: `portainer.seudominio.com.br` e `chat.seudominio.com.br`.
      🔴 Se o nome `chat` já é usado por outro fornecedor, escolha outro **agora** — trocar depois é
      caro, porque ele fica gravado em link, na configuração e no webhook do WhatsApp.

---

## 1. A chave SSH — **antes** de criar a máquina

> *"cria uma chave SSH pra minha VPS nova"*

🔴 **Isto tem que ser feito antes.** A chave é injetada quando a máquina nasce. Anexar chave a uma
VPS **já criada não funciona** — o painel responde que deu certo e ela simplesmente não entra.

Se você já errou isso: dá para colar a chave pública em `~/.ssh/authorized_keys` usando o terminal
que o painel do provedor abre no navegador.

---

## 2. Criar a VPS

| Campo | Escolha | Por quê |
|---|---|---|
| Plano | **KVM 2** (2 vCPU · 8 GB · 100 GB) | o menor não aguenta — veja o README |
| Sistema | **Ubuntu 24.04 LTS** | não a versão mais nova: o que quebra em versão nova não é o Docker, é o que está em volta |
| Chave SSH | a que você acabou de criar | |
| Script de pós-instalação | o `postinstall.sh` desta pasta | roda sozinho no primeiro boot |

⚠️ Se o painel recusar o script com **erro 403**, não é tamanho: o firewall do provedor implica com
os trechos de segurança. A saída é colar o script empacotado em base64 dentro de um envelope de
seis linhas — peça ao agente: *"empacota o postinstall pro painel"*.

**Deu certo quando:** a máquina fica *running* e você recebe o IP.

---

## 3. Fechar a máquina — **antes** de instalar qualquer coisa

No firewall do provedor, libere **22, 80 e 443**. Nada mais.

> *"fecha minha VPS deixando só 22, 80 e 443"*

🔴 **Use o firewall do painel, não o de dentro da máquina.** Uma regra errada no firewall de dentro
te tranca do lado de fora do seu próprio servidor, e só se sai disso pelo console de recuperação.
Errou no painel? Você clica e corrige.

⚠️ O provisionamento de alguns provedores **reabre o login de root por senha** — é o template deles,
não erro seu. O `postinstall.sh` corrige isso, e o arquivo de correção precisa começar com `01-` no
nome (o SSH lê a pasta em ordem alfabética e vale o primeiro valor que encontra).

**Deu certo quando:** `ss -tlnp` na máquina mostra só 22, 80 e 443 escutando para fora.

---

## 4. Apontar os endereços

Crie dois registros **A**, cada um apontando para o IP da VPS:

```
portainer   →   <IP da sua VPS>
chat        →   <IP da sua VPS>
```

🔴 **Acrescente, não sobrescreva.** Se o domínio já é usado para e-mail, mexer errado na zona
derruba o e-mail da empresa. Peça ao agente para listar a zona antes e depois: tem que ter os
antigos **+ 2**.

**Deu certo quando:** os dois nomes resolvem para o seu IP.

---

## 5. Enviar a pasta e subir a base

```bash
cp vps.env.exemplo vps.env      # e preencha os dois hosts e o seu e-mail
```

> *"envia essa pasta pra minha VPS e sobe o Traefik e o Portainer"*

⚠️ **Se você usa Windows:** os arquivos chegam com uma marca invisível no fim de cada linha e o
Linux reclama de "comando não encontrado" em lugares sem sentido. É a causa mais provável de um
deploy que falha sem explicação. O agente já corrige, mas se você criar um arquivo novo, lembre.

**Deu certo quando:** `https://portainer.seudominio.com.br` abre **com cadeado**, e o emissor do
certificado é o Let's Encrypt.

Se aparecer "TRAEFIK DEFAULT CERT" em vez disso, o DNS ainda não propagou. **Espere** — não recrie
o serviço, porque quem emite o certificado tem trava de tentativa e insistir só atrasa.

---

## 6. Subir o Chatwoot

> *"instala o Chatwoot em chat.seudominio.com.br"*

O agente gera as três senhas **dentro da máquina** (elas nunca passam pelo seu computador) e sobe
quatro serviços: banco, fila, aplicação e o trabalhador de segundo plano. Nenhum deles fica
exposto na internet.

---

## 7. 🔴 Preparar o banco — senão ele sobe e morre em loop

```bash
bash /opt/infra/chatwoot-rails.sh bundle exec rails db:chatwoot_prepare
```

**Por que isso não é automático:** o arquivo de inicialização da imagem oficial só espera o banco
responder e executa — **ele não cria as tabelas**. A documentação oficial esconde isso atrás de um
comando que não existe no jeito que a gente instalou.

O sintoma, se você pular: `relation "installation_configs" does not exist`, com os serviços
reiniciando sem parar. O erro fala de tabela e não fala de migração — é por isso que custa meia
hora para quem não sabe.

---

## 8. 🔴 Criar o dono E fechar a porta de trás — o mesmo comando

```bash
CW_SENHA='UmaSenhaForte@2026' bash /opt/infra/chatwoot-criar-usuario.sh \
    dono@seudominio.com "Seu Nome" superadmin
```

**Leia isto antes de rodar.** Uma instalação nova de Chatwoot nasce com uma tela de *criar o dono da
instalação* aberta na internet, sem senha nenhuma. Quem chegasse primeiro criaria um administrador
com poder total na **sua** instância.

E o detalhe que pega todo mundo: o que controla essa tela **não está no banco de dados**, está na
memória rápida. Criar o dono pelo caminho normal **não apaga aquilo**. Você faz tudo certo e a porta
continua aberta. Por isso, aqui, criar e fechar são uma operação só.

⚠️ Dê a esse usuário um **e-mail só dele**. Por dentro, o super administrador e os atendentes são a
mesma tabela e disputam endereço — não promova o login que o time usa para atender.

**Deu certo quando:** abrir `https://chat.seudominio.com.br/installation/onboarding` numa aba
anônima e ser **redirecionado para o login**.

---

## 9. Criar quem vai atender

```bash
CW_SENHA='OutraSenha@2026' bash /opt/infra/chatwoot-criar-usuario.sh \
    pessoa@seudominio.com "Nome da Pessoa" agent      # ou administrator
```

⚠️ A senha exige **minúscula, MAIÚSCULA, número e símbolo**. Senha aleatória "limpa" é recusada —
depois de um minuto carregando.

⚠️ Isto é por comando porque **não há servidor de e-mail** nesta instalação. O convite pela tela
dispararia um e-mail que não sai. O custo: ninguém recupera a própria senha sozinho.

---

## 10. O backup — e por que ele tem duas metades

O `deploy-chatwoot.sh` já instalou o backup diário. Mas entenda o que ele guarda:

| Metade | O que é | Guarda por |
|---|---|---|
| o banco | conversas, contatos, etiquetas | 7 dias |
| os anexos | as fotos e arquivos que o cliente mandou | para sempre |

🔴 **O backup do banco sozinho não é backup.** O Chatwoot guarda no banco só o **endereço** do
arquivo anexado, não o arquivo. Restaurar só o banco devolve todas as conversas com **todos os
anexos quebrados**.

🔴 **E nada disso cobre perder a máquina** — os dois moram na própria VPS. Vá no painel do provedor e
confirme que o backup automático está ligado. **Snapshot não é backup:** ele expira em 24 horas e é
rede de proteção da manutenção do dia.

---

## 11. Provar que está no ar — e não se enganar

> *"roda a lista de aceitação"*

| O quê | Esperado |
|---|---|
| serviços saudáveis | histórico **sem falha recente** |
| site responde | com certificado válido do Let's Encrypt |
| cadastro público | **bloqueado** |
| tela de criar dono | **fechada** |
| login com a senha certa | entra, com o papel correto |
| login com senha errada | recusa |
| backup | rodar na mão e ver o arquivo aparecer, com tamanho |
| portas | **continuam só 22, 80 e 443** |

⚠️ **Duas formas de se enganar sozinho:**

- O painel dizendo **"1 de 1"** não prova saúde — um serviço reiniciando em loop aparece assim
  durante os segundos em que a tentativa nova está viva. Quem conta a verdade é o **histórico**.
- Abrir a **tela de cadastro** e ver que ela carrega não prova nada: ela abre mesmo bloqueada,
  porque quem decide é a parte visual. A prova é bater na interface de programação.

---

## E depois

- **Conectar o WhatsApp** ao Chatwoot é trabalho à parte, e vem depois — não antes.
- **Instalar mais coisa** (n8n, banco, painel) usa a mesma base: é só mais um andar em cima.
- **Manutenção:** o sistema instala correção de segurança sozinho, mas **não reinicia** a máquina. De
  vez em quando: *"tem atualização pendente? precisa reiniciar?"*
