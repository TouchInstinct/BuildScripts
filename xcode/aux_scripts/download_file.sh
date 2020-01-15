file_name=$1
file_link=$2
folder_to_delete=$3
file_to_delete=$4

folder="Downloads"
file_path="./${folder}/${file_name}"

# remove folder and all files it
if [ -e ${folder_to_delete} ]; then
    rm -rf ${folder_to_delete}
fi

# remove some file
if [ -e ${file_to_delete} ]; then
    rm ${file_to_delete}
fi

# make folder if not exist
if ! [ -e ${folder} ]; then
    mkdir ${folder}
fi

# download file if not downloaded
if ! [ -e ${file_path} ]; then
    curl -L ${file_link} -o ${file_path}
fi
