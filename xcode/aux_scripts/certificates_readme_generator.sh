CERTS_PATH="${PROJECT_DIR}/Certificates"

for config_folder in $CERTS_PATH/*/; do
  CONFIG_FOLDER_NAME="$(basename "$config_folder")"

  echo "# ${CONFIG_FOLDER_NAME}"

  for type_folder in $CERTS_PATH/$CONFIG_FOLDER_NAME/*/; do
 		TYPE_FOLDER_NAME="$(basename "$type_folder")"

	echo "### ${TYPE_FOLDER_NAME}"
	echo "|Target|Description|"
	echo "|-|-|"

  	for target_folder in $CERTS_PATH/$CONFIG_FOLDER_NAME/$TYPE_FOLDER_NAME/*/; do
		TARGET_FOLDER_NAME="$(basename "$target_folder")"

		DESCRIPTION_FILE_NAME="description.txt"

		DESCRIPTION_FILE_PATH="${CERTS_PATH}/${CONFIG_FOLDER_NAME}/${TYPE_FOLDER_NAME}/${TARGET_FOLDER_NAME}/${DESCRIPTION_FILE_NAME}"

		if [ -e "$DESCRIPTION_FILE_PATH" ]
		then
			DESCRIPTION="$(cat $DESCRIPTION_FILE_PATH)"
		else
			DESCRIPTION="-"
		fi

  		for file in $CERTS_PATH/$CONFIG_FOLDER_NAME/$TYPE_FOLDER_NAME/$TARGET_FOLDER_NAME/*; do
 				FILE_NAME="$(basename "$file")"

				if ! [ "$FILE_NAME" == "$DESCRIPTION_FILE_NAME" ]
			then
  				echo "|[${TARGET_FOLDER_NAME}](${CONFIG_FOLDER_NAME}/${TYPE_FOLDER_NAME}/${TARGET_FOLDER_NAME}/${FILE_NAME})|${DESCRIPTION}|"
  			fi
  		done
  	done
  done
done