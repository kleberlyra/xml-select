#/bin/bash

for DOC in Nfe Nfce Bpe; do
  for EVENTO in 0 1 2; do

    case $EVENTO in
        0 ) DEV="Evento" ;;
        1 ) DEV="Inutilizacao";;
        2 ) DEV="Nota";;
    esac

    time find $(pwd)/mnt/POOL-02/XML/$DOC/$DEV/* -type f -exec bin/processa.sh 05 $EVENTO links \{} \;

  done
done 
