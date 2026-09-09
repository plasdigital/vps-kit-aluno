# Comece aqui — do zero até a sua primeira ferramenta no ar

Você vai montar um servidor seu e instalar nele as ferramentas que hoje se paga por mês.
**Você não vai digitar comando de servidor.** Quem executa é o agente de IA; você decide e confere.

A ordem importa. Alguns passos **não são reversíveis de graça** — estão marcados 🔴.

## A corrente inteira, em uma tela

```
   0. A mesa            Claude Code + esta pasta + o agente com mão na sua conta
        |
   1. O domínio         o nome  ->  sem ele não existe cadeado
        |
   2. A chave SSH  🔴   a chave da casa  ->  tem que existir ANTES de a máquina nascer
        |
   3. A máquina         comprada e provisionada pelo agente
        |
   4. O firewall        3 portas abertas, nada mais
        |
   5. O DNS             o nome apontando para o número
        |
   6. A base            Traefik (o cadeado) + Portainer (a janela)
        |
        +---> 7. A ferramenta que você quiser  (uma de cada vez)
                 Chatwoot · n8n · NocoDB · Evolution · qualquer projeto do GitHub
```

Da etapa 0 à 6 você faz **uma vez na vida**. Da 7 em diante é sempre o mesmo ciclo curto, e cada
ferramenta nova custa poucos minutos.

| Se você quer… | Vá para |
|---|---|
| entender o que vai gastar e se vale a pena | [README.md](README.md) |
| montar a máquina do zero | **§0 a §6, nesta ordem** |
| instalar o Chatwoot (atendimento) | [docs/instalar-chatwoot.md](docs/instalar-chatwoot.md) |
| instalar o n8n (automações) | [docs/instalar-n8n.md](docs/instalar-n8n.md) |
| instalar o NocoDB (a planilha que é banco) | [docs/instalar-nocodb.md](docs/instalar-nocodb.md) |
| instalar a Evolution API (WhatsApp por QR Code) | [docs/instalar-evolution.md](docs/instalar-evolution.md) |
| entender onde fica o **banco de dados** | [docs/onde-o-banco-mora.md](docs/onde-o-banco-mora.md) |
| **instalar uma ferramenta que você achou no GitHub** | [docs/instalar-do-github.md](docs/instalar-do-github.md) |
| saber por que cada decisão é assim | [docs/por-que-este-padrao.md](docs/por-que-este-padrao.md) |

---

## 0. A mesa — o que precisa existir no seu computador

Nada aqui é servidor ainda. É só deixar a mesa pronta.

| # | O que | Por que | ✅ Deu certo quando |
|---|---|---|---|
| 0.1 | **Um e-mail que você acessa** *(óbvio)* | é com ele que se cria todo o resto | — |
| 0.2 | **Forma de pagamento** | a máquina e a IA são pagas. Não existe caminho 100% grátis | — |
| 0.3 | **Um terminal aberto** *(óbvio)* | é a tela onde o agente trabalha. No Windows, o PowerShell serve | ele abre e aceita você digitar |
| 0.4 | **Node.js instalado** *(óbvio para quem já programa, novidade para o resto)* | é o motor que o Claude Code precisa | `node -v` responde um número |
| 0.5 | **Git instalado** *(óbvio)* | é o que baixa esta pasta | `git --version` responde um número |
| 0.6 | **Claude Code instalado** | é ele que executa tudo daqui pra frente | digitar `claude` abre a conversa |
| 0.7 | 🔴 **Plano Pro ou Max da IA** | o plano **grátis não dá Claude Code**. Codex e Antigravity funcionam igual, com assinatura própria | a conversa abre sem pedir upgrade |

### 0.8 — Baixar esta pasta

```bash
git clone https://github.com/plasdigital/vps-kit-aluno.git
cd vps-kit-aluno
claude
```

**Deu certo quando:** a pasta abriu e o agente respondeu. Ele já leu o `CLAUDE.md` que está aqui
dentro — é por isso que você conversa em português em vez de decorar comando.

### 0.9 — 🔴 Dar mão ao agente: a chave da API do provedor

Até aqui o agente só sabe *falar*. Este passo é o que dá a ele **mão** na sua conta de hospedagem:
comprar máquina, abrir firewall, criar registro de DNS, tirar snapshot.

Quase todo provedor tem uma **API**, e é por ela que o agente trabalha. Gere um token no painel da
sua conta (procure por *API*, *tokens* ou *desenvolvedor*) e guarde num arquivo que **não vai para
o git** — o `.gitignore` desta pasta já bloqueia `*.env`:

```bash
echo 'PROVEDOR_API_TOKEN=cole-o-token-aqui' > provedor.env
```

Depois é só dizer ao agente que o token está lá. Ele lê o arquivo na hora de chamar a API.

**Deu certo quando:** você pede *"lista as minhas VPS"* e ele responde com a sua conta de verdade.

⚠️ **Duas coisas que salvam tempo com API de provedor:**
- Muitas ficam atrás de um firewall que **recusa cliente sem identificação** — o sintoma é um `403`
  falando de *"browser signature"*, e não tem nada a ver com o seu token. Manda um `User-Agent`
  qualquer no cabeçalho e passa.
- **Erro de senha costuma vir com a lista de símbolos aceitos.** Senha aleatória comum é recusada;
  leia a mensagem, ela diz exatamente quais caracteres precisa ter.

#### O MCP do provedor — opcional

Alguns provedores oferecem um MCP, que é um atalho: o agente ganha as mesmas ações sem você gerar
token nenhum.

```bash
claude mcp add --transport http <provedor> https://mcp.<provedor>.com
```

**É conveniente, mas não conte com ele.** Numa sessão real de 08/set/2026 os oito servidores MCP do
provedor caíram com *"connection closed"* enquanto **a API respondia normalmente** — a instalação
inteira foi feita pela API, sem perder um passo. Por isso o caminho principal deste kit é a API, e
o MCP é o atalho de quem tem ele funcionando.

> 📌 **Você não precisa de nenhum dos dois para instalar.** Comprar a máquina, abrir o firewall e
> criar o DNS também se faz **clicando no painel** do provedor. A API existe para o agente fazer por
> você e para o passo a passo ficar repetível — não porque o painel esteja errado.

> 📌 **São duas IAs diferentes, e confundir as duas atrapalha muito.** O **Claude Code** é esta IA
> aqui, no terminal, que instala o servidor. A **IA dentro do n8n** é outra coisa: é a que vai rodar
> as suas automações depois (responder cliente, classificar, resumir). Nesta etapa só existe a
> primeira.

⛔ **A partir de agora o agente pode gastar dinheiro na sua conta.** Isso não é motivo para medo, é
motivo para entender: ele é obrigado a mostrar o que vai contratar e esperar o seu "pode" — mas se
você disser "compra" sem olhar, ele usa a forma de pagamento padrão da conta.

---

## 1. O domínio — o nome

> *"registra o domínio seudominio.com.br na minha conta"* — ou use um que você já tem.

🔴 **Sem domínio não existe cadeado.** O certificado gratuito (Let's Encrypt) **não é emitido para
endereço de número**. Sem cadeado o navegador acusa site inseguro, o WhatsApp recusa o webhook, e
metade das ferramentas simplesmente não funciona.

Você não precisa de um domínio bonito nem do nome da sua marca. Qualquer nome barato serve — ele vai
ser o endereço das suas ferramentas internas.

**Deu certo quando:** o domínio aparece na sua conta como *ativo* e o agente consegue listar a zona
de DNS dele. Domínio recém-registrado leva de minutos a algumas horas para responder no mundo
inteiro — por isso ele vem **antes** da máquina, e não depois.

### Os endereços que você vai usar

Decida agora, porque eles entram na configuração:

| Ferramenta | O que é | Endereço sugerido |
|---|---|---|
| Portainer (a janela da máquina) | o painel que mostra o que está rodando | `portainer.seudominio.com.br` |
| Chatwoot | a caixa onde as conversas chegam | `chat.seudominio.com.br` |
| n8n | as automações rodando sozinhas | `n8n.` **e** `webhook.seudominio.com.br` |
| NocoDB | a planilha que é banco de dados | `noco.seudominio.com.br` |
| Evolution API | o WhatsApp por QR Code | `evo.seudominio.com.br` |

🔴 **Escolha o nome definitivo agora.** Trocar depois é caro: ele fica gravado em link salvo, em
configuração de serviço e no webhook do WhatsApp.

---

## 2. 🔴 A chave SSH — **antes** de a máquina existir

> *"cria uma chave SSH pra minha VPS nova e cadastra na minha conta"*

A chave SSH é a chave da casa: um par de arquivos que substitui a senha. A máquina só abre a porta
para quem tem o arquivo.

🔴 **Esta é a trava número um deste kit.** A chave é injetada **no momento em que a máquina nasce**.
Anexar chave a uma VPS **já criada não funciona** — e o pior: a conta responde *sucesso*, com corpo
vazio, e a chave simplesmente não entra. Você só descobre quando tenta entrar e é recusado.

Foi conferido de novo em 08/set/2026, numa máquina real: o endpoint de anexar chave respondeu
`HTTP 200` com um corpo de objeto zerado (`id: 0`, `name: ""`), e o SSH seguiu recusando com
`Permission denied (publickey)`. **Sucesso na resposta não é prova de nada aqui** — a prova é
entrar.

Se você já errou isso: dá para colar a chave pública em `~/.ssh/authorized_keys` usando o terminal
que o painel do provedor abre dentro do navegador. Ou reinstalar o sistema da máquina com a chave
anexada — se ela ainda estiver vazia, é mais rápido.

**Deu certo quando:** o arquivo existe no seu computador (`~/.ssh/minha-vps`) **e** a chave pública
aparece cadastrada na sua conta do provedor.

⛔ **A parte privada da chave nunca sai do seu computador.** Não cole em chat, não mande por e-mail,
não versione. Se ela vazar, a casa é de quem tiver o arquivo.

---

## 3. A máquina

> *"sobe o postinstall desta pasta como script de pós-instalação, compra uma KVM 2 com Ubuntu 24.04
> no data center mais perto de São Paulo, usa a minha chave SSH e liga o backup automático"*

Duas coisas acontecem aqui, e é bom saber que são **duas**: **comprar** (a fatura) e **provisionar**
(instalar o sistema na máquina). A chave SSH e o script de pós-instalação entram na segunda.

| Campo | Escolha | Por quê |
|---|---|---|
| Plano | **KVM 2** — 2 vCPU · 8 GB · 100 GB | 🔴 o mais barato não serve: só o Chatwoot reserva 4,25 GB, antes do sistema |
| Sistema | **Ubuntu 24.04 LTS** | duas escolhas numa linha só — o **Ubuntu** e o **LTS**. Explicadas logo abaixo |
| Região | o data center **mais perto de quem usa** | não de onde você mora: é a latência que o seu atendente sente o dia inteiro |
| Chave SSH | a que você acabou de criar | é a única forma de entrar |
| Script de pós-instalação | o `postinstall.sh` desta pasta | roda sozinho no primeiro boot: instala o Docker, cria o Swarm e fecha o SSH |
| Backup automático | **ligado** | é o único que sobrevive a perder a máquina inteira |

### Por que Ubuntu, e por que LTS

Duas perguntas diferentes, e quase todo mundo responde as duas com um encolher de ombros.

**Por que Ubuntu e não outro Linux?** Tecnicamente, tanto faz: o Docker suporta oficialmente Ubuntu,
Debian, Fedora e RHEL, e o que este kit instala roda igual em qualquer um deles. O motivo é outro —
**quando der erro às 23h, a resposta que existe na internet foi escrita para Ubuntu.** O fórum do
Chatwoot, a issue do n8n, o README do projeto que você achou no GitHub: todos assumem `apt` e
Ubuntu. Debian é mais enxuto e igualmente sólido, e te deixa mais sozinho na hora do problema.

**Por que LTS, e não a versão mais nova?** *LTS* quer dizer *long term support*: **5 anos** de
correção de segurança sem você trocar de sistema. A versão comum do Ubuntu dura **9 meses** — você
estaria migrando o servidor uma vez por ano, de graça.

**E entre uma LTS e a LTS seguinte, fique na anterior por um tempo.** O que quebra numa versão
recém-lançada não costuma ser o Docker: é tudo o que está em volta — o script do provedor, a imagem
que assume o nome da versão antiga, o tutorial que o seu agente vai ler. É a mesma régua do resto
deste kit: **a última versão não é a melhor versão.** Troque quando alguém já tiver rodado este
caminho inteiro nela.

⏸️ **O agente vai parar e pedir confirmação antes de comprar.** É de propósito. Confira plano, preço
e período antes de dizer "pode".

⚠️ **Se o painel recusar o script com erro 403**, não é tamanho: o firewall do provedor implica com
os trechos de segurança que existem lá dentro. A saída é mandar o script empacotado em base64 dentro
de um envelope de seis linhas — peça: *"empacota o postinstall pro painel"*.

⚠️ **Sobre o "mínimo" que a documentação de qualquer software promete:** número de documentação vem
com um "para quê" embutido. O Chatwoot diz que 4 GB bastam — é o limiar de *sobreviver*, não de
*funcionar com mais alguma coisa junto*. Sempre pergunte: **mínimo para quê?**

**Deu certo quando:** a máquina aparece como *running* e você recebe o IP.

---

## 4. Fechar a máquina — **antes** de instalar qualquer coisa

> *"cria um firewall liberando só 22, 80 e 443, aplica nessa VPS e me mostra o resultado"*

Três portas: 22 (a sua entrada), 80 e 443 (o site). Nada mais.

🔴 **Use o firewall do painel do provedor, não o de dentro da máquina.** Uma regra errada no firewall
de dentro te tranca do lado de fora do seu próprio servidor, e só se sai disso pelo console de
recuperação. Errou no painel? Você clica e corrige.

⚠️ O provisionamento de alguns provedores **reabre o login de root por senha** — é o template deles,
não erro seu. O `postinstall.sh` corrige isso, e o arquivo de correção precisa começar com `01-` no
nome (o SSH lê a pasta em ordem alfabética e vale o **primeiro** valor que encontra).

**Deu certo quando:** o agente mostra a lista de portas da máquina com só 22, 80 e 443 escutando
para fora.

---

## 5. Apontar os endereços (DNS)

> *"tira um snapshot da zona de DNS e cria o registro A de portainer apontando pro IP da VPS"*

Um registro **A** para cada endereço da tabela da §1, todos apontando para o mesmo IP.

🔴 **Acrescente, nunca sobrescreva.** Se esse domínio já serve o e-mail da empresa, mexer errado na
zona **derruba o e-mail** — e ninguém percebe na hora. Peça ao agente para listar a zona antes e
depois: tem que ter os registros antigos **+ os novos**.

⚠️ Se o domínio está em **outro registrador**, o agente não alcança a zona pela API do provedor da
VPS: nesse caso os registros se criam no painel de quem hospeda o DNS, e o resto do processo não
muda em nada.

**Deu certo quando:** o nome resolve para o seu IP. Pode levar alguns minutos.

---

## 6. A base — Traefik e Portainer

```bash
cp vps.env.exemplo vps.env      # e preencha os endereços e o seu e-mail
```

> *"envia essa pasta pra minha VPS e sobe o Traefik e o Portainer"*

O que sobe aqui não é ferramenta de trabalho — é o **chão** onde todas as outras vão pisar:

- **Traefik** é o porteiro. Toda visita da internet bate nele, e é ele quem pede e renova o
  certificado (o cadeado) sozinho, de graça. Nenhuma outra peça fala com a internet.
- **Portainer** é a janela: a tela onde você vê o que está rodando sem abrir terminal.

⚠️ **Se você usa Windows:** os arquivos chegam com uma marca invisível no fim de cada linha e o
Linux reclama de "comando não encontrado" em lugares sem sentido. É a causa mais provável de um
deploy que falha sem explicação. O agente já corrige; se você criar um arquivo novo, lembre.

**Deu certo quando:** `https://portainer.seudominio.com.br` abre **com cadeado**, e o emissor do
certificado é o Let's Encrypt.

Se aparecer "TRAEFIK DEFAULT CERT" no lugar, o DNS ainda não propagou. **Espere** — não recrie o
serviço: quem emite o certificado tem trava de tentativa (5 falhas por hora, por domínio) e insistir
só atrasa.

🔴 **O Portainer se tranca em 5 minutos.** Se ninguém definir a senha do administrador nesse prazo,
ele responde *"initialization timeout"* e só volta reiniciando o serviço. Neste kit a senha é
definida no próprio deploy — a máquina nasce com dono.

---

## 6.5. 🔴 Antes de instalar qualquer aplicação, o agente descobre a versão

> *"antes de instalar, descobre a última versão estável desse projeto, confere os avisos de
> segurança e preenche o vps.env"*

Os arquivos daqui vêm com a versão em branco (`PREENCHER`). **Este kit não decide versão por você**
— quem descobre o número é o agente, na hora de instalar, olhando as releases e os advisories de
segurança do projeto.

É assim porque o contrário já falhou: quando o kit trazia versão fixa, ele envelheceu e passou a
ensinar, sem avisar, versões com falha conhecida. O protocolo inteiro está em
[docs/antes-de-instalar.md](docs/antes-de-instalar.md).

**Deu certo quando:** o agente disser **qual versão vai instalar, como descobriu, e o que achou de
segurança**. Se ele não falou as três coisas, ele não conferiu.

⛔ E se a versão mais nova tiver aviso aberto ou mudança que quebra: **a decisão é sua, não dele.**
A pergunta certa nunca é *"qual é a última?"*, é **"o que a nova traz que eu quero, e o que eu
perco?"**

📌 **Depois de instalado, a régua vira outra: o padrão é ficar parado.** Descobrir a última versão
vale para a instalação. Atualizar depois só por dois motivos — a nova tem algo que você quer, ou a
atual está dando problema constatado (e aviso de segurança conta como problema constatado).

---

## 7. A ferramenta — uma de cada vez

A máquina está de pé e **vazia**, de propósito. Agora cada ferramenta é um ciclo curto, e é sempre o
mesmo ciclo:

```
   registro A do subdomínio  ->  segredos em /opt/infra/<app>/  ->  conferir a doc oficial
        ->  bash /opt/infra/deploy-<app>.sh  ->  abrir no navegador e ver o cadeado
```

| O que instalar | Para quê | Passo a passo |
|---|---|---|
| **Chatwoot** | atendimento: várias pessoas na mesma caixa, histórico que não expira | [docs/instalar-chatwoot.md](docs/instalar-chatwoot.md) |
| **n8n** | automação: o que precisa acontecer às 3 da manhã sem ninguém acordado | [docs/instalar-n8n.md](docs/instalar-n8n.md) |
| **NocoDB** | a planilha da equipe que na verdade já virou banco de dados | [docs/instalar-nocodb.md](docs/instalar-nocodb.md) |
| **Evolution API** | WhatsApp por QR Code ⚠️ não é o oficial: leia o §0 do documento antes | [docs/instalar-evolution.md](docs/instalar-evolution.md) |
| **Qualquer projeto do GitHub** | o que ninguém vende pronto para o seu problema | [docs/instalar-do-github.md](docs/instalar-do-github.md) |

📌 **E o banco de dados?** Ele não entra nesta lista de propósito: a recomendação é **contratar**, não
instalar aqui — o porquê está em [docs/onde-o-banco-mora.md](docs/onde-o-banco-mora.md).

⚠️ **Uma de cada vez, sempre.** As ferramentas convivem bem na mesma máquina, mas instalar três de
uma vez transforma qualquer erro num quebra-cabeça: você não sabe qual peça falhou. Suba uma,
confirme que abre com cadeado, e só então a próxima.

⚠️ **Antes da terceira aplicação, olhe a memória.** Peça: *"quanto de memória sobrou?"*. Não é para
otimizar nada — é para você saber se a próxima cabe.

---

## 8. Provar que está no ar — e não se enganar sozinho

> *"roda a lista de aceitação"*

| O quê | Esperado |
|---|---|
| serviços saudáveis | histórico **sem falha recente** |
| o site responde | com certificado válido do Let's Encrypt |
| a máquina está fechada | **só** 22, 80 e 443 escutando |
| backup | rodar na mão e ver o arquivo aparecer, **com tamanho** |

⚠️ **Duas formas clássicas de se enganar:**

- O painel dizendo **"1 de 1"** não prova saúde — um serviço reiniciando em loop aparece assim
  durante os segundos em que a tentativa nova está viva. Quem conta a verdade é o **histórico**.
- Uma tela que **abre** não prova que ela está liberada nem que está bloqueada. A prova é bater na
  interface de programação, não olhar a página.

---

## 9. Depois — a manutenção que existe de verdade

Você trocou mensalidade por manutenção. É pouca, mas não é zero:

- **Atualização:** o sistema instala correção de segurança sozinho, mas **não reinicia** a máquina.
  De vez em quando pergunte: *"tem atualização pendente? precisa reiniciar?"*
- **Backup:** cada aplicação instala o seu, e ele mora **na própria máquina**. Confirme no painel do
  provedor que o backup automático da VPS está ligado — é o único que sobrevive a perder a máquina.
  🔴 **Snapshot não é backup:** ele expira e é rede de proteção da manutenção do dia.
- **Versão:** o padrão é **ficar parado**. Só se atualiza quando a versão nova tem algo que você
  quer, ou quando a atual está dando problema **constatado**.
