# Instalar a Evolution API — WhatsApp por QR Code

> **Antes de começar:** a máquina de pé e a base no ar ([COMECE-AQUI.md](../COMECE-AQUI.md), §0 a §6).
> E, sempre: **[o protocolo de conferência](antes-de-instalar.md)**.

> 🟡 **Este é o único serviço deste kit que não vem com script pronto.** Não existe
> `deploy-evolution.sh` aqui. O caminho é o agente montar a stack seguindo o molde das outras
> (mesma rede, mesmas etiquetas, mesma regra de versão) **a partir da documentação oficial de
> hoje** — que neste projeto muda com frequência. Está escrito assim de propósito: entregar um
> arquivo fixo para um projeto que muda todo mês seria entregar um arquivo errado.

---

## 0. 🔴 Leia isto antes de decidir instalar

A Evolution API conecta o WhatsApp **por QR Code**, como o WhatsApp Web. Ela **não é a API oficial
do WhatsApp**. Isso tem uma consequência que ninguém deveria descobrir depois:

⚠️ **O número pode ser bloqueado.** Não é ameaça teórica: é o comportamento normal da plataforma
contra automação não autorizada. Bloqueio pode ser temporário ou definitivo, e leva junto o
histórico daquele número.

Como reduzir o risco — e nenhuma dessas medidas o elimina:

- **Use um número secundário**, nunca o número principal da empresa.
- **Nada de disparo em massa para lista fria.** É o caminho mais rápido para o bloqueio, e é o uso
  que mais gente tenta primeiro.
- Prefira **responder quem falou com você** a iniciar conversa com quem nunca falou.

### Fazer ou contratar?

| | Você mesmo (este documento) | Contratar um serviço pronto |
|---|---|---|
| **Custo** | só a máquina que você já tem | mensalidade por número/instância |
| **De quem é a sessão** | 🔴 **sua** — o número está na sua máquina | do fornecedor: se ele cair ou encerrar, você reconecta em outro lugar |
| **Manutenção** | sua: atualizar, reconectar quando cair | dele |
| **Risco de bloqueio** | igual nos dois | igual nos dois |

⚠️ **O critério não é marca, é posse.** A mesma ferramenta aparece dos dois lados: o que muda é de
quem é o servidor onde a sessão do seu WhatsApp está guardada.

📌 **E existe o caminho oficial.** Se o número é o principal da empresa e o volume é sério, a API
oficial da Meta é o caminho — ela custa por conversa, exige aprovação, e **não** é assunto deste
kit.

---

## 1. O endereço

Registro **A** de `evo.seudominio.com.br` (ou o nome que você preferir) apontando para o IP da VPS.

🔴 **Este endereço não é para divulgar.** Quem tiver a URL e a chave de API manda mensagem pelo seu
número.

## 2. 🔴 A conferência — aqui ela vale mais do que nos outros

> *"pesquisa a documentação oficial da Evolution API hoje: qual é a versão estável atual, qual
> imagem Docker usar, quais variáveis de ambiente são obrigatórias nesta versão, se exige Postgres
> e Redis, e se mudou alguma coisa no jeito de instalar. Me traz os links."*

Este projeto muda de forma com frequência: nome de imagem, variáveis, provedor de banco, formato do
webhook. **Não instale de memória, nem a partir de um tutorial antigo do YouTube** — inclusive este
documento.

O que o agente precisa trazer antes de escrever qualquer arquivo:

- a **imagem** e a **versão** a fixar (nunca `latest`);
- as variáveis **obrigatórias** desta versão — em especial a **chave de autenticação da API**;
- se esta versão exige **banco de dados** (Postgres) e **cache** (Redis) — as versões recentes
  exigem;
- a **porta interna** que o container escuta;
- onde a **sessão do WhatsApp** é gravada (é o que não pode se perder num restart).

## 3. Montar a stack — o molde já existe

Peça ao agente para escrever a stack **copiando o padrão das outras deste kit**, e confira você
mesmo que ela tem as cinco coisas:

| # | O que | Por quê |
|---|---|---|
| 1 | **Nenhuma porta publicada no host** (`ports:` não existe) | só o Traefik fala com a internet. Publicar a 8080 põe a sua API de WhatsApp na internet aberta |
| 2 | Na rede do Traefik **e** numa rede interna própria | banco e cache ficam invisíveis para o resto da máquina |
| 3 | As etiquetas do Traefik iguais às do NocoDB, trocando nome e porta | inclusive `traefik.swarm.network` — a etiqueta antiga é ignorada **em silêncio** e o sintoma é *bad gateway* sem log |
| 4 | **Volume** para a sessão e para o banco | sem volume, o WhatsApp desconecta a cada restart e você reconecta o QR toda vez |
| 5 | **Versão fixada** e a chave de API num arquivo de segredos em `/opt/infra/evolution/` | mesma regra de todo o resto: senha não vai para arquivo versionado |

> *"escreve a stack da Evolution seguindo o mesmo padrão do nocodb.yml deste kit, com a versão que
> você conferiu, sem publicar porta, com volume para a sessão, e me mostra antes de subir"*

**Deu certo quando:** `https://evo.seudominio.com.br` responde com cadeado, e responde **pedindo
autenticação** — não abrindo um painel para qualquer um.

## 4. Conectar o número

1. Criar uma instância pela API (o agente faz, com a sua chave).
2. Ler o **QR Code** com o WhatsApp do número secundário — igual ao WhatsApp Web.
3. Mandar uma mensagem de teste **para você mesmo**.

**Deu certo quando:** a mensagem chega no celular. Só isso prova; a instância aparecer como
"conectada" na API não prova.

## 5. Depois: quem vai usar isso

A Evolution sozinha não faz nada — ela é um cano. Quem usa é:

- o **n8n**, para automatizar conversa (é a combinação mais comum);
- o **Chatwoot**, para o atendimento humano cair numa caixa com histórico.

Cada uma dessas ligações é um trabalho próprio, e vem **depois** de o número estar conectado.

## 6. O que dá manutenção neste serviço

| O que acontece | O que fazer |
|---|---|
| a sessão cai (celular sem internet, WhatsApp Web deslogado) | reconectar o QR — por isso o volume importa |
| restart da máquina | conferir se as instâncias voltaram conectadas |
| o projeto lança versão nova | 🔴 a mesma regra de sempre: só sobe se traz algo que você quer, ou se a atual está dando problema |
| o número foi bloqueado | não há conserto técnico. Reveja o §0 antes de conectar outro |

## ⚠️ E o dado que passa por aqui

Toda conversa de cliente passa por esta máquina. Isso é **dado pessoal**, e em alguns ramos é dado
sensível. A responsabilidade sobre ele é sua a partir do momento em que ele entra no seu servidor —
veja [dados-sensiveis.md](dados-sensiveis.md).
