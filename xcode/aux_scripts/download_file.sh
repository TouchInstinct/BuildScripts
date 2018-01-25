file_name=$1
file_link=$2

folder="Downloads"
file_path="./${folder}/${file_name}"

# make folder if not exist
if ! [ -e ${folder} ]; then
    mkdir ${folder}
fi

# download file if not downloaded
if ! [ -e ${file_path} ]; then
    curl -L ${file_link} -o ${file_path}
fi
