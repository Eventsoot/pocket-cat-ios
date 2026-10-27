"""Package only the cat project, including the workflow at the archive root."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent
destination = root.parent / 'PocketCat-GitHub-ready.zip'
files = [root / name for name in [
    '.gitignore', 'project.yml', 'project-basic.yml', 'check_project.py',
    'package-source.py', 'README.md', 'INSTALL-WINDOWS.md',
    '.github/workflows/build-ios.yml', 'scripts/build-ios.sh',
    'scripts/make-assets.py', 'scripts/preview-ios.sh', 'Tests/main.swift',
]]
files += sorted((root / 'App').glob('*.swift'))
files += sorted((root / 'Shared').glob('*.swift'))
files += sorted((root / 'Widgets').glob('*.swift'))
with ZipFile(destination, 'w', ZIP_DEFLATED) as archive:
    for file in files:
        assert file.is_file(), file
        archive.write(file, file.relative_to(root).as_posix())
with ZipFile(destination) as archive:
    assert archive.testzip() is None
    assert '.github/workflows/build-ios.yml' in archive.namelist()
    assert all(not name.startswith('../') for name in archive.namelist())
print(f'Created {destination.name}: {len(files)} project files, workflow at root, no other workspace files.')
