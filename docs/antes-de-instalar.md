# 🔴 Antes de instalar qualquer coisa — o protocolo de conferência

> **Este é o documento mais importante da pasta.** Todos os outros mandam voltar para cá.

## A regra

**Este kit não é a última palavra sobre nada.** Ele é um ponto de partida testado, escrito numa
data, com versões fixadas de propósito. Software muda toda semana: o projeto renomeia uma variável,
troca a imagem base, passa a exigir um pré-requisito que não existia, publica um aviso de segurança,
muda o jeito de instalar.

Por isso, **antes de subir qualquer serviço — inclusive os que já vêm prontos aqui — o agente
pesquisa a documentação oficial de hoje e te conta o que mudou.**

> *"antes de instalar, pesquisa a documentação oficial e as releases desse projeto no GitHub, e me
> diz: mudou alguma coisa desde que este kit foi escrito? apareceu pré-requisito novo? tem aviso de
> segurança? o jeito de instalar continua o mesmo?"*

Trinta segundos de leitura evitam uma hora de erro que não faz sentido.

## O que o agente procura, em ordem de importância

| # | O que | Por que importa |
|---|---|---|
| 1 | **Mudança que quebra** entre a versão fixada aqui e a atual | variável renomeada, valor que virou obrigatório, migração de banco que deixou de ser automática |
| 2 | **Aviso de segurança** na versão fixada | é o único motivo que obriga a subir de versão |
| 3 | **Pré-requisito novo** | o projeto passou a exigir um banco, uma extensão, uma versão mínima, uma chave |
| 4 | **Mudança no jeito de instalar** | o compose oficial mudou de forma; o processo de inicialização passou a fazer (ou deixou de fazer) uma etapa |
| 5 | **O projeto morreu?** | último commit de dois anos atrás, issues sem resposta, aviso de arquivado |

## O que ele faz com o que achou

- **Achou diferença** → conta em português, **com o link**, e diz o que recomenda. Não conserta
  calado: quem ler esta pasta daqui a seis meses precisa saber que ela mudou.
- **Não achou nada** → segue o kit como está, **e diz que conferiu**. *"Conferi as releases, a versão
  fixada aqui é a atual e não há aviso de segurança"* é uma frase que custa 30 segundos e vale o dia.
- ⛔ **Nunca troca a versão fixada por conta própria**, e nunca por `latest`.

## 🔴 A decisão de subir de versão é sempre sua

A versão nova pode ser **regressão**: projeto que remove funcionalidade, muda de licença, corta a
opção que você usa. Já aconteceu com ferramenta famosa mais de uma vez.

A pergunta certa nunca é *"qual é a última?"*. É:

> **"o que a versão nova traz que eu quero, e o que eu perco?"**

E o padrão, quando a resposta é "nada de especial": **ficar parado**. Software que funciona não se
atualiza por existir número maior. Só há dois motivos para mexer — a nova tem algo que você quer, ou
a atual está dando problema **constatado** (visto no log, não suspeitado).

## Deu certo quando

O agente te disser explicitamente **uma das duas coisas**:

- *"conferi, a versão fixada é a atual e não há aviso de segurança"* — pode seguir; ou
- *"mudou X, aqui está o link, e eu recomendo Y"* — você decide antes de seguir.

**Se ele não falou nenhuma das duas, ele não conferiu.** Peça de novo.
