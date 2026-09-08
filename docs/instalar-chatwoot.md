# Instalar o Chatwoot — a caixa de atendimento

> **Antes de começar:** a máquina precisa estar de pé, fechada e com a base no ar
> ([COMECE-AQUI.md](../COMECE-AQUI.md), §0 a §6). Se `https://portainer.seudominio.com.br` não abre
> com cadeado, pare aqui — nada em cima vai funcionar.
>
> E, sempre: **[o protocolo de conferência](antes-de-instalar.md)** antes de subir. Este documento
> descreve o caminho que funcionou numa data — quem diz se ele ainda vale hoje é a documentação
> oficial, e é o agente quem vai lá conferir.

## O que é, e quando vale

O Chatwoot é a tela onde as conversas dos seus canais chegam: **várias pessoas atendendo na mesma
caixa**, com histórico, etiqueta e transferência entre atendentes.

| Fica na nuvem paga se… | Vem para a sua máquina se… |
|---|---|
| é você sozinho atendendo | entram **3 pessoas ou mais** — lá se cobra por pessoa |
| conversa pouca, histórico curto | o histórico **não pode expirar** |
| você não quer consertar nada, nunca | você já vai rodar **outras ferramentas** na mesma máquina |

⚠️ **Conectar o WhatsApp vem depois, não antes.** Primeiro a caixa de pé; o canal é trabalho à parte.

---

## 1. O endereço

Crie o registro **A** de `chat.seudominio.com.br` apontando para o IP da VPS
(§5 do COMECE-AQUI) e preencha `CHATWOOT_HOST` no `vps.env`.

🔴 **Se o nome `chat` já é usado por outro fornecedor, escolha outro agora.** Trocar depois é caro:
ele fica gravado em link, em configuração e no webhook do WhatsApp.

**Deu certo quando:** o nome resolve para o seu IP.

## 2. Conferir a documentação oficial

> *"antes de instalar o Chatwoot, confere as releases e o compose oficial no GitHub do
> chatwoot/chatwoot e me diz se mudou algo desde que este kit foi escrito"*

## 3. Os segredos

O agente gera as três senhas **dentro da máquina** — elas nunca passam pelo seu computador — e
grava em `/opt/infra/chatwoot/chatwoot.env`, com permissão só para o dono. O modelo do arquivo é o
`chatwoot.env.exemplo`.

⚠️ **Guarde uma cópia no seu gerenciador de senhas.** Não existe "recuperar" esse arquivo.

## 4. Subir

> *"instala o Chatwoot em chat.seudominio.com.br"*

```bash
bash /opt/infra/deploy-chatwoot.sh
```

Sobem quatro peças: **banco**, **fila**, **aplicação** e o **trabalhador de segundo plano** (quem
processa o que não pode travar a tela). Só a aplicação é alcançável pela internet, e mesmo assim
por trás do Traefik.

**Deu certo quando:** os quatro serviços aparecem, e o histórico deles não mostra falha recente.

## 5. 🔴 Preparar o banco — senão ele sobe e morre em loop

```bash
bash /opt/infra/chatwoot-rails.sh bundle exec rails db:chatwoot_prepare
```

**Por que isto não é automático:** o arquivo de inicialização da imagem oficial só espera o banco
responder e executa — **ele não cria as tabelas**. A documentação oficial esconde isso atrás de um
comando que não existe do jeito que a gente instalou.

O sintoma, se você pular: `relation "installation_configs" does not exist`, com os serviços
reiniciando sem parar. **O erro fala de tabela e não fala de migração** — é por isso que custa meia
hora para quem não sabe.

**Deu certo quando:** o comando termina sem erro e os serviços param de reiniciar.

## 6. 🔴 Criar o dono E fechar a porta de trás — o mesmo comando

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

## 7. Criar quem vai atender

```bash
CW_SENHA='OutraSenha@2026' bash /opt/infra/chatwoot-criar-usuario.sh \
    pessoa@seudominio.com "Nome da Pessoa" agent      # ou administrator
```

⚠️ A senha exige **minúscula, MAIÚSCULA, número e símbolo**. Senha aleatória "limpa" é recusada —
depois de um minuto carregando.

⚠️ Isto é por comando porque **não há servidor de e-mail** nesta instalação. O convite pela tela
dispararia um e-mail que não sai. O custo: **ninguém recupera a própria senha sozinho** — quem
troca senha é você, por comando.

## 8. O backup — e por que ele tem duas metades

O deploy já instalou o backup diário. Mas entenda o que ele guarda:

| Metade | O que é | Guarda por |
|---|---|---|
| o banco | conversas, contatos, etiquetas | 7 dias |
| os anexos | as fotos e arquivos que o cliente mandou | para sempre |

🔴 **O backup do banco sozinho não é backup.** O Chatwoot guarda no banco só o **endereço** do
arquivo anexado, não o arquivo. Restaurar só o banco devolve todas as conversas com **todos os
anexos quebrados**.

🔴 **E nada disso cobre perder a máquina** — os dois moram na própria VPS. Confirme no painel do
provedor que o backup automático está ligado.

## 9. Provar que está no ar

| O quê | Esperado |
|---|---|
| serviços saudáveis | histórico **sem falha recente** |
| o site responde | cadeado do Let's Encrypt |
| cadastro público | **bloqueado** |
| tela de criar dono | **fechada** |
| login com a senha certa | entra, com o papel correto |
| login com senha errada | recusa |
| backup | rodar na mão e ver o arquivo aparecer, **com tamanho** |
| portas | continuam só 22, 80 e 443 |

⚠️ Abrir a **tela de cadastro** e ver que ela carrega **não prova nada**: ela abre mesmo bloqueada,
porque quem decide é a parte visual. A prova é bater na interface de programação.

## As armadilhas deste serviço

| O que aparece | O que é de verdade |
|---|---|
| `relation "installation_configs" does not exist`, serviços em loop | faltou o passo 5 |
| a tela de "criar dono" continua abrindo | faltou o passo 6 — criar usuário por fora **não** fecha |
| `Password must contain at least 1 special character` | senha gerada sem símbolo |
| anexos quebrados depois de restaurar | restaurou só o banco (§8) |
