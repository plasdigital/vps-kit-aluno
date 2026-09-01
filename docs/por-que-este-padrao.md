# Por que este padrão — e o que foi recusado

As decisões abaixo já estão tomadas dentro dos arquivos. Este documento existe para você saber
**o que dá para desfazer** e o que é melhor não mexer.

## O que substituímos

Quase todo tutorial em português manda usar um **instalador de menu**: você cola um comando, escolhe
numa lista e ele instala. Funciona, e continua funcionando depois deste padrão — a base montada aqui
respeita o que ele checa, então o menu segue como saída de emergência.

O que incomoda nele, lendo o script:

| O que faz | Consequência |
|---|---|
| instala em `latest` | a ferramenta troca de versão sozinha no primeiro restart |
| guarda a configuração **na máquina**, não com você | máquina nova = começar do zero |
| envia o **IP** e o inventário do que roda para a telemetria deles | não vai credencial, mas vai o mapa |
| não faz firewall, hardening de SSH, swap, backup nem monitoramento | é justamente a parte que dói depois |

## As decisões

**Firewall do provedor, não o de dentro da máquina.** Filtra antes de chegar na VPS e se administra
pelo painel. O que decide: um firewall interno mal configurado **te tranca fora do teu próprio
servidor** e exige console de recuperação. Erro no painel se corrige clicando.

**Ubuntu 24.04 LTS, não a versão mais nova.** Compatibilidade não desempata (o Docker suporta
várias). Ubuntu ganha pelo **ecossistema**: o material em português assume essa versão, então o
tutorial que você achar vai bater com a sua tela. E 24.04 ganha da mais nova pela **idade** — versão
recém-lançada quebra nos pacotes de terceiros em volta, não no Docker. Suporte até 2029.

**Certificado por HTTP, e não curinga.** Dá para emitir um certificado curinga (`*.seudominio`)
usando a API do provedor. Foi recusado: exige guardar dentro da VPS um token que dá acesso à **conta
inteira** — VPS, DNS, domínios, cobrança. Risco desproporcional para um ganho dispensável, já que o
proxy emite um certificado por endereço sozinho.

**SSH na porta 22, não numa porta alternativa.** Trocar a porta não protege: quem varre a internet
acha porta alternativa em segundos. O que protege é chave + fail2ban + firewall. E a porta trocada é
um detalhe que se esquece — e quando se esquece, perde-se o acesso à máquina.

**Um nó só.** É o correto para este porte. Duas máquinas como gerentes **toleram zero falhas** — pela
regra de quórum, redundância real começa em três. Duas só fazem sentido como um gerente + um
trabalhador, que é divisão de carga, não alta disponibilidade. O desenho já aceita um segundo nó.

**Sem servidor de e-mail.** Todo usuário nasce por comando. O custo é real: ninguém recupera a
própria senha sozinho. Ligar e-mail depois não exige refazer nada.

**Senha do painel definida no deploy.** Não é firula: o Portainer **se tranca sozinho** se ninguém
preencher a tela de boas-vindas em 5 minutos. Numa instalação automatizada essa corrida se perde
quase sempre — a máquina precisa nascer com dono.

## O que a primeira execução ensinou

Cinco coisas que o desenho no papel não previa:

1. **O provisionamento reabre o login de root por senha.** O cloud-init do provedor reescreve essa
   linha. Não é erro de ninguém — é o template. Por isso o arquivo de correção precisa começar com
   `01-`: o SSH lê a pasta em ordem alfabética e vale o **primeiro** valor.
2. **Atualização completa do sistema dentro do post-install se mata sozinha.** Ela atualiza o
   systemd, que reinicia o ssh, que derruba o processo que está rodando o script — no meio da
   instalação de pacotes. O resultado é o pior tipo de falha: uma máquina que **parece** pronta.
   Por isso aqui só entra correção de segurança automática; atualização completa é manutenção, com
   reinício planejado.
3. **O firewall do provedor bloqueia o cadastro do próprio script** (erro 403). Não é tamanho: são
   os trechos de segurança dentro dele. A saída é o envelope em base64.
4. **No Traefik v3 a label de rede mudou de nome** — é `traefik.swarm.network`, e não
   `traefik.docker.network`, que é o que praticamente todo tutorial ainda ensina. A antiga é
   ignorada **em silêncio**: nada no log, e o sintoma é um "bad gateway" sem causa aparente.
5. **O painel se tranca em 5 minutos** (acima).

## O que dá para trocar sem quebrar

- os **endereços** (`vps.env`)
- as **versões** — mas leia a regra: o padrão é ficar parado
- o **tamanho da máquina**, para cima
- **trocar de provedor** — só o firewall e o DNS mudam de lugar; os scripts e as stacks não

## O que é melhor não mexer

- publicar porta direto num serviço (só o proxy faz isso)
- `latest` em qualquer imagem
- tirar o middleware de segurança das rotas
