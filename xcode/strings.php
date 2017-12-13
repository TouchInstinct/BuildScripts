<?php
    $PROJECT_NAME = $argv[1];
    $COMMON_STRINGS_PATH = $argv[2];

    foreach (glob($COMMON_STRINGS_PATH.'/*.json') as $file) {
        $languageName = array_pop(explode('_', basename($file, '.json')));
        $isBase = strpos($file, 'default') !== false;

        $jsonFile = file_get_contents($file);
        $json = json_decode($jsonFile);

        $ios_strings = "";
        foreach ($json as $key=>$value) {
            $ios_strings.='"'.$key.'" = "'.str_replace('%s', '%@', str_replace('"','\"', str_replace("\n", '\n', $value))).'";'.PHP_EOL;
        }
        $ios_strings = preg_replace('/(\\\\)(u)(\d{4})/', '$1U$3', $ios_strings);
        file_put_contents('./'.$PROJECT_NAME.'/Resources/'.$languageName.'.lproj/Localizable.strings', $ios_strings);

        if($isBase) {
            file_put_contents('./'.$PROJECT_NAME.'/Resources/Base.lproj/Localizable.strings', $ios_strings);
            $ios_swift_strings = 'import Foundation'.PHP_EOL.
                                 'import LeadKit'.PHP_EOL.PHP_EOL.
                                 '// swiftlint:disable superfluous_disable_command'.PHP_EOL.
                                 '// swiftlint:disable line_length'.PHP_EOL.
                                 '// swiftlint:disable file_length'.PHP_EOL.
                                 '// swiftlint:disable identifier_name'.PHP_EOL.PHP_EOL.
                                 'extension String {'.PHP_EOL;
            foreach ($json as $key=>$value) {
                $value_without_linefeed = preg_replace("/\r|\n/", " ", $value);
                $ios_swift_strings .= "\t/// ".$value_without_linefeed."\n\t".'static let '.preg_replace_callback('/_(.?)/', function ($m) { return strtoupper($m[1]); }, $key).' = "'.$key.'".localized()'."\n".PHP_EOL;
            }
            $ios_swift_strings .= '}'.PHP_EOL;
            file_put_contents('./'.$PROJECT_NAME.'/Resources/String+Localization.swift', $ios_swift_strings);
        }
    }
?>