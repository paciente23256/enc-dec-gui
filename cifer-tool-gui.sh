#!/usr/bin/env bash
# @paciente23256
# encriptação e desencritacao simetrica com openssl.
#
#
#export SUDO_ASKPASS="/home/player/Desktop/SSU/cipher.sh"
#zenity --password --title=Authentication

#verifica se é root
if [[ $UID != 0 ]]; then
    zenity --width=400 --error --text="Este script deve ser executado com sudo:"
    zenity --width=400 --info --text="sudo $0 $*"
    exit 1
fi


uso() {
        echo "$0 -f <ficheiro>"
        echo
        echo " necessário:"
        echo "   -f  insirir ficheiro"
        echo
}


while getopts ":f:" i; do
        case "${i}" in
                f)
                        f=${OPTARG}
                        ;;
                *)
                        echo "Erro - opção inválida. $1" 1>&2;
                        uso
                        ;;
        esac
done
shift $((OPTIND-1))

# Check if file is specified
if [ -z "${f}" ]; then
        echo "Erro - não foi especificado um ficheiro" 1>&2;
        uso
        exit 1
fi

# Check if gpg exists
if ! command -v openssl >/dev/null 2>&1 ; then
        echo "Erro - 'gpg' Não foi encontrado." 1>&2
        exit 1
fi

# Check if zenity exists
if ! command -v zenity >/dev/null 2>&1 ; then
        echo "Erro - 'zenity' Não foi encontrado." 1>&2
        exit 1
fi


chooseOptions () {
        Algoritmos=$(openssl enc -ciphers 2>&1 \
                | grep '^-' \
                | xargs \
                | sed -e 's/^-//' -e 's/ -/|/g')

        CMD="zenity --forms \
                --title=\"Cifrar/Decifrar com OpenSSL\" \
                --separator=\"|\" \
                --add-combo=\"Ação\" \
                --combo-values=\"cifrar|Decifrar\" \
                --add-combo=\"Algoritmo\" \
                --combo-values=\"${Algoritmos}\" \
                --add-password=\"Chave\""

        eval "${CMD}"
}


IFS="|" read -ra options <<< "$(chooseOptions)"

if [ -z "${options[0]}" ]; then
        zenity --error --text="Não foi efetuada qualquer operação."
        exit 1
elif [ -z "${options[1]}" ]; then
        zenity --error --text="Escolha um Algoritmo."
        exit 1
elif [ -z "${options[2]}" ]; then
        zenity --error --text="Inserir Password."
        exit 1
fi

cmd_option=""
extension=".out"

case ${options[0]} in
        "cifrar" ) cmd_option="-e" ; extension=".enc"
                ;;
        "Decifrar" ) cmd_option="-d" ; extension=".dec"
                ;;
esac

alg="-${options[1]}"

error="$(openssl enc ${cmd_option} "${alg}" -md sha1 -k "${options[2]}" -in "${f}" -out "${f}${extension}" 2>&1)"
errno=$?

if [ "$errno" -gt "0" ]; then
        zenity --error --text="${error}\nreturn code: ${errno}"
        exit 1
else
        zenity --info --text="Operação ${options[0]} \n OK."
        exit $?
fi
