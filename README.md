# Sua VPS, instalada pela IA

Esta pasta monta um servidor seu, do zero, e coloca uma caixa de atendimento rodando nele:
**Docker + Traefik (o cadeado sai sozinho) + Portainer (o painel) + Chatwoot (o atendimento)**.

Você não vai decorar comando. Abra o Claude Code **dentro desta pasta** e converse em português —
ela já sabe se explicar para ele.

## O que você precisa ter

| | O que | Quanto custa |
|---|---|---|
| 1 | Uma VPS **KVM 2** (2 vCPU · 8 GB · 100 GB) com **Ubuntu 24.04 LTS** | ~R$ 44/mês |
| 2 | Um **domínio** que você controla — sem ele não existe cadeado | ~R$ 40/ano |
| 3 | **Claude Code** (plano Pro ou Max). Codex e Antigravity funcionam igual | US$ 20/mês |
| 4 | Uma **chave SSH** — o agente cria em um comando |  — |

⚠️ **O plano mais barato de VPS não serve.** Esta instalação reserva 4,25 GB só para o Chatwoot,
antes do sistema operacional. O "mínimo de 4 GB" da documentação do Chatwoot é limiar de
sobrevivência do software, não de uma máquina de verdade.

⚠️ **E você talvez não precise disso.** Com um ou dois atendentes e pouca conversa, o plano grátis
da nuvem do Chatwoot é mais esperto — você não cuida de nada. Isto aqui compensa quando entram três
atendentes ou mais, quando o histórico não pode expirar, ou — o motivo de verdade — quando você vai
rodar **várias ferramentas na mesma máquina**.

## A ordem de leitura

1. **[COMECE-AQUI.md](COMECE-AQUI.md)** — a configuração, na ordem, uma vez só.
2. `docs/` — o porquê de cada decisão, e o que dá para desfazer.
3. `CLAUDE.md` — não é para você: é o que o seu agente lê.

## O que tem aqui dentro

```
vps.env.exemplo       copie para vps.env e preencha os dois endereços
postinstall.sh        prepara a máquina sozinha, no primeiro boot
deploy.sh             sobe a base: Traefik + Portainer
stacks/               os arquivos de cada serviço
deploy-chatwoot.sh    sobe o Chatwoot e instala o backup diário
chatwoot-rails.sh     roda comando por dentro do Chatwoot
chatwoot-criar-usuario.sh   cria pessoa — e fecha a porta de trás
backup-chatwoot.sh    o backup de todo dia
CLAUDE.md / AGENTS.md o manual do seu agente de IA
docs/                 as decisões e o porquê
```

## Três coisas que valem mais que o resto

**1. As versões estão fixadas, com número.** Não é `latest`, e isso é de propósito: `latest` troca
de versão sozinho no primeiro restart e você descobre pelo cliente reclamando. **O padrão é ficar
parado** — só se atualiza quando a versão nova tem algo que você quer, ou quando a atual está dando
problema de verdade.

**2. Só o Traefik fala com a internet.** Banco, fila e todo o resto ficam escondidos atrás dele. O
firewall libera três portas e nada mais.

**3. Instalação nova de Chatwoot nasce com uma porta aberta.** Enquanto uma chave existir na
memória dele, qualquer pessoa na internet pode criar um administrador na sua instância — e criar o
dono pelo caminho normal **não fecha isso**. Por isso, aqui, criar o dono e fechar a porta são o
mesmo comando. Não separe os dois.

## Se algo der errado

O `CLAUDE.md` tem uma tabela de "o que o erro diz × o que ele significa" — a maior parte dos
problemas desta instalação são erros cuja mensagem aponta para o lugar errado. Peça ao agente:

> *"deu esse erro aqui, o que é de verdade?"*
