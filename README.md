# Build Mkdocs Based Docs Site Static Locally

This repo helps you build the Mkdocs Based Docs site (all Languages) locally as a static site.

It uses a bash script to build the entire static structure, and then the npm package `http-server` to serve the static site locally.

**If you are using MacOS you should install `gcp` package by running `brew install coreutils`! The check is done via `uname` and the return value is compared with `Linux` for Ubuntu. You'll also need to install `gnu-sed` which you can do by running `brew install gnu-sed`.**

## Getting Started - Building the File Structure

**This repo assumes you have all the dependencies of the Mkdocs repo installed!**

To get started clone the repo:

```
git clone https://github.com/papermoonio/build-docs-site.git
cd build-docs-site
```

Then you can run the bash file `buildSite.sh` - You might need to change execution permissions by doing the following:

```
chmod u+x ./buildSite.sh
```

With the right execution permissions, run:

```
./buildSite.sh -m papermoonio/wormhole-mkdocs -b main  -o wormhole-foundation/wormhole-docs -e main
```

You need to provide the flag:
 - m <repository> -> mkdocs repository to clone, for example, `papermoonio/wormhole-mkdocs`
 - b \"<mkdocs_branch>\" -> mkdocs branch to clone, for example, `main`
 - o \"<en_DOCS>\" ->  docs repository to clone, for example, `wormhole-foundation/wormhole-docs`
 - e \"<en_branch>\" -> docs branch to clone, for example, `main`

Optional flags for docs with multiple languages:

 - s \"<cn_DOCS>\" ->  chinese docs repository to clone, for example, `moonbeam-foundation/moonbeam-docs-cn`
 - c \"<cn_branch>\" -> cn docs branch to clone, for example, `main`

For example:

```
./buildSite.sh -f -m papermoonio/moonbeam-mkdocs -b "master" -o "moonbeam-foundation/moonbeam-docs" -e "master" -s "moonbeam-foundation/moonbeam-docs-cn" -c "master"
```

## Serving the Static Site

Once the file structure has been built, you need to install the npm packages with `yarn` or `npm i`:

```
yarn
```

Or:

```
npm i
```

Then you can serve the static site in port `8000` with the following command:

```
yarn start
```

Or you can run the command manually with:

```
npx http-server ./moonbeam-docs-static/ -p 8000
```

You can find more info on `http-server` [here](https://www.npmjs.com/package/http-server).
