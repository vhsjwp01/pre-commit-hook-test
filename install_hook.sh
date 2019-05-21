#!/bin/bash
#set -x

hooks_dir="$(git rev-parse --show-toplevel)/git_hooks"
git_hooks_dir="$(git rev-parse --show-toplevel)/.git/hooks"

hook_framework="IyEvYmluL2Jhc2gKI3NldCAteAoKU1VDQ0VTUz0wCkVSUk9SPTEKCmVycl9tc2c9IiIKZXhpdF9jb2RlPSR7U1VDQ0VTU30KCiMgV0hBVDogUHJvY2VzcyBhbGwgb2Ygb3VyIGhvb2tzIHVzaW5nIGEgPGhvb2tfdHlwZT4uZCBpbmNsdWRlIHN0cnVjdHVyZQojIFdIWTogIFdlIHdhbnQgdG8gYXBwbHkgYWxsIG9mIG91ciBob29rcyBvZiB0aGlzIHR5cGUgaW4gYSBtb2R1bGFyIHdheQojCmlmIFsgJHtleGl0X2NvZGV9IC1lcSAke1NVQ0NFU1N9IF07IHRoZW4KICAgIG15X2Jhc2VuYW1lPSQoYmFzZW5hbWUgIiR7MH0iKQogICAgbXlfZGlybmFtZT0kKGRpcm5hbWUgIiR7MH0iKQoKICAgIGlmIFsgLWQgIiR7bXlfZGlybmFtZX0vJHtteV9iYXNlbmFtZX0uZCIgXTsgdGhlbgoKICAgICAgICBmb3IgaSBpbiAkKGZpbmQgJHtteV9kaXJuYW1lfS8ke215X2Jhc2VuYW1lfS5kIC10eXBlIGYgLW1heGRlcHRoIDEpIDsgZG8KICAgICAgICAgICAgc291cmNlICIke2l9IgogICAgICAgICAgICBsZXQgZXhpdF9jb2RlPSR7P30KCiAgICAgICAgICAgIGlmIFsgJHtleGl0X2NvZGV9IC1uZSAke1NVQ0NFU1N9IF07IHRoZW4KICAgICAgICAgICAgICAgIGJyZWFrCiAgICAgICAgICAgIGZpCiAgICAgICAgICAgIAogICAgICAgIGRvbmUKCiAgICBmaQoKZmkKCmV4aXQgJHtleGl0X2NvZGV9Cg=="

f__available_hooks() {
    # See what types of hooks we have available
    if [ -d "${hooks_dir}" ]; then
        all_available_hooks=$(find "${hooks_dir}" -maxdepth 1 -type f 2> /dev/null | awk -F'/' '{print $NF}')
        available_hook_types=$(for i in "${all_available_hooks}" ; do echo "${i}" | awk -F'_' '{print $1}' ; done | sort -u)
    fi
        
    # See what our available hooks are, by type
    if [ ! -z "${all_available_hooks}" ]; then
    
        for hook_type_available in ${available_hook_types} ; do
            echo
            echo "----------------------------------"
            echo "${hook_type_available} hooks AVAILABLE:"
            echo "----------------------------------"
            hooks_available=$(for i in "${all_available_hooks}" ; do echo "${i}" ; done | egrep "^${hook_type_available}_")
        
            for available_hook in ${hooks_available} ; do
                filename="${available_hook}"
                hook_type=$(echo "${filename}" | awk -F'_' '{print $1}')
                hook_description=$(egrep "^# DESCRIPTION: " "${hooks_dir}/${filename}" | sed -e 's|^# DESCRIPTION: ||g')
    
                echo "  name: ${filename}"
                echo "    type: ${hook_type}"
                echo "    description: ${hook_description}"
                echo
            done
    
        done
    
    fi

}

f__installed_hooks() {
# Identify all installed hooks
if [ -d "${git_hooks_dir}" ]; then
    all_installed_hooks=$(find "${git_hooks_dir}"/*.d/* -maxdepth 1 -type f 2> /dev/null | awk -F'/' '{print $NF}')
    installed_hook_types=$(find "${git_hooks_dir}" -maxdepth 1 -type d -name "*.d" 2> /dev/null | awk -F'/' '{print $NF}' | sed -e 's|\.d$||g' | sort -u)
fi

# See what our installed hooks are, by type
if [ ! -z "${installed_hook_types}" ]; then

    for hook_type_installed in ${installed_hook_types} ; do
        installed_hooks=$(find "${git_hooks_dir}/${hook_type_installed}.d" -maxdepth 1 -type f 2> /dev/null | awk -F'/' '{print $NF}')

        if [ ! -z "${installed_hooks}" ]; then
            echo
            echo "----------------------------------"
            echo "${hook_type_installed} hooks INSTALLED:"
            echo "----------------------------------"
    
            for hook_installed in ${installed_hooks} ; do
                filename="${hook_installed}"
                hook_type=$(echo "${filename}" | awk -F'_' '{print $1}')

                echo "  name: ${filename}"
                echo
            done

        fi

    done

fi
}

# See how we were called
my_arg="${1}"

f__available_hooks


# Figure out our uninstalled hooks
if [ ! -z "${all_available_hooks}" ]; then
    uninstalled_hooks=""

    for i in ${all_available_hooks} ; do
        filename="${i}"
        hook_type=$(echo "${filename}" | awk -F'_' '{print $1}')

        if [ ! -e "${git_hooks_dir}/${hook_type}.d/${i}" ]; then
            uninstalled_hooks+=" ${i}"
        fi

    done

fi

# Enter interactive mode if there are any uninstalled hooks
if [ ! -z "${uninstalled_hooks}" ]; then
    my_choice=""

    if [ ! -z "${1}" ]; then
        my_choice="${1}"
    fi

    while [ "${my_choice}" = "" ]; do
        read -p "Enter the name of the hook you wish to enable: " this_choice

         if [ "${this_choice}" != "" ]; then

             if [ -e "${hooks_dir}/${this_choice}" ]; then
                 my_choice="${this_choice}"
                 my_hook_type=$(echo "${my_choice}" | awk -F'_' '{print $1}')
             else
                 echo
                 echo "Invalid choice"
                 echo
                 sleep 5
             fi

         fi

    done

    # See if the file hook_framework exists in the git hooks dir
    # by virtue of searching for a symbolic link to it named ${my_hook_type}
    let hook_type_is_link=$(file -h "${git_hooks_dir}/${my_hook_type}" 2> /dev/null | egrep -ic "symbolic link.* hook_framework")

    # If we don't find a link, then we ensure the hook_framework script exists
    if [ ${hook_type_is_link} -eq 0 ]; then
        my_base64_decode_arg=$(base64 --help | egrep decode | awk -F',' '{print $1}')

        if [ ! -z "${my_base64_decode_arg}" ]; then
            CWD=$(pwd)                                                                                               &&
            cd "${git_hooks_dir}"                                                                                    &&
            eval "echo \"${hook_framework}\" | base64 ${my_base64_decode_arg} > \"${git_hooks_dir}/hook_framework\"" &&
            chmod 750 hook_framework                                                                                 &&
            cd "${CWD}"
        else
            echo "ERROR:  Could not unpack hook framework script.  Hook ${my_choice} was not installed"
        fi

    fi

    # If the hook framework script is present and executable
    if [ -x "${git_hooks_dir}/hook_framework" ]; then

        # Make sure ${my_hook_type} is a symlink to hook_framework
        if [ ! -L "${git_hooks_dir}/${my_hook_type}" ]; then
            CWD=$(pwd)                                                                                                &&
            cd "${git_hooks_dir}"                                                                                     &&
            rm -f ${my_hook_type} > /dev/null 2>&1                                                                    &&
            ln -s hook_framework ${my_hook_type}
            cd "${CWD}"
        fi

        # Make sure the ${my_hook_type}.d directory exists
        if [ ! -d "${git_hooks_dir}/${my_hook_type}.d" ]; then
            mkdir -p "${git_hooks_dir}/${my_hook_type}.d"
        fi

        # Install the hook in the ${my_hook_type}.d directory
        if [ ! -e "${git_hooks_dir}/${my_hook_type}.d/${my_choice}" ]; then
            cp "${hooks_dir}/${my_choice}" "${git_hooks_dir}/${my_hook_type}.d"
        else
            echo "Hook ${my_choice} is already installed"
        fi

    else
        echo "ERROR:  Failed to install hook framework script.  Hook ${my_choice} was not installed"
    fi
            
else
    echo "NOTICE:  Nothing to do -- All available hooks are installed"
fi












