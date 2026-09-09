# 🔴 Antes de instalar qualquer coisa — o protocolo de conferência

> **Este é o documento mais importante da pasta.** Todos os outros mandam voltar para cá.

## A regra

**Este kit não decide a versão de nada.** Ele entrega os arquivos com o campo de versão em branco
— `PREENCHER` — e quem descobre o número é o seu agente, **na hora de instalar**.

Isso mudou em 08/set/2026, e mudou por um motivo concreto. Antes, o kit vinha com as versões
fixadas: as que estavam rodando na instalação que serviu de referência. Parecia prudente. Numa
instalação feita do zero meses depois, **as três versões que ele fixava tinham vulnerabilidade
conhecida** — uma delas crítica, outra permitindo execução de código. O kit não estava errado no
dia em que foi escrito; ele envelheceu em silêncio, que é o jeito que material técnico apodrece.

Versão escrita em arquivo é uma foto. Falha de segurança é descoberta depois da foto.

## O que o agente faz, toda vez

> *"antes de instalar o <ferramenta>, descobre a última versão estável, confere os avisos de
> segurança e as notas de versão, e preenche o vps.env"*

| # | O que ele procura | Por que importa |
|---|---|---|
| 1 | **Qual é a última versão estável** | é a que vai ser instalada, salvo motivo para não ser |
| 2 | **Avisos de segurança** que atinjam essa versão | uma versão nova também pode ter aviso aberto |
| 3 | **Mudança que quebra** em relação ao que a doc do kit descreve | variável renomeada, valor que virou obrigatório, migração que deixou de ser automática |
| 4 | **Pré-requisito novo** | o projeto passou a exigir um banco, uma extensão, uma chave |
| 5 | **Mudança no jeito de instalar** | o compose oficial mudou de forma |
| 6 | **O projeto ainda é mantido?** | último commit de dois anos atrás, issues sem resposta, aviso de arquivado |

Onde ele olha: as **releases** do projeto e a lista de **advisories de segurança** do repositório —
não um blog, não a memória dele. Advisory diz a faixa de versões afetada e a versão corrigida; é
esse par que decide o número, não "qual é a mais nova".

## Por que preencher o número, e não usar `latest`

São dois problemas diferentes, e `latest` resolve um criando o outro.

|  | versão fixada no kit | `latest` | **descobrir e fixar** |
|---|---|---|---|
| instala o mais novo | ❌ envelhece | ✅ | ✅ |
| não troca sozinha depois | ✅ | ❌ troca no primeiro restart | ✅ |

Com `latest`, o container pega uma imagem nova em qualquer reinício — inclusive um reinício que a
máquina fez sozinha às 3 da manhã. A mudança chega sem ninguém ter pedido, e você descobre pelo
sintoma. **Aqui a versão é sempre nova na instalação, e fixa depois dela.**

🔴 **Exceção: Postgres e Redis ficam fixos**, e vêm preenchidos. Trocar a versão maior de um banco
não é atualizar, é **migrar dado** — nunca deve acontecer de surpresa.

## O que ele faz com o que achou

- **Achou tudo em ordem** → preenche o `vps.env`, **diz qual número escolheu e por quê**, e segue.
- **A última versão tem aviso aberto, ou mudou algo que quebra** → conta em português, **com o
  link**, e recomenda: instalar a anterior, esperar, ou seguir sabendo do risco. Não decide calado.
- ⛔ **Nunca deixa `PREENCHER`.** O deploy falha com `manifest unknown` — de propósito.

## 🔴 Depois de instalado, o padrão é ficar parado

Descobrir a versão vale para a **instalação**. Depois que está rodando, a régua vira outra: só se
atualiza quando a versão nova tem algo que você quer, ou quando a atual está dando problema
**constatado** (visto no log, não suspeitado) — e **aviso de segurança conta como problema
constatado**.

A pergunta certa nunca é *"qual é a última?"*. É:

> **"o que a versão nova traz que eu quero, e o que eu perco?"**

A versão nova pode ser **regressão**: projeto que remove funcionalidade, muda de licença, corta a
opção que você usa. Já aconteceu com ferramenta famosa mais de uma vez.

## Deu certo quando

O agente te disser explicitamente **as duas coisas**:

- **qual versão ele vai instalar e como descobriu** — *"a última estável do n8n é a 2.38.4, de
  07/set"*; e
- **o que ele achou de segurança** — *"não há advisory aberto para ela"*, ou *"a 2.35 tinha escape
  de sandbox, corrigido a partir da 2.38.2, aqui está o link"*.

**Se ele não falou as duas, ele não conferiu.** Peça de novo.
