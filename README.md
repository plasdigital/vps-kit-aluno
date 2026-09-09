# Sua VPS, instalada pela IA

Esta pasta monta um servidor seu, do zero, e coloca dentro dele as ferramentas que hoje se paga
por mês: **Docker + Traefik (o cadeado sai sozinho) + Portainer (o painel)** como base, e em cima
dela o que você escolher — **Chatwoot**, **n8n**, **NocoDB**, **Evolution API**, ou qualquer
projeto que você achar no GitHub.

Você não vai decorar comando. Abra o Claude Code **dentro desta pasta** e converse em português —
ela já sabe se explicar para ele.

## 🔴 A regra que vale mais que todo o resto

**Esta pasta não decide a versão de nada.** Os arquivos vêm com o campo de versão em branco
(`PREENCHER`), e **quem descobre o número é o seu agente, na hora de instalar** — olhando a última
versão estável e os avisos de segurança do projeto. Depois ela fica fixa no seu arquivo.

Era o contrário até 08/set/2026, e mudou porque falhou: com as versões escritas aqui dentro, o kit
envelheceu e passou a ensinar, calado, três versões com falha conhecida.

Está tudo em **[docs/antes-de-instalar.md](docs/antes-de-instalar.md)**. É o documento mais
importante da pasta, e é o que impede este kit de envelhecer em silêncio.

## O que você precisa ter

| | O que | Quanto custa |
|---|---|---|
| 1 | **Claude Code** (plano Pro ou Max). Codex e Antigravity funcionam igual | US$ 20/mês |
| 2 | Uma conta na **[Hostinger](https://www.hostg.xyz/aff_c?offer_id=6&aff_id=214984&url_id=5038)** — é onde a máquina vai ser comprada (cupom `PEDROALMEIDA`, 10% OFF) | — |
| 3 | Um **domínio** que você controla — sem ele não existe cadeado | ~R$ 40/ano |
| 4 | Uma **chave SSH** — o agente cria em um comando | — |
| 5 | Uma VPS **KVM 2** (2 vCPU · 8 GB · 100 GB) com **Ubuntu 24.04 LTS** | ~R$ 44/mês |

⚠️ **O plano mais barato de VPS não serve.** Só o Chatwoot reserva 4,25 GB, antes do sistema
operacional. O "mínimo de 4 GB" da documentação dele é limiar de sobrevivência do software, não de
uma máquina de verdade.

⚠️ **E talvez você não precise disso.** Com um ou dois atendentes e pouca conversa, o plano grátis
da nuvem é mais esperto — você não cuida de nada. Isto aqui compensa quando entram três atendentes
ou mais, quando o histórico não pode expirar, ou — o motivo de verdade — quando você vai rodar
**várias ferramentas na mesma máquina**.

## A ordem de leitura

1. **[COMECE-AQUI.md](COMECE-AQUI.md)** — a máquina do zero até a base no ar. Uma vez na vida.
2. O documento da ferramenta que você quer instalar (tabela abaixo).
3. `docs/` — o porquê de cada decisão, e o que dá para desfazer.
4. `CLAUDE.md` — não é para você: é o que o seu agente lê.

## O que dá para instalar

| Ferramenta | O que resolve | Passo a passo |
|---|---|---|
| **Chatwoot** | atendimento: várias pessoas na mesma caixa, histórico que não expira | [docs/instalar-chatwoot.md](docs/instalar-chatwoot.md) |
| **n8n** | automação: o que precisa acontecer às 3 da manhã sem ninguém acordado | [docs/instalar-n8n.md](docs/instalar-n8n.md) |
| **NocoDB** | a planilha da equipe que na verdade já virou banco de dados | [docs/instalar-nocodb.md](docs/instalar-nocodb.md) |
| **Evolution API** | WhatsApp por QR Code ⚠️ não é o oficial — leia o §0 do documento | [docs/instalar-evolution.md](docs/instalar-evolution.md) |
| **Qualquer projeto do GitHub** | o que ninguém vende pronto para o seu problema | [docs/instalar-do-github.md](docs/instalar-do-github.md) |
| **Banco de dados** | 🟢 este é para **contratar**, não para instalar aqui | [docs/onde-o-banco-mora.md](docs/onde-o-banco-mora.md) |

## O que tem aqui dentro

```
vps.env.exemplo       copie para vps.env e preencha os endereços
postinstall.sh        prepara a máquina sozinha, no primeiro boot
deploy.sh             sobe a base: Traefik + Portainer
stacks/               os arquivos de cada serviço
deploy-<app>.sh       sobe uma aplicação e instala o backup dela
backup-<app>.sh       o backup de todo dia
<app>.env.exemplo     o modelo dos segredos (o de verdade só existe na VPS)
CLAUDE.md / AGENTS.md o manual do seu agente de IA
docs/                 os passos por ferramenta, e as decisões
```

## Quatro coisas que valem mais que o resto

**1. Pesquisar antes de instalar não é opcional.** Veja a regra lá em cima. O agente que instala de
memória instala a versão do ano passado.

**2. A versão é nova na instalação, e fixa depois dela.** O agente descobre a última estável na
hora de instalar e **grava o número** no seu `vps.env`. Não é `latest`, de propósito: `latest` troca
de versão sozinho no primeiro restart e você descobre pelo cliente reclamando. Instalado, **o padrão
é ficar parado** — só se atualiza quando a nova tem algo que você quer, ou quando a atual está dando
problema de verdade (e aviso de segurança conta como problema).

**3. Só o Traefik fala com a internet.** Banco, fila e todo o resto ficam escondidos atrás dele. O
firewall libera três portas e nada mais. Toda ferramenta nova que você trouxer segue essa regra —
inclusive a que veio do GitHub.

**4. Instalação nova costuma nascer com uma porta aberta.** No Chatwoot é uma tela de "criar o dono
da instalação"; no n8n e no NocoDB é a primeira conta que qualquer um pode criar. Feche na mesma
sessão em que instalar — cada documento diz como.

## Se algo der errado

O `CLAUDE.md` tem uma tabela de "o que o erro diz × o que ele significa" — a maior parte dos
problemas desta instalação são erros cuja mensagem aponta para o lugar errado. Peça ao agente:

> *"deu esse erro aqui, o que é de verdade?"*
