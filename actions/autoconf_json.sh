#!/bin/bash

echo "{"
grep "^AC_SUBST" configure.ac | sed 's/^AC_SUBST(\[\(.*\)\], \[\(.*\)\])/"\1": "\2"/' | grep -E "^\"(SPELLER|GLANG)" |\
    sed 's/""/"/g' | sed 's/GLANGUAGE/human_name/g' | sed 's/GLANG2/language_tag/g' | sed 's/GLANG/name/g' | sed 's/SPELLERVERSION/version/' |\
    sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/, /g'
echo "}"
