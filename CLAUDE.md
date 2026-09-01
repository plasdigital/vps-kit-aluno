# Instruções do agente — kit de VPS

Esta pasta instala e opera uma VPS: Docker + Swarm, Traefik (proxy com SSL automático),
Portainer (painel) e Chatwoot (caixa de atendimento). Você é o operador; o dono não abre terminal.

## Onde os parâmetros moram

| Arquivo | O que tem | Onde fica |
|---|---|---|
| `vps.env` | domínio, hosts, versões fixadas. **Sem segredo.** | nesta pasta e em `/opt/infra/` na VPS |
| `chatwoot.env` | as três senhas do Chatwoot | **só na VPS**, em `/opt/infra/chatwoot/`, `chmod 600` |

Se `vps.env` não existir, copie de `vps.env.exemplo` e peça ao dono os dois hosts.

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
| "o backup rodou?" | `ssh <vps> 'ls -la /opt/infra/backups/chatwoot; tail -5 /var/log/chatwoot-backup.log'` |
| "qual versão está rodando?" | `ssh <vps> "docker service inspect <serviço> --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'"` |

🔴 **Estado nunca se lê de documento.** "Está no ar?", "qual versão?", "quanto de RAM?" se perguntam
à máquina, na hora. Documento sobre estado está errado no dia seguinte.

### Escrita — mostre o que vai fazer e espere o "pode"

| O dono pede | Comando | Antes |
|---|---|---|
| "sobe a base" | `bash /opt/infra/deploy.sh` | conferir que o DNS já resolve |
| "instala o Chatwoot" | `bash /opt/infra/deploy-chatwoot.sh` | os segredos precisam existir |
| "prepara o banco" | `bash /opt/infra/chatwoot-rails.sh bundle exec rails db:chatwoot_prepare` | uma vez, na instalação |
| "cria um atendente" | `CW_SENHA='...' bash /opt/infra/chatwoot-criar-usuario.sh <email> "<Nome>" agent` | senha precisa de símbolo |
| "cria o dono" | o mesmo, com `superadmin` | **fecha a porta de trás — veja as travas** |
| "atualiza o X" | editar a versão em `vps.env` e rodar o deploy | leia a regra de versão abaixo |

**Enviar arquivo para a VPS** (Windows quebra sem o `sed` — veja armadilhas):

```bash
scp -i ~/.ssh/minha-vps -r ./* root@<IP>:/opt/infra/
ssh -i ~/.ssh/minha-vps root@<IP> 'sed -i "s/\r$//" /opt/infra/*.sh /opt/infra/*.env'
```

## As travas — o que você NUNCA faz sozinho

1. **Nada que altere a máquina sem mostrar antes** o que faz, o que quebra se der errado e como se
   desfaz. Servidor não tem desfazer.
2. **Nunca `docker system prune -a`** sem listar o que sairia. No Swarm ele apaga imagem que um
   serviço parado ainda vai precisar no próximo deploy.
3. **Nunca mexer no firewall junto com outra mudança.** Se o acesso cair, não se sabe qual foi.
4. **Nunca escrever segredo** em arquivo versionado, em documento, ou na resposta do chat. Senha se
   gera na VPS (`openssl rand -hex 32`) e fica lá.
5. **Nunca subir de versão porque existe número maior.** Só há dois motivos: a nova tem algo que o
   dono quer, ou a atual está dando problema **constatado no log**. O padrão é ficar parado.
6. **Nunca apagar registro de DNS** nem sobrescrever a zona. Acrescente; liste antes e depois e
   confirme que os antigos continuam lá.
7. **Nunca rodar `SELECT` em conversa** "para dar uma olhada". É dado de cliente final.
8. **Instalação nova de Chatwoot não fica de pé sem fechar a porta de trás** — veja a armadilha 3.
   Criar o dono e fechar são o mesmo comando; não separe.

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
| a chave SSH "foi cadastrada" mas não entra | anexar chave a uma VPS **já criada** não propaga — a API responde sucesso com corpo vazio | colar em `~/.ssh/authorized_keys` pelo terminal do navegador, ou recriar a máquina |
| erro `403` ao colar o script de pós-instalação | o firewall do provedor bloqueia os trechos de hardening | usar o envelope em base64 (veja `docs/`) |

## Onde está escrito o porquê

`docs/por-que-este-padrao.md` · `docs/retencao-e-backup.md` · `docs/dados-sensiveis.md`

Decisão de arquitetura vive lá, não aqui. Se o dono perguntar "por que não X?", leia antes de opinar.
