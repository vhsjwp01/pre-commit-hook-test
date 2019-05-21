#!/bin/bash
#set -x

SUCCESS=0
ERROR=0

exit_code=${SUCCESS}
err_msg=""

hooks_dir="$(git rev-parse --show-toplevel)/git_hooks"
git_hooks_dir="$(git rev-parse --show-toplevel)/.git/hooks"

hook_framework="IyEvYmluL2Jhc2gKI3NldCAteAoKU1VDQ0VTUz0wCkVSUk9SPTEKCmVycl9tc2c9IiIKZXhpdF9jb2RlPSR7U1VDQ0VTU30KCiMgV0hBVDogUHJvY2VzcyBhbGwgb2Ygb3VyIGhvb2tzIHVzaW5nIGEgPGhvb2tfdHlwZT4uZCBpbmNsdWRlIHN0cnVjdHVyZQojIFdIWTogIFdlIHdhbnQgdG8gYXBwbHkgYWxsIG9mIG91ciBob29rcyBvZiB0aGlzIHR5cGUgaW4gYSBtb2R1bGFyIHdheQojCmlmIFsgJHtleGl0X2NvZGV9IC1lcSAke1NVQ0NFU1N9IF07IHRoZW4KICAgIG15X2Jhc2VuYW1lPSQoYmFzZW5hbWUgIiR7MH0iKQogICAgbXlfZGlybmFtZT0kKGRpcm5hbWUgIiR7MH0iKQoKICAgIGlmIFsgLWQgIiR7bXlfZGlybmFtZX0vJHtteV9iYXNlbmFtZX0uZCIgXTsgdGhlbgoKICAgICAgICBmb3IgaSBpbiAkKGZpbmQgJHtteV9kaXJuYW1lfS8ke215X2Jhc2VuYW1lfS5kIC10eXBlIGYgLW1heGRlcHRoIDEpIDsgZG8KICAgICAgICAgICAgc291cmNlICIke2l9IgogICAgICAgICAgICBsZXQgZXhpdF9jb2RlPSR7P30KCiAgICAgICAgICAgIGlmIFsgJHtleGl0X2NvZGV9IC1uZSAke1NVQ0NFU1N9IF07IHRoZW4KICAgICAgICAgICAgICAgIGJyZWFrCiAgICAgICAgICAgIGZpCiAgICAgICAgICAgIAogICAgICAgIGRvbmUKCiAgICBmaQoKZmkKCmV4aXQgJHtleGl0X2NvZGV9Cg=="

f__hook_listing() {
    let return_code=${SUCCESS}

    self="${FUNCNAME[0]}"

    these_hooks="${1}"
    hook_disposition="${2}"

    # List our available hooks by type
    these_hook_types=$(for i in "${these_hooks}" ; do echo "${i}" | awk -F'_' '{print $1}' ; done | sort -u)

    if [ ! -z "${these_hooks}" -a ! -z "${hook_disposition}" ]; then
    
        for this_hook_type in ${these_hook_types} ; do
            echo
            echo "----------------------------------"
            echo "${hook_type} hooks ${hook_disposition}:"
            echo "----------------------------------"
            hooks_of_this_type=$(for i in "${these_hooks}" ; do echo "${i}" ; done | egrep "^${this_hook_type}_")
        
            for this_hook in ${hooks_of_this_type} ; do
                filename="${this_hook}"
                hook_type=$(echo "${filename}" | awk -F'_' '{print $1}')
                hook_description=$(egrep "^# DESCRIPTION: " "${hooks_dir}/${filename}" | sed -e 's|^# DESCRIPTION: ||g')
    
                echo "  name: ${filename}"
                echo "    type: ${hook_type}"
                echo "    description: ${hook_description}"
                echo
            done
    
        done
    
    fi

    return ${return_code}
}

f__available_hooks() {
    let return_code=${SUCCESS}

    self="${FUNCNAME[0]}"

    these_available_hooks=""

    # Discover installable hooks
    if [ -d "${hooks_dir}" ]; then
        these_available_hooks=$(find "${hooks_dir}" -maxdepth 1 -type f 2> /dev/null | awk -F'/' '{print $NF}')
    fi

    echo "${these_available_hooks}"

    return ${return_code}
}

f__installed_hooks() {
    let return_code=${SUCCESS}

    self="${FUNCNAME[0]}"

    these_installed_hooks=""

    # Discover installed hooks
    if [ -d "${git_hooks_dir}" ]; then
        these_installed_hooks=$(find "${git_hooks_dir}"/*.d/* -maxdepth 1 -type f 2> /dev/null | awk -F'/' '{print $NF}' | sort -u)
    fi

    echo "${these_installed_hooks}"
    
    return ${return_code}
}

f__uninstalled_hooks() {
    let return_code=${SUCCESS}

    self="${FUNCNAME[0]}"

    these_available_hooks="${1}"
    
    these_uninstalled_hooks=""

    # Discern our uninstalled hooks
    if [ ! -z "${these_available_hooks}" ]; then
    
        for i in ${these_available_hooks} ; do
            filename="${i}"
            hook_type=$(echo "${filename}" | awk -F'_' '{print $1}')
    
            if [ ! -e "${git_hooks_dir}/${hook_type}.d/${i}" ]; then
                these_uninstalled_hooks+=" ${i}"
            fi
    
        done
    
    fi

    echo "${these_uninstalled_hooks}"

    return ${return_code}
}

f__install_hook_framework() {
    let return_code=${SUCCESS}

    self="${FUNCNAME[0]}"

    my_base64_decode_arg=$(base64 --help | egrep decode | awk -F',' '{print $1}')

    if [ ! -z "${my_base64_decode_arg}" ]; then
        CWD=$(pwd)                                                                                               &&
        cd "${git_hooks_dir}"                                                                                    &&
        eval "echo \"${hook_framework}\" | base64 ${my_base64_decode_arg} > \"${git_hooks_dir}/hook_framework\"" &&
        chmod 750 hook_framework                                                                                 &&
        cd "${CWD}"
    else
        echo "ERROR:  Function ${self} - Could not unpack hook framework script.  Hook framework was not installed"
        let return_code=${ERROR}
    fi

    return ${return_code}
}

f__activate_hook_framework() {
    let return_code=${SUCCESS}

    self="${FUNCNAME[0]}"

    this_hook="${1}"

    if [ ! -z "${this_hook}" ]; then
        this_hook_type=$(echo "${this_hook}" | awk -F'_' '{print $1}')

        if [ ! -z "${this_hook_type}" ]; then

            # Make sure ${this_hook_type} is a symlink to hook_framework
            if [ ! -L "${git_hooks_dir}/${this_hook_type}" ]; then
                CWD=$(pwd)                               &&
                cd "${git_hooks_dir}"                    &&
                rm -f ${this_hook_type} > /dev/null 2>&1 &&
                ln -s hook_framework ${this_hook_type}   &&
                cd "${CWD}"
            fi

            # Make sure the ${my_hook_type}.d directory exists
            if [ ! -d "${git_hooks_dir}/${this_hook_type}.d" ]; then
                mkdir -p "${git_hooks_dir}/${this_hook_type}.d"
            fi

            # Install the hook in the ${my_hook_type}.d directory
            if [ ! -e "${git_hooks_dir}/${this_hook_type}.d/${this_hook}" ]; then
                cp "${hooks_dir}/${this_hook}" "${git_hooks_dir}/${this_hook_type}.d"
            else
                echo "NOTICE:  Function ${self} - Hook ${this_hook} is already installed"
            fi

        else
            err_msg="ERROR:  Function ${self} - Could not determint hook type for hook \"${this_hook}\""
            let return_code=${ERROR}
        fi

    else
        err_msg="ERROR:  Function ${self} - Not enough arguments provided"
        let return_code=${ERROR}
    fi

    return ${return_code}
}

f__main() {
    let return_code=${SUCCESS}

    self="${FUNCNAME[0]}"

    all_available_hooks=$(f__available_hooks)
    all_installed_hooks=$(f__installed_hooks)
    uninstalled_hooks=$(f__uninstalled_hooks "${all_available_hooks}")

    # See how we were called
    my_arg="${1}"

    case "${my_arg}" in 

        -l)
            f__hook_listing "${all_available_hooks}" "AVAILABLE"
            f__hook_listing "${all_installed_hooks}" "INSTALLED"
        ;;

        -d)

            # Enter interactive mode if there are any installed hooks
            if [ ! -z "${all_installed_hooks}" ]; then
                f__hook_listing "${all_installed_hooks}" "INSTALLED"

                my_choice=""
            
                while [ "${my_choice}" = "" ]; do
                    read -p "Enter the name of the hook you wish to disable: " choice
            
                     if [ "${choice}" != "" ]; then
                         this_hook_type=$(echo "${choice}" | awk -F'_' '{print $1}')
            
                         if [ ! -z "${this_hook_type}" -a -e "${git_hooks_dir}/${this_hook_type}.d/${choice}" ]; then
                             my_choice="${choice}"
                             my_hook_type="${this_hook_type}"
                         else
                             echo
                             echo "Invalid choice"
                             echo
                             sleep 2
                         fi
            
                     fi
            
                done

                if [ ! -z "${my_choice}" -a -e "${git_hooks_dir}/${this_hook_type}.d/${my_choice}" ]; then
                    rm -f "${git_hooks_dir}/${this_hook_type}.d/${my_choice}"
                fi

            fi

        ;;

        *)

            # Enter interactive mode if there are any uninstalled hooks
            if [ ! -z "${uninstalled_hooks}" ]; then
                f__hook_listing "${all_available_hooks}" "AVAILABLE"
                f__hook_listing "${all_installed_hooks}" "INSTALLED"

                my_choice=""
            
                while [ "${my_choice}" = "" ]; do
                    read -p "Enter the name of the hook you wish to enable: " choice
            
                     if [ "${choice}" != "" ]; then
            
                         if [ -e "${hooks_dir}/${choice}" ]; then
                             my_choice="${choice}"
                             my_hook_type=$(echo "${my_choice}" | awk -F'_' '{print $1}')
                         else
                             echo
                             echo "Invalid choice"
                             echo
                             sleep 2
                         fi
            
                     fi
            
                done
            
                # See if the file hook_framework exists in the git hooks dir
                # by virtue of searching for a symbolic link to it named ${my_hook_type}
                let hook_type_is_link=$(file -h "${git_hooks_dir}/${my_hook_type}" 2> /dev/null | egrep -ic "symbolic link.* hook_framework")
            
                # If we don't find a link, then we ensure the hook_framework script exists
                if [ ${hook_type_is_link} -eq 0 ]; then
                    f__install_hook_framework
                fi
            
                # If the hook framework script is present and executable
                if [ -x "${git_hooks_dir}/hook_framework" ]; then
                    f__activate_hook_framework "${my_choice}"
                else
                    err_msg="ERROR:  Function ${self} - Failed to install hook framework script.  Hook ${my_choice} was not installed"
                    let return_code=${ERROR}
                fi
                        
            else
                err_msg="NOTICE:  Function ${self} - Nothing to do -- All available hooks are installed"
                let return_code=${ERROR}
            fi

        ;;

    esac

    return ${return_code}
}

# Call main
f__main "${@}"
exit_code=${?}

if [ ${exit_code} -ne ${SUCCESS} ]; then

    if [ ! -z "${err_msg}" ]; then
        echo "${err_msg}"
    fi

fi

exit ${exit_code}
