<?php
    $PRODUCT_NAME = $argv[1];
    $COMMON_STRINGS_PATH = $argv[2];

    function createFolder($path) {
        if (!file_exists($path)) {
            mkdir($path, 0777, true);
        }
    }
    
    $localization = './'.$PRODUCT_NAME.'/Resources/Localization/';

    $baseFile = file_get_contents(array_pop(glob($COMMON_STRINGS_PATH.'/default*.json')));
    $baseJson = json_decode($baseFile, true);

    foreach (glob($COMMON_STRINGS_PATH.'/*.json') as $file) {
        $languageName = array_pop(explode('_', basename($file, '.json')));
        $isBase = strpos($file, 'default') !== false;

        $jsonFile = file_get_contents($file);
        $json = array_merge($baseJson, json_decode($jsonFile, true));
        
        if ($json == null) {
            echo "Invalid JSON format\n";
            exit(1);
        }

        $ios_strings = "";
        foreach ($json as $key=>$value) {
            $ios_strings.='"'.$key.'" = "'.str_replace('%s', '%@', str_replace('"','\"', str_replace("\n", '\n', $value))).'";'.PHP_EOL;
        }
        $ios_strings = preg_replace('/(\\\\)(u)([0-9a-fA-F]{4})/', '$1U$3', $ios_strings);

        $lproj = $localization.$languageName.'.lproj/';
        createFolder($lproj);
        file_put_contents($lproj.'Localizable.strings', $ios_strings);

        if($isBase) {
            createFolder($localization.'Base.lproj/');
            file_put_contents($localization.'Base.lproj/Localizable.strings', $ios_strings);
            $ios_swift_strings = 'import Foundation'.PHP_EOL.PHP_EOL.
                                 '// swiftlint:disable superfluous_disable_command'.PHP_EOL.
                                 '// swiftlint:disable line_length'.PHP_EOL.
                                 '// swiftlint:disable file_length'.PHP_EOL.
                                 '// swiftlint:disable identifier_name'.PHP_EOL.PHP_EOL.
                                 'public extension String {'.PHP_EOL;
            foreach ($json as $key=>$value) {
                $value_without_linefeed = preg_replace("/\r|\n/", " ", $value);
                $ios_swift_strings .= "\t/// ".$value_without_linefeed."\n\t".'static let '.preg_replace_callback('/_(.?)/', function ($m) { return strtoupper($m[1]); }, $key).' = NSLocalizedString("'.$key.'", comment: "")'."\n".PHP_EOL;
            }
            $ios_swift_strings .= '}'.PHP_EOL;
            file_put_contents($localization.'String+Localization.swift', $ios_swift_strings);
        }
    }
?>
