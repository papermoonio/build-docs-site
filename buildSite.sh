#!/bin/bash

usage() { echo "Usage: $0 [-f] [-c \"<cn_branch>\"]" 1>&2; exit 0; }

force=0
CNBRANCH="master"
ESBRANCH="master"
FRBRANCH="master"
RUBRANCH="master"
while getopts ":fc:" arg; do
    case "${arg}" in
        f)
            force=1
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
MKDOCSLEGACYPATH=$ORIGINPATH/moonbeam-mkdocs-legacy
DOCSPATH=$MKDOCSPATH/moonbeam-docs
DOCSLEGACYPATH=$MKDOCSLEGACYPATH/moonbeam-docs-legacy
STATICPATH=$ORIGINPATH/moonbeam-docs-static
# Github Moonbeam-docs latest legacy commit hash for legacy sites
LEGACY_DOCS="6920f333d7ab94f99807632579354fc166e53626"
LEGACY_MKDOCS="e84e20d0bb83a811efa414adba01e5b75e970245"

printf "\n%s\n\n" "======== Moonbeam Docs Static Site Builder ========"


# Define Revamped and Legacy Sites
REVAMP_LG=("cn")
LEGACY_LG=("es" "fr" "ru")
ML_SITES=(${REVAMP_LG[@]} ${LEGACY_LG[@]})
ML_BRANCH=($CNBRANCH $ESBRANCH $FRBRANCH $RUBRANCH)

# Check if moonbeam-mkdocs exists
# If not, clones the repo (requires SSH Cloning)
printf "%s\n" "-------- Mkdocs Repo --------"
if [ ! -d $MKDOCSPATH ] && [ ! -d $MKDOCSLEGACYPATH ] || [ $force == 1 ];
then
  printf "%s\n" "----> Cloning moonbeam-mkdocs Repo"
  mkdir $MKDOCSLEGACYPATH
  git clone git@github.com:PureStake/moonbeam-mkdocs.git
  git clone git@github.com:PureStake/moonbeam-mkdocs.git $MKDOCSLEGACYPATH
  cd $MKDOCSLEGACYPATH
  git checkout $LEGACY_MKDOCS
  cd ..
fi

# Pull latests changes from master
cd $MKDOCSPATH
printf "%s\n\n\n" "--> Pulling latest moonbeam-mkdocs changes"
git merge origin/master

# Get moonbeam-docs init/update submodules, and build static site
printf "\n\n%s\n\n" "-------- Moonbeam Docs repo --------"
if [ ! -d $DOCSPATH ] && [ ! -d $DOCSLEGACYPATH ] || [ $force == 1 ];
then
  printf "%s\n" "----> Cloning moonbeam-docs repo"
  mkdir $DOCSLEGACYPATH
  git clone git@github.com:PureStake/moonbeam-docs.git
  git clone git@github.com:PureStake/moonbeam-docs.git $DOCSLEGACYPATH
  cd $DOCSLEGACYPATH
  git checkout $LEGACY_DOCS
  cd ..
else
  printf "%s\n" "----> No cloning needed, pulling latest changes from moonbeam-docs"
  cd $DOCSPATH
  git merge origin/master
  cd ..
fi
printf "%s\n" "----> Initializing submodules"
cd $DOCSPATH
git submodule update --init 
cd $DOCSLEGACYPATH
git submodule update --init 

# Build static path does not exist or force is enabled
cd $MKDOCSPATH
if [ ! -d $STATICPATH ] || [ $force == 1 ]; then
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
  if [ ! -d $TMPSTATICML ]; then
    printf "%s\n" "----> Creating static folder inside moonbeam-docs static"
    mkdir $TMPSTATICML
  fi
  #

  # Create each ML mkdocs directory
  # This is the mkdocs language folder
  TMPBUILDML=$MKDOCSPATH-${ML_SITES[i]}
  if [ ! -d $TMPBUILDML ]; then
    printf "%s\n" "----> Creating mkdocs-${ML_SITES[i]} folder"
    mkdir $TMPBUILDML
  fi

  # Create symlinks for mkdocs
  # This symlink depends if legacy or revamp
  printf "%s\n" "----> Creating material-overrides symlinks"
  if [[ " ${REVAMP_LG[*]} " =~ " ${ML_SITES[i]} " ]]; 
  then
    [ ! -d $TMPBUILDML/material-overrides ] && cp -Rs $MKDOCSPATH/material-overrides/ $TMPBUILDML
  else
    [ ! -d $TMPBUILDML/material-overrides ] && cp -Rs $MKDOCSLEGACYPATH/material-overrides/ $TMPBUILDML
  fi

  # Copy the ML mkdocs specific content
  # This symlink depends if legacy or revamp
  printf "%s\n" "----> Creating mkdocs.yml symlink"
  if [[ " ${REVAMP_LG[*]} " =~ " ${ML_SITES[i]} " ]]; 
  then
    [ ! -f $TMPBUILDML/mkdocs.yml ] && cp -Rsf $MKDOCSPATH/mkdocs-${ML_SITES[i]}/* $TMPBUILDML
  else
    [ ! -f $TMPBUILDML/mkdocs.yml ] && cp -Rsf $MKDOCSLEGACYPATH/mkdocs-${ML_SITES[i]}/* $TMPBUILDML
  fi

  # Clone the corresponding moobeam-docs-ML
  cd $TMPBUILDML
  TMPDOCSML=$TMPBUILDML/moonbeam-docs-${ML_SITES[i]}
  if [ ! -d $TMPDOCSML ]
  then
    printf "%s\n" "----> Cloning moonbeam-docs-${ML_SITES[i]} repo"
    git clone git@github.com:PureStake/moonbeam-docs-${ML_SITES[i]}.git -b ${ML_BRANCH[i]}
  else
    printf "%s\n" "----> No cloning needed, pulling latest changes from moonbeam-docs-${ML_SITES[i]}"
    cd $TMPDOCSML
    git merge origin/master
  fi
  
  # Create Symlinks to moonbeam-docs
  # These symlinks depends if legacy or revamp
  printf "%s\n" "----> Creating symlinks for files inside moonbeam-docs"
  if [[ " ${REVAMP_LG[*]} " =~ " ${ML_SITES[i]} " ]]; 
  then
    [ ! -L $TMPDOCSML/.gitmodules ] && ln -s $DOCSPATH/.gitmodules $TMPDOCSML/.gitmodules
    [ ! -L $TMPDOCSML/variables.yml ] && ln -s $DOCSPATH/variables.yml $TMPDOCSML/variables.yml
    [ ! -L $TMPDOCSML/images ] && ln -s $DOCSPATH/images $TMPDOCSML/images
    [ ! -L $TMPDOCSML/js ] && ln -s $DOCSPATH/js $TMPDOCSML/js
    [ ! -L $TMPDOCSML/snippets/code ] && ln -s $DOCSPATH/snippets/code $TMPDOCSML/snippets/code
    [ ! -L $TMPDOCSML/learn/dapps-list ] && ln -s $DOCSPATH/learn/dapps-list $TMPDOCSML/learn/dapps-list
  else
    [ ! -L $TMPDOCSML/.gitmodules ] && ln -s $DOCSLEGACYPATH/.gitmodules $TMPDOCSML/.gitmodules
    [ ! -L $TMPDOCSML/variables.yml ] && ln -s $DOCSLEGACYPATH/variables.yml $TMPDOCSML/variables.yml
    [ ! -L $TMPDOCSML/images ] && ln -s $DOCSLEGACYPATH/images $TMPDOCSML/images
    [ ! -L $TMPDOCSML/js ] && ln -s $DOCSLEGACYPATH/js $TMPDOCSML/js
    [ ! -L $TMPDOCSML/snippets/code ] && ln -s $DOCSLEGACYPATH/snippets/code $TMPDOCSML/snippets/code
    [ ! -L $TMPDOCSML/dapps-list ] && ln -s $DOCSLEGACYPATH/dapps-list $TMPDOCSML/dapps-list
  fi

  # Build each of the ML sites
  printf "%s\n" "----> Building the static ${ML_SITES[i]} site"
  cd $TMPBUILDML
  mkdocs build -d $TMPSTATICML --clean

  printf "%s\n\n\n" "----> Post processing static"
  # fix relative links to include language subdir
  find $TMPSTATICML -type f -name index.html -exec sed -i "s|href=\"\/|href=\"\/$lang\/|g" '{}' \;
  # temporary patch to fix relative path of the assets to 
  # an absolute path in multi language folders
  find $TMPSTATICML -type f -name index.html -exec sed -i "s|href=\"\/$lang\/assets\/|href=\"\/assets\/|g" '{}' \;
  # remove images folder of the static sites as they are not necessary
  rm -rf $TMPSTATICML/images/
done