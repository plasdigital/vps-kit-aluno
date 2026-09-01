# Retenção e backup — a decisão que muda o resto

Esta é a única decisão do kit que é **sua**, e ela precisa ser tomada **antes** de instalar, não
depois: por quanto tempo você guarda a conversa do cliente.

## O padrão que veio configurado: nunca apagar

A razão é de atendimento, não de tecnologia. Um cliente que ficou seis meses sem falar e volta
precisa ser reconhecido, com o que já foi conversado.

Conferido lendo os processos periódicos dentro da imagem (não a documentação): o Chatwoot na edição
comunitária **não apaga conversa por tempo**. Dos três que tocam em dados, nenhum ameaça histórico:

| Processo | O que apaga | Situação |
|---|---|---|
| contatos parados | contato **sem nenhuma conversa** com mais de 90 dias | **desligado** — a variável está escrita como `"false"` na stack |
| conversas órfãs | conversa sem contato **ou** sem caixa de entrada | conversa normal tem contato; não entra |
| notificações antigas | notificação com mais de um mês | não é conversa |

A variável está escrita na stack **mesmo sendo o padrão de fábrica**, de propósito: assim a decisão
fica visível para quem ler o arquivo, e ninguém liga o processo depois "para economizar espaço".

## Se você quiser um prazo

Mexa na stack (`stacks/chatwoot.yml`, seção de retenção). Mas saiba o que muda:

**A LGPD olha para os dois lados.** Guardar para sempre é escolha de quem controla o dado — a lei
fala em eliminar depois de cumprida a finalidade, com exceções que costumam cobrir histórico de
atendimento. O que a escolha de guardar aumenta é o **dever de proteger**. Se um cliente pedir a
exclusão dos dados dele, a resposta é apagar sob demanda; o que não existe é prazo automático.

## 🔴 Por que o backup tem duas metades

Este é o erro que só aparece no dia da restauração, quando já não dá para consertar.

O Chatwoot guarda no banco de dados apenas o **endereço** do arquivo anexado — não o arquivo. Se
você fizer só o backup do banco e precisar restaurar, você volta com **todas as conversas e todos
os anexos quebrados**.

| Metade | Como | Guarda por |
|---|---|---|
| o banco | dump comprimido, validado por tamanho antes de apagar os antigos | 7 gerações |
| os anexos | espelho da pasta de arquivos, com permissão fechada | infinita |

**O espelho vai sem apagar nada, de propósito.** Arquivo anexado nunca é reescrito — só criado ou
apagado. Guardar 7 cópias diárias dos mesmos arquivos multiplicaria o disco sem ganhar nada; e
espelhar as exclusões faria o backup repetir, no dia seguinte, qualquer apagão indevido. Sem isso, o
espelho só acumula — é a retenção infinita aplicada também à mídia.

## 🔴 O que este backup NÃO cobre

Ele mora na própria VPS e **morre junto com ela**. Ele cobre erro de operação: uma migração ruim,
alguém apagando uma caixa de entrada sem querer.

Perder a máquina é outra camada, e é a do provedor:

- **Backup automático do provedor** — confira no painel se está ligado, e volte uma semana depois
  para ver se o primeiro apareceu de verdade.
- **Snapshot não é backup.** Ele expira em 24 horas e restaura a **máquina inteira** ao momento em
  que foi tirado — perde-se tudo que foi gravado depois. É rede de proteção para a manutenção do
  dia, não para "perdi o servidor".
- Em muitos provedores só existe **um snapshot por máquina**: criar um novo apaga o anterior.

## E o disco

Nunca apagar + anexo = disco crescendo para sempre. Em 100 GB isso demora, mas não é infinito.
De vez em quando, pergunte ao agente: *"quanto de disco sobrou?"*
