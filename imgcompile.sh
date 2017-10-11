#!/bin/bash

USR="$(pwd)"
CUR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $USR
SUB=false
PDF=true
IMG=false
BACKGROUND=true
COMPDIR=""
COMPBOOL=false
COMPILED=""
FLAGS=""
for ARG in $@;
do
    if [ "$COMPBOOL" = true ] && [ ! -f $ARG ]
    then

        cd $USR
        cd $ARG
        COMPBOOL=false
        if [ ! -d $ARG ]
        then
            mkdir $ARG
        fi
        COMPDIR="$(pwd)"
        FLAGS+="-d $COMPDIR "
        cd $USR
        continue
    fi
    case $ARG in
        "--help")
            echo "Usage:"
            echo "    Pass .tex files in any argument position for compilation"
            echo "    Pass directories to compile all .tex files in the directory"
            echo "Flags:"
            echo "    -i: converts all latex files to jpg or png (see nobackground) following this flag with imagemagick"
            echo "    -s: compiles the subdirectories of all directories after this flag"
            echo "    -d: takes the next non-file in the list as arguments as a compilation directory"
            echo "    --nopdf: removes the compiled pdf file"
            echo "    --nobackground: converts files to .png with no background instead of .jpg"
            continue
            ;;
        "-i")
            IMG=true
            FLAGS+="-i "
            continue
            ;;
        "-s")
            SUB=true
            FLAGS+="-s "
            continue
            ;;
        "-d")
            COMPBOOL=true
            continue
            ;;
        "--nopdf")
            PDF=false
            FLAGS+="--nopdf "
            continue
            ;;
        "--nobackground")
            BACKGROUND=false
            FLAGS+="--nobackground "
            continue
            ;;
    esac
    if [ ! -d $ARG ] && [ ! -f $ARG ]
    then
        echo "file or directory doesn't exist"
        continue
    fi
    if [ -d $ARG ]
    then
        cd $ARG
        $CUR/imgcompile.sh $FLAGS $(find . -name "*.tex")
        if [ "$SUB" = true ]
        then
            SUBDIRECTORIES=$(find -maxdepth 1 -type d)
            $CUR/imgcompile $FLAGS $SUBDIRECTORIES
        fi
        continue
    else
        TEX=${ARG##*/}
        NAME=${TEX%%.tex}
        if [ "${TEX##*.}" != "tex" ]
        then
            echo Not a .tex file. Skipping...
            continue
        fi
        DIR=${ARG%%/$TEX}
        cd $DIR
        pdflatex -interaction=batchmode $TEX
        if [ "$PDF" = true ]
        then
            COMPILED+="$NAME.pdf "
        else
            rm "$NAME.pdf"
        fi
        if [ "$IMG" = true ]
        then
            if [ "$BACKGROUND" = true ]
            then
                convert -quality 100 "${TEX%%.tex}.pdf" "$NAME.jpg"
                COMPILED+=$(find . -name "$NAME*.jpg")
            else
                convert -quality 100 "${TEX%%.tex}.pdf" "$NAME.png"
                COMPILED+=$(find . -name "$NAME*.png")
            fi
        fi
        rm "$NAME.aux" "$NAME.log"
        if [ "$COMPDIR" != "" ]
        then
            echo $(pwd)
            mv $COMPILED $COMPDIR
        fi
        cd $USR
        if [ "$SUB" = true ]
        then
            SUBDIRECTORIES=$(find -maxdepth 1 -type d)
            $CUR/imgcompile $FLAGS $SUBDIRECTORIES
        fi
    fi
done
