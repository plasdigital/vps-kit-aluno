# Instalar o n8n — as automações que rodam sozinhas

> **Antes de começar:** a máquina precisa estar de pé, fechada e com a base no ar
> ([COMECE-AQUI.md](../COMECE-AQUI.md), §0 a §6).
>
> E, sempre: **[o protocolo de conferência](antes-de-instalar.md)** antes de subir. Este documento
> descreve o caminho que funcionou numa data — quem diz se ele ainda vale hoje é a documentação
> oficial, e é o agente quem vai lá conferir.

## O que é

O n8n é onde você desenha o que a empresa faz sem ninguém apertar botão: chegou o pedido → grava no
banco → avisa no WhatsApp → cria a tarefa. É o pilar da estrutura, porque ele é quem **liga uma
ferramenta na outra**.

Na nuvem deles se paga por execução. Aqui, o limite é a máquina.

⚠️ **Não confunda as duas IAs.** O **Claude Code** é a IA que está instalando este servidor. A IA
que responde cliente dentro de um fluxo é outra coisa: é uma chave de API que você coloca **dentro
do n8n**, depois, e que se paga por uso.

---

## 1. 🔴 Os DOIS endereços

O n8n deste kit sobe em **modo fila** — três processos separados em vez de um só:

```
   n8n.seudominio.com.br        ->  EDITOR    a tela onde você desenha o fluxo
   webhook.seudominio.com.br    ->  WEBHOOK   quem recebe as chamadas de fora
                                    WORKER    quem executa (não tem endereço)
                                       |
                                    Redis     a fila entre eles
```

**Por que separado, se dá mais peça:** assim um fluxo pesado não trava a tela do editor, e o
endereço que você entrega para fora (o do webhook) não é o mesmo que dá acesso à sua área de
trabalho.

🔴 **Crie os dois registros A antes de subir.** Este é o erro mais comum aqui: quem cria só o do
editor descobre depois, quando um webhook externo não responde — e o erro não fala de DNS.

Preencha `N8N_HOST` e `N8N_WEBHOOK_HOST` no `vps.env`.

**Deu certo quando:** os dois nomes resolvem para o IP da VPS.

## 2. Conferir a documentação oficial

> *"antes de instalar o n8n, confere as releases do n8n-io/n8n e a documentação de queue mode, e me
> diz se mudou algo desde que este kit foi escrito"*

## 3. Os segredos

Gerados na VPS, em `/opt/infra/n8n/n8n.env` (modelo: `n8n.env.exemplo`):

| Valor | O que é |
|---|---|
| `POSTGRES_PASSWORD` | senha do banco desta stack |
| `REDIS_PASSWORD` | senha da fila |
| `N8N_ENCRYPTION_KEY` | 🔴 a chave que **cifra as credenciais** que os seus fluxos guardam |

🔴 **A chave de criptografia é a peça mais perigosa deste serviço.** Ela decifra tudo o que os seus
fluxos salvarem (token do WhatsApp, senha de e-mail, chave de API).

- **Nunca reaproveite** a chave de outra instalação sua — isso amarra as duas para sempre.
- **Trocar depois de instalado torna todas as credenciais salvas ilegíveis.** Não tem recuperação:
  é recriar credencial por credencial, na mão.
- **Guarde uma cópia** no seu gerenciador de senhas, hoje. Sem ela, um backup do banco não serve
  para restaurar as credenciais.

## 4. Subir

```bash
bash /opt/infra/deploy-n8n.sh
```

Sobem cinco peças: banco, fila (Redis), editor, webhook e worker. O deploy também instala o
**backup diário do banco às 03:45** — a partir do momento em que existe n8n, existe fluxo e
credencial a perder.

**Deu certo quando:** `https://n8n.seudominio.com.br` abre com cadeado.

## 5. 🔴 Criar o dono, agora — não amanhã

A primeira pessoa que abrir o editor cria a conta de dono da instância. Como o endereço já é
público, **esse convite está aberto para a internet até você aceitá-lo**.

Abra o editor e crie o dono **na mesma sessão em que instalou**.

⚠️ **Não há servidor de e-mail nesta instalação.** Consequência prática: o *"esqueci minha senha"*
não funciona — o e-mail não sai. Anote a senha do dono no gerenciador de senhas; recuperar é por
comando, com o agente.

**Deu certo quando:** você entra no editor com o seu usuário, e uma aba anônima na mesma URL mostra
tela de **login**, não de cadastro.

## 6. Provar que está no ar

| O quê | Como |
|---|---|
| o editor abre | `https://n8n.seudominio.com.br` com cadeado |
| o webhook responde | crie um fluxo com nó *Webhook*, ative, e chame a URL de produção pelo navegador |
| o worker executa | o fluxo aparece em *Executions* como concluído |
| o backup | rodar na mão e ver o arquivo aparecer, **com tamanho** |

⚠️ **O teste que importa é o do webhook**, não o do editor. Editor abrindo prova metade: quem recebe
chamada de fora é o outro endereço, e é ele que a maior parte das suas automações vai usar.

## O que este kit já decidiu por você

| Decisão | Por quê |
|---|---|
| **Modo fila** (editor · webhook · worker separados) | fluxo pesado não trava a tela, e webhook não cai junto |
| **Postgres e Redis próprios**, não emprestados de outra aplicação | se uma aplicação for invadida, o estrago para nela |
| **Execuções velhas apagadas depois de 14 dias** | histórico de execução é o que enche disco de VPS — e ninguém percebe até acabar |
| **Pacotes da comunidade liberados** | é o que permite instalar nó que não vem de fábrica |
| **Versão fixada**, nunca `latest` | `latest` troca de versão sozinho no primeiro restart |

## As armadilhas deste serviço

| O que aparece | O que é de verdade |
|---|---|
| o webhook externo não chega, e o erro não fala de DNS | faltou o registro A do **segundo** endereço (§1) |
| todas as credenciais viraram lixo depois de uma reinstalação | a `N8N_ENCRYPTION_KEY` mudou (§3) |
| "esqueci a senha" não manda e-mail | não há SMTP — é assim de propósito (§5) |
| disco enchendo com o tempo | histórico de execução; confira a retenção antes de culpar backup |
