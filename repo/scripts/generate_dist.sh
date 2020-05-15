# Argument 1: Title
# Argument 2: Package id
# Argument 3: Package file name

echo '<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>'$1'</title>
  <options customize="never" rootVolumeOnly="true" />
  <choices-outline>
    <line choice="default">
      <line choice="'$2'"/>
    </line>
  </choices-outline>
  <choice id="default"/>
  <choice id="'$2'" visible="false">
    <pkg-ref id="'$2'"/>
  </choice>
  <pkg-ref auth="root" id="'$2'" version="0">'$3'</pkg-ref>
</installer-gui-script>'
