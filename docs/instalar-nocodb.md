# Instalar o NocoDB — a planilha que na verdade é um banco

> **Antes de começar:** a máquina de pé e a base no ar ([COMECE-AQUI.md](../COMECE-AQUI.md), §0 a §6).
> E, sempre: **[o protocolo de conferência](antes-de-instalar.md)** antes de subir.

## O que é

Aquela planilha compartilhada que virou o cadastro de clientes, o controle de pedidos, a lista de
processos — e que ninguém mais consegue ler por automação sem gambiarra. O NocoDB é a mesma tela de
planilha, só que por baixo é um banco de dados de verdade, com API.

**A dupla que importa:** NocoDB guarda, n8n usa. Ele lê e escreve por API — é essa combinação que
substitui a planilha compartilhada sem tirar a planilha da mão de quem trabalha nela.

⚠️ **Não tem nada de errado em usar planilha.** Ela é simples e resolve. A troca compensa quando a
lista precisa ser **lida por automação**, quando duas pessoas editam a mesma linha, ou quando o
arquivo já está grande demais para abrir.

---

## 1. O endereço

Registro **A** de `noco.seudominio.com.br` para o IP da VPS, e `NOCO_HOST` preenchido no `vps.env`.

**Deu certo quando:** o nome resolve para o seu IP.

## 2. Conferir a documentação oficial

> *"antes de instalar o NocoDB, confere as releases do nocodb/nocodb e a doc de instalação por
> Docker: mudou algo? tem pré-requisito novo? tem aviso de segurança?"*

Ver [antes-de-instalar.md](antes-de-instalar.md).

## 3. Os segredos

Gerados na VPS, em `/opt/infra/nocodb/nocodb.env` (modelo: `nocodb.env.exemplo`):

| Valor | O que é |
|---|---|
| `POSTGRES_PASSWORD` | senha do banco desta stack |
| `NC_AUTH_JWT_SECRET` | a chave que assina a sessão de quem faz login |

⚠️ Trocar o `NC_AUTH_JWT_SECRET` depois de instalado **derruba a sessão de todo mundo** — não
corrompe dado nenhum, só obriga a fazer login de novo. E nunca reaproveite a chave de outra
instalação sua.

## 4. Subir

```bash
bash /opt/infra/deploy-nocodb.sh
```

Sobem duas peças: o banco e a aplicação. O banco não é alcançável nem pelos outros containers da
máquina. O deploy também instala o **backup diário às 04:00**.

**Deu certo quando:** `https://noco.seudominio.com.br` abre com cadeado.

## 5. 🔴 Criar o dono, agora — não amanhã

A primeira conta criada é a de administrador. Como o endereço já é público, **esse convite fica
aberto até você aceitá-lo**. Abra e crie a sua conta na mesma sessão em que instalou.

Depois de criar:

> *"confere na documentação oficial do NocoDB como fechar o cadastro público nesta versão, e me diz
> se a minha instalação está aberta ou fechada"*

⚠️ **Não assuma que está fechado porque você já criou o dono** — isso muda de versão para versão, e
a única resposta que vale é a que o agente conferir na sua instalação. Este kit não decide isso por
você.

## 6. Provar que está no ar

| O quê | Como |
|---|---|
| a tela abre | `https://noco.seudominio.com.br` com cadeado |
| o login funciona | entra com o usuário criado |
| o cadastro público | conferido no passo 5 — e você sabe qual é a resposta |
| a API responde | criar uma tabela de teste e ler por API (é assim que o n8n vai usar) |
| o backup | rodar na mão e ver o arquivo aparecer, **com tamanho** |

## O que este kit já decidiu por você

| Decisão | Por quê |
|---|---|
| **Postgres próprio**, não emprestado | isolamento: invadiu um, não pegou o resto |
| **Usuário de banco dedicado**, não o superusuário | se o NocoDB for comprometido, o estrago para na base dele |
| **Chave de sessão gerada por você** | assim ela sobrevive a recriar o container |
| **Telemetria desligada** | o que roda na sua máquina é seu |
| **Versão fixada**, nunca `latest` | — |

## ⚠️ O que vai entrar aqui é dado de gente

Cadastro de cliente, telefone, endereço, o que ele comprou. A partir do momento em que isso sai da
planilha e entra num banco no seu servidor, **a responsabilidade sobre esse dado é sua** — backup,
quem tem acesso, e o que acontece se vazar. Veja [dados-sensiveis.md](dados-sensiveis.md).
