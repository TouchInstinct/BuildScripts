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

		TARGET_FOLDER_PATH="${CERTS_PATH}/${CONFIG_FOLDER_NAME}/${TYPE_FOLDER_NAME}/${TARGET_FOLDER_NAME}"
		DESCRIPTION_FILE_PATH="${TARGET_FOLDER_PATH}/${DESCRIPTION_FILE_NAME}"

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
				FILE_PATH="${TARGET_FOLDER_PATH}/${FILE_NAME}"
				EXTENSION="${FILE_NAME##*.}"
				PROPER_FILE_PREFIX="${PROJECT_NAME}${TARGET_FOLDER_NAME}${CONFIG_FOLDER_NAME}"

				if [ "$EXTENSION" == "mobileprovision" ]; then
					FILE_TYPE="Profile"
				elif [ "$EXTENSION" == "p12" ]; then
					FILE_TYPE="Cert"
				elif [ ]; then
					echo "Unknown type of file has been found. Not a profile or a certificate."
					exit 1
				fi

				PROPER_FILE_NAME="${PROPER_FILE_PREFIX}${FILE_TYPE}"

				mv $FILE_PATH "${TARGET_FOLDER_PATH}/${PROPER_FILE_NAME}.${EXTENSION}"

  				echo "|[${TARGET_FOLDER_NAME}](${CONFIG_FOLDER_NAME}/${TYPE_FOLDER_NAME}/${TARGET_FOLDER_NAME}/${PROPER_FILE_NAME}.${EXTENSION})|${DESCRIPTION}|"
  			fi
  		done
  	done
  done
done