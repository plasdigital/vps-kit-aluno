# A partir daqui, a máquina guarda dado de gente

Antes do Chatwoot, a VPS não guardava nada de ninguém. Depois dele, guarda. A superfície não mudou
só de tamanho — mudou de natureza, e é por isso que este documento existe.

## O que muda na prática

**Conversa de cliente final é dado pessoal.** Dependendo do seu ramo, é dado **sensível**: saúde
(clínica, farmácia, laboratório), dado financeiro, dado de criança. Sensível tem regra mais dura na
LGPD, e o anexo costuma ser pior que o texto — uma foto de receita, um documento, um comprovante.

## O que o kit já faz por você

| Cuidado | Onde |
|---|---|
| banco e fila **não alcançáveis** de fora, nem pelos outros programas da máquina | rede interna própria, na stack |
| nenhuma porta nova aberta | só o proxy publica porta |
| backup com pasta e arquivo **fechados** (só o dono lê) | `backup-chatwoot.sh` |
| backup **não sai da máquina** | idem |
| **registro de acesso do proxy desligado** | `stacks/traefik.yml` |

O último merece explicação: ligado, o registro do proxy guardaria o endereço que **cada cliente
final** acessou, a cada requisição. É um arquivo de log que ninguém lembra que existe e que vira um
histórico de navegação de terceiros. Fica desligado de propósito.

## O que continua com você

- [ ] **Quem tem acesso ao painel.** Cada atendente com login próprio — nunca uma conta compartilhada
      pelo time. Quando alguém sai da empresa, o login sai junto.
- [ ] **Onde as senhas moram.** Dentro da VPS, em arquivo fechado. Não em planilha, não em grupo de
      WhatsApp, não em documento compartilhado.
- [ ] **Quem entra na máquina.** Só por chave. Chave de quem saiu, se remove.
- [ ] **Pedido de exclusão.** Se um cliente pedir para apagar os dados dele, você precisa conseguir
      fazer isso. Saiba de antemão como.
- [ ] **Não olhar conversa "para dar uma olhada".** Vale para você e vale para o agente — está
      escrito como trava no `CLAUDE.md`.

## Se você faz isso para um cliente

A infra é **dele**: a conta do provedor, o domínio, a máquina, as credenciais. Você opera. Isso não é
formalidade — é o que define de quem é o dado se a relação acabar, e é o que você consegue prometer
com honestidade a ele.

E o desenho de retenção vem **antes** do código: decida com ele por quanto tempo a conversa fica
guardada, e registre a decisão por escrito. Ver [retencao-e-backup.md](retencao-e-backup.md).
