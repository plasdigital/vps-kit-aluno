# Onde o banco de dados mora — e por que este não é para instalar

Quase tudo que você vai montar precisa guardar informação em algum lugar: cadastro de cliente,
histórico de conversa, o que a automação já fez, o login das pessoas. Esse lugar é o **banco de
dados**, e ele substitui a planilha quando a operação cresce.

Existem três respostas para "onde ele fica", e elas convivem na mesma empresa.

## As três respostas

| | Onde | Quando usar | Custo |
|---|---|---|---|
| 1 | **O banco que vem junto com cada ferramenta** | é o caso do Chatwoot, do n8n e do NocoDB deste kit: cada um sobe o seu | já está incluído |
| 2 | **Supabase contratado** (a nuvem deles) | 🟢 **a recomendação padrão** para as aplicações que você mandar construir | tem camada gratuita generosa |
| 3 | Um Postgres seu, na VPS | quando o dado não pode sair da sua máquina, ou quando a camada gratuita não serve mais | uma stack a mais para cuidar |

## 🔴 Por que o Supabase é para contratar, não para instalar

O Supabase é o pacote que dá, de uma vez: banco Postgres, login de usuário, armazenamento de
arquivo, API pronta e uma tela para ver os dados. É o que a maior parte das aplicações modernas
espera encontrar — e é o que você vai usar se pedir ao Claude Code para construir um sistema seu.

**Instalar o Supabase na sua VPS é possível, e é a escolha errada para quase todo mundo:**

- **Não é um programa, são muitos.** A versão instalável sobe mais de dez peças (banco,
  autenticação, arquivos, tempo real, o roteador de API, a tela de administração). Cada uma é uma
  coisa a mais que pode quebrar às 2 da manhã.
- **Ele não cabe junto.** Numa máquina de 8 GB que já roda Chatwoot e n8n, não sobra o que ele
  precisa. Você trocaria a máquina inteira de tamanho por uma peça só.
- **A camada gratuita da nuvem resolve o começo.** Enquanto o seu projeto for pequeno, você não
  paga nada — e ganha backup, atualização e monitoramento feitos por eles.
- **Backup de banco é o mais caro de fazer direito.** Contratado, isso já vem pronto.

> **A régua deste kit:** a VPS existe para hospedar o que **cobra por mês para ser hospedado** —
> caixa de atendimento por atendente, automação por execução, banco visual por usuário. O Supabase
> não cobra nada de quem está começando. Ele entra na lista do que **não** vale trazer para cá.

⚠️ **Isso pode mudar para você.** Se o dado for de um tipo que não pode sair do seu servidor por
exigência do seu ramo, ou se a conta da nuvem começar a doer, aí a conversa é outra — e é quando
vale montar o Postgres na máquina. Nesse dia, peça: *"pesquisa hoje qual é o caminho recomendado
para Supabase self-hosted e me diz o que a minha máquina precisaria ter"*.

## O caminho recomendado, na prática

1. Crie um projeto no **Supabase contratado** (plano gratuito).
2. Guarde a URL do projeto e as chaves no seu gerenciador de senhas — 🔴 e **nunca** em arquivo
   versionado.
3. Aponte para ele as aplicações que você construir e os projetos do GitHub que pedirem banco
   (a maioria pede exatamente isso — veja [instalar-do-github.md](instalar-do-github.md)).
4. O n8n, o Chatwoot e o NocoDB **continuam com o banco próprio deles**. Não junte tudo num banco
   só: isolamento é o que faz um problema parar numa aplicação em vez de derrubar todas.

**Deu certo quando:** a sua aplicação abre no seu domínio, gravando num banco que não mora na mesma
máquina — e derrubar a VPS não perde o dado.
