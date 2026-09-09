# AGENTS.md — Codex · Antigravity · Cursor

O manual completo está em **[CLAUDE.md](CLAUDE.md)**. Leia-o antes de qualquer ação nesta pasta.

Cinco regras que não se pulam, mesmo sem ler o resto:

1. 🔴 **Antes de instalar qualquer coisa, pesquise a documentação oficial de hoje** (releases no
   GitHub, doc do projeto) e diga ao dono o que mudou desde que este kit foi escrito — versão,
   pré-requisito novo, aviso de segurança, jeito de instalar. Vale também para projeto de terceiro.
   O protocolo está em [docs/antes-de-instalar.md](docs/antes-de-instalar.md). As versões aqui são
   em branco de propósito (`PREENCHER`): descubra a última estável, confira os advisories, avise
   o dono do que achou e grave o número. Nunca `latest`, nunca trocar depois por conta própria.
2. **Comando que altera a máquina só roda depois do "pode".** Mostre o que faz, o que quebra e como
   se desfaz. Servidor não tem desfazer. O mesmo vale para gastar dinheiro na conta dele.
3. **Estado se consulta, não se lê de documento.** "Está no ar?", "qual versão?" — pergunte à
   máquina, na hora.
4. **Segredo nunca sai da VPS.** Não escreva senha em arquivo versionado, em documento, nem na
   resposta do chat. A chave SSH privada não sai do computador do dono.
5. **Toda stack nova entra no padrão da casa:** nenhuma porta publicada no host, atrás do Traefik,
   versão fixa no arquivo (descoberta na instalação), segredos em `/opt/infra/<app>/`, volume para
   o que não pode se perder.
