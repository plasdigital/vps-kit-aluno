# Instalar uma ferramenta que você achou no GitHub

> **Antes de começar:** a máquina de pé e a base no ar ([COMECE-AQUI.md](../COMECE-AQUI.md), §0 a §6).

Este é o documento que faz a sua máquina valer a pena. Chatwoot, n8n e NocoDB já vêm prontos aqui —
mas eles são três. **No GitHub existem milhares de ferramentas que resolvem problema de empresa e
não aparecem em anúncio nenhum**, porque não têm vendedor.

Antes de contratar qualquer mensalidade, a pergunta passa a ser outra:

> *"será que já existe isso pronto, de graça, para eu instalar na minha máquina?"*

E a resposta é "sim" com uma frequência que surpreende: editor de vídeo, CRM, gestão de projeto,
controle financeiro, encurtador de link, formulário, assinatura de documento, painel de métricas.

---

## 1. Onde procurar, e o que digitar

O GitHub é onde os programadores guardam e compartilham os projetos. Procurar lá não é diferente de
procurar em qualquer lugar — o que muda são **as palavras**:

| Onde | O que digitar |
|---|---|
| Busca do GitHub | `crm self-hosted`, `whatsapp crm docker`, `invoice self hosted` |
| Busca do GitHub, por assunto | a barra de *Topics*: `selfhosted`, `docker-compose`, `nocode` |
| A lista da comunidade | procure por **awesome-selfhosted** — é um catálogo enorme, organizado por categoria |
| Comparador de ferramenta | sites de "alternativas a X" costumam marcar quais são instaláveis |
| **O próprio agente** | *"pesquisa projetos open source de \<o seu problema\> que dê para instalar por Docker, e me traz 3 com licença permissiva e manutenção recente"* |

🔴 **A palavra-chave que muda tudo é `self-hosted`** (instalável no seu servidor). Sem ela você
acha o site da versão paga; com ela você acha o código.

⚠️ **Procure em inglês.** A quase totalidade destes projetos só existe em inglês, inclusive os
brasileiros. Peça ao agente para traduzir o que achar — não deixe de achar por causa do idioma.

---

## 2. 🔴 Ler o repositório ANTES de instalar

Achar é fácil. O que separa quem monta uma operação de quem entope a máquina de coisa quebrada é
**ler antes**. Peça ao agente:

> *"analisa esse repositório pra mim: o que ele faz, qual a licença, quando foi o último commit,
> quantas issues abertas, se tem docker-compose, do que ele depende (banco, API paga), e me diz se
> vale instalar"*

O que se olha, em ordem:

| # | O que | O que você quer ver | 🚩 Bandeira vermelha |
|---|---|---|---|
| 1 | **Licença** | MIT, Apache 2.0, AGPL — permitem usar na sua empresa | "sem licença" (por padrão, ninguém pode usar), ou licença que proíbe uso comercial |
| 2 | **Último commit** | movimento nos últimos meses | parado há 2 anos, ou repositório **arquivado** |
| 3 | **Issues abertas** | gente reclamando **e sendo respondida** | dezenas de "não instala" sem resposta |
| 4 | **Releases com número de versão** | dá para fixar a versão | nenhuma release: só existe `latest`, e você fica no que o autor subir hoje |
| 5 | **Docker** (`Dockerfile` ou `docker-compose.yml`) | metade do trabalho já está feito | sem Docker: instalação na mão, dependência do sistema, e mais chance de quebrar |
| 6 | **Documentação de instalação** | passo a passo que fala de servidor, não só de "rodar no meu computador" | só `npm run dev` e nada sobre produção |
| 7 | **Do que ele depende** | banco, cache, e **serviços pagos** (uma API de IA, uma API de mensagem) | dependência paga escondida — o projeto é grátis, mas não funciona sem uma conta que custa |
| 8 | **Quem mantém** | empresa ou pessoa com outros projetos | conta criada mês passado, sem mais nada |

⚠️ **Estrela não é qualidade.** Projeto com 20 mil estrelas pode estar abandonado; projeto com 300
pode ser mantido todo dia por quem usa em produção. O que conta é a data do último commit e a
conversa nas issues.

### 🚩 As bandeiras vermelhas que fazem desistir na hora

- **O compose monta `/var/run/docker.sock` dentro do container.** Isso dá ao projeto o controle da
  sua máquina inteira. Existem casos legítimos (o próprio Portainer faz), mas para uma ferramenta
  qualquer é motivo para não instalar.
- **Ele pede para rodar como `root` sem explicar por quê.**
- **A instalação é `curl ... | bash`** de um endereço que não é o repositório oficial.
- **Não tem release, não tem licença e não tem issue respondida.** Três de uma vez é resposta.
- **O README promete demais e não mostra tela.** Projeto sério mostra print ou demonstração.

> **A verdade que precisa ser dita:** instalar projeto de terceiro é **rodar o código de outra
> pessoa dentro da sua máquina**, com acesso ao que estiver ali. O critério não é medo, é
> proporção: para uma ferramenta interna que só você abre, o risco é pequeno; para algo que vai
> guardar o cadastro dos seus clientes, leia com o dobro do cuidado.

---

## 3. As três perguntas antes de subir

1. **O que ele guarda?** Se guarda dado de cliente, ele entra na sua responsabilidade — backup e
   controle de acesso ([dados-sensiveis.md](dados-sensiveis.md)).
2. **Quem pode abrir?** Ferramenta interna não precisa estar aberta para a internet inteira. Se ela
   não tem login próprio bom, é melhor não publicar.
3. **Ele cabe?** Peça *"quanto de memória sobrou?"* antes. Toda ferramenta nova come um pedaço.

---

## 4. O ciclo de instalação — sempre o mesmo

```
   1. ler o repositório        (§2)
   2. conferir a doc de hoje   (docs/antes-de-instalar.md)
   3. registro A do subdomínio
   4. adaptar o compose ao padrão desta máquina   (§5)
   5. segredos em /opt/infra/<app>/
   6. subir e provar na tela
   7. decidir o backup         (§7)
```

> *"instala esse projeto na minha VPS seguindo o padrão deste kit: sem publicar porta, atrás do
> Traefik em app.seudominio.com.br, com versão fixada, e me mostra a stack antes de subir"*

---

## 5. 🔴 As adaptações que quase todo `docker-compose` precisa

O compose que vem no repositório foi escrito para **rodar no computador do programador**, não na sua
VPS. Ele quase nunca serve como está. As adaptações são sempre as mesmas:

| O que vem no projeto | O que fazer aqui | Por quê |
|---|---|---|
| `ports: - "3000:3000"` | **remover** | publicar porta põe a ferramenta na internet **sem cadeado e sem o Traefik**. Quem publica é só o Traefik |
| nenhuma etiqueta de Traefik | **acrescentar** as mesmas do `nocodb.yml`, trocando nome e porta | é o que faz o cadeado sair e o endereço funcionar |
| `image: projeto:latest` | **fixar a versão** que você conferiu | `latest` troca sozinho no primeiro restart |
| `build: .` (constrói na hora) | preferir a **imagem publicada**, se existir; se não, construir na máquina e fixar a marca | construir a cada deploy é lento e traz surpresa |
| variáveis com senha no próprio arquivo | mover para `/opt/infra/<app>/<app>.env`, com permissão só do dono | segredo não entra em arquivo versionado |
| sem `volumes:` | acrescentar volume para o que **não pode se perder** | sem volume, o dado some no primeiro restart |
| `restart: unless-stopped` | vira política de reinício do Swarm | esta máquina roda em Swarm, não em compose simples |
| rede padrão | a rede do Traefik **+** uma rede interna própria | banco e cache ficam invisíveis para o resto |

⚠️ **A etiqueta que engana:** aqui é `traefik.swarm.network`, e **não** `traefik.docker.network`. A
antiga é ignorada **em silêncio**, e o sintoma é *bad gateway* sem nada no log. É o erro que mais
custa tempo neste tipo de instalação.

---

## 6. Um exemplo de verdade: um CRM de WhatsApp do GitHub

Vamos usar um projeto real como exercício — `github.com/ArnasDon/wacrm`, um CRM para WhatsApp com
caixa compartilhada, funil e disparo. **O que interessa aqui não é este projeto: é o raciocínio**,
que se repete em qualquer outro.

### Passo 1 — o que a leitura mostrou

| O que se olhou | O que se achou | Leitura |
|---|---|---|
| Licença | MIT | 🟢 pode usar na empresa |
| Docker | tem `Dockerfile` e `docker-compose.yml` | 🟢 meio caminho |
| Tecnologia | Next.js (Node) | 🟢 comum, o agente sabe lidar |
| Do que depende | **Supabase** (banco + login + arquivos) e a **API oficial da Meta** para o WhatsApp | 🟡 dependência externa: sem elas, o app sobe e não faz nada |
| Porta | 3000, dentro do container | — |
| Como o compose está escrito | `build: .` e `ports: 3000` | 🟡 escrito para o computador do programador |

### Passo 2 — o que isso muda no plano

- **O banco não vai para a VPS.** Este projeto espera Supabase, e Supabase é para **contratar** —
  veja [onde-o-banco-mora.md](onde-o-banco-mora.md). Você cria o projeto na conta gratuita e
  aponta o app para lá. A máquina roda só a aplicação.
- **O WhatsApp dele é o oficial da Meta**, não QR Code. Ou seja: este CRM **não** se liga na
  Evolution sem trabalho de adaptação. É exatamente o tipo de coisa que só se descobre lendo antes —
  e que teria custado uma tarde depois.
- **O compose precisa das adaptações da §5:** tirar `ports`, entrar na rede do Traefik, ganhar as
  etiquetas, fixar a marca da imagem, e as chaves vão para um arquivo de segredos na máquina.

### Passo 3 — o pedido ao agente

> *"lê o repositório ArnasDon/wacrm, confere na documentação oficial dele o que é exigido hoje, e
> monta a stack pra minha VPS seguindo o padrão deste kit: sem publicar porta, atrás do Traefik em
> crm.seudominio.com.br, imagem construída e fixada, variáveis do Supabase e da Meta num arquivo de
> segredos em /opt/infra/wacrm/. Me mostra a stack e o que falta eu providenciar antes de subir."*

### Passo 4 — a prova

Abrir `https://crm.seudominio.com.br` com cadeado, **fazer login** e ver a tela dele carregando os
dados do seu Supabase. Enquanto não logar e ver dado, não está instalado — está apenas no ar.

---

## 7. Depois de instalado — o que agora é seu

Nenhuma dessas ferramentas vem com alguém cuidando dela. A partir de agora:

| O que | Como |
|---|---|
| **Backup** | as ferramentas deste kit já instalam o seu. **A que você trouxe do GitHub, não.** Decida no dia da instalação o que precisa ser salvo (o banco? o volume?) e peça ao agente para instalar a rotina |
| **Atualização** | 🔴 o padrão é ficar parado. Acompanhe as releases; suba de versão só quando a nova trouxer algo que você quer, ou a atual der problema |
| **Quando quebrar** | *"deu esse erro aqui, o que é de verdade?"* — a tabela de armadilhas do `CLAUDE.md` cobre boa parte |
| **Se você desistir dela** | peça para remover a stack, o volume e o registro de DNS. Ferramenta abandonada rodando é memória gasta e porta a mais para cuidar |

## 8. Quando desistir — e não tem problema nenhum

Desista sem culpa quando: o projeto não sobe depois de duas tentativas honestas; a documentação não
fala de produção; ele exige um serviço pago que custa mais que a mensalidade que você queria evitar;
ou você não entendeu o que ele faz.

**A conta que importa não é "de graça × pago". É o seu tempo.** Uma ferramenta que custa R$ 50 por
mês e funciona pode ser mais barata do que três tardes tentando instalar a alternativa livre. A
diferença é que agora **você escolhe** — antes, você só tinha a opção de pagar.
