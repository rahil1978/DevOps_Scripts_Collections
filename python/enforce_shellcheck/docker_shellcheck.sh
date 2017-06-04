#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT 
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : docker_shellcheck.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
##
## More reading: http://www.dennyzhang.com/shellcheck/
##
## --
## Created : <2017-05-12>
## Updated: Time-stamp: <2017-06-03 19:12:32>
##-------------------------------------------------------------------
code_dir=${1?""}
ignore_file_list=${2-""}
exclude_code_list=${3-""}

image_name="denny/shellcheck:1.0"
check_filename="/enforce_shellcheck.py"

current_filename=$(basename "$0")
test_id="${current_filename%.sh}_$$"
container_name="$test_id"
ignore_file="$test_id"

function remove_container() {
    container_name=${1?}
    if docker ps -a | grep "$container_name" 1>/dev/null 2>&1; then
        echo "Destroy container: $container_name"
        docker stop "$container_name"; docker rm "$container_name"
    fi
}

function shell_exit() {
    errcode=$?
    if [ $errcode -eq 0 ]; then
        echo "Test has passed."
    else
        echo "ERROR: Test has failed."
    fi

    echo "Remove tmp file: $ignore_file"
    rm -rf "/tmp/$ignore_file"

    remove_container "$container_name"
    exit $errcode
}

################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0

echo "Generate the ignore file for code check"
echo "$ignore_file_list" > "/tmp/$ignore_file"

echo "Start container"
remove_container "$container_name"
docker run -t -d --privileged -v "${code_dir}:/code" --name "$container_name" --entrypoint=/bin/sh "$image_name"

echo "Copy ignore file"
docker cp "/tmp/$ignore_file" "$container_name:/$ignore_file"

echo "Run code check: python $check_filename --code_dir /code --check_ignore_file /${ignore_file} --exclude_code_list ${exclude_code_list}"
docker exec -t "$container_name" python "$check_filename" --code_dir /code --check_ignore_file "/${ignore_file}" --exclude_code_list "${exclude_code_list}"
## File : docker_shellcheck.sh ends
