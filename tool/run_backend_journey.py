"""Run the optional local F3.3 integration fixture, exclusively on private PostgreSQL.

Requires the isolated F1 PostgreSQL installation and F2 OCR tools already present.
Never reads the main backend datasource configuration or cleans a schema.
"""
from pathlib import Path
import json
import os
import subprocess
import sys

temporary = Path(os.environ['TEMP'])
private = temporary / 'orientia-f1-postgres'
config = json.loads((private / 'connection.json').read_text(encoding='utf-8-sig'))
if config['url'] != 'jdbc:postgresql://127.0.0.1:59745/orientia_f1':
    raise SystemExit('Only the isolated loopback test database is permitted')
environment = os.environ.copy()
environment['JAVA_HOME'] = str(temporary / 'orientia-f1-tools' / 'jdk-21.0.13.0.2+1')
environment['PATH'] = environment['JAVA_HOME'] + '\\bin;' + environment['PATH']
environment['F1_TEST_DB_PASSWORD'] = config['password']
ocr = json.loads((temporary / 'orientia-f2-tools' / 'ocr-runtime.json').read_text(encoding='utf-8-sig'))
backend = Path(__file__).resolve().parents[2] / 'orientation-backend'
if not (backend / 'mvnw.cmd').is_file():
    raise SystemExit('Expected the adjacent orientation-backend checkout')
full_suite = sys.argv[1:] == ['--full']
if sys.argv[1:] not in ([], ['--full']):
    raise SystemExit('Usage: python tool/run_backend_journey.py [--full]')
selection = [] if full_suite else ['-Dtest=MobileFlutterJourneyIT']
schema = 'f33_regression_20261107' if full_suite else 'f33_mobile_20261107'
arguments = ['cmd.exe', '/d', '/c', 'mvnw.cmd', '-q', *selection,
             '-Df1.jdbc.schema=' + schema, '-Df1.jdbc.url=' + config['url'],
             '-Df2.tesseract=' + ocr['executable'], '-Df2.tessdata=' + ocr['tessdata'], 'test']
log = temporary / ('orientia-f33-backend-regression.log' if full_suite else 'orientia-f33-live-backend.log')
with log.open('w', encoding='utf-8') as output:
    result = subprocess.run(arguments, cwd=backend, env=environment,
                            stdout=output, stderr=subprocess.STDOUT)
print('LiveBackendExit', result.returncode)
for line in log.read_text(encoding='utf-8', errors='replace').splitlines():
    if '[ERROR]' in line or 'Tests run:' in line:
        print(line[:700])
sys.exit(result.returncode)
