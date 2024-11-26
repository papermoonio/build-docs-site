#!/bin/bash

usage() { echo "Usage: $0 [-f] [-m <repository>] [-b \"<mkdocs_branch>\"] [-e \"<en_branch>\"] [-o \"<en_DOCS>\"] [-c \"<cn_branch>\"] [-s \"<cn_DOCS>\"]" 1>&2; exit 0; }

force=0
MKDOCS=""
MKDOCSBRANCH=""
ENDOCS=""
ENBRANCH=""
CNBRANCH=""
CNDOCS=""

# Get input variables
while getopts "fm:b:o:e:s:c:" arg; do
    case "${arg}" in
        f)
            force=1
            ;;
        m)
            MKDOCS=${OPTARG}
            ;;
        b)
            MKDOCSBRANCH=${OPTARG}
            ;;
        o)
            ENDOCS=${OPTARG}
            ;;
        e)
            ENBRANCH=${OPTARG}
            ;;
        s)
            CNDOCS=${OPTARG}
            ;;
        c)
            CNBRANCH=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

# Check for mandatory inputs
if [ -z "$MKDOCS" ] || [ -z "$MKDOCSBRANCH" ] || [ -z "$ENDOCS" ] || [ -z "$ENBRANCH" ]; then
    echo "Error: Missing mandatory input(s)."
    echo "The following inputs are required:"
    echo "  -m <repository> (MKDOCS)"
    echo "  -b \"<mkdocs_branch>\" (MKDOCSBRANCH)"
    echo "  -o \"<en_DOCS>\" (ENDOCS)"
    echo "  -e \"<en_branch>\" (ENBRANCH)"
    usage
fi

# Extract the portion after the last "/" for MKDOCS and ENDOCS
MKDOCS_NAME=$(basename "$MKDOCS")  # "wormhole-mkdocs"
ENDOCS_NAME=$(basename "$ENDOCS") # "wormhole-docs"

# Use these extracted names to define paths
ORIGINPATH=$PWD
MKDOCSPATH=$ORIGINPATH/${MKDOCS_NAME}
DOCSPATH=$MKDOCSPATH/${ENDOCS_NAME}
STATICPATH=$ORIGINPATH/${ENDOCS_NAME}-static


printf "\n%s\n\n" "======== Docs Static Site Builder ========"

# Define languages if available
if [ -n "$CNBRANCH" ] && [ "$CNBRANCH" != "" ]; then
    ML_SITES=("cn")
else
    ML_SITES=()
fi
ML_BRANCH=($CNBRANCH)
ML_DOCS=($CNDOCS)

# Check if Mkdocs exists
# If not, clones the repo (requires SSH Cloning)
printf "%s\n" "-------- Mkdocs Repo --------"
if [ ! -d $MKDOCSPATH ] || [ $force == 1 ];
then
  if [ -d "$MKDOCSPATH" ]; then rm -Rf $MKDOCSPATH; fi
  printf "%s\n" "----> Cloning Mkdocs Repo ${MKDOCS} - branch ${MKDOCSBRANCH}"
  git clone https://github.com/${MKDOCS} -b ${MKDOCSBRANCH}
  cd ..
else
  # Pull latests changes from master
  cd $MKDOCSPATH
  printf "%s\n\n\n" "--> Pulling latest Mkdocs changes"
  git merge origin/master
  c ..
fi

cd $MKDOCSPATH

# Build static site
printf "\n\n%s\n\n" "-------- EN Docs repo --------"
if [ ! -d $DOCSPATH ] || [ $force == 1 ];
then
  if [ -d "$DOCSPATH" ]; then rm -Rf $DOCSPATH; fi
  printf "%s\n" "----> Cloning Docs from repo DOCS ${ENDOCS} - branch ${ENBRANCH}"
  git clone https://github.com/${ENDOCS} -b ${ENBRANCH}
  cd ..
else
  printf "%s\n" "----> No cloning needed, pulling latest changes from ${ENDOCS}"
  cd $DOCSPATH
  git merge origin/master
  git checkout -b ${ENBRANCH}
  cd ..
fi

# Build static path does not exist or force is enabled
cd $MKDOCSPATH
if [ ! -d $STATICPATH ] || [ $force == 1 ]; then
  if [ -d "$STATICPATH" ]; then rm -Rf $STATICPATH; fi
  printf "%s\n\n\n" "----> Building static site from ${ENDOCS}"
  mkdocs build -d $STATICPATH --clean
fi

# ML Steps
for i in "${!ML_SITES[@]}"
do
  printf "\n\n%s\n" "-------- Docs ${ML_SITES[i]} repo --------"
  # This is the static language folder
  TMPSTATICML=$STATICPATH/${ML_SITES[i]}
  # Check and creat the static folder inside the static site
  if [ ! -d $TMPSTATICML ] || [ $force == 1 ]; then
    if [ -d "$TMPSTATICML" ]; then rm -Rf $TMPSTATICML; fi
    printf "%s\n" "----> Creating static folder inside ${ENDOCS_NAME} static"
    mkdir $TMPSTATICML
  fi
  #

  # Create each ML mkdocs directory
  # This is the mkdocs language folder
  TMPBUILDML=$MKDOCSPATH-${ML_SITES[i]}
  if [ ! -d $TMPBUILDML ] || [ $force == 1 ]; then
    if [ -d "$TMPBUILDML" ]; then rm -Rf $TMPBUILDML; fi
    printf "%s\n" "----> Creating mkdocs-${ML_SITES[i]} folder"
    mkdir $TMPBUILDML
  fi

  # Create symlinks for mkdocs
  # This symlink depends if legacy or revamp
  printf "%s\n" "----> Creating material-overrides symlinks"
  OS=$(uname)
  if [ "$OS" = "Linux" ]; then
    [ ! -d $TMPBUILDML/material-overrides ] && cp -Rs $MKDOCSPATH/material-overrides/ $TMPBUILDML
  else
    [ ! -d $TMPBUILDML/material-overrides ] && gcp -Rs $MKDOCSPATH/material-overrides/ $TMPBUILDML
  fi 

  # Copy the ML mkdocs specific content
  # This symlink depends if legacy or revamp
  printf "%s\n" "----> Creating mkdocs.yml symlink"
  if [ "$OS" = "Linux" ]; then
    [ ! -f $TMPBUILDML/mkdocs.yml ] && cp -Rsf $MKDOCSPATH/mkdocs-${ML_SITES[i]}/* $TMPBUILDML
  else
    [ ! -f $TMPBUILDML/mkdocs.yml ] && gcp -Rsf $MKDOCSPATH/mkdocs-${ML_SITES[i]}/* $TMPBUILDML
  fi 


  # Clone the corresponding Docs-ML
  cd $TMPBUILDML
  TMPDOCSML=$TMPBUILDML/${ENDOCS_NAME}-${ML_SITES[i]}
  if [ ! -d $TMPDOCSML ]
  then
    printf "%s\n" "----> Cloning ${ENDOCS_NAME}-${ML_SITES[i]} repo DOCS ${ML_DOCS[i]} - branch ${ML_BRANCH[i]}"
    git clone https://github.com/${ML_DOCS[i]} -b ${ML_BRANCH[i]}
  else
    printf "%s\n" "----> No cloning needed, pulling latest changes from ${ENDOCS_NAME}-${ML_SITES[i]}"
    cd $TMPDOCSML
    git merge origin/master
  fi
  
  # Create Symlinks to Docs
  # These symlinks depends if legacy or revamp
  printf "%s\n" "----> Creating symlinks for files inside ${ENDOCS_NAME}"
  [ ! -L $TMPDOCSML/variables.yml ] && ln -s $DOCSPATH/variables.yml $TMPDOCSML/variables.yml
  [ ! -L $TMPDOCSML/images ] && ln -s $DOCSPATH/images $TMPDOCSML/images
  [ ! -L $TMPDOCSML/js ] && ln -s $DOCSPATH/js $TMPDOCSML/js
  [ ! -L $TMPDOCSML/.snippets/code ] && ln -s $DOCSPATH/.snippets/code $TMPDOCSML/.snippets/code


  # Build each of the ML sites
  printf "%s\n" "----> Building the static ${ML_SITES[i]} site"
  cd $TMPBUILDML
  mkdocs build -d $TMPSTATICML --clean


  if [ "$OS" = "Linux" ]; then
    printf "%s\n\n\n" "----> Post processing static (Linux)"
     # fix relative links to include language subdir
    find $TMPSTATICML -type f -name index.html -exec sed -i "s|href=\"\/|href=\"\/${ML_SITES[i]}\/|g" '{}' \;
    # update instances where the language is duplicated
    find $TMPSTATICML -type f -name index.html -exec sed -i "s|href=\"\/${ML_SITES[i]}/${ML_SITES[i]}/|href=\"\/${ML_SITES[i]}\/|g" '{}' \;
    # temporary patch to fix relative path of the assets to 
    # an absolute path in multi language folders
    find $TMPSTATICML -type f -name index.html -exec sed -i "s|href=\"\/${ML_SITES[i]}\/assets\/|href=\"\/assets\/|g" '{}' \;
    # remove images folder of the static sites as they are not necessary
    rm -rf $TMPSTATICML/images/
    ### Making all external source links HTTPS
    find $STATICPATH -type f -name "*.html" -exec sed -i "s|href=\"\/\/|href=\"https:\/\/|g" '{}' \;
    find $STATICPATH -type f -name "*.html" -exec sed -i "s|src=\"\/\/|src=\"https:\/\/|g" '{}' \;
  else
    printf "%s\n\n\n" "----> Post processing static (Mac)"
     # fix relative links to include language subdir
    find $TMPSTATICML -type f -name index.html -exec gsed -i "s|href=\"\/|href=\"\/${ML_SITES[i]}\/|g" '{}' \;
    # update instances where the language is duplicated
    find $TMPSTATICML -type f -name index.html -exec gsed -i "s|href=\"\/${ML_SITES[i]}/${ML_SITES[i]}/|href=\"\/${ML_SITES[i]}\/|g" '{}' \;
    # temporary patch to fix relative path of the assets to 
    # an absolute path in multi language folders
    find $TMPSTATICML -type f -name index.html -exec gsed -i "s|href=\"\/${ML_SITES[i]}\/assets\/|href=\"\/assets\/|g" '{}' \;
    # remove images folder of the static sites as they are not necessary
    rm -rf $TMPSTATICML/images/
    ### Making all external source links HTTPS
    find $STATICPATH -type f -name "*.html" -exec gsed -i "s|href=\"\/\/|href=\"https:\/\/|g" '{}' \;
    find $STATICPATH -type f -name "*.html" -exec gsed -i "s|src=\"\/\/|src=\"https:\/\/|g" '{}' \;
  fi 

done
