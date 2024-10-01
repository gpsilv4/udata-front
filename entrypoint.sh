#!/bin/bash
set -e

if [ "$(ls -A /src)" ]; then
    # Install source repositories as editable
    for d in /src/*/ ; do
        echo "Installing $d"
        pip install -e "$d"
    done
    # Install packages from requirements files
    for r in /src/*/*.pip ; do
        echo "Installing dependencies from $r"
        pip install -r "$r"
    done
fi

# Alterar MAIL_DEFAULT_SENDER no arquivo /python3.7/.../udata/settings.py
settings_file="/usr/local/lib/python3.7/site-packages/udata/settings.py"
search_string="MAIL_DEFAULT_SENDER = 'webmaster@udata'"
replace_string="MAIL_DEFAULT_SENDER = 'noreply.dados.gov@ama.gov.pt'"

if [ -f "$settings_file" ]; then
    sed -i "s/$search_string/$replace_string/g" "$settings_file"
    echo "Substituição concluída com sucesso."
else
    echo "O arquivo $settings_file não foi encontrado."
fi

# Adicionar verificação para arquivos SVG no arquivo /python3.7/.../udata/core/dataset/api.py
api_file="/usr/local/lib/python3.7/site-packages/udata/core/dataset/api.py"
search_string="infos = handle_upload(storages.resources, prefix)"
insert_string="        # Adicionar verificação para arquivos SVG\n        if infos['mime'] == 'image/svg+xml':\n            api.abort(415, 'Unsupported file type: SVG images are not allowed')"

if [ -f "$api_file" ]; then
    sed -i "/$search_string/a $insert_string" "$api_file"
    echo "Código inserido com sucesso."
else
    echo "O arquivo $api_file não foi encontrado."
fi


case $1 in
    uwsgi)
        udata collect -ni /udata/public
        uwsgi --emperor /udata/uwsgi/
        ;;
    front)
        udata collect -ni /udata/public
        uwsgi /udata/uwsgi/front.ini
        ;;
    worker)
        uwsgi /udata/uwsgi/worker.ini
        ;;
    beat)
        uwsgi /udata/uwsgi/beat.ini
        ;;
    celery)
        celery -A udata.worker "${@:2}"
        ;;
    bash)
        /bin/bash
        ;;
    *)
        udata "$@"
        ;;
esac
