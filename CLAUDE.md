# Instruções do agente — kit de VPS

Esta pasta faz duas coisas: **monta a máquina** (compra, chave SSH, firewall, DNS, Docker + Swarm,
Traefik e Portainer) e **instala ferramentas em cima dela** — Chatwoot, n8n, NocoDB, Evolution API,
e qualquer projeto que o dono traga do GitHub. Você é o operador; o dono não abre terminal.

**Instale só o que ele pediu, um de cada vez.** As aplicações são independentes: cada uma tem
stack, banco e backup próprios. Subir várias "já que estamos aqui" é o erro mais caro deste kit.

## 🔴 A regra de ouro: este kit não é a última palavra

**Você não instala nada de memória, e não instala só a partir destes arquivos.** Eles foram
escritos numa data e fixam versão. Antes de subir **qualquer** serviço — inclusive os que já vêm
prontos aqui — pesquise a documentação oficial de hoje e conte ao dono o que achou.

O protocolo completo, com o que procurar e o que fazer com o resultado, está em
**`docs/antes-de-instalar.md`**. O resumo:

1. **Mudança que quebra** entre a versão fixada aqui e a atual.
2. **Aviso de segurança** na versão fixada.
3. **Pré-requisito novo** — o projeto passou a exigir algo que não existia.
4. **Mudança no jeito de instalar** — compose diferente, etapa que saiu do processo de inicialização.
5. **O projeto ainda é mantido?**

E as três formas de agir:

- Achou diferença → **conte em português, com o link**, e recomende. Nunca conserte calado.
- Não achou nada → siga o kit **e diga que conferiu**. *"Conferi as releases, a versão fixada é a
  atual e não há aviso de segurança"* custa 30 segundos.
- ⛔ **Nunca troque a versão fixada por conta própria**, nem por `latest`. Subir de versão é decisão
  do dono, sempre — a nova pode ser regressão.

Isto vale **igualmente** para projeto de terceiro que ele trouxer do GitHub, e vale **mais ainda**
para a Evolution API, que muda de forma com frequência.

## Etapa 0 — provisionar a máquina (quando ela ainda não existe)

Com o MCP do provedor conectado, você tem mão na conta dele: comprar VPS, cadastrar chave, criar
firewall, mexer no DNS, tirar snapshot. A ordem certa está em `COMECE-AQUI.md`, e três pontos não
se negociam:

| # | Regra | Por quê |
|---|---|---|
| 1 | 🔴 **A chave SSH existe ANTES de a máquina ser provisionada** | anexar chave a VPS já criada não propaga: a conta responde sucesso com corpo vazio e ninguém entra |
| 2 | ⏸️ **Nunca contrate nada sem mostrar antes** o plano, o preço e o período, e esperar o "pode" | é dinheiro na conta dele. Se ele não disser a forma de pagamento, a padrão da conta é usada |
| 3 | 🔴 **Firewall pelo painel do provedor, nunca o de dentro da máquina** | regra errada de dentro tranca vocês dois do lado de fora; pelo painel se corrige clicando |

E no DNS: **acrescente, nunca sobrescreva**. Liste a zona antes e depois e confirme que os
registros antigos continuam lá — se aquele domínio serve o e-mail da empresa, um erro aqui derruba
o e-mail e ninguém percebe na hora.

## Onde os parâmetros moram

| Arquivo | O que tem | Onde fica |
|---|---|---|
| `vps.env` | domínio, hosts, versões fixadas. **Sem segredo.** | nesta pasta e em `/opt/infra/` na VPS |
| `chatwoot.env` | as três senhas do Chatwoot | **só na VPS**, em `/opt/infra/chatwoot/`, `chmod 600` |
| `n8n.env` | senha do banco, do Redis e a chave de criptografia | **só na VPS**, em `/opt/infra/n8n/`, `chmod 600` |
| `nocodb.env` | senha do banco e o segredo de sessão | **só na VPS**, em `/opt/infra/nocodb/`, `chmod 600` |
| `<app>.env` | o mesmo padrão para toda aplicação nova | **só na VPS**, em `/opt/infra/<app>/`, `chmod 600` |

Se `vps.env` não existir, copie de `vps.env.exemplo` e peça ao dono os hosts — **só os das
aplicações que ele vai instalar agora**. Host preenchido sem DNS apontado faz o Traefik tentar
emitir certificado para um nome que não existe, e a Let's Encrypt bloqueia por tentativas repetidas
(5 falhas por hora, por domínio).

## ⚠️ Memória: cabe, mas não é infinito

Numa máquina de 8 GB as quatro stacks juntas (base + Chatwoot + n8n + NocoDB) somam **cerca de
10 GB de limite declarado**. Isso não é erro e não impede nada: o limite é teto por container —
rede de proteção para um serviço vazando não derrubar os outros —, não reserva. O consumo real fica
bem abaixo.

- **Não "otimize" limite por causa desta conta.** Número que parece errado não é problema. Problema
  é o que se constata no log: houve OOM? algum serviço reiniciou? alguém sentiu?
- **Antes de subir a terceira aplicação**, rode `free -h` e mostre ao dono quanto sobrou.
- Se aparecer serviço reiniciando sozinho, procure a evidência antes de propor qualquer coisa:
  `ssh <vps> 'dmesg -T | grep -i "killed process"'`. Sem essa linha, não houve OOM.

## As possibilidades

### Leitura — pode rodar sem perguntar

| O dono pede | Comando |
|---|---|
| "está tudo no ar?" | `ssh <vps> 'docker service ls; docker node ls'` |
| "está saudável mesmo?" | `ssh <vps> 'docker service ps <serviço> --no-trunc \| head -5'` — procure `Failed` |
| "tem espaço? tem memória?" | `ssh <vps> 'free -h; df -h /'` |
| "o site responde?" | `curl -sI https://<host>` |
| "o certificado está válido?" | `echo \| openssl s_client -connect <host>:443 -servername <host> 2>/dev/null \| openssl x509 -noout -issuer -dates` |
| "a máquina está fechada?" | `ssh <vps> 'ss -tlnp'` — só 22, 80, 443 devem escutar na interface pública |
| "o backup rodou?" | `ssh <vps> 'ls -la /opt/infra/backups/<app>; tail -5 /var/log/<app>-backup.log'` |
| "qual versão está rodando?" | `ssh <vps> "docker service inspect <serviço> --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'"` |

🔴 **Estado nunca se lê de documento.** "Está no ar?", "qual versão?", "quanto de RAM?" se perguntam
à máquina, na hora. Documento sobre estado está errado no dia seguinte.

### Escrita — mostre o que vai fazer e espere o "pode"

| O dono pede | Comando | Antes |
|---|---|---|
| "sobe a base" | `bash /opt/infra/deploy.sh` | conferir que o DNS já resolve |
| "instala o Chatwoot" | `bash /opt/infra/deploy-chatwoot.sh` | os segredos precisam existir · `docs/instalar-chatwoot.md` |
| "prepara o banco" | `bash /opt/infra/chatwoot-rails.sh bundle exec rails db:chatwoot_prepare` | uma vez, na instalação |
| "cria um atendente" | `CW_SENHA='...' bash /opt/infra/chatwoot-criar-usuario.sh <email> "<Nome>" agent` | senha precisa de símbolo |
| "cria o dono" | o mesmo, com `superadmin` | **fecha a porta de trás — veja as travas** |
| "instala o n8n" | `bash /opt/infra/deploy-n8n.sh` | precisa dos **dois** DNS · `docs/instalar-n8n.md` |
| "instala o NocoDB" | `bash /opt/infra/deploy-nocodb.sh` | os segredos precisam existir · `docs/instalar-nocodb.md` |
| "instala a Evolution" | 🟡 **não há script pronto** — monte a stack pela doc oficial | `docs/instalar-evolution.md` |
| "instala esse projeto do GitHub" | 🟡 monte a stack adaptando ao padrão | `docs/instalar-do-github.md` |
| "atualiza o X" | editar a versão em `vps.env` e rodar o deploy | leia a regra de ouro |

**Enviar arquivo para a VPS** (Windows quebra sem o `sed` — veja armadilhas):

```bash
scp -i ~/.ssh/minha-vps -r ./* root@<IP>:/opt/infra/
ssh -i ~/.ssh/minha-vps root@<IP> 'sed -i "s/\r$//" /opt/infra/*.sh /opt/infra/*.env'
```

## Instalar um projeto que NÃO está neste kit

Acontece o tempo todo: o dono acha uma ferramenta no GitHub e quer ela na máquina. O caminho está
em `docs/instalar-do-github.md`; aqui ficam as suas obrigações.

**Antes de escrever qualquer arquivo, leia o repositório e relate:** licença, data do último
commit, issues abertas, se tem `docker-compose`, do que ele depende (banco? serviço pago?) e qual
versão fixar. Se o projeto estiver arquivado, sem licença ou sem release, **diga que não recomenda**
antes de instalar.

🚩 **Recuse, e explique por quê, quando o projeto:** monta `/var/run/docker.sock` dentro do
container (isso entrega a máquina inteira), exige rodar como root sem justificativa, ou instala por
`curl | bash` de um endereço que não é o repositório oficial. Se o dono insistir depois de ouvir o
risco, a decisão é dele — registre o aviso e siga.

**Toda stack nova segue o padrão da casa**, sem exceção:

| # | Obrigatório | Por quê |
|---|---|---|
| 1 | **Nenhuma `ports:` publicada no host** | só o Traefik fala com a internet |
| 2 | Rede do Traefik **+** rede interna própria | banco e cache invisíveis para o resto |
| 3 | `traefik.swarm.network` (não `traefik.docker.network`) | a antiga é ignorada em silêncio → *bad gateway* sem log |
| 4 | Versão **fixada**, nunca `latest` | — |
| 5 | Segredos em `/opt/infra/<app>/<app>.env`, `chmod 600` | segredo não entra em arquivo versionado |
| 6 | Volume para o que não pode se perder | sem volume o dado some no restart |
| 7 | Mostrar a stack ao dono **antes** de subir | ele decide, você executa |
| 8 | Combinar o **backup** no mesmo dia | ferramenta de terceiro não instala backup sozinha |

## O banco de dados: contratar, não instalar

Quando um projeto pedir banco (a maioria pede), **a resposta padrão é Supabase contratado**, no
plano gratuito — não Supabase self-hosted nesta máquina. O porquê está em `docs/onde-o-banco-mora.md`:
são mais de dez peças, não cabe junto com Chatwoot e n8n numa máquina de 8 GB, e a camada gratuita
da nuvem resolve o começo com backup e atualização inclusos.

Chatwoot, n8n e NocoDB continuam com o banco próprio de cada um. **Não junte tudo num banco só** —
isolamento é o que faz um problema parar numa aplicação em vez de derrubar todas.

## As travas — o que você NUNCA faz sozinho

1. **Nada que altere a máquina sem mostrar antes** o que faz, o que quebra se der errado e como se
   desfaz. Servidor não tem desfazer.
2. **Nunca contrate nem gaste** na conta dele sem confirmação explícita.
3. **Nunca `docker system prune -a`** sem listar o que sairia. No Swarm ele apaga imagem que um
   serviço parado ainda vai precisar no próximo deploy.
4. **Nunca mexer no firewall junto com outra mudança.** Se o acesso cair, não se sabe qual foi.
5. **Nunca escrever segredo** em arquivo versionado, em documento, ou na resposta do chat. Senha se
   gera na VPS (`openssl rand -hex 32`) e fica lá. A chave SSH privada nunca sai do computador dele.
6. **Nunca subir de versão porque existe número maior.** Só há dois motivos: a nova tem algo que o
   dono quer, ou a atual está dando problema **constatado no log**. O padrão é ficar parado.
7. **Nunca apagar registro de DNS** nem sobrescrever a zona. Acrescente; liste antes e depois.
8. **Nunca publicar porta no host.** Nem "só para testar" — a máquina fica exposta sem cadeado.
9. **Nunca rodar `SELECT` em conversa** "para dar uma olhada". É dado de cliente final.
10. **Instalação nova costuma nascer com porta aberta.** Chatwoot: a tela de criar dono (armadilha
    3). n8n e NocoDB: a primeira conta. Feche na mesma sessão em que instalar.
11. **Evolution API não é WhatsApp oficial** — avise sobre risco de bloqueio do número **antes** de
    instalar, e desaconselhe disparo em massa para lista fria.

## As armadilhas — o que o erro diz × o que ele significa

| O que aparece | O que é de verdade | Conserto |
|---|---|---|
| `command not found` em lugar sem sentido | arquivo veio do Windows com `\r` no fim da linha | `sed -i "s/\r$//" /opt/infra/*.sh /opt/infra/*.env` |
| `relation "installation_configs" does not exist`, serviços em loop | o entrypoint do Chatwoot **não** cria o schema, apesar da documentação | `chatwoot-rails.sh bundle exec rails db:chatwoot_prepare` |
| `bad gateway`, **sem nada no log** | label de rede errada: no Traefik v3 com Swarm é `traefik.swarm.network`, não `traefik.docker.network` — a antiga é ignorada em silêncio | corrigir a label na stack |
| certificado aparece como "TRAEFIK DEFAULT CERT" | o DNS ainda não propagou | **esperar.** Não recriar o serviço: o Let's Encrypt tem backoff e insistir atrasa |
| `docker service ls` mostrando `1/1` | pode ser um serviço reiniciando em loop — é a tarefa nova, viva por segundos | conferir com `docker service ps <serviço>` |
| `/app/auth/signup` respondendo `200` | não prova que o cadastro está aberto: o Rails serve o SPA em qualquer rota `/app/...` | testar `POST /api/v1/accounts` — deve dar `404` |
| `Password must contain at least 1 special character` | senha gerada sem símbolo (`openssl rand -base64 \| tr -d '/+='` remove justamente eles) | gerar com símbolo |
| Portainer: `Administrator initialization timeout` | ninguém preencheu a tela em 5 min | reiniciar o serviço dá outros 5 min; o padrão define a senha no deploy |
| a chave SSH "foi cadastrada" mas não entra | anexar chave a uma VPS **já criada** não propaga — a conta responde sucesso com corpo vazio | colar em `~/.ssh/authorized_keys` pelo terminal do navegador, ou reinstalar a máquina com a chave anexada |
| erro `403` ao colar o script de pós-instalação | o firewall do provedor bloqueia os trechos de hardening | usar o envelope em base64 (veja `docs/`) |
| o webhook do n8n não chega, e o erro não fala de DNS | falta o registro A do **segundo** host (webhook) | criar o A e refazer o deploy |
| credenciais do n8n ilegíveis depois de reinstalar | a `N8N_ENCRYPTION_KEY` mudou | não há recuperação: recriar credencial por credencial |

## Onde está escrito o porquê

`docs/antes-de-instalar.md` · `docs/por-que-este-padrao.md` · `docs/retencao-e-backup.md` ·
`docs/dados-sensiveis.md` · `docs/onde-o-banco-mora.md`

Decisão de arquitetura vive lá, não aqui. Se o dono perguntar "por que não X?", leia antes de opinar.
