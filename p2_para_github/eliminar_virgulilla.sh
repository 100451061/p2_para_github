#!/bin/bash

# Elimina todos los archivos que terminan en '~' (backups de emacs)
find . -type f -name '*~' -exec rm '{}' \;