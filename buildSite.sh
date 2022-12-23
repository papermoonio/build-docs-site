#!/bin/bash

usage() { echo "Usage: $0 [-f] [-m \"<mkdocs_branch>\"] [-e \"<en_branch>\"] [-c \"<cn_branch>\"]" 1>&2; exit 0; }

force=0
ENBRANCH="master"
CNBRANCH="master"
MKDOCSBRANCH="master"
while getopts "fm:e:c:" arg; do
    case "${arg}" in
        f)
            force=1

            ;;
        m)
            MKDOCSBRANCH=${OPTARG}

            ;;
        e)
            ENBRANCH=${OPTARG}
            ;;
        c)
            CNBRANCH=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

ORIGINPATH=$PWD
MKDOCSPATH=$ORIGINPATH/moonbeam-mkdocs
DOCSPATH=$MKDOCSPATH/moonbeam-docs
STATICPATH=$ORIGINPATH/moonbeam-docs-static

printf "\n%s\n\n" "======== Moonbeam Docs Static Site Builder ========"

# Define Languages
ML_SITES=("cn")
ML_BRANCH=($CNBRANCH)

# Check if moonbeam-mkdocs exists
# If not, clones the repo (requires SSH Cloning)
printf "%s\n" "-------- Mkdocs Repo --------"
if [ ! -d $MKDOCSPATH ] || [ $force == 1 ];
then
  if [ -d "$MKDOCSPATH" ]; then rm -Rf $MKDOCSPATH; fi
  printf "%s\n" "----> Cloning moonbeam-mkdocs Repo - branch ${MKDOCSBRANCH}"
  git clone git@github.com:PureStake/moonbeam-mkdocs.git -b ${MKDOCSBRANCH}
  cd ..
fi

# Pull latests changes from master
cd $MKDOCSPATH
printf "%s\n\n\n" "--> Pulling latest moonbeam-mkdocs changes"
git merge origin/master

# Get moonbeam-docs init/update submodules, and build static site
printf "\n\n%s\n\n" "-------- Moonbeam Docs repo --------"
if [ ! -d $DOCSPATH ] || [ $force == 1 ];
then
  if [ -d "$DOCSPATH" ]; then rm -Rf $DOCSPATH; fi
  printf "%s\n" "----> Cloning moonbeam-docs repo - branch ${ENBRANCH} "
  git clone https://github.com/PureStake/moonbeam-docs -b ${ENBRANCH}
  cd ..
else
  printf "%s\n" "----> No cloning needed, pulling latest changes from moonbeam-docs"
  cd $DOCSPATH
  git merge origin/master
  git checkout -b ${ENBRANCH}
  cd ..
fi

# Build static path does not exist or force is enabled
cd $MKDOCSPATH
if [ ! -d $STATICPATH ] || [ $force == 1 ]; then
  if [ -d "$STATICPATH" ]; then rm -Rf $STATICPATH; fi
  printf "%s\n\n\n" "----> Building static site from moonbeam-docs"
  mkdocs build -d $STATICPATH --clean
fi

# ML Steps
for i in "${!ML_SITES[@]}"
do
  printf "\n\n%s\n" "-------- Moonbeam Docs ${ML_SITES[i]} repo --------"
  # This is the static language folder
  TMPSTATICML=$STATICPATH/${ML_SITES[i]}
  # Check and creat the static folder inside the static site
  if [ ! -d $TMPSTATICML ] || [ $force == 1 ]; then
    if [ -d "$TMPSTATICML" ]; then rm -Rf $TMPSTATICML; fi
    printf "%s\n" "----> Creating static folder inside moonbeam-docs static"
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


  # Clone the corresponding moobeam-docs-ML
  cd $TMPBUILDML
  TMPDOCSML=$TMPBUILDML/moonbeam-docs-${ML_SITES[i]}
  if [ ! -d $TMPDOCSML ]
  then
    printf "%s\n" "----> Cloning moonbeam-docs-${ML_SITES[i]} repo - branch ${ML_BRANCH[i]} "
    git clone https://github.com/PureStake/moonbeam-docs-${ML_SITES[i]}.git -b ${ML_BRANCH[i]}
  else
    printf "%s\n" "----> No cloning needed, pulling latest changes from moonbeam-docs-${ML_SITES[i]}"
    cd $TMPDOCSML
    git merge origin/master
  fi
  
  # Create Symlinks to moonbeam-docs
  # These symlinks depends if legacy or revamp
  printf "%s\n" "----> Creating symlinks for files inside moonbeam-docs"
  [ ! -L $TMPDOCSML/variables.yml ] && ln -s $DOCSPATH/variables.yml $TMPDOCSML/variables.yml
  [ ! -L $TMPDOCSML/images ] && ln -s $DOCSPATH/images $TMPDOCSML/images
  [ ! -L $TMPDOCSML/js ] && ln -s $DOCSPATH/js $TMPDOCSML/js
  [ ! -L $TMPDOCSML/.snippets/code ] && ln -s $DOCSPATH/.snippets/code $TMPDOCSML/.snippets/code


  # Build each of the ML sites
  printf "%s\n" "----> Building the static ${ML_SITES[i]} site"
  cd $TMPBUILDML
  mkdocs build -d $TMPSTATICML --clean

  printf "%s\n\n\n" "----> Post processing static"
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
done
