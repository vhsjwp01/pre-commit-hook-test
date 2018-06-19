#!/bin/bash
#set -x

SUCCESS=0
ERROR=1

err_msg=""
exit_code=${SUCCESS}

# WHAT: Figure out the filenames in our commit payload
# WHY:  We want to find out if any of them are YAML files
#
if [ ${exit_code} -eq ${SUCCESS} ]; then
    # We gather the filenames in the payload and pad spaces in the filename with
    # an X-Wing fighter (which should hopefully be unique to the actual filename
    file_payload=$(git diff --cached --name-status | egrep "^[A-Z]\t" | egrep -v "^D\t" | strings | sed -e 's?\ ?:=8o8=:?g')
    
    # ${file_payload} should be a space separated list of files
    for file_name in ${file_payload} ; do
        # Reconstitute any spaces that may have been in the original filename
        real_file_name=$(echo "${file_name}" | sed -e 's?:=8o8=:? ?g')
    
        let is_yaml_file=0
        let has_yaml_extension=$(echo "${real_file_name}" | egrep -c "\b\.yaml$")
    
        # A YAML file will have the extension .yaml and be of filetype ASCII text
        if [ ${has_yaml_extension} -gt 0 ]; then
            let is_ascii_file=$(file "${real_file_name}" | egrep -c "ASCII text")
    
            if [ ${is_ascii_file} -gt 0 ]; then
                let is_yaml_file=1
            fi
    
        fi
    
        # If we are a YAML file, search for both the undated and dated SSL cert references
        # Present or no, the count should be the same.  We break if they are not
        if [ ${is_yaml_file} -gt 0 ]; then
            let cert_ref_count=$(egrep -c "star\-.*vital[source|book]" "${real_file_name}")
            let date_cert_ref_count=$(egrep -c "star\-.*vital[source|book].*\-[0-9][0-9]\-[0-9][0-9]\-[0-9][0-9][0-9][0-9]" "${real_file_name}")
    
            if [ ${cert_ref_count} -ne ${date_cert_ref_count} ]; then
                echo "    PROBLEM FOUND:  YAML file \"${real_file_name}\" contains at least one reference to an undated SSL certificate"
                let exit_code=${exit_code}+1
            fi
    
        fi
    
    done

    if [ ${exit_code} -ne ${SUCCESS} ]; then
        err_msg="Problems were found with some SSL certificate references"
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
