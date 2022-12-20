#!/bin/bash

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "/?" ] || [ $# -lt 4 ]; then
  echo -e "\nProcessa documentos eletrônicos para disponibilizacao em sistema web"
  echo -e "SEFAZ-RR/CETIF - cetif@sefaz.rr.gov.br"
  echo -e   "====================================================================\n"
  echo -e "Uso: processa.sh <TIPODOC> <TIPOEVENTO> <DIRDESTINO> <ARQORIGEM>\n"
  echo -e "   <TIPODOC>: Hexadecimal de duas posições"
  echo -e "      00 para BPe"
  echo -e "      01 para CTe"
  echo -e "      02 para MDFe"
  echo -e "      03 para NF3e"
  echo -e "      04 para NFCe"
  echo -e "      05 para NFe\n"
  echo -e "   <TIPOEVENTO>: Hexadecimal de uma posição"
  echo -e "      0 para Evento"
  echo -e "      1 para Inutilização"
  echo -e "      2 para Nota\n"
  echo -e "   <DIRDESTINO>: Diretório onde será criada a estrutura de links simbólicos\n"
  echo -e "   <ARQORIGEM>: Localizção do arquivo eletrônico compactado em formato ZIP\n"
  exit 256
fi

#TIPODOC
# 00 Bpe
# 01 Cte
# 02 Mdfe
# 03 NF3e
# 04 Nfce
# 05 Nfe
TIPODOC=$1

# EVENTO
# 0 Evento
# 1 Inutilização
# 2 Nota
TIPOEVENTO=$2

#Diretório onde criar os links simbólicos
DIRDESTINO=$3

#localização do arquivo zipado original
ARQORIGEM=$4

if [ -e "$ARQORIGEM" ] && [[ "$ARQORIGEM" =~ \.zip$ ]]; then

  ARQTEMPORARIO=/tmp/$(date '+%s.%N').$RANDOM
  unzip -p "$ARQORIGEM" > $ARQTEMPORARIO
  xmlstarlet validate -q $ARQTEMPORARIO
  # informa o erro de validação
  ERRO=$?

  if [ $ERRO ]; then

    # XPATH de cada tipo de documento
    case $TIPODOC in
      "00" )
        # BPe
        [ "$TIPOEVENTO"=="0" ] && source bin/vars-bpe-evento.sh # eventos
        [ "$TIPOEVENTO"=="1" ] && source bin/vars-bpe-inutilizacao.sh # Inutilização
        [ "$TIPOEVENTO"=="2" ] && source bin/vars-bpe-nota.sh # notas
        ;;
      "02" )
        # MDFe
        [ "$TIPOEVENTO"=="0" ] && source bin/vars-mdfe-evento.sh # eventos
        [ "$TIPOEVENTO"=="1" ] && source bin/vars-mdfe-inutilizacao.sh # Inutilização
        [ "$TIPOEVENTO"=="2" ] && source bin/vars-mdfe-nota.sh # notas
        ;;
      "04" )
        # NFCe
        [ "$TIPOEVENTO"=="0" ] && source bin/vars-nfce-evento.sh # eventos
        [ "$TIPOEVENTO"=="1" ] && source bin/vars-nfce-inutilizacao.sh # Inutilização
        [ "$TIPOEVENTO"=="2" ] && source bin/vars-nfce-nota.sh # notas
        ;;
      "05" )
        # NFe
        [ "$TIPOEVENTO"=="0" ] && source bin/vars-nfe-evento.sh # eventos
        [ "$TIPOEVENTO"=="1" ] && source bin/vars-nfe-inutilizacao.sh # Inutilização
        [ "$TIPOEVENTO"=="2" ] && source bin/vars-nfe-nota.sh # notas
        ;;
    esac

    # Recupera valores do XML e trata alguns campos
    CHAVE=$(xmlstarlet sel -t -v "//$XPATHCHAVE"  -n $ARQTEMPORARIO)
    CHAVE=${CHAVE:$INICIOCHAVE:100}
    CNPJ=$(xmlstarlet sel -t -v "//$XPATHCNPJ" -n $ARQTEMPORARIO)
    DHEMI=$(xmlstarlet sel -t -v "//$XPATHDHEMI" -n $ARQTEMPORARIO)
    DHEMIF=$(date -d "$DHEMI" "+%Y%m%d")

    # testa se já existe um diretório criado no destino com o CNPJ do emissor
    if [ ! -d "$DIRDESTINO/$CNPJ" ]; then
      mkdir "$DIRDESTINO/$CNPJ"
    fi

    # TIPODOC.EVENTO.CNPJ.DHEMIF.CHAVE.extensao
    ARQLINK="${TIPODOC}.${TIPOEVENTO}.${CNPJ}.${DHEMIF}.${CHAVE}.zip"

    # testa se o aquivo de link destino existe
    if [ -h "${DIRDESTINO}/${CNPJ}/${ARQLINK}" ]; then
      rm "${DIRDESTINO}/${CNPJ}/${ARQLINK}"
    fi

    # cria arquivo de link
    ln -s "${ARQORIGEM}" "${DIRDESTINO}/${CNPJ}/${ARQLINK}"

  fi

  # remove o arquivo temporario
  rm $ARQTEMPORARIO

else

  # o arquivo nao existe ou não é .zip
  ERRO=128

fi

exit $ERRO
