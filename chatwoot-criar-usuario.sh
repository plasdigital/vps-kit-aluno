#!/usr/bin/env bash
#
# Cria usuário no Chatwoot pelo console. Enquanto não houver SMTP, este é o
# único caminho: convidar pela tela dispara e-mail, e e-mail não sai daqui.
#
#   CW_SENHA='...' bash /opt/infra/chatwoot-criar-usuario.sh \
#       pessoa@exemplo.com "Nome da Pessoa" administrator
#
# Papel: administrator (padrão), agent ou superadmin.
#
# ⚠️ superadmin é outra coisa: é o dono da INSTALAÇÃO (painel /super_admin),
# não um usuário da conta. Enquanto não existir nenhum, o Chatwoot serve
# /installation/onboarding para qualquer visitante — ou seja, quem chegar
# primeiro vira dono. Criar um logo depois de instalar não é opcional.
#
# A senha entra por variável de ambiente, não por argumento, porque argumento
# aparece em `ps` para qualquer usuário da máquina.
#
# É idempotente: rodar de novo com o mesmo e-mail não duplica nem troca senha.

set -euo pipefail
cd "$(dirname "$0")"

CW_EMAIL=${1:-}
CW_NOME=${2:-}
CW_PAPEL=${3:-administrator}
CW_CONTA=${CW_CONTA:-Minha Empresa}

if [[ -z "$CW_EMAIL" || -z "$CW_NOME" ]]; then
  echo "uso: CW_SENHA='...' $0 <email> \"<nome>\" [administrator|agent]" >&2
  exit 1
fi

if [[ -z "${CW_SENHA:-}" ]]; then
  echo "ERRO: defina CW_SENHA no ambiente (não como argumento)." >&2
  exit 1
fi

# O Chatwoot exige minúscula, maiúscula, número E caractere especial. Checar
# aqui é melhor do que descobrir por um stack trace do Devise: foi exatamente
# o que aconteceu na instalação, com uma senha base64 sem símbolo.
erros=()
[[ ${#CW_SENHA} -ge 12 ]]        || erros+=("mínimo 12 caracteres")
[[ "$CW_SENHA" == *[a-z]* ]]     || erros+=("falta letra minúscula")
[[ "$CW_SENHA" == *[A-Z]* ]]     || erros+=("falta letra maiúscula")
[[ "$CW_SENHA" == *[0-9]* ]]     || erros+=("falta número")
[[ "$CW_SENHA" == *[^a-zA-Z0-9]* ]] || erros+=("falta caractere especial")
if [[ ${#erros[@]} -gt 0 ]]; then
  printf 'ERRO na senha (CW_SENHA): %s\n' "$(IFS=', '; echo "${erros[*]}")" >&2
  exit 1
fi

export CW_EMAIL CW_NOME CW_PAPEL CW_CONTA CW_SENHA

if [[ "$CW_PAPEL" == "superadmin" ]]; then
  # SuperAdmin é STI em cima da MESMA tabela `users` (coluna `type`), não um
  # modelo à parte. Duas consequências: o e-mail concorre com o dos atendentes,
  # e `name` é obrigatório. Use um endereço só dele — promover o usuário do
  # atendimento misturaria dois níveis de privilégio no mesmo login.
  # Criar o dono e FECHAR A PORTA são a mesma operação, de propósito: enquanto
  # a chave CHATWOOT_INSTALLATION_ONBOARDING existir no Redis, um POST sem
  # autenticação em /installation/onboarding cria conta com super_admin: true.
  # Não é tela inofensiva de boas-vindas — é criação de dono aberta na internet.
  bash ./chatwoot-rails.sh bundle exec rails runner '
    def fechar_onboarding
      chave = ::Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING
      if ::Redis::Alfred.get(chave)
        ::Redis::Alfred.delete(chave)
        puts "RESULTADO: onboarding publico FECHADO"
      end
    end

    existente = User.find_by(email: ENV["CW_EMAIL"])

    if existente && existente.type == "SuperAdmin"
      puts "RESULTADO: superadmin ja existia (id=" + existente.id.to_s + ")"
      fechar_onboarding
    elsif existente
      puts "ERRO: o e-mail " + ENV["CW_EMAIL"] + " ja pertence a um usuario comum " \
           "(id=" + existente.id.to_s + "). Use outro endereco para o superadmin."
      exit 1
    else
      admin = SuperAdmin.new(
        name: ENV["CW_NOME"],
        email: ENV["CW_EMAIL"],
        password: ENV["CW_SENHA"],
        password_confirmation: ENV["CW_SENHA"]
      )
      admin.skip_confirmation!
      if admin.save
        puts "RESULTADO: superadmin criado id=" + admin.id.to_s +
             " total_de_superadmins=" + SuperAdmin.count.to_s
        fechar_onboarding
      else
        puts "ERRO: " + admin.errors.full_messages.join(" | ")
        exit 1
      end
    end
  ' 2>&1 | grep -E "RESULTADO:|ERRO:|Error|Exception" | tail -5
  exit 0
fi

# O filtro guarda só o que este script imprime (RESULTADO / ERRO) e as linhas
# de erro do Rails. Filtrar demais foi um erro cometido aqui uma vez: escondeu
# a mensagem de validação e transformou um recado claro em stack trace mudo.
bash ./chatwoot-rails.sh bundle exec rails runner '
  conta = Account.find_or_create_by!(name: ENV["CW_CONTA"])
  usuario = User.find_by(email: ENV["CW_EMAIL"])
  criado = false

  if usuario.nil?
    usuario = User.new(
      name: ENV["CW_NOME"],
      email: ENV["CW_EMAIL"],
      password: ENV["CW_SENHA"],
      password_confirmation: ENV["CW_SENHA"]
    )
    # sem SMTP não há como confirmar e-mail pelo link; confirmamos aqui
    usuario.skip_confirmation!

    unless usuario.save
      puts "ERRO: " + usuario.errors.full_messages.join(" | ")
      exit 1
    end
    criado = true
  end

  vinculo = AccountUser.find_or_initialize_by(account_id: conta.id, user_id: usuario.id)
  vinculo.role = ENV["CW_PAPEL"]
  vinculo.save!

  estado = criado ? "criado agora" : "ja existia, papel confirmado"
  puts "RESULTADO: conta=" + conta.id.to_s + " (" + conta.name + ") usuario=" +
       usuario.id.to_s + " papel=" + vinculo.role + " — " + estado
' 2>&1 | grep -E "RESULTADO:|ERRO:|Error|Exception" | tail -5
