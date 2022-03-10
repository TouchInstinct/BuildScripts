file_name=$1
file_link=$2
folder=$3
flag_of_delete=$4

key_of_delete="--remove-cached"
default_folder="./Downloads"

if [[ ${folder} = ${key_of_delete} ]]; then
    folder="${default_folder}"
    flag_of_delete="${key_of_delete}"
fi

if ! [ -n "$folder" ]; then
    folder="${default_folder}"
fi

file_path="${folder}/${file_name}"

if [[ ${flag_of_delete} = ${key_of_delete} ]]; then
    rm ${file_path}
fi

# make folder if not exist
if ! [ -e ${folder} ]; then
    mkdir -p ${folder}
fi

# download file if not downloaded
if ! [ -e ${file_path} ]; then
    curl -L ${file_link} -o ${file_path}
fi
