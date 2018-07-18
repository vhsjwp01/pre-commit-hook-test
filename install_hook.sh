#!/bin/bash
#set -x

hooks_dir="./git_hooks"
git_hooks_dir="./.git/hooks"

# See how we were called
my_arg="${1}"

if [ "${my_arg}" = "" ]; then
    my_arg="none"
fi

case ${my_arg} in 

    none)

        if [ -d "${hooks_dir}" ]; then
            my_choice=""

            while [ "${my_choice}" = "" ]; do
                clear
                echo
                echo "----------------"
                echo "Available hooks:"
                echo "----------------"
    
                for file in $(find "${hooks_dir}" -depth -type f) ; do
                    filename=$(echo "${file}" | awk -F'/' '{print $NF}')
                    hook_type=$(echo "${filename}" | awk -F'_' '{print $1}')
                    hook_descriptor=$(echo "${filename}" | awk -F'_' '{print $NF}' | sed -e 's?-? ?g' -e 's?\.sh$??g')
    
                    echo "name: ${filename}"
                    echo "    type: ${hook_type}"
                    echo "    description: ${hook_descriptor}"
                    echo
    
                done

                read -p "Enter the name of the hook you wish to enable: " this_choice

                if [ "${this_choice}" != "" ]; then

                    if [ -e "${hooks_dir}/${this_choice}" ]; then
                        my_choice="${this_choice}"
                    else
                        echo
                        echo "Invalid choice"
                        sleep 5
                    fi

                fi

            done

            if [ "${my_choice}" != "" ]; then
                hook_type=$(echo "${my_choice}" | awk -F'_' '{print $1}')
                cp "${hooks_dir}/${my_choice}" "${git_hooks_dir}/${hook_type}"
                chmod 755 "${git_hooks_dir}/${hook_type}"
            fi

        fi
 
    ;;

    *)

        if [ -e "${hooks_dir}/${my_arg}" ]; then
            hook_type=$(echo "${my_arg}" | awk -F'_' '{print $1}')
            cp "${hooks_dir}/${my_arg}" "${git_hooks_dir}/${hook_type}"
            chmod 755 "${git_hooks_dir}/${hook_type}"
        else
            echo "Hook \"${hooks_dir}/${my_arg}\" does not exist"
        fi

    ;;

esac

