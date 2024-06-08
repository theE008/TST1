#!/bin/bash

# Caminho para o arquivo de configura��o
CONFIG_FILE=".project_config"
# Caminho para o arquivo de segredo
SECRET_FILE="../SECRET"

# Verificar se o arquivo de segredo existe
if [ ! -f $SECRET_FILE ]; then
  echo "Arquivo de segredo nao encontrado. Certifique-se de que o arquivo $SECRET_FILE existe."
  exit 1
fi

# Carregar as informa��es do arquivo de segredo
source $SECRET_FILE

# Verificar se as vari�veis necess�rias est�o definidas
if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_EMAIL" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "O arquivo de segredo deve conter GITHUB_USER, GITHUB_EMAIL e GITHUB_TOKEN."
  exit 1
fi

# Fun��o para fazer o commit
commit_changes() {
  git add .
  echo "Digite a mensagem do commit (ou pressione Enter para 'Commit automatico'):"
  read COMMIT_MESSAGE
  if [ -z "$COMMIT_MESSAGE" ]; then
    COMMIT_MESSAGE="Commit automatico em $(date)"
  fi
  git commit -m "$COMMIT_MESSAGE"
  git pull origin main --rebase
  git push origin main
}

# Verificar se o arquivo de configuracao existe
if [ ! -f $CONFIG_FILE ]; then
  # Primeiro uso: pedir nome do projeto e configurar reposit�rio
  echo "Digite o nome do projeto:"
  read PROJECT_NAME

  # Salvar o nome do projeto no arquivo de configura��o
  echo "PROJECT_NAME=$PROJECT_NAME" >> $CONFIG_FILE

  # Configurar o Git para usar o token
  git config --global credential.helper 'cache --timeout=3600'
  git config --global user.name "$GITHUB_USER"
  git config --global user.email "$GITHUB_EMAIL"

  # Criar reposit�rio no GitHub
  echo "Criando repositorio no GitHub..."
  RESPONSE=$(curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user/repos -d "{\"name\":\"$PROJECT_NAME\"}")

  if [[ $RESPONSE == *"Bad credentials"* ]]; then
    echo "Token invalido. Por favor, verifique e tente novamente."
    exit 1
  fi

  # Inicializar reposit�rio Git local
  git init
  git remote add origin "https://github.com/$GITHUB_USER/$PROJECT_NAME"

  # Criar o branch main e fazer o primeiro commit
  git checkout -b main
  touch README.md
  echo "# $PROJECT_NAME" > README.md
  commit_changes
else
  # Carregar configura��o existente
  source $CONFIG_FILE

  # Configurar o Git para usar o token
  git config --global credential.helper 'cache --timeout=3600'
  git config --global user.name "$GITHUB_USER"
  git config --global user.email "$GITHUB_EMAIL"
  git remote set-url origin "https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$PROJECT_NAME"

  # Verificar se o reposit�rio remoto j� existe
  if git ls-remote --exit-code origin > /dev/null; then
    # Fazer pull das mudan�as remotas
    git pull origin main --rebase
  else
    # Reposit�rio remoto n�o existe, configurando o reposit�rio local
    git init
    git remote add origin "https://github.com/$GITHUB_USER/$PROJECT_NAME"
  fi

  # Fazer commit das mudan�as
  commit_changes
fi
