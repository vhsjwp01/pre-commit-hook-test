#!/bin/bash
#set -x

SUCCESS=0
ERROR=1

err_msg=""
exit_code=${SUCCESS}

x_wing_fighter=":=8o8=:"

# WHAT: Figure out the filenames in our commit payload
# WHY:  We want to find out if any of them are terraform files
#
if [ ${exit_code} -eq ${SUCCESS} ]; then
    # We gather the filenames in the payload and pad spaces in the filename with
    # an X-Wing fighter (which should hopefully be unique to the actual filename)
    file_payload=$(git diff --cached --name-status | egrep "^[A-Z]\t" | egrep -v "^D\t" | strings | sed -e "s|\ |${x_wing_fighter}|g")
    
    # ${file_payload} should be a space separated list of files
    for file_name in ${file_payload} ; do
        # Reconstitute any spaces that may have been in the original filename
        real_file_name=$(echo "${file_name}" | sed -e "s|${x_wing_fighter}| |g")
    
        let is_tf_file=0
        let has_tf_extension=$(echo "${real_file_name}" | egrep -c "\b\.tf$")
    
        # A TF file will have the extension .tf and be of filetype ASCII text
        if [ ${has_tf_extension} -gt 0 ]; then
            let is_ascii_file=$(file "${real_file_name}" | egrep -c "ASCII text")
    
            if [ ${is_ascii_file} -gt 0 ]; then
                let is_tf_file=1
            fi
    
        fi
    
        # If we are a TF file, compute the dirname and then run terraform fmt against that dir
        if [ ${is_tf_file} -gt 0 ]; then
            this_dirname=$(dirname "${file_name}")
            terraform fmt -check=true ${this_dirname} > /dev/null 2>&1

            if [ ${?} -ne ${SUCCESS} ]; then
                echo "    PROBLEM(S) FOUND:  The command \"terraform fmt '${this_dirname}'\" exited non-zero" >&2
                let exit_code=${exit_code}+1
            fi
    
        fi
    
    done

    if [ ${exit_code} -ne ${SUCCESS} ]; then
        err_msg="Problems were found with some terraform files"
    fi

fi

# WHAT: Complain if necessary and then exit
# WHY:  Success or failure, either way we are through
#
if [ ${exit_code} -ne ${SUCCESS} ]; then

    if [ "${err_msg}" != "" ]; then
        echo
        echo "    ERROR:  ${err_msg} ... processing halted"
        echo
    fi

fi

exit ${exit_code}
