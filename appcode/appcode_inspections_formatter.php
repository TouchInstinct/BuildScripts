<?php
	$problemsCount = 0;
	$html = '';
	$reportsPath = $argv[1];
	$fileNames = scandir($reportsPath);
	$fileNames = array_slice($fileNames, 3);
	foreach ($fileNames as $fileName) {
		$filepath = $reportsPath.DIRECTORY_SEPARATOR.$fileName;
		$xml = simplexml_load_file($filepath);
		foreach ($xml->problem as $problem) {
			if ($problem->description == 'File is too complex to perform context-sensitive data-flow analysis') {
				continue;
			}
			$problemsCount++;
			$html .= '<tr><td>'.$problemsCount.'</td><td>'.$problem->file.'</td><td>'.$problem->line.'</td><td>'.$problem->description.'</td></tr>';
		}
	}
	if ($problemsCount > 0) {
		$html = '<table border cellpadding="5"><tr>'
			.'<td align="center" bgcolor="LightGray"><b>Num</b></td>'
			.'<td align="center" bgcolor="LightGray"><b>File</b></td>'
			.'<td align="center" bgcolor="LightGray"><b>Line</b></td>'
			.'<td align="center" bgcolor="LightGray"><b>Problem</b></td><tr>'.$html.'</table>';
		echo 'Found inspection problems: '.$problemsCount.PHP_EOL;
	} else {
		$html = '<h1 align="center">No inspection problems found</h1>';
	}
	$html = '<html><head></head><body>'.$html.'</body></html>';
	file_put_contents($reportsPath.DIRECTORY_SEPARATOR.'appcode_inspections.html', $html);
?>
