#!/bin/bash

set -euo pipefail

exit_code=0
snyk_test_json=$1
formatted_json=''
args=("$*")

run_snyk_delta () {
    # add in any other arguments you would like to use
    snyk-delta
}


format_snyk_test_output() {
    #echo "Procesing snyk_kotlin_results.json"
    {
        formatted_json=`cat $snyk_test_json | jq -r 'if type=="array" then .[] else . end | @base64'`
        } || {
        echo 'failed to process snyk-test result'
        exit 2
    }
}

# 2. format results to support single & multiple results returned
format_snyk_test_output

# 3. call snyk-delta for each result
for test in `echo $formatted_json`; do
    single_result="$(echo ${test} | base64 -d)" # use "base64 -d -i" on Windows, which will ignore any "gardage" characters echoing may add
    project_name="$(echo ${single_result} | jq -r '.displayTargetFile')"
    echo 'Project: '  ${project_name}
    if echo ${single_result} | run_snyk_delta
    then
        project_exit_code=$?
        #echo 'Finished processing'
    else
        project_exit_code=$?
        if [ $project_exit_code -gt 1 ]
        then
            echo 'snyk-delta encountered an error, retrying.'
            echo ${single_result} | run_snyk_delta
        fi
        #echo 'Finished processing'
    fi

    if [ $project_exit_code -gt $exit_code ]
    then
        exit_code=$project_exit_code
    fi
    #echo "Project: ${project_name} | Exit code: ${project_exit_code}"
done

#echo "Overall exit code for snyk-delta: ${exit_code}"
exit $exit_code